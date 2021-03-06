%   Module : read_constant
%   Author : Richard A. O'Keefe
%   Updated: 01 Nov 1988
%   Purpose: Pascal-style constant reading

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(read_constant, [
	prompted_constant/2,
	prompted_constants/2,
	read_constant/1,
	read_constant/2,
	read_constants/1,
	read_constants/2,
	skip_constant/0,
	skip_constant/1,
	skip_constants/1,
	skip_constants/2
   ]).
:- use_module(library(types), [
	proper_list/1,
	must_be_nonneg/3,
	must_be_proper_list/3
   ]),
   use_module(library(prompt), [
	prompt/1
   ]).

/*  The command	read_constant(X)
    acts much like read(X) would in Pascal.  That is, it skips
    layout in the current input stream, reads a "token", and
    unifies that with X.

    There are two kinds of tokens:
	-- quoted tokens start with ' or ".  They end with the same
	   character they start with.  To include a quotation mark
	   in such a token, write it twice.  A token which starts
	   with a single quote ' will be returned as a Prolog atom
	   (even when it looks like a number).  A token which starts
	   with a double quote " will be returned as a list of ASCII
	   codes.  These tokens are exactly like ordinary Prolog
	   tokens (except that the 'character_escapes' flag is NOT
	   currently supported).  By deliberate design, the
	   character following the closing quotation mark will be
	   discarded.  It will normally be comma, space, or new line.
	-- simple tokens start with any other character.  They end
	   just before the next layout character or comma.  The
	   comma or layout character which ends such a token will be
	   discarded.  Such a token will be returned as a Prolog
	   number if it looks like a number, otherwise as an atom.
	   We use number_chars/2 for this test; it will accept
	   ".5" as the number 0.5, whereas the built in predicate
	   name/2 will take it as the atom '.5'.

    Note this carefully: in both cases, we have leading layout which
    is skipped, the token proper, and a terminating character which
    is discarded.  If, for example, the input looks like
	"  fred, 1.2 ' ', last<END-OF-LINE>"
    where <END-OF-LINE> is the end of line character (LF on UNIX),
    and we call read_constants([A,B,C,D]), the bindings will be
    A=fred, B=1.2, C=' ', D=last, and the entire line will have
    been consumed.

    The command read_constants([X1,...,Xn]) reads N constants using
    read_constant/1 and unifies the results with X1...Xn.  Note
    carefully how this is done!  There is a design principle which
    you would do well to follow called "The Principle of Accomplished
    Effects" which says that the side-effects of a command should be
    accomplished completely or not at all.  In this case, the side
    effect is the reading of N constants.  This reading must be
    completed regardless of whether the subsequent unifications
    succeed or fail.

    skip_constant/0 reads a constant and discards it.  We needn't
    bother with it; we could just call read_constant(_).  But this
    way we avoid the cost of constructing the list of characters
    and perhaps interning an atom.

    skip_constants(N) reads and discards N constants.

    It is perfectly possible to have an empty token in the input.
    There are two ways of doing this: "''" is an empty quoted
    token, and "," is an empty simple token.  Empty tokens are
    returned as the Prolog atom '' whose name contains no characters.

    More from a sense of fun than because it is especially important,
    I've decided to handle %-end-of-line comments, just like the
    normal comments in Prolog.  A % sign will terminate a simple
    token, just as the end-of-line proper would.  Any layout character
    other than space or tab will be taken as the end of a line.

    Reading the first 500 words from a dictionary on a Sun-3/50:
	read(X)		  took 4.6 milliseconds
	read_constant(X)  took 5.6 milliseconds
    The reason for this is that most of the token scanning in read/1
    is done by C code, unlike read_constant/1.  We could recode most
    of this file in C, but (modulo the end of file character and the
    module header) this code would work in C Prolog or Dec-10 Prolog.

    For each of the four basic predicates, there is another version
    with an additional first argument: the stream to read from.  As
    a general rule this is not a good idea, and if library(fromonto)
    were built into the language we should scrap stream arguments at
    once.  For now they are here to make library(prompt)'s task easy.
    These routines rely on the fact that the real routines they call
    will either succeed determinately or cause an error.

    Note that read_constant(_) and skip_constant, when they hit the
    end of the current stream, call themselves recursively.  Mostly,
    this means that they will try to read another character from
    the current stream, which will provoke an error report.  But if
    input is coming from user_input and that is a terminal, they'll
    effectively ignore the end of file signal.  This is not a hack
    for this file; that's just what happens with end of file from a
    tty user_input.  You will probably find occasion to be thankful
    for this, if you ever use this file at all.

    The prompted_constant(Prompt, Result)
    and prompted_constants(Prompt, [Result1,...,Resultn])
    commands are a cross between [read_constant,read_constants]/2
    and the commands in library(ask).  They write a prompt (note
    that the Prompt you supply is ALL that is written), read one
    or more constants, and then discard anything which remains on
    that line.  So the following might happen:
	| ?- prompted_constant('Guess the magic number: ', X),
	|    is_magic(X).
	Guess the magic number: 27 is my guess
				   ^^^^^^^^^^^^^^^ user type-in
	[Warning: The procedure is_magic/1 is undefined]
	   (1) 0 Call: is_magic(27) ? 
    where the debugger is NOT going to see "is my guess", because
    prompted_constant/2 will have eaten it.  If you want to ask the
    user a question whose answer is a single constant of known type,
    library(ask) may have what you want.  Otherwise, one of these
    two routines may be more appropriate.  When reading from the
    terminal, it is important to read entire lines, otherwise the
    debugger may be confused, and the system prompts *will* be.
*/

:- mode
	prompted_constant(+, ?),
	prompted_constants(+, +),
	read_constants(+, +),
	read_constants(+),
	    'read constants'(+, -, +, -),
	read_constant(+, ?),
	read_constant(?),
	    'read constant'(-, -),
	    read_simple(+, -, -),
	    read_quoted(+, +, -, -),
	skip_constants(+, +),
	skip_constants(+),
	    'skip constants'(+),
	skip_constant(+),
	skip_constant,
	skip_rest_of_line(-),
	'maybe skip rest of line'(+).

sccs_id('"@(#)88/11/01 readconst.pl	27.2"').



%   prompted_constant(+Prompt, ?Datum)
%   writes a prompt to the terminal and reads one constant in response.
%   The remainder of the input line is discarded.

prompted_constant(Prompt, Datum) :-
	prompt(Prompt),
	current_input(Old), set_input(user_input),
	  'read constant'(X, Last),
	  'maybe skip rest of line'(Last),
	set_input(Old),
	Datum = X.


%   prompted_constants(+Prompt, +Data)
%   writes a prompt to the terminal and reads as many constants in
%   response as Data has elements.  (Data is plural, Datum singular...)
%   The remainder of the input line is discarded.

prompted_constants(Prompt, Data) :-
	proper_list(Data),
	!,
	prompt(Prompt),
	current_input(Old), set_input(user_input),
	  'read constants'(Data, X, 1, Last),
	  'maybe skip rest of line'(Last),
	set_input(Old),
	Data = X.
prompted_constants(Prompt, Data) :-
	must_be_proper_list(Data, 2, prompted_constants(Prompt,Data)).



%   read_constants([X1,...,Xn])
%   reads N constants from the current input stream and then unifies
%   the results with X1,...,Xn.  The argument may be the empty list,
%   in which case nothing at all is done.

read_constants(Results) :-
	proper_list(Results),
	!,
	'read constants'(Results, Data, 1, _),
	Results = Data.
read_constants(Results) :-
	must_be_proper_list(Results, 1, read_constants(Results)).


%   read_constants(+Stream, [X1,...,Xn])
%   reads N constants from the given input Stream and then unifies
%   the results with X1,...,Xn.  The argument may be the empty list,
%   in which case nothing at all is done.

read_constants(Stream, Results) :-
	proper_list(Results),
	!,
	current_input(Old), see(Stream),
	  'read constants'(Results, Data, 1, _),
	set_input(Old),
	Results = Data.
read_constants(Stream, Results) :-
	must_be_proper_list(Results, 2, read_constants(Stream,Results)).


'read constants'([], [], Last, Last).
'read constants'([_|Results], [Datum|Data], _, Last) :-
	'read constant'(Datum, Char),
	'read constants'(Results, Data, Char, Last).



%   read_constant(?Datum)
%   reads a single "token" from the current input stream.

read_constant(Datum) :-
	'read constant'(X, _),
	Datum = X.


%   read_constant(+Stream, ?Datum)
%   reads a single "token" from the given input Stream.

read_constant(Stream, Datum) :-
	current_input(Old), see(Stream),
	  'read constant'(X, _),
	set_input(Old),
	Datum = X.


'read constant'(Datum, Last) :-
	get(Char),			% skip leading layout
	(   Char < 0 ->			% end of file
	    'read constant'(Datum, Last)% will produce error report	
	;   Char =:= "%" ->		% end-of-line comment
	    skip_rest_of_line(_),
	    'read constant'(Datum, Last)
	;   Char =:= "'" ->		% quoted atom
	    get0(Next),
	    read_quoted(Char, Next, Chars, Last),
	    atom_chars(Datum, Chars)	% NOT name/2!
	;   Char =:= """" ->		% quoted list of chars
	    get0(Next),
	    read_quoted(Char, Next, Datum, Last)
	;   read_simple(Char, Chars, Last),
	    (   number_chars(Number, Chars) -> Datum = Number
	    ;   atom_chars(Datum, Chars)
	    )
	).


%.  read_simple(+Char, -Chars, -Last)
%   reads the rest of an unquoted token, where the next character to
%   be processed, Char, has already been read.  The characters to be
%   included in the token are returned as Chars.  Last is unified
%   with the next character immediately after the token.

read_simple(Char, Chars, Last) :-
	(   Char =:= "," ->		% comma
	    Last = Char, Chars = ""
	;   Char =:= "%" ->		% end-of-line comment
	    Chars = "",			% the comment is skipped and
	    skip_rest_of_line(Last)	% acts as end of line.
	;   Char =< " " ->		% SPACE, or ASCII control
	    Last = Char, Chars = ""	% character (8859/1 lower half)
	;   Char >= 127, Char =< 160 ->	% DEL, or ISO 8859/1 upper half
	    Last = Char, Chars = ""	% control character
	;				% ordinary character
	    Chars = [Char|Chars1],	% Char is included as part of token
	    get0(Next),
	    read_simple(Next, Chars1, Last)
	).


%.  read_quoted(+Quote, +Char, -Chars, -Last)
%   reads the rest of a quoted token, where the next character to be
%   processed, Char, has already been read.  The quote character is
%   Quote (either 0'" or 0'').  The characters to be included in the
%   token are returned as Chars.  Last is unified with the next
%   character immediately after the token.

read_quoted(Quote, Quote, Chars, Last) :- !,
	get0(Char),
	(   Char =:= Quote ->		% doubled quote => include one
	    Chars = [Char|Chars1],
	    get0(Next),
	    read_quoted(Quote, Next, Chars1, Last)
	;   Char =:= "%" ->		% end-of-line comment
	    Chars = "",			% the comment is skipped and
	    skip_rest_of_line(Last)	% acts as end of list
	;   Chars = "", Last = Char	% This was the closing quote.
	).
read_quoted(Quote, Char, [Char|Chars], Last) :-
	get0(Next),
	read_quoted(Quote, Next, Chars, Last).



%   skip_constants(N)
%   reads and discards N constants from the current input stream.

skip_constants(N) :-
	integer(N), N >= 0,
	!,
	'skip constants'(N).
skip_constants(N) :-
	must_be_nonneg(N, 1, skip_constants(N)).


%   skip_constants(Stream, N)
%   reads and discards N constants from the given input Stream.

skip_constants(Stream, N) :-
	integer(N), N >= 0,
	!,
	current_input(Old), see(Stream),
	  'skip constants'(N),
	set_input(Old).
skip_constants(Stream, N) :-
	must_be_nonneg(N, 2, skip_constants(Stream,N)).


'skip constants'(0) :- !.
'skip constants'(N) :-
	N > 0, M is N-1,
	skip_constant,
	'skip constants'(M).



%   skip_constant(+Stream)
%   reads and discards one constant from the given input Stream.

skip_constant(Stream) :-
	current_input(Old), see(Stream),
	  skip_constant,
	set_input(Old).

%   To skip a constant, skip_constant/0 calls one of the basic routines
%   that 'read constant'/2 calls.  These routines return a list of
%   character codes _Chars constituting the constant and the character
%   _Last which terminated the constant.  The (stuff, fail ; true)
%   pattern throws this information away; instant GC as it were.

%   skip_constant
%   reads and discards one constant from the current input stream.

skip_constant :-
	get(Char),				% skip leading layout
	(   Char < 0 ->				% end of file
	    skip_constant			% will produce error report
	;   Char =:= "%" ->			% end-of-line comment
	    skip_rest_of_line(_),
	    skip_constant
	;   (   Char =:= "'" ->			% quoted atom
		get0(Next),
		read_quoted(Char, Next, _Chars, _Last)
	    ;   Char =:= """" ->		% quoted list of chars
		get0(Next),
		read_quoted(Char, Next, _Chars, _Last)
	    ;   read_simple(Char, _Chars, _Last)
	    ),
	    fail				% discard the list
	;   true
	).


%.  skip_rest_of_line(EndOfLine)
%   is called after we have read the "%" character which starts
%   an end-of-line comment.  It skips all the characters up to
%   the end of the line.  Some operating systems use LF for end
%   of line, some use CR, some use either, and some use CRLF.
%   This routine takes any layout character other than a space
%   or tab to be the end of the line.  In particular, CR, LF,
%   and FF will all work, and so will ^Z or -1.

skip_rest_of_line(Char) :-
	repeat,
	    get0(Char),
	    Char < " ",
	    Char =\= 9 /* ^I */,
	!.

%   'maybe skip rest of line'(C)
%   is called by prompted_constant{,s}/2 to discard the rest of the
%   current input line.  (What we really want is a "what was the
%   last character read?" operation.  Someday.)

'maybe skip rest of line'(Last) :-
	(   Last < " ", Last =\= 9 /* ^I */ -> true
	;   repeat,
		get0(Char),
		Char < " ",
		Char =\= 9 /* ^I */,
	    !
	).

