%   Package: update
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: Utilities for updating "data-base" relations.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  The idea is that to update all the tuples in a relation you call
	update(r(A,...,Z), new_r(A,...,Z))
    where A...Z must be variables, and new_r is a goal or body which
    computes all the new tuples (unit clauses) including any tuples
    that haven't changed.

    Another thing one sometimes wants to do is to add a set of tuples
    to a relation without deleting the old ones:
	extend(r(A,...,Z), new_r(A,...,Z))
    adds all the solutions found by new_r to r.

    A third thing one sometimes wants to do in data base work is to
    change a set of tuples.  The command for this is
	modify(OldPattern, NewPattern, Transformer).
    What this does is, for each tuple matching OldPattern such that
    Transformer succeeds (once), to replace that tuple by whatever
    the NewPattern turns into.  OldPattern and NewPattern must have
    the same principal functor.  Note that we declare the first
    argument of modify/3 to be a meta-argument (so we get the module
    name prefix) but NOT the second argument (to avoid any problems
    with perhaps getting a different module prefix).  Ideally, we
    would like the tuples to be modified in place.  Unfortunately,
    there is no way of doing that, so the modified tuples move to
    the front of the table.  That shouldn't worry real relational
    work, as the order isn't supposed to matter.  The relation MUST
    not be modified by the Transformer.

    The fourth operation is to delete a set of tuples satisfying
    some criterion:
	delete(r(A,...,Z), p(A,...,Z))
    every tuple of r which satisifies the general goal p will be
    deleted.  If p is 'true', this reduces to retractall.

    Note for Quintus Prolog users: the relations to be modified
    should be declared :-dynamic.  update/2 will automatically
    make the relation it is updating dynamic if it didn't exist
    before (courtesy of asserta), but you cannot use any of these
    commands to modify :-static code.

    Release 2.0 note: a lot of the point of these commands has gone
    now that the semantics of data base updates has been changed to
    a "transaction"-oriented definition.  But using these routines
    is still a good way to make it clear what you're up to, and it
    will improve the portability of your code.  Retractall/1 is now
    part of the system, so its definition is commented out.

*/

:- module(update, [
	delete/2,
	extend/2,
	modify/3,
	update/2
   ]).
:- meta_predicate
	delete(0, 0),
	extend(0, 0),
	modify(0, +, 0),
	update(0, 0).

:- use_module(library(critical)).

sccs_id('"@(#)89/08/29 update.pl	33.2"').


%   retractall(Template)
%   erases all the clauses whose heads match Template, but does
%   not forget the fact that the predicate was :- dynamic.
%   This used to be defined here, but is now part of the
%   Quintus Prolog released system (much more efficient too).
/*
:- use_module(library(types), [must_be_callable/3]).

retractall(Template) :-
	Goal = retractall(Template),
	must_be_callable(Template, 1, Goal),
	(   begin_critical,
	    clause(Template, _, Ref),
	    erase(Ref),
	    fail
	;   end_critical
	).
*/

%   delete(Template, Selector)
%   deletes all the instances of Template for which Selector has
%   a provable instance.  Note that when Selector is 'true' it is
%   still not quite the same as retractall(Template): it only
%   erases clauses whose bodies are 'true'.

delete(Template, Selector) :-
	update_head(Template, user, Head, Module, _, _),
	!,
	recorda(., ., Ref),		% mark the "stack"
	(   clause(Module:Head, true, Cref),
	    (   call(Selector) -> true   ),
	    recorda(., Cref, _),	% note that Cref is to be deleted
	    fail
	;   begin_critical,		% keep control-Cs away for a while
	    recorded(., Cref, Rref),	% for each note in the stack
	    erase(Rref),		% erase it from the stack, then
	    (   Rref = Ref,		% if it is the marker,
		!			% we are finished
	    ;	erase(Cref),		% otherwise, it is a clause to
		fail			% be erased
	    ),
	    end_critical		% let control-Cs happen now.
	).
delete(Template, Selector) :-
	format(user_error,
	    '~N! Bad predicate argument to ~q~n! Goal: ~q~n',
	    [delete/2, delete(Template,Selector)]),
	fail.



%   update(Template, Generator)
%   effectively replaces the definition of Template's predicate
%   by the extension of Template :- Generator.  That is, for each
%   proof of Generator, the corresponding instance of Template
%   will be stored as a fact, and the previous definition of
%   Template's predicate will be completely lost.  We use the
%   recorded data base to avoid the cost of dynamic indexing.

update(Template, Generator) :-
	update_head(Template, user, Head, Module, Symbol, Arity),
	!,
	recorda(., ., Ref),		%  mark the "stack"
	(   call(Generator),		%  for all proofs of Generator
	    recorda(., Head, _),	%  save an instance of Template
	    fail			%  failure-driven loop
	;   begin_critical,		%  Keep Control-Cs away for a while
	    abolish(Module:Symbol/Arity),
	    recorded(., Tuple, DbRef),	%  for all saved instances
	    erase(DbRef),		%  pop it from the "stack"
	    (   DbRef = Ref,		%  if it is the stack mark,
		!			%  we have finished
	    ;   asserta(Module:Tuple),	%  transfer it to the new relation
	        fail			%  failure-driven loop on recorded/3
	    ),
	    end_critical		%  let control-Cs happen now.
	).
update(Template, Generator) :-
	format(user_error,
	    '~N! Bad predicate argument to ~q~n! Goal: ~q~n',
	    [update/2, update(Template,Generator)]),
	fail.


%.  update_head(+Head0, +Module0, -Head, -Module, -Symbol, -Arity)

update_head(M:H, _, Head, Module, Symbol, Arity) :- !,
	atom(M),
	update_head(H, M, Head, Module, Symbol, Arity).
update_head(Head, Module, Head, Module, Symbol, Arity) :-
	nonvar(Head),
	functor(Head, Symbol, Arity),
	atom(Symbol),
	(   predicate_property(Module:Head, (dynamic)) ->
	    true					% already dynamic
	;   \+ P^predicate_property(Module:Head, P)	% or undefined
	).



%   extend(Template, Generator)
%   adds a suitable instance of Template to its predicate for each
%   proof of Generator, unless just such a fact already exists.
%   In effect it replaces the definition of Template's predicate
%   by the union of that predicate with (the solutions of) Generator.
%   The new clauses are added at the end of the predicate in reverse
%   order.  (Forward order at the front would be possible, but I can
%   not find an easy way to get forward order at the end and still
%   allow extend/2 and update/2 calls to be nested.

extend(Template, Generator) :-
	update_head(Template, user, Head, Module, _, _),
	!,
	recorda(., ., Ref),		%  mark the "stack"
	(   call(Generator),		%  for all proofs of Generator
	    recorda(., Head, _),	%  save an instance of Template
	    fail			%  failure-driven loop
	;   begin_critical,		%  Keep Control-Cs away for a while
	    recorded(., Tuple, DbRef),	%  for all saved instances
	    erase(DbRef),		%  pop it from the "stack"
	    (   DbRef = Ref,		%  if it is the stack mark,
		!			%  we have finished
	    ;   cassert(Module, Tuple),	%  transfer it to the new relation
	        fail			%  failure-driven loop on recorded/3
	    ),
	    end_critical		%  let control-Cs happen now.
	).
extend(Template, Generator) :-
	format(user_error,
	    '~N! Bad predicate argument to ~q~n! Goal: ~q~n',
	    [extend/2, extend(Template,Generator)]),
	fail.


%   cassert(Module, Fact)
%   adds Module:Fact to the data base unless it is already there.
%   It only works for unit clauses, and checks for Heads which are
%   alphabetic variants of Fact.  If the clause is already present,
%   Fact is left ground, so this command should be the last thing
%   in a failure-driven loop, as in fact it is.

cassert(Module, Fact) :-
	numbervars(Fact, 0, _),		% make Fact ground
	clause(Module:Fact, true, Ref),	% find a matching clause
	instance(Ref, :-(Head,true)),	% get a fresh copy of its head
	numbervars(Head, 0, _),		% and make that copy ground
	Head = Fact,			% check that Head and Fact
	!.				% are alphabetic variants.
cassert(Module, Fact) :-
	assertz(Module:Fact).		% not already present.


modify(Template, NewPattern, Transformer) :-
	update_head(Template, user, OldPattern, Module, Symbol, Arity),
	functor(NewPattern, Symbol, Arity),
	!,
	recorda(., ., Ref),			% mark the "stack"
	(   clause(Module:OldPattern, true),	% enumerate old clauses <A>
	    (   call(Transformer) ->		% calculate a new clause
		    recorda(., NewPattern, _)	%    record new clause
	    ;   /* no change -> */		% cannot transform clause
		    recorda(., OldPattern, _)	%    so copy old clause
	    ),
	    fail				% failure-driven loop
	;   begin_critical,			% Keep Control-Cs away
	    retractall(Module:OldPattern),	% zaps clauses found at <A>
	    recorded(., Tuple, DbRef),		% enumerate clauses (in
	    erase(DbRef),			% reverse order!)
	    (   DbRef = Ref,			% if it is the stack mark
		!				% we have finished
	    ;   asserta(Module:Tuple),		% put new clause in relation
		fail				% failure-driven recorded loop
	    ),
	    end_critical			% let Control-Cs happen now.
	).
modify(Template, NewPattern, Transformer) :-
	(   update_head(Template,user,_,_,_,_) ->
	    Message = '1st and 2nd arguments of modify/3 disagree'
	;   Message = 'Bad predicate argument to modify/3'
	),
	format(user_error, '~N! ~w~n! Goal: ~q~n',
	    [Message, modify(Template,NewPattern,Transformer)]),
	fail.

