%   Module : prompt
%   Author : Richard A. O'Keefe
%   Updated: 29 Aug 1989
%   Purpose: Prompted input from the terminal.

%   Adapted from shared code written by the same author; all changes
%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(prompt, [
	prompt/1,
	prompted_char/2,
	prompted_line/2,
	prompted_line/3
   ]).
:- use_module(library(ctypes), [
	is_endline/1
   ]),
   use_module(library(lineio), [
	fget_line/2,
	fget_line/3
   ]).

:- mode
	prompt(+),
	prompt_(+),
	prompted_char(+, -),
	prompted_line(+, ?),
	prompted_line(+, ?, ?).

sccs_id('"@(#)89/08/29 prompt.pl    33.1"').



%   prompt(+ListOrPrompt)
%   writes a Prompt (or a List of terms making up a Prompt) to the
%   terminal, starting at the beginning of a new line, and forcing the
%   output out without adding a newline.  It is used for writing
%   prompts.  Note that a list of character codes will NOT be printed
%   as if it were a string.  This may be reconsidered.

prompt(ListOrPrompt) :-
	current_output(OldTell), set_output(user_output),
	  format('~N', []),	% start at the beginning of a line
	  prompt_(ListOrPrompt),
	  ttyflush,
	set_output(OldTell).


prompt_([]) :- !.
prompt_([Head|Tail]) :- !,
	prompt_(Head),
	prompt_(Tail).
prompt_({Ch}) :-
	integer(Ch), Ch >= 0, Ch =< 255, !,
	put(Ch).
prompt_(Other) :-
	write(Other).		% must be write, not writeq




%   prompted_char(+Prompt, -Char)
%   writes a prompt to the terminal and reads a line of characters from the
%   terminal.  Only the first of the characters is returned.  The reason for
%   using this rather than prompted_line is to avoid creating the list of
%   character codes, as C Prolog lacks a garbage collector.

prompted_char(Prompt, Char) :-
	prompt(Prompt),			% write the prompt to the terminal
	ttyget0(C1),			% read the first character
	(   is_endline(C1)		% either it was an end of line
	;   repeat,			% or else we have to skip the
		ttyget0(C2),		% rest of the terminal line
		is_endline(C2)		
	),  !,				% we have to consume the end of line
	Char = C1.			% before doing this unfication.



%   prompted_line(+Prompt, -Chars)
%   writes a prompt to the terminal and reads a line of characters from the
%   terminal.  It fails if the user ended the line with the EOF character.
%   This might move into ask.pl eventually.

prompted_line(Prompt, Chars) :-
	prompt(Prompt),
	fget_line(user, Chars).



%   prompted_line(+Prompt, -Chars, -Terminator)
%   writes a prompt to the terminal and reads a line of characters from
%   the terminal, as get_line/2 would.  It returns the terminating char.

prompted_line(Prompt, Chars, Terminator) :-
	prompt(Prompt),
	fget_line(user, Chars, Terminator).



