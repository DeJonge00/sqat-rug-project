module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
import analysis::statistics::Correlation;
import IO;

/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?
The highest complexity of a method we found is 8, according to the table in the SIG paper, this makes the 
program "simple, without much risk", a ++.
(The method is: public Direction nextMove() in Inky.java)
*/

set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true); 

alias CC = rel[loc method, int cc];

// returns the amount of branches in the mccabe model in the statement
int complexity(Statement s) {
	int c = 1;
	visit(s) {
		case x: \if(_,_): 
			c+=1;
		case \if(_,_,_): 
			c+=1;
		case \do(_,_): 
			c+=1;
		case \while(_,_): 
			c+=1;
		case \for(_,_,_): 
			c+=1;
		case \for(_,_,_,_): 
			c+=1;
		case foreach(_,_,_): 
			c+=1;
		case \case(_): 
			c+=1;
		case \catch(_,_): 
			c+=1;
		case \conditional(_,_,_): 
			c+=1;
		case infix(_,"&&",_): 
			c+=1;
		case infix(_,"||",_): 
			c+=1;
	}
	return c;
}

// returns the complexity of all methods in the declaration
CC declarationComplexity(Declaration f) {
	CC result = {};
    visit(f){
      case method: \method(_,_,_,_,code): result += <method@src, complexity(code)>;
    }
    return result;
}

CC cc(set[Declaration] decls) {
  CC result = {};
  for (Declaration d <- decls) {
		result += declarationComplexity(d);
	}  
  return result;
}

alias CCDist = map[int cc, int freq];

// returns a histogram of the compexities in the cc
CCDist ccDist(CC cc) {
	CCDist histogram = ();
	
	for(<l, c> <- cc) {
		if(c in histogram)
			histogram[c]+=1;
		else
			histogram[c]=1;	
	}
	return histogram;
}

// answers the above questions
void q() {
	int tc = 0;
	int max = 0;
	loc maxfile;
	CC c = cc(jpacmanASTs());
	for(<loc l, int n> <- c) {
		//print(l);
		//print(" has complexity: " );
		//println(n);
		if(n > max) {
			max = n;
			maxfile = l;
		}
		tc+=n;
	}
	print("Total complexity: ");
	println(tc);
	print("Method with highest complexity is in: ");
	println(maxfile);
	print("with complexity: ");
	println(max);
	
	// Histogram
	print("Histogram: ");
	println(ccDist(c));
}

// helperfunction for testing
int testfunc(loc l, str methodName) {
	visit(createAstFromFile(l, true)) {
		case method: \method(_,name,_,_,code): if(name == methodName) return 1 + complexity(code);
	}
	return -1;
}

// --- TESTING ---
// Test complexity()
loc testfile = |project://sqat-test-project/src/series1_numberOfLines/TestA2.java|;
test bool testDummy() = testfunc(testfile, "testDummy") == 1;
test bool testIf() = testfunc(testfile, "testIf") == 2;
test bool testElse() = testfunc(testfile, "testIfElse") == 2;
test bool testDo() = testfunc(testfile, "testDo") == 2;
test bool testWhile() = testfunc(testfile, "testWhile") == 2;
test bool testFor() = testfunc(testfile, "testFor") == 2;
test bool testForeach() = testfunc(testfile, "testForeach") == 2;
test bool testCase() = testfunc(testfile, "testCase") == 2;
test bool testCatch() = testfunc(testfile, "testCatch") == 2;
test bool testAnd() = testfunc(testfile, "testAnd") == 3;
test bool testOr() = testfunc(testfile, "testOr") == 3;
test bool testConditional() = testfunc(testfile, "testConditional") == 2;
test bool testNestedIf() = testfunc(testfile, "testNestedIf") == 3;
test bool testNestedElse() = testfunc(testfile, "testNestedElse") == 3;
