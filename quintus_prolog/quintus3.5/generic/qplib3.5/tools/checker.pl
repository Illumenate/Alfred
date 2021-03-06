/*  File   : checker.pl
    Updated: 07 Sep 1990
    Purpose: Check compatibility between Prolog-20/C-Prolog and Quintus Prolog
    Copyright (C) 1985, 1990, Quintus Computer Systems, Inc.


    % qpchecker <File>

    reads a Prolog file, which is presumed to run on Prolog-20 or
    C-Prolog or something similar (and recursively, any files it loads),
    and prints warnings about predicates or expressions which may not
    work as expected under Quintus Prolog.

    A ".pl" suffix on File may be omitted.  Several files, rather than
    just a single file, may also be specified.

    Note that some warning messages may be ignored.  In particular, if
    you define a predicate and then get a message saying that that
    predicate is not implemented, then there is no problem.  This can
    happen because the checker considers 2 dialects of Prolog which you
    may be porting from:  Prolog-20 and C-Prolog.  (Note:  it can be
    modified for porting from Edinburgh DAI C-Prolog by putting back
    some clauses for incompatible/2 which are commented out below.)
    "<number> is suspect" messages are also often ignorable:  you get
    warned about every occurrence of 26 and 31 because these were the
    end-of-file and new-line characters in Prolog-20.  If a 26 IS being
    used as an end-of-file character you should change it to -1, and if
    a 31 IS being used for new-line you should change it to 10.  You may
    prefer to use the library predicates is_endfile/1 and is_newline/1.

    If you are porting from some other dialect of Prolog, you may want
    to extend the checker by adding new clauses for incompatible/2
    below.

    The checker recognises Quintus Prolog module-related predicates and
    constructs introduced in Release 2.0.  For example, a "file list"
    may be xyz:[f1, f2, f3] in compile/1, consult/1, and ensure_loaded/1,
    where xyz is the module name and f1, f2, f3 are files.  Also, a
    subgoal may be xyz:g(X), where g is a predicate visible in module xyz.
*/

:- module(checker, [
	check/1
   ]).
:- use_module(library(basics), [
	member/2
   ]),
   use_module(library(files), [
	file_must_exist/1
   ]).

sccs_id('"@(#)90/09/07 checker.pl	56.1"').


:- dynamic
	finished/1,
	is_dynamic/1,
	warn_user/2.


check(F) :-
	retractall(finished(_Path)),
	check(F, []).

checker(Files) :- check(Files).


% 2nd arg is list of ancestor files to avoid use_module loops.
check([], _) :- !.
check(_M:Files, Ancs) :- !,
	check(Files, Ancs).
check([File|Files], Ancs) :- !,
	check(File, Ancs),
	check(Files, Ancs).
check(File, Ancs) :-
	absolute_file_name(File, Path),
	(   member(Path, Ancs) -> true
	|   finished(Path) -> true
	|   file_must_exist(Path)  -> check_file(Path, [Path|Ancs])
	|   true
	).

check_file(Path, Ancs) :-
	length(Ancs, L),
	Indent is (L-1)*2,
	tab(Indent), write('[ '), write(Path), write(' started ]'), nl,
	current_input(OldS),
	open(Path, read, S),
	set_input(S),
	repeat,
	    read(Clause),
	    check_clause(Clause, Ancs),
	    print_warnings(Clause, Ancs),
	    Clause == end_of_file,
	!,
	close(S),
	set_input(OldS),
	assertz(finished(Path)),
	tab(Indent), write('[ '), write(Path), write(' checked ]'), nl.


check_clause(Clause, _) :- check_suspect_numbers(Clause), fail.
check_clause((Head :- Body), _) :- !, check_head(Head), check_goals(Body).
check_clause((:- Command), Ancs) :- !, process(Command, Ancs).
check_clause((?- Command), Ancs) :- !, process(Command, Ancs).
check_clause(C, _) :- check_head(C).

check_head(H) :-
	predicate_property(H, built_in),
	!,
	functor(H, F, N),
	note_warning(F/N, 'is a built-in predicate').
check_head(_).



% Also, detect goal of the form  module:pred(...)   for Rel 2.0  below.
% Note that only built-in predicates which take expression or goal
% arguments have those arguments specially checked, and that you cannot
% redefine built-in predicates.

check_goals(V) :- var(V), !.
check_goals((P,Q))	  :- !, check_goals(P), check_goals(Q).
check_goals((P;Q))	  :- !, check_goals(P), check_goals(Q).
check_goals((P->Q))	  :- !, check_goals(P), check_goals(Q).
check_goals(\+(G))	  :- !, check_goals(G).
check_goals(setof(_,G,_)) :- !, check_goals(G).
check_goals(bagof(_,G,_)) :- !, check_goals(G).
check_goals((_M:P))	  :- !, check_goals(P).
/*  Edinburgh DAI C-Prolog:
check_goals(cases(G))     :- !, check_goals(G),
	note_warning((cases)/1, 'is not implemented').	*/
check_goals(Goal) :-
	evaluates_arg(Goal, I),
	arg(I, Goal, Expression),
	check_expression(Expression),
	fail.
check_goals(Goal) :-
	incompatible(Goal, Warning),
	functor(Goal, F, N),
	note_warning(F/N, Warning),
	fail.
check_goals(_).


process(op(P,T,O), _) :- !, op(P,T,O).
process(dynamic(X), _) :- !, process_dynamic_decl(X).
process(multifile(_), _) :- !.
process(meta_predicate(_), _) :- !.
process(module(_,_), _) :- !.
process(compile(X), Ancs) :- !, check_load(X, Ancs).
process(consult(X), Ancs) :- !, check_load(X, Ancs).
process(ensure_loaded(X), Ancs) :- !, check_load(X, Ancs).
process(use_module(X,_), Ancs) :- !, check_load(X, Ancs).
process(use_module(X), Ancs) :- !, check_load(X, Ancs).
process(use_module(_,X,_), Ancs) :- !, check_load(X, Ancs).
process([H|T], Ancs) :- !, check_load([H|T], Ancs).
process((A,B), Ancs) :- !, process(A, Ancs), process(B, Ancs).
process((A;B), Ancs) :- !, process(A, Ancs), process(B, Ancs).
process(Goal, _) :- check_goals(Goal).

%   If someone has already put dynamic declarations in, suppress any
%   warning messages on explicit asserts and retracts of those predicates.

process_dynamic_decl((D1,D2)) :- !,
	process_dynamic_decl(D1),
	process_dynamic_decl(D2).
process_dynamic_decl(Name/Arity) :-
	functor(Term,Name,Arity),
	asserta(is_dynamic(Term)).


/* Check an arithmetic expression. */

check_expression(V) :-
	var(V), !.
check_expression(X) :-			% Intentionally non-determinate
	incompatible_exp(X, Warning),
	functor(X, F, _),
	note_warning(F, Warning).
check_expression(X) :-
	functor(X, _, N),
	check_expression(N, X).

check_expression(0, _) :- !.
check_expression(N, Exp) :-
	arg(N, Exp, Arg),
	check_expression(Arg),
	M is N-1,
	check_expression(M, Exp).

%   check_load recursively checks files in load directives,
%   but not library files.  A.V.G.

check_load([], _Ancs) :- !.
check_load([H|T], Ancs) :- !, check_load(H, Ancs), check_load(T, Ancs).
check_load(library(_), _Ancs) :- !.
check_load(F, Ancs) :- check(F, Ancs).



%   Check for numbers with special significance to Prolog-20/C-Prolog
%   which do not have the same significance in Quintus Prolog.

check_suspect_numbers(V) :-
	var(V), !.
check_suspect_numbers(26) :- !,
	note_warning(26, 'is suspect - it was the end-of-file character').
check_suspect_numbers(31) :- !,
	note_warning(31, 'is suspect - it was the Prolog-20 new-line character').
check_suspect_numbers(Term) :-
	functor(Term, _, Arity),
	check_suspect_numbers(Arity, Term).

check_suspect_numbers(0, _) :- !.
check_suspect_numbers(N, Term) :-
	arg(N, Term, Arg),
	check_suspect_numbers(Arg),
	M is N-1,
	check_suspect_numbers(M, Term).


note_warning(Culprit, Warning) :-
	warn_user(Culprit, Warning),
	!.
note_warning(Culprit, Warning) :-
	assertz(warn_user(Culprit, Warning)).


there_are_warnings :-
	warn_user(_, _),
	!.


%   Prints the clause if there are any warnings for it,
%   followed by all the warnings.

print_warnings(Clause, Ancs) :-
	there_are_warnings,			% for this clause?
	length(Ancs, L),
	Indent is (L-1)*2,
	nl,
	user:portray_clause(Clause),		% Yes, print the clause
	retract(warn_user(Culprit,Warning)),	% Backtrack through all 
	tab(Indent),
	write('[ Warning: '),			% warnings for this clause
	writeq(Culprit),
	put(" "), write(Warning),
	write(' ]'), nl,
	fail.
print_warnings(_,_).

% Table indicating which built-in predicates evaluate which of their
% arguments as arithmetic expressions.

evaluates_arg(_ is _, 2).
evaluates_arg(_ < _, 1).
evaluates_arg(_ < _, 2).
evaluates_arg(_ > _, 1).
evaluates_arg(_ > _, 2).
evaluates_arg(_ =< _, 1).
evaluates_arg(_ =< _, 2).
evaluates_arg(_ >= _, 1).
evaluates_arg(_ >= _, 2).
evaluates_arg(_ =:= _, 1).
evaluates_arg(_ =:= _, 2).
evaluates_arg(_ =\= _, 1).
evaluates_arg(_ =\= _, 2).
evaluates_arg(put(_), 1).
evaluates_arg(skip(_), 1).
evaluates_arg(tab(_), 1).
evaluates_arg(ttyput(_), 1).
evaluates_arg(ttyskip(_), 1).
evaluates_arg(ttytab(_), 1).
evaluates_arg(put(_,_), 2).
evaluates_arg(skip(_,_), 2).
evaluates_arg(tab(_,_), 2).


% Incompatible Predicates
						% PROLOG-20
incompatible('LC','is not implemented').
incompatible('NOLC','is not implemented').
incompatible(consult(_),'in Quintus Prolog is equivalent to reconsult in Prolog-20 or C-Prolog').
incompatible(current_functor(_,_),'is not implemented').
incompatible(log,'is not implemented').
incompatible(nolog,'is not implemented').
incompatible(rename(_,_),'is in library(files)').
incompatible(revive(_,_),'is not implemented').
incompatible(reconsult(_),'is called consult in Quintus Prolog').

incompatible(plsys(_),'is not implemented').	% DEC10 but not Prolog-20
incompatible(core_image,'is not implemented').	% old DEC10, not Prolog-20
incompatible(run(_,_),'is not implemented').
incompatible(tmpcor(_,_,_),'is not implemented').

						% C-Prolog
incompatible(erased(_),'is not implemented').
incompatible(exists(_),'is not implemented, but see library(files)').
incompatible(expanded_exprs(_,_),'is not implemented').
incompatible(primitive(_),'is not implemented').
incompatible(sh,'is not implemented, use unix(shell)').
incompatible(system(_),'is not implemented, use unix(shell(_))').

/***********************************************************************
						% Edinburgh DAI C-Prolog
						% (version 1.5.edai)
incompatible(all_float(_,_),'is not implemented').
incompatible(append(_),'is not implemented, but see open/3').
incompatible(cd(_),'is not implemented, but see unix/1').
incompatible(chtype(_,_,_),'is not implemented').
incompatible(compound(_),'is not implemented, but see library(types)').
incompatible(current_line_number(_),
	'is not implemented, but see line_count/2').
incompatible(current_line_number(_,_),
	'is not implemented, but see line_count/2').
incompatible(deny(_,_),'is not implemented').
incompatible(findall(_,_,_,_),'is not implemented, but see library(findall)').
incompatible(is(_,_,_),'is not implemented').
incompatible(is(_,_,_,_),'is not implemented').
incompatible(is_op(_,_,_,_,_),'is not implemented').
incompatible(lib(_),'is not implemented').
incompatible(lib(_,_),'is not implemented').
incompatible(merge(_,_,_),'is not implemented').
incompatible(msort(_,_),'is not implemented').
incompatible(not(_),'is not implemented - use \+ or see library(not)').
incompatible(note_lib(_),'is not implemented').
incompatible(occurs_check(_,_),'is not implemented, but see library(unify)').
incompatible(once(_),'is not implemented').
incompatible(peek(_),'is not implemented, but see peek_char(_)').
incompatible(peek0(_),'is not implemented, but see peek_char(_)').
incompatible(plus(_,_,_),'is not implemented').
incompatible(read(_,_),'is not implemented, see read_term').
incompatible(same_functor(_,_),'is in library(same_functor)').
incompatible(same_functor(_,_,_),'is in library(same_functor)').
incompatible(same_functor(_,_,_,_),'is in library(same_functor)').
incompatible(seeing(_,_),'is not implemented').
incompatible(shell(_),'is not implemented, but see unix/1').
incompatible(simple(_),'is not implemented, but see library(types)').
incompatible(succ(_,_),'is not implemented').
incompatible(telling(_,_),'is not implemented').
incompatible(ttyflush(_),'is not implemented, use flush_output/1').
incompatible(unify(_,_),'is not implemented, but see library(unify)').
incompatible(eq(_,_),'is not implemented, use (=:=)/2').
incompatible(ge(_,_),'is not implemented, use (>=)/2').
incompatible(gt(_,_),'is not implemented, use (>)/2').
incompatible(le(_,_),'is not implemented, use (=<)/2').
incompatible(lt(_,_),'is not implemented, use (<)/2').
incompatible(ne(_,_),'is not implemented, use (=\=)/2').
/**********************************************************************/

						% NEW PREDICATES

/* "Vanilla" new built-in predicates as subgoals get no warning.  A.V.G.  */

incompatible(dynamic(_),'is reserved for dynamic declarations').
incompatible(foreign(_,_),'is used in loading foreign files').
incompatible(foreign(_,_,_),'is used in loading foreign files').
incompatible(foreign_file(_,_),'is used in loading foreign files').
	    
	% New predicates in Release 1.5

incompatible(multifile(_),'is reserved for multifile declarations').

	% New predicates in Release 2.0

incompatible(module(_,_),'is reserved for module declarations').
incompatible(meta_predicate(_),'is reserved for meta predicate declarations').

% A dynamic declaration must precede the definitions of predicates which are
% to be asserted or retracted.  However, if there is no source for the
% predicate (all its clauses are asserted) then the dynamic declaration is
% not needed.

incompatible(assert(C), Warning)    :- head(C, H), isnt_dynamic(H, Warning).
incompatible(asserta(C), Warning)   :- head(C, H), isnt_dynamic(H, Warning).
incompatible(assertz(C), Warning)   :- head(C, H), isnt_dynamic(H, Warning).
incompatible(assert(C,_), Warning)  :- head(C, H), isnt_dynamic(H, Warning).
incompatible(asserta(C,_), Warning) :- head(C, H), isnt_dynamic(H, Warning).
incompatible(assertz(C,_), Warning) :- head(C, H), isnt_dynamic(H, Warning).
incompatible(retract(C), Warning)   :- head(C, H), isnt_dynamic(H, Warning).
incompatible(clause(H,_), Warning)  :-		   isnt_dynamic(H, Warning).
incompatible(clause(H,_,_), Warning) :-		   isnt_dynamic(H, Warning).
incompatible(retractall(H), Warning) :-		   isnt_dynamic(H, Warning).


head((H :- _B),H) :- !.
head(H,H).

isnt_dynamic(Head,_) :- 
	nonvar(Head), 
	is_dynamic(Head),		% don't repeat warning 
	!, 
	fail.
isnt_dynamic(Head,'- dynamic declaration of argument may be needed') :-
	(   var(Head) -> true
	;   functor(Head, Name, Arity),
	    functor(MGT, Name, Arity),	% most general term (args all vars)
	    asserta(is_dynamic(MGT))
	).


% Incompatible Expressions

				% PROLOG-20
incompatible_exp(_ / _,
	'means floating point division - use // for integer division').
incompatible_exp(!(_),'is not implemented').
incompatible_exp($(_),'is not implemented').

				% C-Prolog
incompatible_exp(exp(_),'is not implemented').
incompatible_exp(log(_),'is not implemented').
incompatible_exp(log10(_),'is not implemented').
incompatible_exp(sqrt(_),'is not implemented').
incompatible_exp(sin(_),'is not implemented').
incompatible_exp(cos(_),'is not implemented').
incompatible_exp(tan(_),'is not implemented').
incompatible_exp(asin(_),'is not implemented').
incompatible_exp(acos(_),'is not implemented').
incompatible_exp(atan(_),'is not implemented').
incompatible_exp(atan(_,_),'is not implemented').
incompatible_exp(floor(_),'is not implemented - use integer(_)').
incompatible_exp(_ ^ _,'is not implemented').
incompatible_exp(pi,'is not implemented').
incompatible_exp(log2,'is not implemented').
incompatible_exp(cputime,'may not appear in expression - use statistics/2').
incompatible_exp(heapused,'may not appear in expression - use statistics/2').
incompatible_exp(stackused,'may not appear in expression - use statistics/2').

				% Edinburgh DAI C-Prolog
incompatible_exp(div(_,_),'is not implemented - use //').
:- op(400, yfx, div).


user:runtime_entry(start) :-
	unix(argv(L)), 
	check(L), 
	halt.
