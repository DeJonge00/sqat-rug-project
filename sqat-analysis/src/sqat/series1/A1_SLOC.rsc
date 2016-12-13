module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;
import String;

/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman? jpacman/level/Level.java with 179 lines
- what is the total size of JPacman? 2458
- is JPacman large according to SIG maintainability? No, it is ranked ++ (very small) according to SIG, because it is less than 66000 loc
- what is the ratio between actual code and test code size? 3.41

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/

bool isComment(str s) {
	return ( /^\s*\/\/.*$/ := s);
}

bool isWhite(str s) {
	return (/^\s*$/ := s);
}

int isStartOfComment(str s) {
	if (/^\s*\/\*.*$/ := s) {
		return 1;
	}
	if (/^.*\/\*.*$/ := s) {
		return 2;
	}
	return 0;
}

int isEndOfComment(str s) {
	if (/^.*\*\/\s*$/ := s) {
		return 1;
	}
	if (/^.*\*\/.*$/ := s) {
		return 2;
	}
	return 0;
}

alias SLOC = map[loc file, int sloc];

SLOC sloc(loc project) {
	SLOC result = ();
	set[loc] projectFiles = files(project);
	real totalsloc = 0.0,testloc = 0.0;
	
	for (loc file <- projectFiles) {
		if(file.extension == "java"){
			int n=0;
			bool inComment=false;
			list[str] code = readFileLines(file);
			for(str s <- code) {
				if (!(isComment(s) || isWhite(s))) {
					if (inComment) {
						int end = isEndOfComment(s);
						if (end==1) {
							inComment=false;
						} else if (end==2) {
							inComment=false;
							n=n+1;
						}
					} else {
						int \start = isStartOfComment(s);
						if (\start==1) {
							inComment=true;
						} else if (\start==2) {
							inComment=true;
							n=n+1;
						} else {
							n=n+1;
						}
					}
				}
			}
			result += (file:n);
			totalsloc += n;
			if (substring(file.path,5,9)=="test") {
				testloc += n;
			}
		}
	}
	print("total lines of code: ");
	println(totalsloc);
	print("total lines of test code: ");
	println(testloc);
	print("ratio between actual code and test code: ");
	println((totalsloc-testloc)/testloc);
	
	return result;
}

SLOC q() {
	SLOC s =  sloc(|project://jpacman-framework/src|);
}

test bool testFileLength()
	= sloc(/*TODO*/) == (/*TODO*/);
	
// Test isStartOfComment()
test bool isBeginCommentFalse()
	= isStartOfComment("\n") == 0;
	
test bool isBeginCommentTrue()
	= isStartOfComment("/*\n") == 1;

test bool isBeginCommentTruePlus()
	= isStartOfComment("inti=0; /*\n") == 2;
	
// Test isEndOfComment()
test bool isEndCommentFalse()
	= isEndOfComment("\n") == 0;

test bool isEndCommentTrue()
	= isEndOfComment("*/\n") == 1;

test bool isEndCommentTruePlus()
	= isEndOfComment("*/ x == 2;\n") == 2;

// Test isComment()
test bool isCommentFalse()
	= isComment("\n") == 0;
	
test bool isCommentTrue()
	= isComment("   //comment\n") == 1;
	
// Test isWhite()
test bool isCommentFalse()
	= isComment("\n") == 0;

