%   File   : activeread.pl
%   Author : Richard A. O'Keefe
%   SCCS   : @(#)88/11/02 activeread.pl	27.2
%   Purpose: allow input to be computed.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  Languages like Lisp let you read an expression and evaluate it, and
    the result is a data structure.  Prolog has "evaluation" only for
    arithmetic expressions, and then only in certain argument positions.
    There is no standard way of reading in an "expression" and
    "evaluating" it.  This file provides an experimental facility for
    doing something of the sort.

	active_read(Term)

    reads a term from the current input stream.  If this term has the
    form	X | Goal
    the Goal is called and Term is unified with X.  Otherwise, Term is
    unified with the term which was read.  Note that Goal may backtrack,
    in which case active_read/1 will backtrack.

    EXAMPLES:

	| ?- active_read(X).
	|: T | append([1,2],[3,4], T).
	X = [1,2,3,4]
	yes

	| ?- active_read(X).
	|: Front+Back | append(Front, Back, [1,2,3,4]).
	X = []+[1,2,3,4] ;
	X = [1]+[2,3,4] ;
	X = [1,2]+[3,4] ;
	X = [1,2,3]+[4] ;
	X = [1,2,3,4]+[] ;
	no

    NOTE:
	This is not a module.  If it were, we'd need a
	:- meta_predicate active_read(:).
	declaration so that we'd know which module to call the Goal
	in.  As it is, each module that loads this file will get its
	own copy of the predicate, which will automatically call the
	Goal in the appropriate module.  Since there is just the one
	clause, this isn't too much of a burden.
*/

:- public
	active_read/1.

%   active_read(Term)
%   reads a term from the current input stream.
%   If the input has the form Term | Goal, the goal is called.
%   Otherwise Term is unified with the input as it stands.
%   Most of library(activeread) is a comment explaining this.

active_read(Term) :-
	read(Form),
	(   nonvar(Form), Form = (Result | Goal) ->
	    call(Goal),
	    Term = Result
	;   Term = Form
	).

