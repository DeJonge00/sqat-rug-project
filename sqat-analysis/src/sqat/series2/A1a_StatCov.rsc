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
M3 covTestM3() = createM3FromEclipseProject(|project://sqat-test-statCov|);

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

/* Returns a set of the names of methods for testing purposes */
set[loc] methodNameList(set[method] methods) {
	set[loc] names = {};
	for(method m <- methods) {
		names += m.name;
	}
	return names;
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


/************************* TEST METHODS **********************************/

/* */
test bool testGetMethods()
	= methodNameList(getMethods(covTestM3())) == {
	  |java+method:///main/MethodsToBeTested/method1()|,
	  |java+method:///main/MethodsToBeTested/method2()|,
	  |java+method:///main/MethodsToBeTested/method3()|,
	  |java+method:///main/MethodsToBeTested/method4()|,
	  |java+method:///test/TestMethods/test1()|,
	  |java+method:///test/TestMethods/test2()|,
	  |java+method:///test/TestMethods/test3()|,
	  |java+method:///main/MethodsToBeTested/main()|
	};
	
/* */
test bool testGetTestMethods()
	= methodNameList(getTestMethods(covTestM3())) == {
	  |java+method:///test/TestMethods/test1()|,
	  |java+method:///test/TestMethods/test2()|,
	  |java+method:///test/TestMethods/test3()|
	};
	
/* */
test bool testGetTestableMethods()
	= methodNameList(getTestableMethods(covTestM3())) == {
	  |java+method:///main/MethodsToBeTested/method1()|,
	  |java+method:///main/MethodsToBeTested/method2()|,
	  |java+method:///main/MethodsToBeTested/method3()|,
	  |java+method:///main/MethodsToBeTested/method4()|,
	  |java+method:///main/MethodsToBeTested/main()|
	};
