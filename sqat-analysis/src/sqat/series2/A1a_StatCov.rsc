module sqat::series2::A1a_StatCov

import lang::java::jdt::m3::Core;
import IO;
import List;
import Tuple;
import Set;
import String;
import util::Math;

/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3@declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3@types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3@uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3@containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3@messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3@names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3@documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3@modifiers;     // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3@extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3@implements;         // classes implementing interfaces
rel[loc from, loc to] M3@methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3@fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3@typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3@methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3@annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)


*/


M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework|);
M3 covTestM3() = createM3FromEclipseProject(|project://sqat-test-project/statCov|);

alias method = tuple[loc name, loc src];
alias graph = rel[method nodeFrom, method nodeTo];

/* Returns all methods in the model */
set[method] getMethods(M3 model){
	return toSet([m | method m <- model@declarations, isMethod(m.name)]);
}

/* Returns all methods that are tests */
set[method] getTestMethods(M3 model) {
	return toSet([m | method m <- model@declarations, contains(m.src.path, "/test/"), isMethod(m.name)]);
}

set[method] getTestableMethods(M3 model) {
	return getMethods(model) - getTestMethods(model);
}

/* Returns the set of all methods that are called by method m */
set[method] getFunctionCalls(M3 model, method m){
	set[method] methods = getMethods(model);
	set[loc] names = model@methodInvocation[m.name];
	return toSet([<name, getOneFrom(methods[name])> | name <- names, !isEmpty(methods[name])]);	
}

/* Makes a graph, where and edge from node A to node B represents the fact that method A calls method B */
graph createGraph(M3 model) {
	set[method] methods = getMethods(model);
	return toSet([<m, c> | method m <- methods, c <- getFunctionCalls(model, m)]);
}

/* Returns the transitive closure of a graph */
graph closure(g) {
	return g+;
}

/* Finds all methods in a graph that are accessible */
set[method] getTestedMethods(M3 model, graph g) {
	g = closure(g);
	set[method] tests = getTestMethods(model);
	set[method] testables = getTestableMethods(model);
	return toSet([t2 | t1 <- tests, t2 <- testables, <t1, t2> in g]);
}

/* Prints all relations in a graph for testing purposes */
void printGraph(g) {
	for(tuple[method nodeFrom,method nodeTo] t <- g) {
		println("<t.nodeFrom.name> - <t.nodeTo.name>");
	}
}

/* Prints all method names in a list of methods for testing purposes */
void printMethodList(set[method] methods) {
	for(method m <- methods) {
		println(m.name);
	}
}

/* Calculates the percentage of methods that is covered by tests */
void getTestCoverage(M3 model) {
	graph g = createGraph(model);
	
	set[method] testableMethods = getTestableMethods(model);
	set[method] testMethods = getTestMethods(model);
	set[method] testedMethods = getTestedMethods(model, g);
	int coverage = 100 * size(testedMethods) / size(testableMethods);
	
	println("There are <size(testMethods)> test methods.");
	println("There are <size(testableMethods)> normal methods, of which <size(testedMethods)> are covered by tests.");
	println("That means the test coverage is <coverage>%");
}

