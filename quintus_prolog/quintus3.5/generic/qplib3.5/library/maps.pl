%   Package: maps
%   Author : Richard A. O'Keefe
%   Updated: 25 Aug 1988
%   Purpose: Implement finite maps.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  A finite map is a function from terms to terms with a finite
    domain.  This definition actually implies that its domain
    consists of ground terms, and the code below assumes that.
    The representation is similar to the representation for bags
    (indeed a bag could be regarded as a map from keys to integers),
    that is, the empty map is 'map' and any other map is
	map(Key,Val,Map)
    where Map is a finite map and Key is @< than every key in Map.
*/

:- module(maps, [
	is_map/1,		%  map ->
	list_to_map/2,		%  list -> map
	map_agree/2,		%  map x map ->
	map_compose/3,		%  map x map -> map
	map_disjoint/2,		%  map x map ->
	map_domain/2,		%  map -> ordset
	map_exclude/3,		%  map x ordset -> map
	map_include/3,		%  map x ordset -> map
	map_intersection/3,	%  map x map -> map
	map_invert/2,		%  map -> map
	map_map/3,		%  relation x map -> map
	map_range/2,		%  map -> ordset
	map_to_assoc/2,		%  map -> tree
	map_to_list/2,		%  map -> list
	map_union/3,		%  map x map -> map
	map_update/3,		%  map x map -> map
	map_update/4,		%  map x key x val -> map
	map_value/3,		%  map x dom -> rng
	portray_map/1		%  map ->
   ]).
:- meta_predicate
	map_map(2, ?, ?),
	    map_map_(?, ?, 2).	    
:- use_module(library(call), [
	call/3
   ]),
   use_module(library(assoc), [
	ord_list_to_assoc/2	% just for us, in fact!
   ]),
   use_module(library(ordsets), [
	ord_disjoint/2
   ]).

:- mode
	is_map(+),
	    is_map(+, +),
	list_to_map(+, ?),
	    list_to_map_(+, ?),
	map_agree(+, +),
	    map_agree(+, +, +, +, +, +, +),
	map_compose(+, +, ?),
	    map_compose_(+, +, ?),
		map_compose_(+, +, +, +, +, +, +, ?),
	map_disjoint(+, +),
	map_domain(+, ?),
	map_exclude(+, +, ?),
	    map_exclude(+, +, +, +, +, +, ?),
	map_include(+, +, ?),
	    map_include(+, +, +, +, +, +, ?),
	map_intersection(+, +, ?),
	    map_intersection(+, +, +, +, +, +, +, ?),
	map_invert(+, ?),
	    map_invert_(+, -),
	map_map(+, +, ?),
	    map_map_(+, ?, +),
	map_range(+, ?),
	    map_range_(+, -),
	map_to_assoc(+, ?),
	map_to_list(+, ?),
	map_union(+, +, ?),
	    map_union(+, +, +, +, +, +, +, ?),
	map_update(+, +, ?),
	    map_update(+, +, +, +, +, +, +, ?),
	map_update(+, +, +, ?),
	    map_update(+, +, +, +, +, +, ?),
	map_value(+, +, ?),
	    map_value(+, +, +, +, ?),
	portray_map(+),
	    portray_map(+, +).

sccs_id('"@(#)88/08/25 maps.pl	27.1"').

/*
:- type map(Key,Val) --> map | map(Key,Val,map(Key,Val)).

:- pred
	is_map(map(_,_)),
	    is_map(map(K,_), K),
	list_to_map(list(pair(K,V)), map(K,V)),
	    list_to_map_(list(pair(K,V)), map(K,V)),
	map_agree(map(K,V), map(K,V)),
	    map_agree(order, K, V, map(K,V), K, V, map(K,V)),
	map_compose(map(K,M), map(M,V), map(K,V)),
	    map_compose_(list(pair(M,K)), map(M,V), list(pair(K,V))),
		map_compose_(order, M, K, list(pair(M,K)), M, V, map(M,V), list(pair(K,V))),
	map_disjoint(map(K,V), map(K,V)),
	map_domain(map(K,V), list(K)),
	map_exclude(map(K,V), list(K), map(K,V)),
	    map_exclude(order, K, V, map(K,V), K, list(K), map(K,V)),
	map_include(map(K,V), list(K), map(K,V)),
	    map_include(order, K, V, map(K,V), K, list(K), map(K,V)),
	map_intersection(map(K,V), map(K,V), map(K,V)),
	    map_intersection(order, K,V,map(K,V), K,V,map(K,V), map(K,V)),
	map_invert(map(K,V), map(V,K)),
	    map_invert_(map(K,V), list(pair(V,K))),
	map_map(void(V1,V2), map(K,V1), map(K,V2)),
	    map_map_(map(K,V1), map(K,V2), void(V1,V2)),
	map_range(map(K,V), list(V)),
	    map_range_(map(K,V), list(V)),
	map_to_assoc(map(K,V), tree(K,V)),
	map_to_list(map(K,V), list(pair(K,V))),
	map_union(map(K,V), map(K,V), map(K,V)),
	    map_union(order, K, V, map(K,V), K, V, map(K,V), map(K,V)),
	map_update(map(K,V), map(K,V), map(K,V)),
	    map_update(order, K, V, map(K,V), K, V, map(K,V), map(K,V)),
	map_update(map(K,V), K, V, map(K,V)),
	    map_update(order, K, V, map(K,V), K, V, map(K,V)),
	map_value(map(K,V), K, V),
	    map_value(order, V, map(K,V), K, V),
	portray_map(map(_,_)),
	    portray_map(map(_,_), atom).
*/


%   is_map(Thing)
%   is true when Thing is a well-formed map (it is proper, and the keys
%   are strictly ascending).  library(maps) construct only well-formed maps.

is_map(-) :- !, fail.		% catch and reject variables
is_map(map).
is_map(map(Key,_,Map)) :-
	is_map(Map, Key).

is_map(-) :- !, fail.		% catch and reject variables.
is_map(map, _).
is_map(map(Key,_,Map), PreviousKey) :-
	PreviousKey @< Key,
	is_map(Map, Key).



%   list_to_map(+KeyValList, ?Map)
%   takes a list of Key-Value pairs and orders them to form a representation
%   of a finite map.  The list should not have two elements with the same Key.

list_to_map(List, Map) :-
	keysort(List, Sorted),
	list_to_map_(Sorted, Map).

list_to_map_([], map).
list_to_map_([Key-Val|List], map(Key,Val,Map)) :-
	list_to_map_(List, Map).



%   map_agree(+Map1, +Map2)
%   is true if whenever Map1 and Map2 have a key in common, they
%   agree on its value.  If they have no keys in common they agree.
%   You may find it useful to combine this with map_intersection/3.

map_agree(_, map) :- !.
map_agree(map, _).
map_agree(map(Key1,Val1,Map1), map(Key2,Val2,Map2)) :-
	compare(R, Key1, Key2),
	map_agree(R, Key1, Val1, Map1, Key2, Val2, Map2).

map_agree(<, _, _, Map1, Key2, Val2, Map2) :-
	map_agree(Map1, map(Key2,Val2,Map2)).
map_agree(>, Key1, Val1, Map1, _, _, Map2) :-
	map_agree(map(Key1,Val1,Map1), Map2).
map_agree(=, _, Val, Map1, _, Val, Map2) :-
	map_agree(Map1, Map2).



%   map_compose(Map1, Map2, Composition)
%   constructs Map1 o Map2.  That is, for each K-T in Map1 such that
%   there is a T-V in Map2, K-V is in Composition.  The way this is
%   done requires the range of Map1 to be ground as well as the domains
%   of both maps, but then any fast composition has the same problem.

map_compose(Map1, Map2, Composition) :-
	map_invert_(Map1, Inv0),
	keysort(Inv0, Inv1),
	map_compose_(Inv1, Map2, Mid0),
	keysort(Mid0, Mid1),
	list_to_map_(Mid1, Composition).

map_compose_(_, map, []) :- !.
map_compose_([], _, []).
map_compose_([Val1-Key1|Map1], map(Key2,Val2,Map2), Composition) :-
	compare(R, Val1, Key2),
	map_compose_(R, Val1, Key1, Map1, Key2, Val2, Map2, Composition).

map_compose_(<, _, _, Map1, Key2, Val2, Map2, Composition) :-
	map_compose_(Map1, map(Key2,Val2,Map2), Composition).
map_compose_(>, Val1, Key1, Map1, _, _, Map2, Composition) :-
	map_compose_([Val1-Key1|Map1], Map2, Composition).
map_compose_(=, Com, Key1, Map1, Com, Val2, Map2, [Key1-Val2|Composition]) :-
	map_compose_(Map1, map(Com,Val2,Map2), Composition).



%   map_disjoint(+Map1, +Map2)
%   is true when the two maps have no domain elements in common.
%   That is, if K-V1 is in Map1, there is no K-V2 in Map2 and conversely.
%   This implementation assumes you have loaded the ordered sets package.

map_disjoint(Map1, Map2) :-
	map_domain(Map1, Dom1),
	map_domain(Map2, Dom2),
	ord_disjoint(Dom1, Dom2).



%   map_domain(+Map, ?Domain)
%   unifies Domain with the ordered set representation of the domain
%   of the finite map Map.  As the keys (domain elements) of Map are
%   in ascending order and there are no duplicates, this is trivial.

map_domain(map, []).
map_domain(map(Key,_,Map), [Key|Domain]) :-
	map_domain(Map, Domain).



%   map_exclude(+Map, +Set, ?Restricted)
%   constructs a restriction of the Map by dropping members of the Set
%   from the Restricted map's domain.  That is, Restricted and Map agree,
%   but domain(Restricted) = domain(Map)\Set.
%   Set must be an *ordered* set.

map_exclude(Map, [], Map) :- !.
map_exclude(map, _, map).
map_exclude(map(Key,Val,Map), [Elt|Set], Restricted) :-
	compare(R, Key, Elt),
	map_exclude(R, Key, Val, Map, Elt, Set, Restricted).

map_exclude(<, Key, Val, Map, Elt, Set, map(Key,Val,Restricted)) :-
	map_exclude(Map, [Elt|Set], Restricted).
map_exclude(>, Key, Val, Map, _, Set, Restricted) :-
	map_exclude(map(Key,Val,Map), Set, Restricted).
map_exclude(=, _, _, Map, _, Set, Restricted) :-
	map_exclude(Map, Set, Restricted).



%   map_include(+Map, +Set, ?Restricted)
%   constructs a restriction of the Map by dropping everything which is
%   NOT a member of Set from the restricted map's domain.  That is, the
%   Restricted and original Map agree, but
%   domain(Restricted) = domain(Map) intersection Set.
%   Set must be an *ordered* set.

map_include(Map, [], Map) :- !.
map_include(map, _, map).
map_include(map(Key,Val,Map), [Elt|Set], Restricted) :-
	compare(R, Key, Elt),
	map_include(R, Key, Val, Map, Elt, Set, Restricted).

map_include(<, _, _, Map, Elt, Set, Restricted) :-
	map_include(Map, [Elt|Set], Restricted).
map_include(>, Key, Val, Map, _, Set, Restricted) :-
	map_include(map(Key,Val,Map), Set, Restricted).
map_include(=, Key, Val, Map, _, Set, map(Key,Val,Restricted)) :-
	map_include(Map, Set, Restricted).



%   map_intersection(+Map1, +Map2, ?Map)
%   unifies Map with the intersection of the two given maps Map1 and Map2.
%   That is, map_value(Map, Key, Val) is true if and only if both
%   map_value(Map1, Key, Val) and map_value(Map2, Key, Val) are true.
%   If Map1 and Map2 are both defined on Key, but associate different
%   values with it, Map will not be defined on Key at all.
%   Fernando C. N. Pereira @ SRI wrote this predicate.

map_intersection(_, map, map) :- !.
map_intersection(map, _, map).
map_intersection(map(Key1,Val1,Map1), map(Key2,Val2,Map2), Intersection) :-
	compare(R, Key1, Key2),
	map_intersection(R, Key1, Val1, Map1, Key2, Val2, Map2, Intersection).

map_intersection(<, _, _, Map1, Key2, Val2, Map2, Int) :-
	map_intersection(Map1, map(Key2,Val2,Map2), Int).
map_intersection(>, Key1, Val1, Map1, _, _, Map2, Int) :-
	map_intersection(map(Key1,Val1,Map1), Map2, Int).
map_intersection(=, Key, Val, Map1, Key, Val, Map2, Int) :- !,
	Int = map(Key,Val,Map),
	map_intersection(Map1, Map2, Map).
map_intersection(=, _, _, Map1, _, _, Map2, Int) :-
	map_intersection(Map1, Map2, Int).



%   map_invert(+Map, ?Inverse)
%   unifies Inverse with the inverse of a finite invertible map.
%   All we do is swap the pairs round, sort, and check that the
%   result is indeed a map.  

map_invert(Map, Inverse) :-
	map_invert_(Map, Inv0),
	keysort(Inv0, Inv1),
	list_to_map_(Inv1, Inverse).

%.  map_invert_(Map, KeyValList)
%   takes a map structure and produces a list of key-value pairs
%   with the keys and values swapped around.  Note that this list
%   is NOT in any particular order, but is ready for keysort/2.

map_invert_(map, []).
map_invert_(map(Key,Val,Map), [Val-Key|Inv]) :-
	map_invert_(Map, Inv).



%   map_map(+Predicate, +Map1, ?Map2)
%   composes Map1 with the Predicate, so that K-V2 is in Map2 if
%   K-V1 is in Map1 and Predicate(V1,V2).  There is a convention
%   which got established more or less by accident that the user-
%   callable version of a predicate like this has its Predicate
%   argument first.  That doesn't do wonders for indexing, hence
%   the map_map_ predicate, which puts the indexed argument first.
%   There should be another predicate like this which gives the
%   Key to the Predicate as well, but there is currently no
%   convention for that.  There should also be inclusion and
%   exclusion meta-predicates, but there aren't.

map_map(Pred, Map1, Map2) :-
	map_map_(Map1, Map2, Pred).

map_map_(map, map, _).
map_map_(map(Key,Val1,Map1), map(Key,Val2,Map2), Pred) :-
	call(Pred, Val1, Val2),
	map_map_(Map1, Map2, Pred).



%   map_range(+Map, ?Range)
%   unifies Range with the ordered set representation of the range of the
%   finite map Map.  Note that the cardinality (length) of the domain and
%   the range are seldom equal, except of course for invertible maps.

map_range(Map, Range) :-
	map_range_(Map, Random),
	sort(Random, Range).

map_range_(map, []).
map_range_(map(_,Val,Map), [Val|Range]) :-
	map_range_(Map, Range).



%   map_to_assoc(+Map, ?Assoc)
%   converts a finite map held as an ordered list of Key-Val pairs to
%   an ordered binary tree such as the library package `assoc' works on.
%   This predicate used to call an internal routine of library(assoc),
%   but with the introduction of the module system this ceased to be an
%   attractive thing to do.  The price was to introduce a new public
%   routine to library(assoc).  If keysort/2 were based on samsort/2,
%   there'd have been no point in the first place; what we want to do
%   is avoid sorting a list we already know is sorted.

map_to_assoc(Map, Assoc) :-
	map_to_list(Map, List),
	ord_list_to_assoc(List, Assoc).



%   map_to_list(+Map, ?KeyValList)
%   converts a map from its compact form to a list of Key-Val pairs
%   such as keysort yields or list_to_assoc wants.

map_to_list(map, []).
map_to_list(map(Key,Val,Map), [Key-Val|List]) :-
	map_to_list(Map, List).



%   map_union(+Map1, +Map2, ?Union)
%   forms the union of the two given maps.  That is Union(X) =
%   Map1(X) if it is defined, or Map2(X) if that is defined.
%   But when both are defined, both must agree.  (See map_update
%   for a version where Map2 overrides Map1.)

map_union(Map, map, Map) :- !.
map_union(map, Map, Map).
map_union(map(Key1,Val1,Map1), map(Key2,Val2,Map2), Union) :-
	compare(R, Key1, Key2),
	map_union(R, Key1, Val1, Map1, Key2, Val2, Map2, Union).

map_union(<, Key1, Val1, Map1, Key2, Val2, Map2, map(Key1,Val1,Union)) :-
	map_union(Map1, map(Key2,Val2,Map2), Union).
map_union(>, Key1, Val1, Map1, Key2, Val2, Map2, map(Key2,Val2,Union)) :-
	map_union(map(Key1,Val1,Map1), Map2, Union).
map_union(=, Key, Val, Map1, Key, Val, Map2, map(Key,Val,Union)) :-
	map_union(Map1, Map2, Union).



%   map_update(+Base, +Overlay, ?Updated)
%   combines the finite maps Base and Overlay as map_union does,
%   except that when both define values for the same key, the
%   Overlay value is taken regardless of the Base value.  This
%   is useful for changing maps (you may know it as the "mu" function).

map_update(Map, map, Map) :- !.
map_update(map, Map, Map).
map_update(map(Key1,Val1,Map1), map(Key2,Val2,Map2), Updated) :-
	compare(R, Key1, Key2),
	map_update(R, Key1, Val1, Map1, Key2, Val2, Map2, Updated).

map_update(<, Key1, Val1, Map1, Key2, Val2, Map2, map(Key1,Val1,Updated)) :-
	map_update(Map1, map(Key2,Val2,Map2), Updated).
map_update(>, Key1, Val1, Map1, Key2, Val2, Map2, map(Key2,Val2,Updated)) :-
	map_update(map(Key1,Val1,Map1), Map2, Updated).
map_update(=, _, _, Map1, Key, Val, Map2, map(Key,Val,Updated)) :-
	map_update(Map1, Map2, Updated).



%   map_update(+Map, +Key, +Val, ?Updated)
%   computes an Updated map which is the same as Map except that the
%   image of Key is Val, rather than the image it had under Map if any.
%   This is an O(N) operation, not O(1).  By using trees we could get
%   O(lgN).  Eventually this package should be merged with ASSOC.PL.

map_update(map, Key, Val, map(Key,Val,map)).
map_update(map(Key1,Val1,Map), Key, Val, Updated) :-
	compare(R, Key1, Key),
	map_update(R, Key1, Val1, Map, Key, Val, Updated).

map_update(<, Key1, Val1, Map, Key, Val, map(Key1,Val1,Updated)) :-
	map_update(Map, Key, Val, Updated).
map_update(=, _, _, Map, Key, Val, map(Key,Val,Map)).
map_update(>, Key1, Val1, Map, Key, Val, map(Key,Val,map(Key1,Val1,Map))).



%   map_value(+Map, +Arg, ?Result)
%   applies the finite map Map to an argument, and unifies Result with
%   the answer.  It fails if Arg is not in the domain of Map, or if the
%   value does not unify with Result.  Note that this operation is O(N)
%   like all the others; this package is really meant for working on
%   maps as wholes.  We can achieve O(lgN) by using trees (as in ASSOC),
%   and eventually MAPS and ASSOC should be merged.  In the mean time,
%   use map_to_assoc to convert a map to a tree for faster lookup.

map_value(map(Key,Val,Map), Arg, Result) :-
	compare(R, Key, Arg),
	map_value(R, Val, Map, Arg, Result).

map_value(<, _, Map, Arg, Result) :- !,
	map_value(Map, Arg, Result).
map_value(=, Result, _, _, Result).



%   portray_map(+Map)
%   writes a finite Map to the current output stream in a pretty
%   form so that you can easily see what it is.  Note that a map
%   written out this way can NOT be read back in.  The point of
%   this predicate is that you can add a clause
%	portray(X) :- is_map(X), !, portray_map(X).
%   to get maps displayed nicely by print/1.

portray_map(map) :- !,
	write('Map{'), write('}').
portray_map(Map) :-
	portray_map(Map, 'Map{').

portray_map(map, _) :-
	write('}').
portray_map(map(Key,Val,Map), Prefix) :-
	write(Prefix),
	print(Key), write('->'), print(Val),
	portray_map(Map, ', ').

