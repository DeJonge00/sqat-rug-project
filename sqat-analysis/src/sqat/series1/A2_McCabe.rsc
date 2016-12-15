module sqat::series1::A2_McCabe

import lang::java::jdt::m3::AST;
import IO;

/*

Construct a distribution of method cylcomatic complexity. 
(that is: a map[int, int] where the key is the McCabe complexity, and the value the frequency it occurs)


Questions:
- which method has the highest complexity (use the @src annotation to get a method's location)

- how does pacman fare w.r.t. the SIG maintainability McCabe thresholds?

- is code size correlated with McCabe in this case (use functions in analysis::statistics::Correlation to find out)? 
  (Background: Davy Landman, Alexander Serebrenik, Eric Bouwers and Jurgen J. Vinju. Empirical analysis 
  of the relationship between CC and SLOC in a large corpus of Java methods 
  and C functions Journal of Software: Evolution and Process. 2016. 
  http://homepages.cwi.nl/~jurgenv/papers/JSEP-2015.pdf)
  
- what if you separate out the test sources?

Tips: 
- the AST data type can be found in module lang::java::m3::AST
- use visit to quickly find methods in Declaration ASTs
- compute McCabe by matching on AST nodes

Sanity checks
- write tests to check your implementation of McCabe

Bonus
- write visualization using vis::Figure and vis::Render to render a histogram.

*/

int complexity(Statement s) {
	int c = 0;
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

set[Declaration] jpacmanASTs() = createAstsFromEclipseProject(|project://jpacman-framework|, true); 

alias CC = rel[loc method, int cc];

CC cc(set[Declaration] decls) {
  CC result = {};
  int c;
  for(Declaration d <- decls){
  	c = 0;
    visit(d){
      case method: \method(_,name,_,_,code): c+=complexity(code);
    }
    result += <d@src, c>;
  }
  return result;
}

alias CCDist = map[int cc, int freq];

CCDist ccDist(CC cc) {

}

void q1() {
	int tc = 0;
	for(<loc l, int n> <- cc(jpacmanASTs())) {
		print(l);
		print(" has complexity: " );
		println(n);
		tc+=n;
	}
	print("Total complexity: ");
	println(tc);
}

// --- TESTING ---
// Test complexity()
test bool testFileLength()
	= complexity(/*TODO*/) == (/*TODO*/);
	


