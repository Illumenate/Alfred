%   Package: ordprefix
%   Author : Richard A. O'Keefe
%   Updated: 10 Nov 1987
%   Purpose: Extract ordered prefixes from sequences
%   SeeAlso: ordered.pl; ordsets.pl

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(ordprefix, [
	decreasing_prefix/3,
	decreasing_prefix/4,
	increasing_prefix/3,
	increasing_prefix/4
   ]).
:- meta_predicate
	decreasing_prefix(2, +, ?, ?),
	first_precedes(2, +, +),
	increasing_prefix(2, +, ?, ?),
	precedes_first(2, +, +).
:- use_module(library(call), [
	call/3
   ]).

/* mode
	decreasing_prefix(+, ?, ?),
	decreasing_prefix(+, +, ?, ?),
	first_precedes(+, +),
	first_precedes(+, +, +),
	increasing_prefix(+, ?, ?),
	increasing_prefix(+, +, ?, ?),
	precedes_first(+, +),
	precedes_first(+, +, +).

:- pred
	decreasing_prefix(list(T), list(T), list(T)),
	decreasing_prefix(void(T,T), list(T), list(T), list(T)),
	first_precedes(T, list(T)),
	first_precedes(void(T,T), T, list(T)),
	increasing_prefix(list(T), list(T), list(T)),
	increasing_prefix(void(T,T), list(T), list(T), list(T)),
	precedes_first(T, list(T)),
	precedes_first(void(T,T), T, list(T)).
*/

sccs_id('"@(#)87/11/10 ordprefix.pl	10.2"').

/*  The routines in this package are intended for finding runs
    in sequences.
*/

%   increasing_prefix(Sequence, Prefix, Tail)
%   is true when append(Prefix, Tail, Sequence)
%   and Prefix, together with the first element of Tail,
%   forms a monotone non-decreasing sequence, and
%   no longer Prefix will do.  Pictorially,
%   Sequence = [x1,...,xm,xm+1,...,xn]
%   Prefix   = [x1,...,xm]
%   Tail     = [xm+1,...,xn]
%   x1 @=< x2 @=< ... @=< xm @=< xm+1
%   not xm+1 @=< xm+2
%   This is perhaps a surprising definition; you might expect
%   that the first element of Tail would be included in Prefix.
%   However, this way, it means that if Sequence is a strictly
%   decreasing sequence, the Prefix will come out empty.  The
%   routine is part of a package for counting runs.

increasing_prefix([Elem|Sequence], [Elem|Prefix], Tail) :-
	precedes_first(Elem, Sequence),
	!,
	increasing_prefix(Sequence, Prefix, Tail).
increasing_prefix(Sequence, [], Sequence).

precedes_first(X, [Y|_]) :-
	X @=< Y.


%   increasing_prefix(Order, Sequence, Prefix, Tail)
%   is the same as increasing_prefix/3, except that it uses the
%   binary relation Order in place of @=<.

increasing_prefix(Order, [Elem|Sequence], [Elem|Prefix], Tail) :-
	precedes_first(Order, Elem, Sequence),
	!,
	increasing_prefix(Order, Sequence, Prefix, Tail).
increasing_prefix(_, Sequence, [], Sequence).

precedes_first(Order, X, [Y|_]) :-
	call(Order, X, Y).


%   decreasing_prefix([Order, ]Sequence, Prefix, Tail)
%   is the same, except it looks for a decreasing prefix.
%   The order is the converse of the given order.  That
%   is, where increasing_prefix/3-4 check X(R)Y, these
%   routines check Y(R)X.

decreasing_prefix([Elem|Sequence], [Elem|Prefix], Tail) :-
	first_precedes(Elem, Sequence),
	!,
	decreasing_prefix(Sequence, Prefix, Tail).
decreasing_prefix(Sequence, [], Sequence).

first_precedes(X, [Y|_]) :-
	Y @=< X.


decreasing_prefix(Order, [Elem|Sequence], [Elem|Prefix], Tail) :-
	first_precedes(Order, Elem, Sequence),
	!,
	decreasing_prefix(Order, Sequence, Prefix, Tail).
decreasing_prefix(_, Sequence, [], Sequence).

first_precedes(Order, X, [Y|_]) :-
	call(Order, Y, X).


/*  As an example of these predicates, here is how to tell
    whether a sequence is unimodal:

	unimodal(Seq) :-
		increasing_prefix(Seq, _, Mid),
		decreasing_prefix(Mid, _, [_]).
*/
