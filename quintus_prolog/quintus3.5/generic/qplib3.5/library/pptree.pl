%   Package: pp_tree
%   Authors: Edward P. Stabler, Jr, & Richard A. O'Keefe
%   Updated: 21 Apr 1987
%   Defines: pretty-printers for (parse) trees represented in the form
%	     <tree> --> <node label>/[<son>,...<son>]
%		     |  <leaf label>		-- anything else

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This module provides two ways of displaying (parse) trees given it
    in a particular format.  First, a note on the tree notation:

    We want a notation which distinguishes the dominance relation
    from the sibling relation.  This rules out the Lispish notation:
	  [category,child1,child2,child3]
    And we want a notation that allows complex categories, i.e. complex
    node labels like "noun(plural)".  Almost every main-stream
    linguistic theory uses complex categories.  This rules out the most
    common Prologish notation:
	  category(child1,child2,child3)
    So we have chosen
	  category/[child1,child2,child3]
    For example,
	  noun_phrase(plural)/[determiner/[the],noun(plural)/[men]]

    Note by R.A.O'K: a well-chosen Prolog notation would use an
    explicit constructor function for the leaf case as well as for the
    non-leaf case.  E.g. we might use nt(Label,Sons) | t(Leaf) to
    discriminate between NonTerminals and Terminals.  Since Quintus
    Prolog indexes both compiled and interpreted code on the first
    argument, this would dispense with the lamentable cuts below.  As
    it is, since a tree is defined to be "_/_" or "anything else" we
    need cuts in the clauses that match the "_/_" cases to ensure that
    they don't fall through into the "anything else" cases.  As a
    general rule, AVOID this kind of mess by using explicit constructur
    functions; this module was written to suit an existing program and
    cleanliness and efficiency here were not felt to be a sufficient
    reward for the cost of changing the existing code.

    There are two forms of output.  The first was designed by E.P.S,
    and is intended for human consumption.  Empty productions are 
    suppressed, and the minimum of information is displayed.  The
    command
		pp_tree(Tree)
    writes a (parse) tree out this way.  An example would be
    pp_tree(a/[b/[x],d/[y]]) =>
		a
		    b  x
		    d  y

    The second form of output was designed by R.A.O'K.  The idea is to
    use the same indentation, but to include all the punctuation marks
    and so forth so that the result can be read back as a Prolog term
    by the Prolog reader.  This has at the very least the benefit that
    you can easily move around the tree with a decent text editor.
    An example of this form of output would be
		a /[
		    b /[ x ],
		    d /[ y ]].
    The test/0 predicate below (commented out) is a larger example.

    Note that we use numbervars/3 and fail back over it.  This is to
    exploit a rather neat hack which has been present since Dec-10
    Prolog days, namely that the terms numbervars/3 binds variables
    to print out as alphabetic variables.  Thus the variables in the
    tree will be written as A, B, C, ..., Z, A1, B1, ... .  We fail
    back over numbervars/3 so that these bindings are undone.  This
    is a standard output hack in Edinburgh Prolog.

    We use format('~N', []) to ensure that output starts at the
    beginning of a line.  (This is the command 'sl' in C Prolog.)
    Thereafter we use 'nl' to end lines.  This again is standard
    practice in Prolog: assume or ensure that you are at the start
    of a line, and then keep using nl to *TERMINATE* lines.

    A third command was added for the 2.0 release.  This command
    assumes the style of parse tree, and generates the style of output,
    used in a forthcoming book by Pereira & Shieber.  Hence the name
    ps_tree/1.
*/

:- module(pp_tree, [
	pp_tree/1,
	pp_term/1,
	ps_tree/1
   ]).

:- mode
	pp_tree(+),
	    pp_tree(+, +),
		pp_trees(+, +),
	pp_term(+),
	    pp_term(+, +),
		pp_terms(+, +),
		    pp_rest_terms(+, +),
	ps_tree(+),	
	    ps_tree(+, +),
		ps_tree(+, +, +, +, +).

sccs_id('"@(#)87/04/21 pptree.pl	9.1"').


pp_tree(Tree) :-
	format('~N', []),		% ensure we're at the start of a line
	numbervars(Tree, 0, _),		% make the trace variables come out as
	pp_tree(Tree, 0),		% letters, for easier reading.
	fail				% undo the numbervars/3 bindings
    ;	true.				% succeed.


pp_tree(_/[], _) :- !.			% do not show empty productions
pp_tree(Cat/[Word], Column) :-		% catch lexical productions on 1 line
	atom(Word),
	!,
	tab(Column), write(Cat), tab(2), write(Word), nl.
pp_tree(Cat/Children, Column) :- !,	% write Cat, return and pp children
	tab(Column), write(Cat), nl,
	NextColumn is Column+4,
	pp_trees(Children, NextColumn).
pp_tree(Leaf, Column) :-
	tab(Column), write(Leaf), nl.


pp_trees([], _).			% write a list of trees all
pp_trees([Tree|Trees], Column) :-	% starting in the same column.
	pp_tree(Tree, Column),
	pp_trees(Trees, Column).



pp_term(Term) :-
	format('~N', []),		% ensure we're at the start of a line
	numbervars(Term, 0, _),		% make the trace variables come out as
	pp_term(Term, 0),		% letters, for easier reading.
	fail				% undo the numbervars/3 bindings
    ;	put("."), nl.			% finish off for read/1.


pp_term(Cat/Children, Column) :- !,
	tab(Column), writeq(Cat), write(' /['),
	pp_terms(Children, Column).
pp_term(Leaf, Column) :-
	tab(Column), writeq(Leaf).

pp_terms([], _) :-
	put("]").
pp_terms([Word], _) :-
	atom(Word),
	!,
	put(" "), writeq(Word), write(' ]').
pp_terms([Tree|Trees], Column) :-
	NextColumn is Column+4,
	nl, pp_term(Tree, NextColumn),
	pp_rest_terms(Trees, NextColumn).

pp_rest_terms([], _) :-
	put("]").
pp_rest_terms([Tree|Trees], Column) :-
	put(","),
	nl, pp_term(Tree, Column),
	pp_rest_terms(Trees, Column).



ps_tree(Term) :-
	format('~N', []),		% ensure we're at the start of a line
	current_output(Stream),		% for line_position/2
	numbervars(Term, 0, _),		% make the trace variables come out as
	ps_tree(Term, Stream),		% letters, for easier reading.
	fail				% undo the numbervars/3 bindings
    ;	put("."), nl.			% finish off.

ps_tree(Term, Stream) :-
	functor(Term, Symbol, Arity),
	Arity > 0,			% has arguments
	arg(1, Term, Arg),
	( atomic(Arg) -> Arity > 1 ; true ),
	!,
	writeq(Symbol), put("("),
	line_position(Stream, Indent),	% all args will start here
	ps_tree(Arg, Stream),
	ps_tree(1, Arity, Term, Indent, Stream).
ps_tree(Term, _) :-
	writeq(Term).


ps_tree(N, N, _, _, _) :- !,
	put(")").
ps_tree(I, N, Term, Indent, Stream) :-
	J is I+1,
	arg(J, Term, Arg),
	put(","), nl, tab(Indent),
	ps_tree(Arg, Stream),
	ps_tree(J, N, Term, Indent, Stream).



/*				        % test code.
					% The examples should be printed
					% out as they appear here.
test :- 
	Tree =
	s/[
	    np/[
		det/[a],
		n(singular)/[man],
		sbar/[
		    comp/[
			np(A)/[
			    n(singular)/[who]]],
		    s/[
			np/[
			    det/[a],
			    n(singular)/[woman],
			    sbar([])/[]],
			vp/[
			    v(singular)/[like],
			    np/[
				np_trace(A)]],
			adjunct/[]]]],
	    vp/[
		v(singular)/[read],
		np/[
		    det/[a],
		    n(singular)/[book],
		    sbar([])/[]]],
	    adjunct/[]],
	pp_tree(Tree), write(------), nl,
	pp_term(Tree), write(------), nl,
	Tree =
	s(np(det({a}),
	     n(singular,
	       {man}),
	     sbar(comp(np(A,
			  n(singular,
			    {who}))),
		  s(np(det({a}),
		       n(singular,
			 {woman}),
		       sbar([])),
		    vp(v(singular,
			 {like}),
		       np(np_trace(A))),
		    adjunct([])))),
	  vp(v(singular,
	       {read}),
	     np(det({a}),
		n(singular,
		  {book}),
		sbar([]))),
	  adjunct([])),
	ps_tree(Tree), write(------), nl, nl.
*/
