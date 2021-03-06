%   Package: retract
%   Author : Richard A. O'Keefe
%   Updated: 31 May 1990
%   Defines: a complete set of clause-at-a-time data base updates

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(retract, [
	affirm/2,		%  Head x Body ->
	affirm/3,		%  Head x Body -> DbRef
	affirma/2,		%  Head x Body ->
	affirma/3,		%  Head x Body -> DbRef
	affirmz/2,		%  Head x Body ->
	affirmz/3,		%  Head x Body -> DbRef
	affirmed/2,		%  Head x Body
	affirmed/3,		%  Head x Body x DbRef
	asserted/1,		%  Clause
	asserted/2,		%  Clause x DbRef
	deny/2,			%  Head x Body
	deny_every/1,		%  Head ->
	deny_every/2,		%  Head x Body ->
	deny_first/1,		%  Head ->
	deny_first/2,		%  Head x Body ->
	make_defined/1,		%  Goal ->
	make_dynamic/1,		%  Goal ->
	record/2,		%  Key x Term ->
	record/3,		%  Key x Term -> Ref
	recorda/2,		%  Key x Term ->
	recordz/2,		%  Key x Term ->
	recorded/2,		%  Key x Term
	retract_every/1,	%  Clause ->
	retract_first/1,	%  Clause ->
	wipe/2,			%  Key x Term
	wipe_every/1,		%  Key ->
	wipe_every/2,		%  Key x Term ->
	wipe_first/1,		%  Key ->
	wipe_first/2		%  Key x Term ->
   ]).	

:- meta_predicate
	affirm(0, +),		%  Head x Body ->
	affirm(0, +, -),	%  Head x Body -> DbRef
	affirma(0, +),		%  Head x Body ->
	affirma(0, +, -),	%  Head x Body -> DbRef
	affirmz(0, +),		%  Head x Body ->
	affirmz(0, +, -),	%  Head x Body -> DbRef
	affirmed(0, ?),		%  Head x Body
	affirmed(0, ?, ?),	%  Head x Body x DbRef
	asserted(:),		%  Clause
	asserted(:, ?),		%  Clause x DbRef
	deny(0, ?),		%  Head x Body
	deny_every(0),		%  Head
	deny_every(0, ?),	%  Head x Body
	deny_first(0),		%  Head
	deny_first(0, ?),	%  Head x Body
	make_defined(0),	%  Goal ->
	make_dynamic(0),	%  Goal ->
	retract_every(:),	%  Clause !
	retract_first(:).	%  

%  Note that the record-/wipe- family are NOT meta-predicates!

sccs_id('"@(#)90/05/31 retract.pl	49.1"').


/*  Quintus Prolog contains the following predicates for changing
    and accessing the clause store:
	assert( +Clause[, -Ref])
	asserta(+Clause[, -Ref])
	assertz(+Clause[, -Ref])
	clause(+Head, ?Body[, ?Ref])
	retract(+Clause)
	retractall(+Head)
    These names are inherited from Dec-10 Prolog.  [You may have
    thought that retractall/1 was an innovation.  It isn't.  It
    used to be in Dec-10 Prolog, but was dropped when abolish/2
    was introduced.  But (a) several other Prolog implementations
    had picked it up, and (b) it turns out that abolish/2 and
    retractall/1 do usefully different things.]

    We *MUST* retain these Dec-10 names for backwards compatibility.
    But it is obvious at first glance that this single list
    contains members of two incomplete families: a family which
    take a clause as argument, and a family which take a separate
    head and body.  The point of this file is to provide a
    rationalised set.

	assert(  +Clause[, -Ref])	affirm(  +Head, +Body[, -Ref])
	asserta( +Clause[,- Ref])	affirma( +Head, +Body[, -Ref])
	assertz( +Clause[, -Ref])	affirmz( +Head, +Body[, -Ref])
	asserted(?Clause[, ?Ref])	affirmed(?Head, ?Body[, ?Ref])
	retract(      +Clause)		deny(      +Head,  ?Body )
	retract_first(+Clause)		deny_first(+Head[, ?Body])
	retract_every(+Clause)		deny_every(+Head[, ?Body])

		    record(  +Key, +Term[, -Ref])
		    recorda( +Key, +Term[, -Ref])
		    recordz( +Key, +Term[, -Ref])
		    recorded(?Key, ?Term[, ?Ref])
		    wipe(      +Key,  ?Term )
		    wipe_first(+Key[, ?Term])
		    wipe_every(+Key[, ?Term])

    Note that the -/-a/-z/-ed series applies to assert-, affirm-,
    and record-.  We use retract_first/1 rather than retracta/1
    because the apparent analogy is in fact false.  retract_first/1
    retracts the first match (and only the first match), while
    retracta/1, were it to exist, would have to retract the first
    clause and then unify it with its argument.  And there is no
    retractz/1, nor ever will be.
    Note that the -/_first/_every series applies to retract-,
    deny-, and wipe-, and that assert/retract, affirm/deny, and
    record/wipe are antonyms.  (erase- would have been a nice
    antonym for record-, but it is taken.)

    affirmed/[2,3] is simply another name for clause/[2,3].
    Similarly, deny_every/1 is simply another name for retractall/1.
    The new names are there to make the patterns complete, hence
    easier to remember.  retractall/1 was always a bit muddling:
    the name suggests that it takes the same kind of argument as
    retract/1, when in fact it takes a clause Head as argument.
    In fact, this whole file was inspired by a customer's "bug"
    report due to the fact that retractall/1 was working just the
    way we said it was supposed to...

    make_dynamic(Goal) is a command for making predicates dynamic.
    make_defined(Goal) is a commend for ensuring that a predicate
    is defined, by giving it an empty dynamic definition if it is
    currently undefined.  (This is how make_dynamic/1 works, too.)
    NOTE WELL: the argument should properly be like the argument
    of spy/1 or abolish/1.  To keep this trial implementation as
    simple as possible, however, the argument is like the first
    argument of predicate_property/2.  In fact, you could do
	( predicate_property(X, (dynamic)) -> true
	; make_dynamic(X)
	)
    where it is the same X in both places.  You are urged to use
    the :- dynamic declaration if you possibly can, instead.  If
    you assert to a predicate before calling it, there is no need
    for any sort of dynamic declaration, as assert will make a
    previously undefined predicate dynamic.

    Have fun.
*/


%   is_db_ref(+Ref)
%   is used in several places to check whether a term, known not to
%   be a variable, is a data base reference.  BEWARE!  Data base 
%   references are now a distinct Prolog term type that have their
%   own type-test, db_reference/1.  is_db_ref/1 has been retained
%   in this file to keep changes minimal; however, db_reference/1
%   could just as well have been used directly, and doing so would
%   in fact be somewhat more efficient.

is_db_ref(Ref) :-
	db_reference(Ref).



%   affirm{,a,z}(Head, Body[, Ref])
%   check the Head, glue the Body onto it, and then call the
%   appropriate version of assert.  Strictly speaking, we should
%   check that the complete clause makes sense, but we leave it
%   to assert to do any checking that is necessary.  Note that
%   assert(H) and assert((H:-true)) do the same thing (provided
%   that H hasn't got (:-)/2 as principal functor, of course).

affirm(Head, Body) :-
	affirm_parts(Head, Body, Module, Clause),
	!,
	assert(Module:Clause).
affirm(Head, Body) :-
	affirm_error(Head, affirm(Head,Body)).


affirm(Head, Body, Ref) :-
	affirm_parts(Head, Body, Module, Clause),
	!,
	assert(Module:Clause, Ref).
affirm(Head, Body, Ref) :-
	affirm_error(Head, affirm(Head,Body,Ref)).


affirma(Head, Body) :-
	affirm_parts(Head, Body, Module, Clause),
	!,
	asserta(Module:Clause).
affirma(Head, Body) :-
	affirm_error(Head, affirma(Head,Body)).


affirma(Head, Body, Ref) :-
	affirm_parts(Head, Body, Module, Clause),
	!,
	asserta(Module:Clause, Ref).
affirma(Head, Body, Ref) :-
	affirm_error(Head, affirm(Head,Body,Ref)).


affirmz(Head, Body) :-
	affirm_parts(Head, Body, Module, Clause),
	!,
	assertz(Module:Clause).
affirmz(Head, Body) :-
	affirm_error(Head, affirmz(Head,Body)).


affirmz(Head, Body, Ref) :-
	affirm_parts(Head, Body, Module, Clause),
	!,
	assertz(Module:Clause, Ref).
affirmz(Head, Body, Ref) :-
	affirm_error(Head, affirm(Head,Body,Ref)).



%   affirm_parts(+Head, +Body, -Module, -Clause)
%   is the common code which checks that the Head and Body
%   make sense, and constructs the Clause.  Note that the
%   case Body = 'true' receives special treatment, while the
%   case Body = 'otherwise' does NOT receive special treatment.
%   This is true of the built in operations as well:
%	assert((Head:-true)) will have the :-true pruned, but
%	assert((Head:-otherwise)) will NOT change its form.
%   The 'affirmed' family is consistent with the 'asserted' family.

affirm_parts(Head0, Body, Module, Head) :-
	nonvar(Body),
	Body = true,
	!,
	affirm_head(Head0, user, Head, Module, undefined).
affirm_parts(Head0, Body, Module, (Head:-Body)) :-
	affirm_head(Head0, user, Head, Module, undefined).


%   affirm_head(+Head0, +Module0, -Head, -Module, -Type)
%   unscrambles and checks a Module0:Head0 form into a clause Head
%   ready for giving to assert or whatever, and a Type which is one
%   of	Variable	-- dynamic predicate
%	undefined	-- undefined predicate
%	static		-- static interpreted predicate
%	compiled	-- compiled static user-defined predicate
%	built_in	-- built-in predicate (:- is built in).
%   Only dynamic (or undefined) predicates can be changed.


affirm_head(0, _, _, _, _) :- !,
	fail.		% this actually catches variables, via a hack.
affirm_head(Module:Head0, _, Head, M, Type) :- !,
	atom(Module),
	affirm_head(Head0, Module, Head, M, Type).
affirm_head(Head, Module, Head, Module, Type) :-
    %	callable(Head),
	functor(Head, Symbol, _),
	atom(Symbol),
	(   predicate_property(Module:Head, (dynamic)) ->
	    true	% leave Type a variable
	;   predicate_property(Module:Head, interpreted) ->
	    Type = (static)
	;   predicate_property(Module:Head, compiled) ->
	    Type = compiled
	;   predicate_property(Module:Head, built_in) ->
	    Type = built_in
	;   /* otherwise undefined */
	    Type = undefined
	).


%   affirm_error(Head, Goal)
%   reports an error in Goal.  The error is always in the first
%   argument.  The last argument of affirm_head is for the
%   benefit of this command.

affirm_error(Head, Goal) :-
	affirm_head(Head, user, G, M, Type),
	!,
	functor(G, F, N),
	( M = user -> Culprit = F/N ; Culprit = M:F/N ),
	format(user_error,
	    '~N! You cannot change ~q -- it is ~w~n! Goal: ~q~n',
	    [Culprit, Type, Goal]),
	fail.
affirm_error(Head, Goal) :-
	format(user_error,
	    '~N! Malformed clause head: ~q~n! Goal: ~q~n',
	    [Head, Goal]),
	fail.


/*  affirmed(Head, Body) and
    affirmed(Head, Body, Ref)
    shouldn't really be any more than aliases for clause/2 and clause/3.
    But it is attractive to ensure that all the predicates defined here
    have the same kind of error messages, and it is instructive to see
    what the module system has done to clause/2 and clause/3.

    The basic problem is this: the meta-predicate machinery is really
    designed for passing goals INTO predicates to be executed, and it
    isn't terribly convenient for returning fragments of code OUT.
    We have made strenuous attempts to design the system so that all
    the built in predicates act as you might expect.  In particular,
    the criterion which forced almost every detail of the module
    system was our desire that if you take a complete program which
    didn't use the module system and wrap it up as a module, it
    shouldn't notice the change.  You will find out how well we have
    met this goal.

    Basically, if affirmed/3 was called from a module fred: we can
    be sure that Head will be instantiated to fred:X, where X is
    the term the user wrote, UNLESS the user wrote M:X, in which
    case we got M:X.  If it was called from user:, user: will NOT
    have been generated (unless the user put it there, of course).
    So, we strip off module prefixes, starting with user as the
    default, and using the last one we find, and we are left with
    Module:Head as the (notional) first argument, and Head is
    either a callable term or a variable.  In either case Head
    will end up as something excluding the module part.  Now there
    are two cases:
	Ref is a variable:
	    We have to use the information in Head and Body to
	    find the clause.  Head had better be instantiated.
	Ref is not a variable:
	    We can pick up the clause without any module
	    prefix using instance/2, and can then fill in the
	    module to check that we have the right module and head.
*/
affirmed(Head0, Body) :-
	affirmed_head(Head0, user, Head, Head, Module),
	!,
	clause(Module:Head, Body).
affirmed(Head0, Body) :-
	affirmed_error(Head0, affirmed(Head0,Body)).


affirmed(Head0, Body, Ref) :-
	nonvar(Ref),
	!,
	(   is_db_ref(Ref) ->
	    instance(Ref, (Head:-Body)),
	    affirmed_head(Head0, user, Head, H, Module),
	    H = Head,
	    clause(Module:Head, Body, Ref)
	;   format(user_error,
		'~N! Type failure in argument ~w of ~w/~w~n',
		[3, affirmed, 3]),
	    format(user_error,
		'! data base reference expected, but found ~q~n! Goal: ~q~n',
		[Ref, affirmed(Head0,Body,Ref)]),
	    fail
	).
affirmed(Head0, Body, Ref) :-
	affirmed_head(Head0, user, Head, Head, Module),
	!,
	clause(Module:Head, Body, Ref).
affirmed(Head0, Body, Ref) :-
	affirmed_error(Head0, affirmed(Head0,Body,Ref)).


affirmed_head(Head, Module, Hint, Head, Module) :-
	var(Head),
	!,
	Head = Hint,
	nonvar(Head).
affirmed_head(Module:Head0, _, Hint, Head, Mod) :- !,
	atom(Module),
	affirmed_head(Head0, Module, Hint, Head, Mod).
affirmed_head(Head, Module, _, Head, Module) :-
	functor(Head, Symbol, _), atom(Symbol),
	predicate_property(Module:Head, (dynamic)),
	!.


affirmed_error(Head, Goal) :-
	affirm_head(Head, user, G, M, Type),
	/* if Type was a variable, we wouldn't have arrived here */	
	!,
	functor(G, F, N),
	( M = user -> Culprit = F/N ; Culprit = M:F/N ),
	format(user_error,
	    '~N! You cannot inspect clauses for ~q -- it is ~w~n! Goal: ~q~n',
	    [Culprit, Type, Goal]),
	fail.
affirmed_error(Head, Goal) :-
	format(user_error,
	    '~N! Malformed clause head: ~q~n! Goal: ~q~n',
	    [Head, Goal]),
	fail.



%   deny(Head, Body)
%   is like retract/1, but takes a clause as separate Head and Body.
%   It was originally put in the library for backwards compatibility
%   with PDP-11 Prolog, C Prolog, and some Prologs modelled on PDP-11
%   Prolog.  Then it was decided that a complete family of operations
%   similar to clause/[2,3] would be useful, and the file just grew.
%   With retract/1 it can be very confusing working out whether to
%   put in a 'true' body or not; with this predicate it's obvious.
%
%   We put user: in front of the calls to clause/3 to ensure that
%   a module prefix will NOT be stuck in front of Head, as the
%   predicate deny_head/2 is supposed to get the prefix exactly
%   right.

deny(Head0, Body) :-
	deny_head(Head0, Head),
	!,
	user:clause(Head, Body, Ref),
	erase(Ref).
deny(Head, Body) :-
	affirm_error(Head, deny(Head,Body)).


%   deny_first(Head, Body)
%   is like deny/2 but retracts only the first match.

deny_first(Head0, Body) :-
	deny_head(Head0, Head),
	!,
	user:clause(Head, Body, Ref),
	!,
	erase(Ref).
deny_first(Head, Body) :-
	affirm_error(Head, deny_first(Head,Body)).


%   deny_first(Head)
%   retracts the first clause whose head matches Head

deny_first(Head0) :-
	deny_head(Head0, Head),
	!,
	user:clause(Head, _, Ref),
	!,
	erase(Ref).
deny_first(Head) :-
	affirm_error(Head, deny_first(Head)).


%   deny_every(Head, Body)
%   retracts every clause matching Head:-Body

deny_every(Head0, Body) :-
	deny_head(Head0, Head),
	!,
	(   user:clause(Head, Body, Ref),
	    erase(Ref),
	    fail
	;   true
	).
deny_every(Head, Body) :-
	affirm_error(Head, deny_every(Head,Body)).


%   deny_every(Head)
%   retracts every clause whose head matches Head.

deny_every(Head0) :-
	deny_head(Head0, Head),
	!,
	(   user:clause(Head, _, Ref),
	    erase(Ref),
	    fail
	;   true
	).
deny_every(Head) :-
	affirm_error(Head, deny_every(Head)).


deny_head(Head0, Head) :-
	affirm_head(Head0, user, Head1, Module, (dynamic)),
	(   Head1 = user ->
	    Head = Head1
	;   Head = Module:Head1
	).


/*  asserted(?Clause)
    is a version of the built in predicate clause/2 which takes the
    same kind of argument as assert/1 and retract/1.  They take a
    clause as argument.  For symmetry, you'd expect there to be a
    clause/1, but there isn't.  Well, now there is.  The argument
    has to be sufficiently fleshed out to determine what predicate
    you're talking about.  In fact, asserted/1 and retract/1 should
    take the exactly the same arguments, but in order to share the
    clause_parts/4 and clause_head/3 subroutines with the other
    predicates in this file, clause/1 is a bit more general than
    it should be.  If there were anything which retract/1 would have
    accepted and dealt with correctly, and if clause/1 weren't to
    work on it, that would be a bug.

    All of the predicates and commands in this file work only on
    dynamic predicates, that is, predicates which have explicitly
    been declared :-dynamic, or which had no clauses in the source,
    but were created by assert/1.  The built in data base operations
    clause/2 and retract/1 have the same restriction: you cannot
    inspect or change system or static predicates.
*/

asserted(Clause) :-
	clause_parts(Clause, user, Head, Body),
	!,
	user:clause(Head, Body).
asserted(Clause) :-
	format(user_error,
	    '~N! Argument malformed or predicate not :-dynamic~n! Goal: ~q~n',
	    [asserted(Clause)]),
	fail.


asserted(Clause, Ref) :-
	nonvar(Ref),
	!,
	(   is_db_ref(Ref) ->
	    instance(Ref, (Head:-Body)),
	    asserted_parts(Clause, user, Module, Head, Body),
	    clause(Module:Head, Body, Ref)
	;   format(user_error,
		'~N! Type failure in argument ~w of ~w/~w~n',
		[2, asserted, 2]),
	    format(user_error,
		'! data base reference expected, but found ~q~n! Goal: ~q~n',
		[Ref, asserted(Clause,Ref)]),
	    fail
	).
asserted(Clause, Ref) :-
	clause_parts(Clause, user, Head, Body),
	!,
	user:clause(Head, Body, Ref).
asserted(Clause, Ref) :-
	format(user_error,
	    '~N! Argument malformed or predicate not :-dynamic~n! Goal: ~q~n',
	    [asserted(Clause,Ref)]),
	fail.


asserted_parts(Module:Clause, _, Mod, Head, Body) :-
	atom(Module),
	!,
	asserted_parts(Clause, Module, Mod, Head, Body).
asserted_parts((Head:-Body), Module, Module, H, B) :- !,
	Head = H, Body = B.
asserted_parts(Head, Module, Module, Head, true).


clause_parts(0, _, _, _) :- !,
	fail.		% this actually catches variables, via a hack.
clause_parts(Module:Clause, _, Head, Body) :- !,
	atom(Module),
	clause_parts(Clause, Module, Head, Body).
clause_parts((Head0 :- Body), Module, Head, Body) :- !,
	clause_head(Head0, Module, Head).
clause_parts(Head0, Module, Head, true) :-
	clause_head(Head0, Module, Head).


clause_head(0, _, _) :- !,
	fail.		% this actually catches variables, via a hack.
clause_head(Module:Head0, _, Head) :- !,
	atom(Module),
	clause_head(Head0, Module, Head).
clause_head(Head, Module, Module:Head) :-
    %	callable(Head),
	functor(Head, Symbol, _),
	atom(Symbol),
	predicate_property(Module:Head, (dynamic)).



%   retract_first(Clause)
%   retracts the first clause which unifies with Clause.
%   It ONLY retracts the first clause.  It is determinate.
%   If you backtrack into it, it will fail.

retract_first(Clause) :-
	clause_parts(Clause, user, Head, Body),
	!,
	user:clause(Head, Body, Ref),
	!,
	erase(Ref).
retract_first(Clause) :-
	format(user_error,
	    '~N! Argument malformed or predicate not :-dynamic~n! Goal: ~q~n',
	    [retract_first(Clause)]),
	fail.


%   retract_every(Clause)
%   retracts all the clauses which would unify with Clause.
%   It is determinate because all the choices have been made.

retract_every(Clause) :-
	clause_parts(Clause, user, Head, Body),
	!,
	( user:clause(Head, Body, Ref), erase(Ref), fail ; true ).
retract_every(Clause) :-
	format(user_error,
	    '~N! Argument malformed or predicate not :-dynamic~n! Goal: ~q~n',
	    [retract_every(Clause)]),
	fail.



%   make_dynamic(Spec)
%   ensures that the predicate called by Spec is dynamic.  If the
%   predicate exists and is not dynamic, this is not possible.
%   Note that you could simply do assert(Spec, Ref), erase(Ref)
%   to accomplish this.  If the predicate is already dynamic, no
%   harm will be done, while if it is static or ill-formed,
%   assert/1 will report the error.  The principal benefit of
%   using make_dynamic/1 is that you get a better error message.

make_dynamic(Spec) :-
	affirm_head(Spec, user, Head, Module, Type),
	(   Type = (dynamic), !
	;   Type = (undefined), !,
	    assert(Module:Head, Ref),
	    erase(Ref)
	).
make_dynamic(Spec) :-
	affirm_error(Spec, make_dynamic(Spec)).


%   make_defined(Spec)
%   ensures that the predicate called by Spec is defined, by making
%   it dynamic if it does not already exist.

make_defined(Spec) :-
	affirm_head(Spec, user, Head, Module, Type),
	!,
	(   Type = (undefined) ->
	    assert(Module:Head, Ref),
	    erase(Ref)
	;   true
	).
make_defined(Spec) :-
	affirm_error(Spec, make_defined(Spec)).



%   record(Key, Term, Ref)
%   records Term under Key in the data base, returning a data base
%   reference Ref for the new record, but we don't make any promises
%   about where it goes.  Just to drive that home, despite the fact
%   that assert/1 currently acts like assertz/1, I have chosen to
%   make record/3 act like recorda/3, not recordz/3.  You should be
%   using the assertion routines without an -a or -z suffix only when
%   you genuinely don't care where the clause or record goes.

record(Key, Term, Ref) :-
	recorda(Key, Term, Ref).


%   record(  Key, Term),
%   recorda( Key, Term),
%   recordz( Key, Term), and
%   recorded(Key, Term)
%   are identical to the three-place predicates of the same names,
%   except that they don't return a data base reference.  They could
%   be implemented directly, and would then be significantly more
%   efficient.  Indeed, that is true of all the routines in this file.
%   But none of them will be implemented directly if you don't tell
%   us that you have found them useful!

record(Key, Term) :-
	record(Key, Term, _).

recorda(Key, Term) :-
	recorda(Key, Term, _).

recordz(Key, Term) :-
	recordz(Key, Term, _).

recorded(Key, Term) :-
	recorded(Key, Term, _).

/*  A note on recorded/[2,3].  If you supply a data base reference,
    the key and term can be recovered.  But if you do not supply a
    data base reference, the key must be instantiated.  (The same
    rule applies to asserted/[1,2], affirmed/[2,3], and of course
    the real evaluable predicates clause/[2,3].)  Since recorded/2
    has no place to supply a data base reference, the Key must be
    instantiated.
*/

/*  The wipe- /[1,2] family of commands is completely new: there
    has never been an analogue of "retract" for the recorded
    data base before, only the primitive erase/1 which kills anything.
    They are exactly like the deny- /[1,2] family, except that data
    base records are removed, not clauses.  The Key argument must be
    instantiated, but any non-variable term is acceptable as a Key.
    BEWARE!!!  In this release of Quintus Prolog, all data base
    references are indistinguishable as Keys, all streams are
    indistinguishable as Keys, and all stream positions are also
    indistinguishable as Keys.  If R is a data base reference, for
    example, wipe_every(R) will erase every record recorded under
    ANY data base reference as key.
*/

%   wipe(Key, Term)
%   enumerates the Key/Term pairs for which recorded(Key,Term)
%   would have succeeded, and erases each pair in turn.

wipe(Key, Term) :-
	nonvar(Key),
	!,
	recorded(Key, Term, Ref),
	erase(Ref).
wipe(Key, Term) :-
	wipe_error(wipe(Key,Term)).


%   wipe_first(Key, Term)
%   erases the first Key/Term pair in the recorded data base
%   for which recorded(Key, Term) is true.  If there is no
%   such Key/Term pair, it simply fails.

wipe_first(Key, Term) :-
	nonvar(Key),
	!,
	recorded(Key, Term, Ref),
	!,
	erase(Ref).
wipe_first(Key, Term) :-
	wipe_error(wipe_first(Key,Term)).


%   wipe_first(Key)
%   erases the first Key/Term pair in the recorded data base
%   for which recorded(Key, Term) is true.  If there is no
%   such Key/Term pair, it simply fails.

wipe_first(Key) :-
	nonvar(Key),
	!,
	recorded(Key, _, Ref),
	!,
	erase(Ref).
wipe_first(Key) :-
	wipe_error(wipe_first(Key)).


%   wipe_every(Key, Term)
%   erases every Key/Term in the recorded data base for which
%   recorded(Key, Term) would have been true.  If there is no
%   such Key/Term pair, it succeeds; it can fail only if the
%   Key is invalid.

wipe_every(Key, Term) :-
	nonvar(Key),
	!,
	(   recorded(Key, Term, Ref), erase(Ref), fail
	;   true
	).
wipe_every(Key, Term) :-
	wipe_error(wipe_every(Key,Term)).


%   wipe_every(Key)
%   erases every Key/Term pair in the recorded data base for
%   which recorded(Key, Term) would have been true.  If there
%   is no such Key/Term pair, it succeeds; it can fail only
%   if the Key is invalid.

wipe_every(Key) :-
	nonvar(Key),
	!,
	(   recorded(Key, _, Ref), erase(Ref), fail
	;   true
	).
wipe_every(Key) :-
	wipe_error(wipe_every(Key)).


%   wipe_error(Goal)
%   is called when the Key argument of Goal is invalid.  Following
%   Dec-10 Prolog, only variables are rejected as keys.  Beware: a
%   data base reference is accepted as a key, but all data base
%   references are equivalent.  (Same goes for streams.)  The key
%   argument is always the first one, so we don't need to pass it.
%   This is the same error message that the must_be_* tests from
%   library(types) print for uninstantiated variables.

wipe_error(Goal) :-
	functor(Goal, Symbol, Arity),
	format(user_error,
	    '~N! Instantiation fault in argument ~w of ~w/~w~n! Goal: ~q~n',
	    [1, Symbol, Arity, Goal]),
	fail.   /* THIS IS NOT QUITE RIGHT */

	    

