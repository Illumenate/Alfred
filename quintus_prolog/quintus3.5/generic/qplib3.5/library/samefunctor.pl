%   Module : same_functor
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Defines: same_functor/[2,3,4]

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(same_functor, [
	same_functor/2,
	same_functor/3,
	same_functor/4
   ]).
:- mode
	same_functor(?, ?),
	same_functor(?, ?, ?),
	same_functor(?, ?, ?, ?).

sccs_id('"@(#)89/08/29 samefunctor.pl    33.1"').


%   same_functor(?T1, ?T2)
%   is true when T1 and T2 have the same principal functor.  If one of
%   the terms is a variable, it will be instantiated to a new term
%   with the same principal functor as the other term (which should be
%   instantiated) and with arguments being new distinct variables.  If
%   both terms are variables, an error is reported.

same_functor(T1, T2) :-
	(   nonvar(T1) ->
	    functor(T1, F, N),
	    functor(T2, F, N)
	;   nonvar(T2) ->
	    functor(T2, F, N),
	    functor(T1, F, N)
	;   % var(T1), var(T2)
	    format(user_error,	
		'~N! Instantiation fault in same_functor/~d~n! Goal: ~q~n',
		[2, same_functor(T1,T2)]),
	    fail	/* THIS IS NOT QUITE RIGHT */
	).


%   same_functor(?T1, ?T2, ?N)
%   is true when T1 and T2 have the same principal functor, and their
%   common arity is N. Like same_functor/2, at least one of T1 and T2
%   must be bound, or an error will be reported.  No errors involving
%   N are currently reported.

same_functor(T1, T2, N) :-
	(   nonvar(T1) ->
	    functor(T1, F, N),
	    functor(T2, F, N)
	;   nonvar(T2) ->
	    functor(T2, F, N),
	    functor(T1, F, N)
	;   % var(T1), var(T2)
	    format(user_error,	
		'~N! Instantiation fault in same_functor/~d~n! Goal: ~q~n',
		[3, same_functor(T1,T2,N)]),
	    fail	/* THIS IS NOT QUITE RIGHT */
	).



%   same_functor(?T1, ?T2, ?F, ?N)
%   is true when T1 and T2 have the same principal functor, and their
%   common functor is F/N. Given T1 (or T2) the remaining arguments
%   can be computed.  Given F and N, the remaining arguments can be
%   computed.  If too many arguments are unbound, an error is reported.

same_functor(T1, T2, F, N) :-
	(   nonvar(T1) ->
	    functor(T1, F, N),
	    functor(T2, F, N)
	;   nonvar(T2) ->
	    functor(T2, F, N),
	    functor(T1, F, N)
	;   number(F) ->
	    N = 0, T1 = F, T2 = F
	;   nonvar(F), nonvar(N) ->
	    functor(T1, F, N),
	    functor(T2, F, N)
	;   %  var(T1), var(T2), (var(F) ; var(N)), \+number(F).
	    format(user_error,
		'~N! Instantiation fault in same_functor/~d~n! Goal: ~q~n',
		[4, same_functor(T1,T2,F,N)]),
	    fail	/* THIS IS NOT QUITE RIGHT */
	).

