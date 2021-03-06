%   Package: note
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: New "recorded" data-base commands.
%   SeeAlso: library(retract).

%   Copyright (C) 1989, Quintus Computer Systems, Inc.  All rights reserved.

:- module(note, [
	note/2,			%  Key x Term ->
	note/3,			%  Key x Term -> Ref
	notea/2,		%  Key x Term ->
	notea/3,		%  Key x Term -> Ref
	notez/2,		%  Key x Term ->
	notez/3,		%  Key x Term -> Ref
	noted/2,		%  Key x Term
	noted/3,		%  Key x Term x Ref
	scrap/2,		%  Key x Term
	scrap_every/1,		%  Key ->
	scrap_every/2,		%  Key x Term ->
	scrap_first/1,		%  Key ->
	scrap_first/2		%  Key x Term ->
   ]).
:- use_module(library(types), [
	must_be/4
   ]).

sccs_id('"@(#)89/08/29 note.pl	33.1"').

/*  The point of this package is to provide a version of the recorded
    data base which uses all of the key (which must be ground), not just
    the principal functor.  This runnable specification provides the
    function of such an extended internal data base, but not the
    efficient indexing that you would expect.  This does not represent a
    commitment by Quintus to develop such an extended internal data
    base, and is not necessarily the opinion of its author or of anyone
    else at all.
*/


%   note(Key, Term[, Ref])
%   stores a Term under a ground Key in the recorded data base, and
%   optionally returns a data base reference to it.  Use this when you
%   do not care about the order of Terms.  Just to ensure that you
%   don't care, from release to release I intend to change the order...
%   This predicate has already been flipped twice...

note(Key, Term, Ref) :-
	Goal = note(Key, Term, Ref),
	must_be(ground, Key, 1, Goal),
	recordz(Key, Key^Term, X),
	(   var(Ref) -> Ref = X
	;   must_be(var, Ref, 3, Goal)
	).


note(Key, Term) :-
	must_be(ground, Key, 1, note(Key,Term)),
	recordz(Key, Key^Term, _).



%   notea(Key, Term, Ref)
%   is just like recorda(Key, Term, Ref) except that the Key must be
%   ground, and that all of the key is significant, not just the principal
%   functor.  Note that this is just a runnable specification; if we were
%   to implement this operation properly in Quintus Prolog we could index
%   on the first argument of the Key as well.  notea/3 uses a standard
%   hack for making all of the Key significant which has been known ever
%   since recorda/3 was first introduced.

notea(Key, Term, Ref) :-
	Goal = notea(Key, Term, Ref),
	must_be(ground, Key, 1, Goal),
	recorda(Key, Key^Term, X),
	(   var(Ref) -> Ref = X
	;   must_be(var, Ref, 3, Goal)
	).


%   notea(Key, Term)
%   is to be used when you couldn't care less about the db_reference.

notea(Key, Term) :-
	must_be(ground, Key, 1, notea(Key,Term)),
	recorda(Key, Key^Term, _).



%   notez(Key, Term, Ref)
%   is just like recordz(Key, Term, Ref) except that the Key must be
%   ground, and that all of the key is significant, not just the principal
%   functor.  While it is not strictly necessary, we check that the Ref
%   argument is a variable; there is nothing else you could put here
%   which would allow the goal to succeed.

notez(Key, Term, Ref) :-
	Goal = notez(Key, Term, Ref),
	must_be(ground, Key, 1, Goal),
	recordz(Key, Key^Term, X),
	(   var(Ref) -> Ref = X
	;   must_be(var, Ref, 3, Goal)
	).


%   notez(Key, Term)
%   is to be used when you couldn't care less about the db_reference.

notez(Key, Term) :-
	must_be(ground, Key, 1, notez(Key,Term)),
	recordz(Key, Key^Term, _).



%   noted(Key, Term, Ref)
%   is just like recorded(Key, Term, Ref) except that it is able to
%   enumerate Keys, thanks to current_key/3.  This predicate is fully
%   relational, unlike recorded/3.

noted(Key, Term, Ref) :-
	Hack = Key^Term,
	(   nonvar(Ref) ->
	    instance(Ref, Hack)
	;   nonvar(Key) ->
	    true
	;   current_key(_, Key)
	),
	recorded(Key, Hack, Ref).


%   noted(Key, Term)
%   is to be used when you couldn't care less about the db_reference.

noted(Key, Term) :-
	current_key(_, Key),
	recorded(Key, Key^Term, _).



%   scrap(Key, Term)
%   is an analogue of retract/1 (more accurately, of the PDP-11 NU7 Prolog
%   and C Prolog predicate deny/2).  It enumerates Keys and Terms from the
%   data base, erasing each matching Key/Term pair.  There is no direct
%   equivalent for recorda/3.  We don't really need this operation, as it
%   is possible to call noted(Key, Term, Ref), erase(Ref) directly.

scrap(Key, Term) :-
	current_key(_, Key),
	recorded(Key, Key^Term, Ref),
	erase(Ref).



%   scrap_every(Key, Term)
%   erases every Key/Term in the "noted" data base for which
%   noted(Key, Term) would have been true.  If there is no such
%   Key/Term pair, it still succeeds.

scrap_every(Key, Term) :-
	current_key(_, Key),
	recorded(Key, Key^Term, Ref),
	erase(Ref),
	fail ; true.



%   scrap_every(Key)
%   erases every Key/Term pair in the "noted" data base for
%   which noted(Key,Term) would have been true.  If there is
%   no such Key/Term pair, it still succeeds.

scrap_every(Key) :-
	current_key(_, Key),
	recorded(Key, Key^_, Ref),
	erase(Ref),
	fail ; true.


%   scrap_first(Key, Term)
%   erases the first Key/Term pair to match in the "noted" data
%   base.  It is not 100% clear what the best definition of this
%   would be: you might expect it to erase the first match with
%   Key and unify the result with Term, and that would be quite
%   reasonable.  For the moment, it is just like wipe_first in
%   this respect (which is influenced by deny_first, which is
%   consistent with retract...)  The Key must be fully specified.

scrap_first(Key, Term) :-
	must_be(ground, Key, 1, scrap_first(Key,Term)),
	recorded(Key, Key^Term, Ref),
	!,
	erase(Ref).


%   scrap_first(Key)
%   erases the first Key/Term pair for Key.  Note that
%   erase_first(K,T) might have erased a different term.

scrap_first(Key) :-
	must_be(ground, Key, 1, scrap_first(Key)),
	recorded(Key, Key^_, Ref),
	!,
	erase(Ref).

