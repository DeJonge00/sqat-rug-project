module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;
import String;

/* 
Answer the following questions:
- what is the biggest file in JPacman? jpacman/level/Level.java with 179 lines
- what is the total size of JPacman? 2458
- is JPacman large according to SIG maintainability? No, it is ranked ++ (very small) according to SIG, because it is less than 66000 loc
- what is the ratio between actual code and test code size? 29% of the total code is test code.
*/

alias SLOC = map[loc file, int sloc];

/* checks whether this line is a comment of the form "//comment" */
bool isComment(str s) {
	return ( /^\s*\/\/.*$/ := s);
}

/* checks whether a line is whitespace-only */
bool isWhite(str s) {
	return (/^\s*$/ := s);
}

/* checks for the start of a comment: 
	0: this line is not the start of a comment 
	1: this line is the start of a comment 
	2: this line is the start of a comment, but also has code before that comment */
int isStartOfComment(str s) {
	if (/^\s*\/\*.*$/ := s)
		return 2;
	if (/^.*\/\*.*$/ := s)
		return 1;
	return 0;
}

/* checks for the end of a comment: 
	0: this line is not the end of a comment 
	1: this line is the end of a comment 
	2: this line is the end of a comment, but also has code after that comment */
int isEndOfComment(str s) {
	if (/^.*\*\/\s*$/ := s) {
		return 1;
	}
	if (/^.*\*\/.*$/ := s) {
		return 2;
	}
	return 0;
}

//Returns the source lines of code for every java file in the location, as well as the total SLOC.
SLOC sloc(loc project) {
	SLOC result = ();
	set[loc] projectFiles = files(project);
	real totalsloc = 0.0,testloc = 0.0;
	int max = 0; loc maxfile ;
	
	for (loc file <- projectFiles) {
		if(file.extension == "java"){
			int n=0;
			bool inComment=false;
			list[str] code = readFileLines(file);
			for(str s <- code) {
				if (!(isComment(s) || isWhite(s))) {
					if (!inComment) {
						int \start = isStartOfComment(s);
						if (\start>=1)
							inComment=true;
						if (\start<=1)
							n=n+1;
					}
					if (inComment) {
						int end = isEndOfComment(s);
						if (end>=1)
							inComment=false;
						if (end==2)
							n=n+1;
					}
				}
			}
			result += (file:n);
			totalsloc += n;
			if(n > max) {
				max = n;
				maxfile = file;
			}
			if (/^.*test.*$/ := file.path) {
				testloc += n;
			}
		}
	}
	//printing results:
	print("biggest file: ");
	print(maxfile);
	print(" with ");
	print(max);
	println(" lines of code.");
	print("total lines of code: ");
	println(totalsloc);
	print("total lines of test code: ");
	println(testloc);
	print("fraction of total code that is test code: ");
	println(testloc/(totalsloc-testloc));
	
	return result;
}

//return SLOC for JPacman
SLOC questions() {
	return sloc(|project://jpacman-framework/src|);
}

// --- TESTING ---
// Test isStartOfComment()
test bool isBeginCommentFalse()
	= isStartOfComment("\n") == 0;
	
test bool isBeginCommentTrue()
	= isStartOfComment("/*\n") == 2;

test bool isBeginCommentTruePlus()
	= isStartOfComment("inti=0; /*\n") == 1;
	
// Test isEndOfComment()
test bool isEndCommentFalse()
	= isEndOfComment("\n") == 0;

test bool isEndCommentTrue()
	= isEndOfComment("*/\n") == 1;

test bool isEndCommentTruePlus()
	= isEndOfComment("*/ x == 2;\n") == 2;

// Test isComment()
test bool isCommentFalse()
	= isComment("\n") == false;
	
test bool isCommentTrue()
	= isComment("   //comment\n") == true;
	
// Test isWhite()
test bool isWhiteFalse()
	= isWhite("   c  \n") == false;

test bool isWhiteTrue()
	= isWhite("    \n") == true;

// Test sloc()
loc testfile = |project://sqat-test-project/src/series1_numberOfLines/NumberOfLines1.java|;
test bool testFileLength()
	= sloc(testfile)
	== (testfile:4);
	
loc testfile2 = |project://sqat-test-project/src/series1_numberOfLines/NumberOfLines2.java|;
test bool testFileLength()
	= sloc(testfile2)
	== (testfile2:7);