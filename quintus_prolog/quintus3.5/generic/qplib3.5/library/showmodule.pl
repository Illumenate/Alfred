%   Package: show_module
%   Author : Dave Bowen
%   Updated: 30 Jun 1988
%   Purpose: show the imports and exports of a module

%   Copyright (C) 1987, Quintus Computer Systems, Inc.  All rights reserved.

:- module(show_module, [
	show_module/1
   ]).

sccs_id('"@(#)88/06/30 showmodule.pl	27.1"').


%   show_module(?Module)
%   writes import/export information for Module to current output in
%   the form of a :-module declaration and zero or more :-use_module
%   directives.  Other information is written out as %comments.  If
%   you call show_module(_),fail; all modules will be described.  We
%   have made the information come out in the same format as used in
%   the library itself.

show_module(Module) :-
	current_module(Module),
	format('~N%~`*t ~a ~`*t%~72|~n', [Module]),
	show_module_file(Module),
	show_module_exports(Module),
	show_module_imports(Module),
	format('~n%~`*t%~72|~n~n', []).


%   show_module_file(Module)
%   writes a comment saying which file(s) Module was loaded from, if known.

show_module_file(Module) :-
	current_module(Module, File),
	format('% loaded from file: ~a~n', [File]),
	fail
    ;	current_predicate(sccs_id, Module:sccs_id(SCCS_id)),
	Module:sccs_id(SCCS_id),
	format('% SCCS time stamp : ~a~n', [SCCS_id]),
	fail
    ;	true.


%   show_module_exports(Module)
%   writes out a :- module directive for module, listing all the predicates
%   it exports, if any.  Since it is very odd for a module not to export
%   anything, we write a %comment in that case.

show_module_exports(Module) :-
	bagof(Pred, exports(Module,Pred), Exports),
	!,
	output_directive(module, Module, Exports).
show_module_exports(Module) :-
	format(':- module(~q, []).  % no exports.~n', [Module]).


exports(Module, Name/Arity) :-
	predicate_property(Module:Goal, exported),
	functor(Goal, Name, Arity).


%   show_module_imports(Module)
%   writes out a :-use_module directive for each module used by Module.
%   Note how bagof enumerates Exporter modules, giving us the Imports list
%   for each Exporter in turn.

show_module_imports(Module) :-
	bagof(Pred, imports(Module,Pred,Exporter), Imports),
	output_directive(use_module, Exporter, Imports),
	fail ; true.

imports(Module, Name/Arity, Exporter) :-
	predicate_property(Module:Goal, imported_from(Exporter)),
	functor(Goal, Name, Arity).


%   output_directive is used to write :-module/2 and :-use_module/2
%   directives, which are similarly indented.  It is important that
%   we use ~q and writeq/1 here, so that the predicate names can be
%   read back later (and module names too).

output_directive(Directive, Module, Customs) :-
	format(':- ~q(~q, [~n', [Directive,Module]),
	output_directive(Customs).

output_directive([Last]) :- !,
	tab(8), writeq(Last), nl,
	write('   ]).'), nl.
output_directive([Head|Tail]) :-
	tab(8), writeq(Head), put(","), nl,
	output_directive(Tail).

