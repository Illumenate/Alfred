%   Package: call
%   Author : Richard A. O'Keefe
%   Updated: 31 Jan 1994
%   Defines: apply/2 and several arities of call/N

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(call, [
	apply/2,
	call/2,
	call/3,
	call/4,
	call/5,
	call/6,
	call/7,
	strip_module_prefix/4	%<------- for the IPC code ONLY!
   ]).
:- meta_predicate
	apply(:, +),
	call(1, ?),
	call(2, ?, ?),
	call(3, ?, ?, ?),
	call(4, ?, ?, ?, ?),
	call(5, ?, ?, ?, ?, ?),
	call(6, ?, ?, ?, ?, ?, ?).

:- mode
	append_term(+, +, -),
	append_term1(+, +, +),
	append_term2(+, +, +),
	append_term(+, +, -, -),
	apply(+, +),
	call(+, ?),
	call(+, ?, ?),
	call(+, ?, ?, ?),
	call(+, ?, ?, ?, ?),
	call(+, ?, ?, ?, ?, ?),
	call(+, ?, ?, ?, ?, ?, ?),
	strip_module_prefix(+, +, -, -).

sccs_id('"@(#)94/01/31 call.pl	71.1"').

/* pred
	apply(any, list(any)),		% as close as we can get
	call(void(A), A),
	call(void(A,B), A, B),
	call(void(A,B,C), A, B, C),
	call(void(A,B,C,D), A, B, C, D),
	call(void(A,B,C,D,E), A, B, C, D, E),
	call(void(A,B,C,D,E,F), A, B, C, D, E, F).
*/

%%  strip_module_prefix(+Term, +DefaultModule, -Goal, -Module)
%   is given a Term and a default module, and returns the Term
%   as a Goal with all module prefixes stripped off and the
%   Module it appears to be called in.  (Note that the called
%   predicate may have been defined in some other module and
%   imported).  It checks that the Module is an atom, and that
%   the Goal is not a variable.  It is left to append_term/[3,4]
%   to check that the Goal is not a number, as they have to call
%   functor/3 on the Goal anyway.  Note the hack in the first
%   clause which lets us use indexing to do a nonvar/1 test:
%   0 is not a valid Term, and will also catch variables, which
%   are not valid Terms either.  This predicate is EXTREMELY
%   unlikely to survive into the next release, so please do not
%   use it in your programs.  It is exported for the sake of the
%   IPC code and for that only.

strip_module_prefix(0, _, _, _) :- !,
	fail.
strip_module_prefix(Prefix:Term, _, Goal, Module) :- !,
	strip_module_prefix(Term, Prefix, Goal, Module).
strip_module_prefix(Goal, Module, Goal, Module) :-
	nonvar(Goal),		% should be callable(Goal)
	atom(Module).



%   apply(+Pred, +[Arg1,...,Argn])
%   is the key to this whole module.  It is basically a variant of
%   call/1 where some of the arguments may be already in the Pred,
%   and the rest are passed in the list of Args.  Thus
%   apply(foo, [X,Y]) is the same as call(foo(X,Y)), and
%   apply(foo(X), [Y]) is also the same as call(foo(X,Y)). The
%   ability to pass goals around with some of their (initial)
%   arguments already filled in is what makes apply/2 so useful.
%   Because of the cost of constructing the new goal, and of looking
%   up the predicate at run time, apply and the routines based on it
%   are not well thought of.  You should not use apply/2 if one of
%   the call/N predicates can be used instead.

apply(Pred, Args) :-
	strip_module_prefix(Pred, user, Form, Module),
	append_term(Form, Args, Goal),
	!,
	Module:Goal.
apply(Pred, Args) :-
	call_error(Pred, apply(Pred,Args)).


%%  append_term(+Term, +MoreArgs, ?FullTerm)
%   takes a callable term P(X1,...,Xk) and a list of extra arguments
%   [Xk+1,...,Xn] and returns the term P(X1,...,Xn).  This is useful
%   for apply/2, and also for grammar preprocessors which often have
%   reason to add arguments to something.  One reason for using this
%   routine is that it turns over less space than the more obvious
%   solution using univ.  Another is that it does check whether the
%   Term is in fact callable.  It is now called after strip_module_
%   prefix has removed any module: prefix and checked that Term is
%   not a variable.  We are left to check that Term is callable.

%   Efficiency note.  Letting the arity of Term be A and the length
%   of MoreArgs be L, the cost of doing append_term this way is
%	0.15 + 0.10 A + 0.06 L	(milliseconds on a Sun-3/50)
%   whereas the cost of using univ (=..) is
%	0.35 + 0.45 A + 0.15 L	(milliseconds on a Sun-3/50)
%   For some typical arguments, univ can be three times as expensive.
%   Help stamp out univ!  If you tell us that this operation is
%   important to you, we could make it quite a lot faster.

append_term(Term, MoreArgs, FullTerm) :-
	functor(Term, Symbol, Arity),
	atom(Symbol),		% must test as MoreArgs=[] is ok.
	len(MoreArgs, Arity, FullArity),
	functor(FullTerm, Symbol, FullArity),
	append_term1(MoreArgs, Arity, FullTerm),
	append_term2(Arity, Term, FullTerm).

len(0, _, _) :- !, fail.	% catch partial lists
len([], N, N).
len([_|L], N0, N) :-
	N1 is N0+1,
	len(L, N1, N).

append_term1([A1,A2|Args], M, FullTerm) :- !,
	N1 is M+1, arg(N1, FullTerm, A1),
	N2 is M+2, arg(N2, FullTerm, A2),
	append_term1(Args, N2, FullTerm).
append_term1([A1], M, FullTerm) :- !,
	N1 is M+1, arg(N1, FullTerm, A1).
append_term1([], _, _).


%%  append_term2(N, OldTerm, NewTerm)
%   is true when the Ith argument of OldTerm unifies with the
%   Ith argument of NewTerm, for 1 <= I <= N.  It has been
%   hacked for speed rather than clarity.

append_term2(N, OldTerm, NewTerm) :-
	(   N > 1 ->
	    arg(N, OldTerm, ArgN),
	    arg(N, NewTerm, ArgN),
	    M is N-1,
	    arg(M, OldTerm, ArgM),
	    arg(M, NewTerm, ArgM),
	    L is M-1,
	    append_term2(L, OldTerm, NewTerm)
	;   N > 0 ->
	    arg(1, OldTerm, Arg1),
	    arg(1, NewTerm, Arg1)
	;   true
	).


%%  append_term(+Term, +Nextra, -Arity, -FullTerm)
%   is given a Term and the number of extra arguments (>=1) to be
%   added.  It returns the Arity of Term, and a new FullTerm which
%   has the same function Symbol and first Arity arguments as Term
%   and whose last Nextra arguments are uninstantiated.  Note that
%   we do not need to explicitly test for atom(Symbol), as the
%   functor(FullTerm, Symbol, FullArity /* > 0 */) construction
%   will implicitly make this test.

append_term(Term, Nextra, Arity, FullTerm) :-
	functor(Term, Symbol, Arity),		% we know nonvar(Term)
	FullArity is Arity+Nextra,		% FullArity > 0
	functor(FullTerm, Symbol, FullArity),	% tests atom(Symbol)
	append_term2(Arity, Term, FullTerm).


/*  The call/N family have the form
	call(Pred, Y1, ..., Yn).
    They have exactly the same effect as
	apply(Pred, [Y1,...,Yn])
    except that they don't require the construction of a list,
    and they can be type-checked, which apply/2 cannot be.
    The idea is that
	call(Module:pred(X1,...,Xm), Y1,...,Yn)
    is equivalent to
	Module:pred(X1, ..., Xm, Y1, ..., Yn)

    Ideally, call/N should be defined for all values of N.
    At the moment, it is only defined for up to N=6 extra arguments.
*/

%   call(+pred(X1,...,Xm), ?Y1)
%   calls pred(X1, ..., Xm, Y1))

call(Term, Y1) :-
	strip_module_prefix(Term, user, Form, Module),
	append_term(Form, 1, N, Full),
	!,
	N1 is N+1, arg(N1, Full, Y1),
	Module:Full.
call(Term, Y1) :-
	call_error(Term, call(Term,Y1)).


%   call(+pred(X1,...,Xm), ?Y1, ?Y2)
%   calls pred(X1, ..., Xm, Y1, Y2))

call(Term, Y1, Y2) :-
	strip_module_prefix(Term, user, Form, Module),
	append_term(Form, 2, N, Full),
	!,
	N1 is N+1, arg(N1, Full, Y1),
	N2 is N+2, arg(N2, Full, Y2),
	Module:Full.
call(Term, Y1, Y2) :-
	call_error(Term, call(Term,Y1,Y2)).


%   call(+pred(X1,...,Xm), ?Y1, ?Y2, ?Y3)
%   calls pred(X1, ..., Xm, Y1, Y2, Y3))

call(Term, Y1, Y2, Y3) :-
	strip_module_prefix(Term, user, Form, Module),
	append_term(Form, 3, N, Full),
	!,
	N1 is N+1, arg(N1, Full, Y1),
	N2 is N+2, arg(N2, Full, Y2),
	N3 is N+3, arg(N3, Full, Y3),
	Module:Full.
call(Term, Y1, Y2, Y3) :-
	call_error(Term, call(Term,Y1,Y2,Y3)).


%   call(+pred(X1,...,Xm), ?Y1, ?Y2, ?Y3, ?Y4)
%   calls pred(X1, ..., Xm, Y1, Y2, Y3, Y4))

call(Term, Y1, Y2, Y3, Y4) :-
	strip_module_prefix(Term, user, Form, Module),
	append_term(Form, 4, N, Full),
	!,
	N1 is N+1, arg(N1, Full, Y1),
	N2 is N+2, arg(N2, Full, Y2),
	N3 is N+3, arg(N3, Full, Y3),
	N4 is N+4, arg(N4, Full, Y4),
	Module:Full.
call(Term, Y1, Y2, Y3, Y4) :-
	call_error(Term, call(Term,Y1,Y2,Y3,Y4)).


%   call(+pred(X1,...,Xm), ?Y1, ?Y2, ?Y3, ?Y4, ?Y5)
%   calls pred(X1, ..., Xm, Y1, Y2, Y3, Y4, Y5))

call(Term, Y1, Y2, Y3, Y4, Y5) :-
	strip_module_prefix(Term, user, Form, Module),
	append_term(Form, 5, N, Full),
	!,
	N1 is N+1, arg(N1, Full, Y1),
	N2 is N+2, arg(N2, Full, Y2),
	N3 is N+3, arg(N3, Full, Y3),
	N4 is N+4, arg(N4, Full, Y4),
	N5 is N+5, arg(N5, Full, Y5),
	Module:Full.
call(Term, Y1, Y2, Y3, Y4, Y5) :-
	call_error(Term, call(Term,Y1,Y2,Y3,Y4,Y5)).


%   call(+pred(X1,...,Xm), ?Y1, ?Y2, ?Y3, ?Y4, ?Y5, ?Y6)
%   calls pred(X1, ..., Xm, Y1, Y2, Y3, Y4, Y5, Y6))

call(Term, Y1, Y2, Y3, Y4, Y5, Y6) :-
	strip_module_prefix(Term, user, Form, Module),
	append_term(Form, 6, N, Full),
	!,
	N1 is N+1, arg(N1, Full, Y1),
	N2 is N+2, arg(N2, Full, Y2),
	N3 is N+3, arg(N3, Full, Y3),
	N4 is N+4, arg(N4, Full, Y4),
	N5 is N+5, arg(N5, Full, Y5),
	N6 is N+6, arg(N6, Full, Y6),
	Module:Full.
call(Term, Y1, Y2, Y3, Y4, Y5, Y6) :-
	call_error(Term, call(Term,Y1,Y2,Y3,Y4,Y5,Y6)).


%   Raise an instantiation error or type error

call_error(Term, Goal) :-
	(   var(Term) ->
	        raise_exception(instantiation_error(Goal,1))
	;   Term = _Module:X ->
	        call_error(X, Goal)
	;   otherwise ->
	        raise_exception(type_error(Goal,1,callable,Term))
	).


