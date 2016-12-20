module sqat::series1::A3_CheckStyle

import lang::java::\syntax::Java15;
import IO;
import util::FileSystem;
import String;
import Message;
import List;

/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

  
Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/

/* Checks for comments of the form //TODO:... or /*TODO:.. */
set[Message] checkToDo(loc file) {
	if(file.extension != "java"){
		return {};
	}
	
	int lineNumber = 0;
	bool inComment = false;
	list[str] code = readFileLines(file);
	set[Message] warnings = {};
	
	for(str s <- code) {
		lineNumber += 1;
		if (/\/\*/ := s && /\*\// !:= s) {
			inComment = true;
		} else if (/\*\// := s) {
			inComment = false;
		}
		if (/^\s*\/\/TODO.*$/ := s || (inComment && /TODO/ := s) || (/\/\*.*TODO.*\*\// := s)) {
			warnings += warning("This line contains a todo statement.", file + ":line<lineNumber>");
		}
	}
	
	return warnings;
}

/* Checks whether a file of the specified extension is at most the specified length. */
set[Message] checkFileLength(loc file, int maxLength, list[str] extensions) {
	if(indexOf(extensions,file.extension) == -1){
		return {};
	}
	
	set[Message] warnings = {};
	list[str] code = readFileLines(file);
	
	if (size(code) > maxLength) {
		warnings += warning("File too long",file);
	}
	
	return warnings;
}

/* Checks that the specified exception types do not appear in a catch statement. */
set[Message] checkIllegalCatch(loc file, list[str] exceptions) {
	if(file.extension != "java"){
		return {};
	}
	
	int lineNumber = 0;
	set[Message] warnings = {};
	list[str] code = readFileLines(file);
	
	for(str s <- code) {
		lineNumber += 1;
		for (str ex <- exceptions) {
			if (/^.*catch.*\(.*<ex>.*\).*$/ := s) {
				warnings += warning("Illegal Catch: " + ex, file + ":line<lineNumber>");
			}
		}
	}
	
	return warnings;
}

//TODO: personal style check 
set[Message] check4(list[str] code) {
	if(file.extension != "java"){
		return;
	}
	int lineNum = 0;
	list[str] code = readFileLines(file);
	for(str s <- code) {
		print("");
	}
}

set[Message] checkStyle(loc project) {
 	set[Message] result = {};
 	set[loc] projectFiles = files(project);

 	for (loc file <- projectFiles) {
		result += checkToDo(file);
		result += checkFileLength(file,500,["java"]);
		result += checkIllegalCatch(file,["java.lang.Exception", "java.lang.Throwable", "java.lang.RuntimeException"]);
		//result += check4(file);
	}
  
	return result;
}



// Test methods"

test bool testCheckToDo()
	= checkToDo(|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java|)
	== {
  		warning("This line contains a todo statement.",
  		|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line9|),
  		warning("This line contains a todo statement.",
  		|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line16|),
  		warning("This line contains a todo statement.",
  		|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line22|)
		};
		
test bool testCheckToDo()
	= checkToDo(|project://sqat-test-project/src/series1_CheckStyle/EmptyFile.bmp|)
	== {};
		
test bool testCheckFileLength()
	= checkFileLength(|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java|,25,["java"])
	== {warning("File too long",|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java|)};
	
test bool testCheckFileLength()
	= checkFileLength(|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java|,40,["java"])
	== {};
	
test bool testCheckFileLength()
	= checkFileLength(|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java|,5,["php"])
	== {};
	
test bool testCheckIllegalCatch()
	= checkIllegalCatch(|project://sqat-test-project/src/series1_CheckStyle/CheckIllegalCatch.java|,
		["java.lang.Exception", "java.lang.Throwable", "java.lang.RuntimeException"])
	== {
  		warning("Illegal Catch: java.lang.Throwable",
    		|project://sqat-test-project/src/series1_CheckStyle/CheckIllegalCatch.java/:line12|),
  		warning("Illegal Catch: java.lang.Exception",
    		|project://sqat-test-project/src/series1_CheckStyle/CheckIllegalCatch.java/:line9|)
		};
	
test bool testCheckIllegalCatch()
	= checkIllegalCatch(|project://sqat-test-project/src/series1_CheckStyle/EmptyFile.bmp|,
		["java.lang.Exception", "java.lang.Throwable", "java.lang.RuntimeException"])
	== {};
