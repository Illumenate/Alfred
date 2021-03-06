%   Package: qsort
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Defines: qsort/2, qmsort/2, qkeysort/2

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(qsort, [
	qsort/2,		% sort on whole values, discard duplicates
	qmsort/2,		% sort on whole values, retain duplicates
	qkeysort/2		% sort on first argument, retain duplicates
   ]).

sccs_id('"@(#)89/08/29 qsort.pl    33.1"').

/*  These routines mimic the built-in predicates sort/2 and keysort/2,
    except that they use a stable version of quick-sort instead of
    the merge-sort variant used by the built-in predicates.

    This file is just an example.  library(samsort) is a better
    sorting routine, and offers the possibility of providing your
    own comparison predicate.

    A general warning:
	+==================================================+
	|  quick-sort is not a very good sorting routine.  |
	+==================================================+
    It doesn't matter _what_ programming language you use, quick-sort
    does (on a good day, with the wind behind it) more comparisons
    than merge sort, by quite a large margin.

    For Prolog, and for applicative languages in general, merge sort
    is superior in every way.  The many studies which seem to show that
    quicksort is good have all, as far as I know, sorted sequences of
    numbers, for which there are algorithms with LINEAR expected time.

    A problem with the usual implementation of quicksort is that it
    is not STABLE.  Stability means that if A occurs before B in the
    input, and the comparison routine regards A and B as equivalent,
    then A will occur before B in the output.  This is particularly
    useful for multi-key sorting, where you want to sort on the
    least significant key, then the next least significant key, and
    so on.  This version of quick-sort IS stable.  The secret is in
    partition/5.  This modification is easy in Prolog, as we have to
    construct a new list anyway.
*/


:- mode
	qsort(+, ?),
	qsort(+, ?, +),
	qpartition(+, +, -, -),
	qpartition(+, +, -, -, +, +).

%   qsort(+Raw, ?Sorted)
%   mimics the standard predicate sort/2.  See the code for qkeysort
%   for comments which explain how it works.  This version of partition
%   is different: for compatibility with sort/2 it discards duplicates
%   of Key rather than putting them in a difference list.

qsort(Random, Ordered) :-
	qsort(Random, Ordered, []).

qsort([], Result, Result).
qsort([Head|Tail], Front, Back) :-
	qpartition(Tail, Head, Less, Greater),
	qsort(Less, Front, [Head|Middle]),
	qsort(Greater, Middle, Back).

qpartition([], _, [], []).
qpartition([Head|Tail], Key, Less, Greater) :-
	compare(R, Head, Key),
	qpartition(R, Key, Less, Greater, Head, Tail).

qpartition(<, Key, [Head|Less], Greater, Head, Tail) :-
	qpartition(Tail, Key, Less, Greater).
qpartition(>, Key, Less, [Head|Greater], Head, Tail) :-
	qpartition(Tail, Key, Less, Greater).
qpartition(=, Key, Less, Greater, _, Tail) :-
	qpartition(Tail, Key, Less, Greater).



:- mode
	qmsort(+, ?),
	qmsort(+, ?, +),
	qmpartition(+, +, -, -, ?, ?),
	qmpartition(+, +, -, -, ?, ?, +, +).


%   qmsort(+Raw, ?Sorted)
%   mimics the predicate msort/2 which is present in some Prologs.
%   That is, it is a stable sort which retains duplicate elements,
%   but otherwise is like sort/2.  The only difference between
%   this routine and qkeysort/2 is that it calls compare/3 rather
%   than keycompare/3.

qmsort(Random, Ordered) :-
	qmsort(Random, Ordered, []).

qmsort([], Result, Result).
qmsort([Head|Tail], Front, Back) :-
	qmpartition(Tail, Head, Less, Greater, Equal, Middle),
	qmsort(Less, Front, [Head|Equal]),
	qmsort(Greater, Middle, Back).

qmpartition([], _, [], [], Equal, Equal).
qmpartition([Head|Tail], Key, Less, Greater, Equal0, Equal) :-
	compare(R, Head, Key),
	qmpartition(R, Key, Less, Greater, Equal0, Equal, Head, Tail).

qmpartition(<, Key, [Head|Less], Greater, Equal0, Equal, Head, Tail) :-
	qmpartition(Tail, Key, Less, Greater, Equal0, Equal).
qmpartition(>, Key, Less, [Head|Greater], Equal0, Equal, Head, Tail) :-
	qmpartition(Tail, Key, Less, Greater, Equal0, Equal).
qmpartition(=, Key, Less, Greater, [Head|Equal0], Equal, Head, Tail) :-
	qmpartition(Tail, Key, Less, Greater, Equal0, Equal).



:- mode
	qkeysort(+, ?),
	qkeysort(+, ?, +),
	qkeypartition(+, +, -, -, ?, ?),
	qkeypartition(+, +, -, -, ?, ?, +, +),
	keycompare(-, +, +).

%   qkeysort(+Random, ?Ordered)
%   unifies Ordered with a sorted version of the list Random,
%   where the elements of Random are Key-Value pairs, and only the
%   Key fields are to participate in comparison.  If any element
%   of Random is not a Key-Value pair, it quietly fails.

qkeysort(Random, Ordered) :-
	qkeysort(Random, Ordered, []).

%.  qkeysort(+Random, ?Front, ?Back)
%   constructs the ordered version of Random in the DIFFERENCE LIST
%   Front-Back.

qkeysort([], Result, Result).
qkeysort([Head|Tail], Front, Back) :-
	qkeypartition(Tail, Head, Less, Greater, Equal, Middle),
	qkeysort(Less, Front, [Head|Equal]),
	qkeysort(Greater, Middle, Back).

%.  qkeypartition(List, Key0, LessEqual, Greater, Key)
%   binds LessEqual to a list containing all the elements of
%   [Key0|List] that are less than or equal to Key0, with the
%   exception of the LAST element EQUAL to Key0, which is returned
%   in Key.  Greater is bound to a list containing all the elements
%   of [Key0|List] which are greater than Key0.  The fact that Key0
%   may be put back into LessEqual and the last equal element returned
%   as Key is necessary to make this sorting routine stable.

qkeypartition([], _, [], [], Equal, Equal).
qkeypartition([Head|Tail], Key, Less, Greater, Equal0, Equal) :-
	keycompare(R, Head, Key),
	qkeypartition(R, Key, Less, Greater, Equal0, Equal, Head, Tail).

qkeypartition(<, Key, [Head|Less], Greater, Equal0, Equal, Head, Tail) :-
	qkeypartition(Tail, Key, Less, Greater, Equal0, Equal).
qkeypartition(>, Key, Less, [Head|Greater], Equal0, Equal, Head, Tail) :-
	qkeypartition(Tail, Key, Less, Greater, Equal0, Equal).
qkeypartition(=, Key, Less, Greater, [Head|Equal0], Equal, Head, Tail) :-
	qkeypartition(Tail, Key, Less, Greater, Equal0, Equal).

keycompare(R, Key1-_, Key2-_) :-
	compare(R, Key1, Key2).

