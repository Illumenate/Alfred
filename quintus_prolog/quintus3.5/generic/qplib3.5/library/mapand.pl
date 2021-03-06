%   Package: mapand
%   Author : Richard A O'Keefe
%   Updated: 25 Aug 1988
%   Purpose: mapping routines over &-trees

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(mapand, [
	checkand/2,
	mapand/3
   ]).
:- meta_predicate
	checkand(1, +),
	mapand(2, ?, ?).
:- use_module(library(call), [
	call/2,
	call/3
   ]).

sccs_id('"@(#)88/08/25 mapand.pl	27.1"').


/*  Once upon a time, there was a single file called apply.pl.
    Now, it has been split into three files:
	call.pl		- apply/2, call/2-5, and others
	maplist.pl	- mapping routines for lists
	mapand.pl	- this file
    These routines are of mainly historical interest.  They've not
    been deleted from the library in case anyone still has a use for
    them, and they do illustrate how one might write mapping routines
    for binary trees with data only at the tips.  If you want other
    mapping routines, you can cobble something together in a hurry
    by doing
	and_to_list(TheTree, AList),
	<list version of mapping routine>(Pred, AList, AnotherList),
	list_to_and(AnotherList, TheAnswerTree)
    Let us know what's useful, so we can put it in the next version.
    It is possible for checkand/2 and mapand/3 to backtrack and try
    alternative solutions.  The cuts are there only because "non-and"
    is defined by exclusion.  A consequence of this is that neither of
    these predicates can be assigned a type.  (Unlike list mapping.)
*/

%   checkand(+Pred, +Conjunction)
%   succeeds when Pred(Conjunct) succeeds for every Conjunct
%   in the Conjunction.  Conjunction must be a proper &-tree.

checkand(_, true) :- !.
checkand(Pred, &(A,B))  :- !,
	checkand(Pred, A),
	checkand(Pred, B).
checkand(Pred, A) :-
	call(Pred, A).



%   mapand(+Rewrite, ?OldConj, ?NewConj)
%   succeeds when Rewrite is able to rewrite each conjunct of OldConj,
%   and combines the results into NewConj.  Either OldConj or NewConj
%   should be a proper &-tree.

mapand(_, true, true) :- !.
mapand(Pred, &(Old,Olds), &(New,News)) :- !,
	mapand(Pred, Old,  New),
	mapand(Pred, Olds, News).
mapand(Pred, Old, New) :-
	call(Pred, Old, New).



