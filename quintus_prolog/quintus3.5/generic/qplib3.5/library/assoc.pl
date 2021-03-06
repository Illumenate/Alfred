%   Package: assoc
%   Author : Richard A. O'Keefe
%   Updated: 19 Jul 1991
%   Purpose: Binary tree implementation of "association lists".

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

%   Note   : the keys should be ground, the associated values need not be.
%   CHANGE : 2 December 1987; arguments of gen_assoc/3 re-ordered to be
%	     the same as the get_assoc* (i.e. to follow the arg/3 rule).

:- module(assoc, [
	assoc_to_list/2,	% Assoc -> List
	gen_assoc/3,		% Key x Assoc x Val
	get_assoc/3,		% Key x Assoc -> Val
	get_next_assoc/4,	% Key x Assoc -> Key x Val
	get_prev_assoc/4,	% Key x Assoc -> Key x Val
	is_assoc/1,		% Assoc ->
	list_to_assoc/2,	% List -> Assoc
	ord_list_to_assoc/2,	% for library(maps)
	map_assoc/2,		% Pred x Assoc ->
	map_assoc/3,		% Pred x Assoc -> Assoc
	max_assoc/3,		% Assoc -> Key x Val
	min_assoc/3,		% Assoc -> Key x Val
	portray_assoc/1,	% Assoc ->
	put_assoc/4		% Key x Assoc x Val -> Assoc
   ]).

:- meta_predicate
	map_assoc(1, +),
	map_assoc(2, +, -).

:- use_module(library(call), [
	call/2,
	call/3
   ]).

:- mode
	assoc_to_list(+, -),
	    assoc_to_list(+, -, +),
	gen_assoc(?, +, ?),
	get_assoc(+, +, ?),
	    get_assoc(+, +, +, +, +, ?),
	get_next_assoc(+, +, ?, ?),
	get_prev_assoc(+, +, ?, ?),
	is_assoc(+),
	    is_assoc(+, ?, ?),
	list_to_assoc(+, -),
	    list_to_assoc(+, +, +, -),
	ord_list_to_assoc(+, -),
	map_assoc(+, ?),
	    'map assoc'(?, +),
	map_assoc(+, ?, ?),
	    'map assoc'(?, ?, +),
	portray_assoc(+),
	    portray_assoc(+, +, -),
	put_assoc(+, +, +, -),
	    'put assoc'(+, +, +, -),
		'put assoc'(+, +, +, -, +,+,+,+).

/* type
	assoc(Key,Val) -->
		assoc
	    |	assoc(Key, Val, assoc(Key,Val), assoc(Key,Val)).

:- pred
	assoc_to_list(assoc(K,V), list(pair(K,V))),
	    assoc_to_list(assoc(K,V), list(pair(K,V)), list(pair(K,V))),
	gen_assoc(K, assoc(K,V), V),
	get_assoc(K, assoc(K,V), V),
	    get_assoc(order, K, V, assoc(K,V), assoc(K,V), V),
	get_next_assoc(K, assoc(K,V), K, V),
	get_prev_assoc(K, assoc(K,V), K, V),
	is_assoc(assoc(K,V)),
	    is_assoc(assoc(K,V), K, K),
	list_to_assoc(list(pair(K,V)), assoc(K,V)),
	    list_to_assoc(integer, list(pair(K,V)), list(pair(K,V)), assoc(K,V)),
	ord_list_to_assoc(list(pair(K,V)), assoc(K,V)),
	map_assoc(void(V), assoc(K,V)),
	    'map assoc'(assoc(K,V), void(V)),
	map_assoc(void(V,U), assoc(K,V), assoc(K,U)),
	    'map assoc'(assoc(K,V), assoc(K,U), void(V,U)),
	max_assoc(assoc(K,V), K, V),
	min_assoc(assoc(K,V), K, V),
	portray_assoc(assoc(K,V)),
	    portray_assoc(assoc(K,V), atom, atom),
	put_assoc(K, assoc(K,V), V, assoc(K,V)),
	    'put assoc'(assoc(K,V), K, V, assoc(K,V)),
		'put assoc'(order, K, , V, assoc(K,V)K, V, assoc(K,V), assoc(K,V)).
*/

sccs_id('"@(#)91/07/19 assoc.pl    64.1"').



%   assoc_to_list(+Assoc, ?List)
%   assumes that Assoc is a proper "assoc" tree, and is true when
%   List is a list of Key-Value pairs in ascending order with no
%   duplicate Keys specifying the same finite function as Assoc.
%   Use this to convert an assoc to a list.

assoc_to_list(Assoc, List) :-
	assoc_to_list(Assoc, List, []).


assoc_to_list(assoc) --> [].
assoc_to_list(assoc(Key,Val,L,R)) -->
	assoc_to_list(L),
	[Key-Val],
	assoc_to_list(R).



%   gen_assoc(?Key, +Assoc, ?Value)
%   assumes that Assoc is a proper "assoc" tree, and is true when
%   Key is associated with Value in Assoc.  Use this to enumerate
%   Keys and Values in the Assoc, or to find Keys associated with
%   a particular Value.  If you want to look up a particular Key,
%   you should use get_assoc/3.  Note that this predicate is not
%   determinate.  If you want to maintain a finite bijection, it
%   is better to maintain two assocs than to drive one both ways.
%   The Keys and Values are enumerated in ascending order of Keys.

gen_assoc(Key, assoc(_,_,L,_), Val) :-
	gen_assoc(Key, L, Val).
gen_assoc(Key, assoc(Key,Val,_,_), Val).
gen_assoc(Key, assoc(_,_,_,R), Val) :-
	gen_assoc(Key, R, Val).



%   get_assoc(+Key, +Assoc, ?Value)
%   assumes that Assoc is a proper "assoc" tree.  It is true when
%   Key is identical to (==) one of the keys in Assoc, and Value
%   unifies with the associated value.  Note that since we use the
%   term ordering to identify keys, we obtain logarithmic access,
%   at the price that it is not enough for the Key to unify with a
%   key in Assoc, it must be identical.  This predicate is determinate.
%   The argument order follows the the pattern established by the
%   built-in predicate arg/3 (called the arg/3, or selector, rule):
%	<predicate>(<indices>, <structure>, <element>).
%   The analogy with arg(N, Term, Element) is that
%	Key:N :: Assoc:Term :: Value:Element.

get_assoc(Key, assoc(K,V,L,R), Val) :-
	compare(Rel, Key, K),
	get_assoc(Rel, Key, V, L, R, Val).


get_assoc(=, _, Val, _, _, Val).
get_assoc(<, Key, _, Tree, _, Val) :-
	get_assoc(Key, Tree, Val).
get_assoc(>, Key, _, _, Tree, Val) :-
	get_assoc(Key, Tree, Val).




%   get_next_assoc(+Key, +Assoc, ?Knext, ?Vnext)
%   is true when Knext is the smallest key in Assoc such that Knext@>Key,
%   and Vnext is the value associated with Knext.  If there is no such
%   Knext, get_next_assoc/4 naturally fails.  It assumes that Assoc is
%   a proper assoc.  Key should normally be ground.  Note that there is
%   no need for Key to be in the association at all.  You can use this
%   predicate in combination with min_assoc/3 to traverse an association
%   tree; but if there are N pairs in the tree the cost will be O(NlgN).
%   If you want to traverse all the pairs, calling assoc_to_list/2 and
%   walking down the list will take O(N) time.

get_next_assoc(Key, assoc(K,V,L,R), Knext, Vnext) :-
	(   K @=< Key ->
	    get_next_assoc(Key, R, Knext, Vnext)
	;   get_next_assoc(Key, L, Knext, Vnext) ->
	    true
	;   Knext = K, Vnext = V
	).




%   get_prev_assoc(+Key, +Assoc, ?Kprev, ?Vprev)
%   is true when Kprev is the largest key in Assoc such that Kprev@<Key,
%   and Vprev is the value associated with Kprev.  You can use this
%   predicate in combination with max_assoc/3 to traverse an assoc.
%   See the notes on get_next_assoc/4.

get_prev_assoc(Key, assoc(K,V,L,R), Kprev, Vprev) :-
	(   K @>= Key ->
	    get_prev_assoc(Key, L, Kprev, Vprev)
	;   get_prev_assoc(Key, R, Kprev, Vprev) ->
	    true
	;   Kprev = K, Vprev = V
	).




%   is_assoc(+Thing)
%   is true when Thing is a (proper) association tree.  If you use the
%   routines in this file, you have no way of constructing a tree with
%   an unbound tip, and the heading of this file explicitly warns
%   against using variables as keys, so such structures are NOT
%   recognised as being association trees.  Note that the code relies
%   on variables (to be precise, the first anonymous variable in
%   is_assoc/1) being @< than any non-variable.

is_assoc(Assoc) :-
	is_assoc(Assoc, _, _).

is_assoc(-, _, _) :- !, fail.		% catch and reject variables
is_assoc(assoc, Min, Min).
is_assoc(assoc(Key,_,L,R), Min, Max) :-
	is_assoc(L, Min, Mid),
	Mid @< Key,
	is_assoc(R, Key, Max).



%   list_to_assoc(+List, ?Assoc)
%   is true when List is a proper list of Key-Val pairs (in any order)
%   and Assoc is an association tree specifying the same finite function
%   from Keys to Values.  Note that the list should not contain any
%   duplicate keys.  In this release, list_to_assoc/2 doesn't check for
%   duplicate keys, but the association tree which gets built won't work.

list_to_assoc(List, Assoc) :-
	keysort(List, Pairs),
	length(Pairs, N),
	list_to_assoc(N, Pairs, [], Assoc).


list_to_assoc(0, List, List, assoc) :- !.
list_to_assoc(N, List, Rest, assoc(Key,Val,L,R)) :-
	A is (N-1) >> 1,
	Z is (N-1) - A,
	list_to_assoc(A, List, [Key-Val|More], L),
	list_to_assoc(Z, More, Rest, R).



%   ord_list_to_assoc(+List, ?Assoc)
%   is a version of list_to_assoc/2 which trusts you to have sorted
%   the list already.  If you pair up an ordered set with suitable
%   values, calling this instead will save the sort.

ord_list_to_assoc(List, Assoc) :-
	length(List, N),
	list_to_assoc(N, List, [], Assoc).



%   map_assoc(+Pred, +Assoc)
%   is true when Assoc is a proper association tree, and for each
%   Key->Val pair in Assoc, the proposition Pred(Val) is true.
%   Pred must be a closure, and Assoc should be proper.
%   There should be a version of this predicate which passes Key
%   to Pred as well as Val, but there isn't.

map_assoc(Pred, Assoc) :-
	/* we should check Pred here */
	'map assoc'(Assoc, Pred).

'map assoc'(assoc, _).
'map assoc'(assoc(_,Val,L,R), Pred) :-
	'map assoc'(L, Pred),
	call(Pred, Val),
	'map assoc'(R, Pred).



%   map_assoc(+Pred, ?OldAssoc, ?NewAssoc)
%   is true when OldAssoc and NewAssoc are association trees of the
%   same shape (at least one of them should be provided as a proper
%   assoc, or map_assoc/3 may not terminate), and for each Key,
%   if Key is associated with Old in OldAssoc and with New in
%   NewAssoc, the proposition Pred(Old,New) is true.  Normally we
%   assume that Pred is a function from Old to New, but the code
%   does not require that.  There should be a version of this
%   predicate which passes Key to Pred as well as Old and New,
%   but there isn't.  If you'd have a use for it, please tell us.

map_assoc(Pred, OldAssoc, NewAssoc) :-
	% we should check Pred here!
	'map assoc'(OldAssoc, NewAssoc, Pred).

'map assoc'(assoc, assoc, _).
'map assoc'(assoc(Key,Old,L0,R0), assoc(Key,New,L1,R1), Pred) :-
	'map assoc'(L0, L1, Pred),
	call(Pred, Old, New),
	'map assoc'(R0, R1, Pred).



%   max_assoc(+Assoc, ?Key, ?Val)
%   is true when Key is the largest Key in Assoc, and Val is the
%   associated value.  It assumes that Assoc is a proper assoc.
%   This predicate is determinate.  If Assoc is empty, it just
%   fails quietly; an empty set can have no largest element!

max_assoc(assoc(K,V,_,R), Key, Val) :-
	(   atom(R) ->		% the right son is empty, K is biggest
	    Key = K, Val = V
	;   max_assoc(R, Key, Val)
	).




%   min_assoc(+Assoc, ?Key, ?Val)
%   is true when Key is the smallest Key in Assoc, and Val is the
%   associated value.  It assumes that Assoc is a proper assoc.
%   This predicate is determinate.  If Assoc is empty, it just
%   fails quietly; an empty set can have no smallest element!

min_assoc(assoc(K,V,L,_), Key, Val) :-
	(   atom(L) ->		% the left son is empty, K is smallest
	    Key = K, Val = V
	;   min_assoc(L, Key, Val)
	).




%   portray_assoc(+Assoc)
%   writes an association tree to the current output stream in a
%   pretty form so that you can easily see what it is.  Note that
%   an association tree written out this way can NOT be read back
%   in.  For that, use writeq/1.  The point of this predicate is
%   that you can add a directive
%	:- add_portray(portray_assoc).
%   to get association trees displayed nicely by print/1.

portray_assoc(assoc) :- !,
	write('Assoc{'),
	put("}").
portray_assoc(Assoc) :-
	is_assoc(Assoc),
	portray_assoc(Assoc, 'Assoc{', _),
	put("}").


portray_assoc(assoc, M, M).
portray_assoc(assoc(Key,Val,L,R), M0, M) :-
	portray_assoc(L, M0, M1),
	write(M1),
	print(Key), write(->), print(Val),
	portray_assoc(R, ',', M).




%   put_assoc(+Key, +OldAssoc, +Val, -NewAssoc)
%   is true when OldAssoc and NewAssoc define the same finite function,
%   except that NewAssoc associates Val with Key.  OldAssoc need not
%   have associated any value at all with Key,

put_assoc(Key, OldAssoc, Val, NewAssoc) :-
	'put assoc'(OldAssoc, Key, Val, NewAssoc).

'put assoc'(assoc, Key, Val, assoc(Key,Val,assoc,assoc)).
'put assoc'(assoc(K,V,L,R), Key, Val, New) :-
	compare(Rel, Key, K),
	'put assoc'(Rel, Key, Val, New, K, V, L, R).


'put assoc'(=, Key, Val, assoc(Key,Val,L,R), _, _, L, R).
'put assoc'(<, Key, Val, assoc(K,V,Tree,R), K, V, L, R) :-
	'put assoc'(L, Key, Val, Tree).
'put assoc'(>, Key, Val, assoc(K,V,L,Tree), K, V, L, R) :-
	'put assoc'(R, Key, Val, Tree).



/* ----------------------------------------------------------------------
test :-
	ord_list_to_assoc([a-1,b-2,c-3,d-4,e-5,g-6,h-7], Assoc),
	portray_assoc(Assoc), nl,
	min_assoc(Assoc, Kmin, Vmin),
	write((Kmin->Vmin)), nl,
	max_assoc(Assoc, Kmax, Vmax),
	write((Kmax->Vmax)), nl,
	get_next_assoc(Kmin, Assoc, Knxt, Vnxt),
	write((Knxt->Vnxt)), nl,
	get_prev_assoc(Kmax, Assoc, Kprv, Vprv),
	write((Kprv->Vprv)), nl,
	get_prev_assoc(Kmin, Assoc, _, _).
---------------------------------------------------------------------- */

