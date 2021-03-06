%   Module : occurs
%   Author : Richard A. O'Keefe
%   Updated: 10 Apr 1990
%   Purpose: checking whether a term does/does not contain a term/variable

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(occurs, [
	contains_term/2,	%   T2 contains term T1
	contains_var/2,		%   T2 contains variable V1
	free_of_term/2,		%   T2 is free of term T1
	free_of_var/2,		%   T2 is free of variable V1
	occurrences_of_term/3,	%   T2 contains N3 instances of term T1
	occurrences_of_var/3,	%   T2 contains N3 instances of var V1
	sub_term/2		%   T1 is a sub-term of T2 (enumerate T1)
   ]).

:- mode
	contains_term(+, +),		%   Kernel x Term ->
	contains_var(+, +),		%   Kernel x Term ->
	free_of_term(+, +),		%   Kernel x Term ->
	    free_of_term(+, +, +),	%   Tally x Term x Kernel ->
	free_of_var(+, +),		%   Kernel x Term ->
	    free_of_var(+, +, +),	%   Tally x Term x Kernel ->
	occurrences_of_term(+, +, ?),	%   Kernel x Term -> Tally
	    occurrences_of_term(+, +, +, -),
		occurrences_of_term(+, +, +, +, -),
	occurrences_of_var(+, +, ?),	%   Kernel x Term -> Tally
	    occurrences_of_var(+, +, +, -),
		occurrences_of_var(+, +, +, +, -),
	sub_term(?, +),			%   Kernel x Term
	    sub_term(+, +, ?).		%   Tally x Term x Kernel

sccs_id('"@(#)90/04/10 occurs.pl	40.1"').



%   These relations were available in the public domain library with
%   different names and inconsistent argument orders.  The names are
%   different so that "contains", "freeof" and so forth can be used
%   by your own code.  free_of_var is used by the "unify" package.
%   The _term predicates check for a sub-term that unifies with the
%   Kernel argument, the _var predicates for one identical to it.
%   In release 2.0, the *_var predicates were modified to continue
%   using the identity (==) rather than unifiability (=) test, but
%   to cease insisting that the Kernel should be a variable.  When
%   the Kernel is a variable, they continue to work as before.



%   contains_term(+Kernel, +Expression)
%   is true when the given Kernel occurs somewhere in the Expression.
%   It can only be used as a test; to generate sub-terms use sub_term/2.

contains_term(Kernel, Expression) :-
	\+ free_of_term(Kernel, Expression).


%   free_of_term(+Kernel, +Expression)
%   is true when the given Kernel does not occur anywhere in the
%   Expression.  NB: if the Expression contains an unbound variable,
%   this must fail, as the Kernel might occur there.  Since there are
%   infinitely many Kernels not contained in any Expression, and also
%   infinitely many Expressions not containing any Kernel, it doesn't
%   make sense to use this except as a test.

free_of_term(Kernel, Kernel) :- !,
	fail.
free_of_term(Kernel, Expression) :-
	nonvar(Expression),
	functor(Expression, _, Arity),
	free_of_term(Arity, Expression, Kernel).

free_of_term(0, _, _) :- !.
free_of_term(N, Expression, Kernel) :-
	arg(N, Expression, Argument),
	free_of_term(Kernel, Argument),
	M is N-1,
	free_of_term(M, Expression, Kernel).



%   occurrences_of_term(+Kernel, +Expression, ?Tally)
%   is true when the given Kernel occurs exactly Tally times in
%   Expression.  It can only be used to calculate or test Tally;
%   to enumerate Kernels you'll have to use sub_term/2 and then
%   test them with this routine.  If you just want to find out
%   whether Kernel occurs in Expression or not, use contains_term/2
%   or free_of_term/2.  occurrences_of_var used to be called occ/3.

occurrences_of_term(Kernel, Expression, Occurrences) :-
	occurrences_of_term(Expression, Kernel, 0, Tally),
	Occurrences = Tally.

occurrences_of_term(Kernel, Kernel, SoFar, Tally) :- !,
	Tally is SoFar+1.
occurrences_of_term(Expression, Kernel, SoFar, Tally) :-
	nonvar(Expression),
	functor(Expression, _, Arity),
	occurrences_of_term(Arity, Expression, Kernel, SoFar, Tally).

occurrences_of_term(0, _, _, Tally, Tally) :- !.
occurrences_of_term(N, Expression, Kernel, SoFar, Tally) :-
	arg(N, Expression, Argument),
	occurrences_of_term(Argument, Kernel, SoFar, Accum),
	M is N-1,
	occurrences_of_term(M, Expression, Kernel, Accum, Tally).



%   contains_var(+Variable, +Term)
%   is true when the given Term contains at least one sub-term which
%   is identical to the given Variable.  We use '=='/2 to check for
%   the variable (contains_term/2 uses '=') so it can be used to check
%   for arbitrary terms, not just variables.

contains_var(Variable, Term) :-
	\+ free_of_var(Variable, Term).


%   free_of_var(+Variable, +Term)
%   is true when the given Term contains no sub-term identical to the
%   given Variable (which may actually be any term, not just a var).
%   For variables, this is precisely the "occurs check" which is
%   needed for sound unification.

free_of_var(Variable, Term) :-
	Term == Variable,
	!,
	fail.
free_of_var(Variable, Term) :-
	compound(Term),
	!,
	functor(Term, _, Arity),
	free_of_var(Arity, Term, Variable).
free_of_var(_, _).

free_of_var(1, Term, Variable) :- !,
	arg(1, Term, Argument),
	free_of_var(Variable, Argument).
free_of_var(N, Term, Variable) :-
	arg(N, Term, Argument),
	free_of_var(Variable, Argument),
	M is N-1, !,
	free_of_var(M, Term, Variable).



%   occurrences_of_var(+Term, +Variable, ?Tally)
%   is true when the given Variable occurs exactly Tally times in
%   Term.  It can only be used to calculate or test Tally;
%   to enumerate Variables you'll have to use sub_term/2 and then
%   test them with this routine.  If you just want to find out
%   whether Variable occurs in Term or not, use contains_var/2
%   or free_of_var/2.  This used to be called occ/3.

occurrences_of_var(Variable, Term, Occurrences) :-
	occurrences_of_var(Term, Variable, 0, Tally),
	Occurrences = Tally.

occurrences_of_var(Term, Variable, SoFar, Tally) :-
	Term == Variable,
	!,
	Tally is SoFar+1.
occurrences_of_var(Term, Variable, SoFar, Tally) :-
	compound(Term),
	!,
	functor(Term, _, Arity),
	occurrences_of_var(Arity, Term, Variable, SoFar, Tally).
occurrences_of_var(_, _, Tally, Tally).


occurrences_of_var(1, Term, Variable, SoFar, Tally) :- !,
	arg(1, Term, Argument),
	occurrences_of_var(Argument, Variable, SoFar, Tally).
occurrences_of_var(N, Term, Variable, SoFar, Tally) :-
	arg(N, Term, Argument),
	occurrences_of_var(Argument, Variable, SoFar, Accum),
	M is N-1,
	occurrences_of_var(M, Term, Variable, Accum, Tally).



%   sub_term(?Kernel, +Term)
%   is true when Kernel is a sub-term of Term.  It enumerates the
%   sub-terms of Term in an arbitrary order.  Well, it is defined
%   that a sub-term of Term will be enumerated before its own
%   sub-terms are (but of course some of those sub-terms might be
%   elsewhere in Term as well).

sub_term(Term, Term).
sub_term(SubTerm, Term) :-
	nonvar(Term),
	functor(Term, _, N),
	sub_term(N, Term, SubTerm).

sub_term(N, Term, SubTerm) :-
	arg(N, Term, Arg),
	sub_term(SubTerm, Arg).
sub_term(N, Term, SubTerm) :-
	N > 1,
	M is N-1,
	sub_term(M, Term, SubTerm).



