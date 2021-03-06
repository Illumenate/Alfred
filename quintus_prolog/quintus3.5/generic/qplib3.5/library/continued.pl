%   Module : continued
%   Author : Richard A. O'Keefe.
%   Updated: 25 Oct 1990
%   Purpose: read continued lines.

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

/*  This is a supplement to the library(lineio) package, for
    reading logical lines which may span more than one physical
    line.  Two conventions are supported.

    read_unix_continued_line(Line)

	uses the UNIX convention (understood by sh, csh, cc, and
	several other programs) that a line terminated by a
	<back-slash,new-line> pair is continued, and the back-
	slash and new-line do not appear in the combined line.
	E.g.
		ab\
		cde\
		f
	is read as "abcdef".

    read_oper_continued_line(Line)

	uses a convention rather like that of BCPL: a line which
	ends with <op,new-line> where op is some sort of left
	bracket or binary infix character (+*-/#=<>^|&:,) is taken
	to be continued, and the op character IS included in the
	combined line but the new-line is NOT.  E.g.

		command /option1=value1,
			/option2=value2

	is read as "command /option1=value1,	/option2=value2".
	This is almost certainly not what you want, which is why
	we give you source code: you should be able to get to a
	reasonable approximation of what you want starting from
	one of these routines.
*/
:- module(continued, [
	read_oper_continued_line/1,
	read_unix_continued_line/1
   ]).
:- use_module(library(lineio), [
	get_line/1
   ]).

sccs_id('"@(#)90/10/25 continued.pl	58.1"').



%   read_oper_continued_line(?Line)
%   reads one or more lines from the current input (omitting newlines)
%   up to a line which doesn't end with an operator or left bracket.

read_oper_continued_line(Line) :-
	get_line(Chars),
	(   append(_, [Char], Chars),
	    oper_char(Char)
	->  append(Chars, Rest, Line),
	    read_oper_continued_line(Rest)
	;   Line = Chars
	).


%   read_unix_continued_line(?Line)
%   reads one or more lines from the current input up to a line which
%   doesn't end with "\".  The "\"s and newlines are omitted.

read_unix_continued_line(Line) :-
	get_line(Chars),
	(   append(Front, "\", Chars)
	->  append(Front, Rest, Line),
	    read_unix_continued_line(Rest)
	;   Line = Chars
	).


oper_char(0'().		% left (round) parenthesis
oper_char(0'[).		% left [square] bracket
oper_char(0'{).		% left {curly} brace
oper_char(0'+).		% plus sign
oper_char(0'*).		% asterisk
oper_char(0'-).		% minus sign
oper_char(0'/).		% solidus (VMS /option)
oper_char(0'#).		% octothorp or sharp (has been used for "or")
oper_char(0'=).		% equal sign
oper_char(0'<).		% less than sign
oper_char(0'>).		% greater than sign
oper_char(0'^).		% circumflex (exponentiation; C's XOR)
oper_char(0'|).		% "or"
oper_char(0'&).		% ampersand (and-per-se-and)
oper_char(0':).		% colon
oper_char(0',).		% comma.


