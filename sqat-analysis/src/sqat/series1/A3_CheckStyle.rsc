module sqat::series1::A3_CheckStyle

import lang::java::\syntax::Java15;
import IO;
import util::FileSystem;
import String;
import Message;
import List;

/*
Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?
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
		if (/^\s*\/\/\s*TODO.*$/ := s || (inComment && /TODO/ := s) || (/\/\*\s*TODO.*\*\// := s)) {
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

/* checks whether a line is whitespace-only */
bool isWhite(str s) {
	return (/^\s*$/ := s);
}

/* checks whether a file contains excess whitelines */
set[Message] checkExcessWhite(loc file) {
	if(file.extension != "java"){
		return {};
	}
	int lineNum = 0;
	set[Message] warnings = {};
	list[str] code = readFileLines(file);
	bool e = false;
	
	for(str s <- code) {
		lineNum += 1;
		if(isWhite(s)) {
			if(e) {
				warnings += warning("Excess whiteline: ", file + ":line<lineNum>");
			}
			e = true;
		} else {
			e = false;
		}
	}
	return warnings;
}

/* Finds style violation in each file in the specified location */
set[Message] checkStyle(loc project) {
 	set[Message] result = {};
 	set[loc] projectFiles = files(project);

 	for (loc file <- projectFiles) {
		result += checkToDo(file);
		result += checkFileLength(file,500,["java"]);
		result += checkIllegalCatch(file,["java.lang.Exception", "java.lang.Throwable", "java.lang.RuntimeException"]);
		result += checkExcessWhite(file);
	}
  
	return result;
}

//checks for style violations in JPacman.
set[Message] questions() {
	return checkStyle(|project://jpacman-framework/src|);
}

// Test methods:

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

test bool testCheckExcessWhite()
	= checkExcessWhite(|project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java|)
	==   
	  {
	  warning(
	    "Excess whiteline: ",
	    |project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line26|),
	  warning(
	    "Excess whiteline: ",
	    |project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line25|),
	  warning(
	    "Excess whiteline: ",
	    |project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line33|),
	  warning(
	    "Excess whiteline: ",
	    |project://sqat-test-project/src/series1_CheckStyle/CheckToDo.java/:line32|)
	};

