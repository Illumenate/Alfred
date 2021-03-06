%   Package: multi_lists
%   Author : Lawrence Byrd
%   Updated: 25 Aug 1988
%   Purpose: Multiple-list routines

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

%   The predicates defined in this package are analogues of those in 'maplist'.
%   This style of programming which would find them useful is now frowned upon,
%   not least because they cannot be type-checked.  (The type checker isn't yet
%   distributed with Quintus Prolog, but was descibed in AI Journal.)  However,
%   you may find their structure instructive.

:- module(multi_lists, [
	ml_maplist/2,
	ml_maplist/3,
	ml_maplist/4,
	ml_member/2,
	ml_memberchk/2,
	ml_select/3
   ]).
:- meta_predicate
	ml_maplist(1, +),
	ml_maplist(2, +, +),
	ml_maplist(3, +, +, +).
:- use_module(library(call), [
	call/2,			% used by ml_maplist/2
	call/3,			% used by ml_maplist/3
	call/4			% used by ml_maplist/4
   ]).

sccs_id('"@(#)88/08/25 multil.pl	27.1"').



%.  ml_taketop(?Lists, ?Heads, ?Tails)
%   is true when Lists is a list of non-empty lists, Heads is a list
%   whose elements are the heads of the elements of Lists, and Tails
%   is a list whose elements are the tails of Lists.  If a type were
%   given, it could only be
%	:- pred ml_taketop(list(list(T)), list(T), list(list(T))).
%   but usually the elements of Lists will have different types.

ml_taketop([], [], []).
ml_taketop([[Head|Tail]|Lists], [Head|Heads], [Tail|Tails]) :-
	ml_taketop(Lists, Heads, Tails).



%.  ml_taketop(?Lists, ?Heads, ?Tails, ?Bound)
%   is the same as ml_taketop(Lists, Heads, Tails) except that it
%   constrains all its arguments to be the same length.

ml_taketop([], [], [], []).
ml_taketop([[Head|Tail]|Lists], [Head|Heads], [Tail|Tails], [_|Bound]) :-
	ml_taketop(Lists, Heads, Tails, Bound).



%.  ml_allempty(+Lists)
%   is true when Lists is a list, all of whose elements are nil ([]).
%   It is used to test whether all the lists being mapped over have
%   come to an end at once.  Since ml_taketop will succeed precisely
%   when all the lists have at least one member, we could produce a
%   set of routines that terminate when any list runs out by simply
%   omitting this test.  As it is, the ml* routines demand that all
%   the lists be the same length.  If a type were given, it would be
%	:- pred ml_allempty(list(list(T))).
%   but usually the elements of Lists will have different types.

ml_allempty([]).
ml_allempty([[]|Tail]) :-
	ml_allempty(Tail).



%   ml_maplist(+Pred, +?Lists)
%   applies Pred to argument tuples which are successive slices of the Lists.
%   Thus ml_maplist(tidy, [Untidy,Tidied]) would apply tidy([U,T]) to each
%   successive [U,T] pair from Untidy and Tidied.  If Pred is determinate,
%   it is tail-recursive.  Note that we try the base case first; this is a
%   good thing to do almost all the time.  If any of the elements of Lists
%   is a proper list, ml_maplist/2 will terminate.

ml_maplist(_, Lists) :-
	ml_allempty(Lists).
ml_maplist(Pred, Lists) :-
	ml_taketop(Lists, Heads, Tails),
	call(Pred, Heads),
	ml_maplist(Pred, Tails).



%   ml_maplist(+Pred, +?Lists, ?Extra)
%   is like ml_maplist/2, but passes the Extra argument to Pred as well
%   as the slices from the Lists.

ml_maplist(_, Lists, _) :-
	ml_allempty(Lists).
ml_maplist(Pred, Lists, Extra) :-
	ml_taketop(Lists, Heads, Tails),
	call(Pred, Heads, Extra),
	ml_maplist(Pred, Tails, Extra).



%   ml_maplist(+Pred, +?Lists, ?Init, ?Final)
%   is like ml_maplist/2, but has an extra accumulator feature.  Init is
%   the initial value of the accumulator, and Final is the final result.
%   Pred(Slice, AccIn, AccOut) is called to update the accumulator.

ml_maplist(_, Lists, Accum, Accum) :-
	ml_allempty(Lists).
ml_maplist(Pred, Lists, AccOld, AccNew) :-
	ml_taketop(Lists, Heads, Tails),
	call(Pred, Heads, AccOld, AccMid),
	ml_maplist(Pred, Tails, AccMid, AccNew).



%   ml_member(?Elems, ?Lists)
%   is true when Lists is a list of lists [[X1,...,Xn],...,[Z1,...,Zn]]
%   and Elems is a slice across that: [Xi,...,Zi] for some i.  It is a
%   multi-list analogue of member/2.

ml_member(Elems, Lists) :-
	ml_taketop(Lists, Heads, Tails, Elems),
	ml_member(Heads, Tails, Elems).

ml_member(Heads, _, Heads).
ml_member(_, Tails, Elems) :-
	ml_member(Elems, Tails).



%   ml_memberchk(+Elems, +Lists)
%   is true when Lists is a list of lists [[X1,...,Xn],...,[Z1,...,Zn]]
%   and Elems is the first slice [Xi,...,Zi] to match.  It is a multi-
%   list analogue of memberchk/2.

ml_memberchk(Elems, Lists) :-
	ml_taketop(Lists, Heads, Tails, Elems),
	ml_memberchk(Heads, Tails, Elems).

ml_memberchk(Heads, _, Heads) :- !.
ml_memberchk(_, Tails, Elems) :-
	ml_memberchk(Tails, Elems).



%   ml_select(?Elems, ?Lists, ?Residues)
%   is true when Lists is a list of lists [[X1,...,Xn],...,[Z1,...,Zn]],
%   Elems is a slice across that: [Xi,...,Zi], and Residues is List with
%   Elems sliced out: [[X1,.{no Xi}.,Xn],...,[Z1,.{no Zi}.,Zn]].  It is
%   a multi-list analogue of select/3.

ml_select(Elems, Lists, Residues) :-
	ml_taketop(Lists, Heads, Tails, Elems),
	ml_select(Heads, Tails, Elems, Residues).

ml_select(Heads, Tails, Heads, Tails).
ml_select(Heads, Tails, Elems, Residues) :-
	ml_putback(Heads, Rests, Residues),
	ml_select(Elems, Tails, Rests).


%.  ml_putback(+Heads, ?Tails, ?Lists)
%   is true when ml_taketop(Lists, Heads, Tails) is true, but is
%   rearranged for efficiency with a different calling pattern.

ml_putback([], [], []).
ml_putback([Head|Heads], [Tail|Tails], [[Head|Tail]|Lists]) :-
	ml_putback(Heads, Tails, Lists).



