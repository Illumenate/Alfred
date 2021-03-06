%   Module : arg
%   Author : Richard A. O'Keefe
%   Updated: 16 Dec 1987
%   Defines: some generalisations of arg

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(arg, [
%	arg/3,				% ArgNo x Term -> Arg
	arg0/3,				% ArgNo x Term -> Arg
	args/3,				% ArgNo x list(Term) -> list(Arg)
	args0/3,			% ArgNo x list(Term) -> list(Arg)
	genarg/3,			% ArgNo x Term -> Arg
	genarg0/3,			% ArgNo x Term -> Arg
	path_arg/3,			% list(ArgNo) x Term -> Term
	project/3			% list(Term) x ArgNo -> list(Arg)
   ]).

:- mode
%	arg(+, +, ?),
	arg0(+, +, ?),
	args(?, +, ?),
	    args_(+, +, ?),
	args0(?, +, ?),
	    args_(+, ?),
	genarg(?, +, ?),
	    genarg(+, +, ?, -),
	genarg0(?, +, ?),
	    genarg0(+, +, ?, -),
	path_arg(?, +, ?),
	project(+, +, ?).

sccs_id('"@(#)87/12/16 arg.pl	21.1"').


%   [arg0,genarg,genarg0]/3 have been revised to do rather more error
%   checking and reporting.  This makes them look much more complicated.
%   To see how they work, ignore the clauses containing calls to
%   format/3.  You might find it worth while to use one of these
%   routines in your code rather than arg/3, on the grounds that more
%   errors are detected and reported.  Better error reporting in the
%   built in predicates awaits the implementation of an error handling
%   system; one has been designed but the garbage collector came first.
%   The clauses of these routines have been carefully ordered so that
%   the non-error cases are cheap.

/*  Some Prolog implementors have redefined arg/3 so that
    arg(0, Term, F) unifies F with the principal function symbol
    of Term.  That was not a co-operative action.  Dec-10 Prolog,
    C-Prolog, Quintus Prolog, and all Prologs whose implementors
    have made a serious attempt to be Dec-10 Prolog compatible,
    define arg(N,T,A) to succeed only when N is at least 1 and no
    more than the arity of T.  (So does BSI-PS/6.)  If something
    claiming some degree of Dec-10 Prolog compatibility uses a
    predicate name which was defined in Dec-10 Prolog, it should
    give it a compatible meaning.  It is ok to extend predicates
    (e.g. it would be ok to make arg/3 able to solve for N), and
    it is ok to tidy up something which was never defined, as in
    the case of assert & retract.  But breaking programs which
    relied on (and were entitled to rely on) arg(0,T,A) failing,
    that is not co-operative.

    In order to help people convert their programs from certain
    Prolog implementations where Dec-10 Prolog compatibility was
    not taken this seriously, arg0/3 has been introduced.  It is
    like arg/3 except that arg0(N, Term, F) unifies F with the
    principal function symbol of Term.  Note that Term *MUST* be
    instantiated: arg0(0, T, 73) will *not* bind T=73, even though
    this is the only possible solution.

    We urge you to avoid arg0/3 in new programs: it is only
    provided to assist in conversion from other dialects.  If you
    want to know the function symbol, call functor/3 directly.
    If you want to treat the function symbol on the same level as
    the arguments, you are building confusion into your program,
    and sooner or later the fact that the function symbol is NOT
    on a level with the arguments (it can only be atomic, they can
    be anything) will lead you into trouble.
*/

%   arg0(+N, +Term, ?Arg)
%   succeeds when N > 0 and arg(N, Term, Arg) is true
%   or when N =:= 0 and functor(Term, Arg, _) is true.
%   Do not use this operation in new programs, it doesn't make sense.

arg0(N, Term, Arg) :-
	integer(N),
	nonvar(Term),
	!,
	(   N =:= 0 -> functor(Term, Arg, _)
	;   arg(N, Term, Arg)
	).
arg0(N, Term, Arg) :-
	(   var(N) ->
	    format(user_error,
		'~N! Instantiation fault in argument ~w of ~q/~w~n! Goal: ~p~n',
		[1,arg0,3,arg0(N,Term,Arg)])
	;   nonvar(Term) -> % and nonvar(N) but not integer(N)
	    format(user_error,
		'~N! Type failure in argument ~w of ~q/~w~n! Goal: ~p~n',
		[1,arg0,3,arg0(N,Term,Arg)])
	;   % integer(N), var(Term) ->
	    format(user_error,
		'~N! Instantiation fault in argument ~w of ~q/~w~n! Goal: ~p~n',
		[2,arg0,3,arg0(N,Term,Arg)])
	),
	fail.


%   There is no particularly good reason why arg/3 should be
%   incapable of solving for N except that it has always been
%   like that.  genarg/3 is a version of arg/3 which is capable
%   of solving for N, and can be used to enumerate all the
%   arguments of a term.  We do NOT define the order in which
%   the arguments are enumerated; this release happens to do it
%   in descending order, but the next release might do it the other
%   way around.  In retrospect, it is obvious that this should have
%   been called 'argument/3'.  Too late.

%   genarg(?N, +Term, ?Arg)
%   is true when arg(N, Term, Arg) is true, except that it can solve
%   for N.  Term, however, must be instantiated.

genarg(N, Term, Arg) :-
	integer(N),
	nonvar(Term),
	!,
	arg(N, Term, Arg).
genarg(N, Term, Arg) :-
	var(N),
	nonvar(Term),
	!,
	functor(Term, _, Arity),
	genarg(Arity, Term, Arg, N).
genarg(N, Term, Arg) :-
	var(Term),
	!,
	format(user_error,
	    '~N! Instantiation fault in argument ~w of ~q/~w~n! Goal: ~p~n',
	    [2,genarg,3,genarg(N,Term,Arg)]),
	fail.
genarg(N, Term, Arg) :-
	format(user_error,
	    '~N! Type failure in argument ~w of ~q/~w~n! Goal: ~p~n',
	    [1,genarg,3,genarg(N,Term,Arg)]),
	fail.


genarg(1, Term, Arg, 1) :- !,
	arg(1, Term, Arg).
genarg(N, Term, Arg, N) :-
	arg(N, Term, Arg).
genarg(K, Term, Arg, N) :-
	K > 1, J is K-1,
	genarg(J, Term, Arg, N).


%   genarg0(?N, +Term, ?Arg)
%   is a combination of arg0/3 and genarg/3.
%   Do not use this operation in new programs, it doesn't make sense.

genarg0(N, Term, Arg) :-
	integer(N),
	nonvar(Term),
	!,
	(   N =:= 0 -> functor(Term, Arg, _)
	;   arg(N, Term, Arg)
	).
genarg0(N, Term, Arg) :-
	var(N),
	nonvar(Term),
	!,
	functor(Term, _, Arity),
	genarg0(Arity, Term, Arg, N).
genarg0(N, Term, Arg) :-
	var(Term),
	!,
	format(user_error,
	    '~N! Instantiation fault in argument ~w of ~q/~w~n! Goal: ~p~n',
	    [2,genarg0,3,genarg0(N,Term,Arg)]),
	fail.
genarg0(N, Term, Arg) :-
	format(user_error,
	    '~N! Type failure in argument ~w of ~q/~w~n! Goal: ~p~n',
	    [1,genarg0,3,genarg0(N,Term,Arg)]),
	fail.


genarg0(0, Term, Arg, 0) :- !,
	functor(Term, Arg, _).
genarg0(N, Term, Arg, N) :-
	arg(N, Term, Arg).
genarg0(K, Term, Arg, N) :-
	K > 0, J is K-1,
	genarg0(J, Term, Arg, N).


%   path_arg(Path, Term, SubTerm)
%   unifies SubTerm with the subterm of Term found by following Path.
%   It may be viewed as a generalisation of genarg/3.  It may be used
%   to find the SubTerm at a known Path, or to find a Path to a
%   known SubTerm.  A path is a generalised Dewey number, as usual.
%   path_arg([1,1,2,2],   2*x^2+2*(x)+1=0, x) and
%   path_arg([1,1,1,2,1], 2*(x)^2+2*x+1=0, x) are both examples.
%   This routine replaces two predicates in the old Dec-10 Prolog
%   library: patharg/3 and position/3.  It does everything they did,
%   and reports errors as well.  In order to obtain reasonable speed
%   when the first argument is instantiated, some error detection has
%   been sacrificed: if the first argument is neither a variable, nil,
%   nor a cons cell, path_arg/3 will just quietly fail; only if it is
%   a list with a non-integer element will any complaint be made.
%   Sorry 'bout that, but a trade-off is a trade-off.
%   Note that the [Var|_] case uses genarg/4, an internal of this file.

path_arg(Path, Term, SubTerm) :-
	var(Term),
	!,
	(   Path == [] -> SubTerm = Term
	;   \+ (Path = [_|_]) -> fail
	;   format(user_error,
		'~N! Instantiation fault in argument ~w of ~q/~w~n! Goal: ~p~n',
		[2,path_arg,3,path_arg(Path,Term,SubTerm)]),
	    fail
	).
path_arg([], Term, Term).
path_arg([Head|Tail], Term, SubTerm) :-
	(   integer(Head) ->
	    arg(Head, Term, Arg),
	    path_arg(Tail, Arg, SubTerm)
	;   var(Head) ->
	    functor(Term, _, Arity),
	    genarg(Arity, Term, Arg, Head),
	    path_arg(Tail, Arg, SubTerm)
	;   /* otherwise */
	    format(user_error,
		'~N! Type failure in argument ~w of ~q/~w~n! Goal: ~p~n',
		[1,path_arg,3,path_arg([Head|Tail],Term,SubTerm)]),
	    fail
	).



%   This problem has cropped up in several programs.  You have a
%   list of compound terms s(A1,...,Ak,...An), which you can guarantee
%   have are all the same functor, and you want a list with just the Ak
%   in the same order.  The best thing to do is to write
/*  type s(T1,...,Tn) --> s(T1,...,Tn).
    pred s_project(list(s(T1,...,Tn)), list(T1), ..., list(Tn)).
    mode s_project(+, -, ..., -).

s_project([], [], ..., []).
s_project([s(A1,...,An)|Ss], [A1|A1s], ..., [An|Ans]) :-
	s_project(Ss, A1s, ..., Ans).
*/
%   This is second best.  Doing it this way does mean that you can
%   extract just the argument you want, and that you only have to
%   remember one predicate, but it also means that it can't be
%   type-checked.  args(K, Compounds, Args) unifies Args with the
%   list of Kth arguments of the Compounds.  K = 0 means the principal
%   function symbol, which is occasionally useful.
%   This could be defined as maplist(arg(K), TermList, ArgList),
%   except that arg(0,Term,X) doesn't unify X with the function
%   symbol (we'd have to be insane to do THAT! and we aren't).

%   K must be an integer, and Compounds should be a proper list.
%   This used to be called project/3 and to live in library(project).
%   project/3 is retained for backwards compatibility.

%   project(+ListOfTerms, +N, ?ListOfArgs)
%   is true when arg0(N, Term, Arg) is true for each corresponding Term
%   in ListOfTerms and Arg in ListOfArgs.  Use args0/3 instead.

project(Terms, K, Args) :-
	args0(K, Terms, Args).


%   args0(+N, +ListOfTerms, ?ListOfArgs)
%   is true when arg0(N, Term, Arg) is true for each corresponding Term
%   in ListOfTerms and Arg in ListOfArgs.  That is, ListOfArgs is the
%   list of Nth arguments of ListOfTerms.  It is better to use args/3.

args0(Index, [], []) :- !,
	(   integer(Index) -> true
	;   format(user_error,
		'~N! Bad first argument~n! Goal: ~q~n',
		[args0(Index,[],[])]),
	    fail
	).
args0(Index, [Term|Terms], [Arg|Args]) :-
	genarg0(Index, Term, Arg),
	(   Index =:= 0 -> args_(Terms, Args)
	;   args_(Terms, Index, Args)
	).


args_([], []).
args_([Term|Terms], [Symbol|Symbols]) :-
	functor(Term, Symbol, _Arity),
	args_(Terms, Symbols).



%   args(+N, +ListOfTerms, ?ListOfArgs)
%   is true when arg(N, Term, Arg) is true for each corresponding Term
%   in ListOfTerms and Arg in ListOfArgs.  That is, ListOfArgs is the
%   list of Nth arguments of ListOfTerms, which must be a proper list.

args(Index, [], []) :- !,
	(   integer(Index) -> true
	;   format(user_error,
		'~N! Bad first argument~n! Goal: ~q~n',
		[args(Index,[],[])]),
	    fail
	).
args(Index, [Term|Terms], [Arg|Args]) :-
	genarg(Index, Term, Arg),
	args_(Terms, Index, Args).


args_([], _, []).
args_([Term|Terms], K, [Arg|Args]) :-
	arg(K, Term, Arg),
	args_(Terms, K, Args).

