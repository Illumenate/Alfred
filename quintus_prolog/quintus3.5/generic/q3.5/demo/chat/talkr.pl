/* @(#)talkr.pl	28.1 06/07/89 */

/* 
	Copyright 1986, Fernando C.N. Pereira and David H.D. Warren,

			   All Rights Reserved
*/
/* Simplifying and executing the logical form of a NL query. */

:-public write_tree/1, answer/1, satisfy/1.

:-mode write_tree(+).
:-mode wt(+,+).
:-mode header(+).
:-mode decomp(+,-,-).
:-mode complex(+).
:-mode othervars(+,-,-).

write_tree(T):-
   numbervars(T,0,_),
   wt(T,0),
   fail.
write_tree(_).

wt((P:-Q),L) :- !, L1 is L+3,
   write(P), tab(1), write((:-)), nl,
   tab(L1), wt(Q,L1).
wt((P,Q),L) :- !, L1 is L-2,
   wt(P,L), nl,
   tab(L1), put("&"), tab(1), wt(Q,L).
wt({P},L) :- complex(P), !, L1 is L+2,
   put("{"), tab(1), wt(P,L1), tab(1), put("}").
wt(E,L) :- decomp(E,H,P), !, L1 is L+2,
   header(H), nl,
   tab(L1), wt(P,L1).
wt(E,_) :- write(E).

header([]).
header([X|H]) :- write(X), tab(1), header(H).

decomp(setof(X,P,S),[S,=,setof,X],P).  
decomp(\+(P),[\+],P) :- complex(P).
decomp(numberof(X,P,N),[N,=,numberof,X],P).
decomp(X^P,[exists,X|XX],P1) :- othervars(P,XX,P1).

othervars(X^P,[X|XX],P1) :- !, othervars(P,XX,P1).
othervars(P,[],P).

complex((_,_)).
complex({_}).
complex(setof(_,_,_)).
complex(numberof(_,_,_)).
complex(_^_).
complex(\+P) :- complex(P).

% Query execution.

:-mode respond(?).
:-mode holds(+,?).
:-mode answer(+).
:-mode yesno(+).         :-mode replies(+).
:-mode reply(+).
:-mode seto(?,+,-).
:-mode satisfy(+).
:-mode pickargs(+,+,+).
:-mode pick(+,?).

respond([]) :- write('Nothing satisfies your question.'), nl.
respond([[A|L]]) :- !, respond([A|L]).
respond([A|L]) :- reply(A), replies(L).

answer((answer([]):-E)) :- !, holds(E,B), yesno(B).
answer((answer([X]):-E)) :- !, seto(X,E,S), respond(S).
answer((answer(X):-E)) :- seto(X,E,S), respond(S).

seto(X,E,S) :- setof(X,satisfy(E),S), !.
seto(X,E,[]).

holds(E,true) :- satisfy(E), !.
holds(E,false).

yesno(true) :- write('Yes.').
yesno(false) :- write('No.').

replies([]) :- 
	write('.').
replies([A]) :- !, 
	write(' '),
	maybe_nl, 
	write('and '), 
	maybe_nl, 
	reply(A), 
	write('.').
replies([A|X]) :- 
	write(', '),
	maybe_nl, 
	reply(A), 
	replies(X).

maybe_nl :- 
	current_output(S),
	line_position(S, P),
	(   P >= 65 -> nl 
	;   true
	).

reply(N--U) :- !, write(N), write(' '), write(U).
reply([A,B]) :- !, write('['), write(A), write(','), maybe_nl,
		   write(B), write(']').
reply(X) :- write(X).

satisfy((P,Q)) :- !, satisfy(P), satisfy(Q).
satisfy({P}) :- !, satisfy(P), !.
satisfy(X^P) :- !, satisfy(P).
satisfy(\+P) :- satisfy(P), !, fail.
satisfy(\+P) :- !.
satisfy(numberof(X,P,N)) :- !, setof(X,satisfy(P),S), length(S,N).
satisfy(setof(X,P,S)) :- !, setof(X,satisfy(P),S).
satisfy(+P) :- exceptionto(P), !, fail.
satisfy(+P) :- !.
satisfy(X<Y) :- !, X<Y.
satisfy(X=<Y) :- !, X=<Y.
satisfy(X>=Y) :- !, X>=Y.
satisfy(X>Y) :- !, X>Y.
satisfy(P) :- database(P).

exceptionto(P) :-
   functor(P,F,N), functor(P1,F,N),
   pickargs(N,P,P1),
   exception(P1).

exception(P) :- database(P), !, fail.
exception(P).

pickargs(0,_,_) :- !.
pickargs(N,P,P1) :- N1 is N-1,
   arg(N,P,S),
   pick(S,X),
   arg(N,P1,X),
   pickargs(N1,P,P1).

pick([X|S],X).
pick([_|S],X) :- !, pick(S,X).
pick([],_) :- !, fail.
pick(X,X).

