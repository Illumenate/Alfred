%   Package: arrays
%   Author : Richard A. O'Keefe
%   Updated: 01 Jun 1989
%   Defines: updatable arrays in Prolog.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.


/*  The operations in this file are fully described in an Edinburgh
    Department of Artificial Intelligence Working Paper (WP-150) by
    me, entitled "Updatable Arrays in Prolog", dated 1983.

    The basic idea is that these operations give you arrays whose
    elements can be fetched AND CHANGED in constant expected time
    and space.  This is an example of logic hacking, rather than
    logic programming.  For a logical solution (with O(lgN) cost)
    see library(logarr) by David Warren and Fernando Pereira.

    This was originally written for Dec-10 Prolog, where functors of
    any arity are allowed.  In Quintus Prolog, only arity 255 is
    currently supported.  Exercise for the reader: make this file
    take that limit into account.
*/
:- module(arrays, [
	array_length/2,		%   array(T) x Length
	array_to_list/2,	%   array(T) -> list(T)
	array_fetch/3,		%   Index x array(T) -> T
	list_to_array/2,	%   list(T) -> array(T)
	list_to_array/3,	%   list(T) <- Length -> array(T)
	array_store/4		%   Index x array(T) x T -> array(T)
   ]).

:- mode
	array_length(?, ?),
	array_to_list(+, ?),
	    un_wrap(+, +, +, ?),
	array_fetch(+, +, ?),	%   was fetch/3
	    get_last(+, ?),
	list_to_array(+, -),
	list_to_array(?, ?, -),
	    wrap_up(+, +, +),
	array_store(+, +, +, -),%   was store/4
	    re_wrap(+, +, +),
	    put_last(+, +).

sccs_id('"@(#)89/06/01 arrays.pl	32.1"').


%   array_length(?Array, ?Length)
%   If +Array is given, it unifies ?Length with the size of the array.
%   If +Length is given, it binds -Array to a new array of that size.
%   The representation of an array of N elements is
%	array(E1,...,EN)+Updates
%    where Updates is an integer (the number of updates so far)
%    and each Ei is a partial list [Ei1,Ei2,...,Eik|_] of the
%    values which have been assigned to that index.
%    The preferred way of making an array is to call list_to_array/2.

array_length(Array+Updates, Length) :-
	functor(Array, array, Length),
	(   integer(Updates) -> true	% testing an existing array
	;   Updates = 0			% making a new array
	).



%   array_to_list(+Array, ?List)
%   unifies List with a list of the current values of the elements
%   of the array.

array_to_list(Array+_Updates, List) :-
	functor(Array, array, Length),
	un_wrap(Length, Array, [], List).

un_wrap(0, _, Accum, List) :- !,
	List = Accum.
un_wrap(N, Array, Accum, List) :-
	arg(N, Array, History),
	get_last(History, Element),
	M is N-1,
	un_wrap(M, Array, [Element|Accum], List).



%   array_fetch(+Index, +Array, ?Element)
%   unifies Element with the Indexth element of Array.
%   get_last(History, Element) unifies Element with the last
%   real element of a History [Ei1,...,Eik|_].

array_fetch(Index, Array+_Updates, Element) :-
	arg(Index, Array, History),
	get_last(History, Element).


get_last([Head|Tail], Element) :-
	(   var(Tail) -> Element = Head
	;   get_last(Tail, Element)
	).



%   list_to_array(+List, -Array)
%   makes a new array having the same elements as List.  List
%   should be a proper list.

list_to_array(List, Array) :-
	list_to_array(List, _, Array).


%   list_to_array(?List, ?Length, -Array)
%   can be used as list_to_array, but returning the length as
%   well, or it can be used to make both a list and an array
%   with the same known length and (unknown) elements.

list_to_array(List, Length, Array+0) :-
	length(List, Length),
	functor(Array, array, Length),
	wrap_up(List, Array, 1).


wrap_up([], _, _).
wrap_up([Element|Elements], Array, M) :-
	arg(M, Array, [Element|_]),
	N is M+1,
	wrap_up(Elements, Array, N).



%   array_store(+Index, +OldArray, +NewElement, -NewArray)
%   makes a NewArray which contains the same elements as OldArray
%   except that the Indexth element is NewElement.  DO NOT USE
%   the OldArray afterwards: it may or may not have been smashed.

array_store(Index, OldArray+OldUpdates, Element, NewArray+NewUpdates) :-
	functor(OldArray, array, Length),
	arg(Index, OldArray, History),
	put_last(History, Element),
	K is OldUpdates+1,
	(   K =:= Length ->
	    NewUpdates = 0,
	    functor(NewArray, array, Length),
	    re_wrap(Length, OldArray, NewArray)
	;   NewUpdates = K, NewArray = OldArray
	).


re_wrap(N, OldArray, NewArray) :-
	(   N =:= 0 -> true
	;   arg(N, OldArray, History),
	    get_last(History, Element),
	    arg(N, NewArray, [Element|_]),
	    M is N-1,
	    re_wrap(M, OldArray, NewArray)
	).


put_last(History, Element) :-
	var(History), !,
	History = [Element|_].
put_last([_|History], Element) :-
	put_last(History, Element).

