module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;

/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
- what is the total size of JPacman?
- is JPacman large according to SIG maintainability?
- what is the ratio between actual code and test code size?

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
	
	for (loc file <- projectFiles) {
		if(file.extension=="java"){
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
							n++;
						}
					} else {
						int \start = isStartOfComment(s);
						if (\start==1) {
							inComment=true;
						} else if (\start==2) {
							inComment=true;
							n++;
						} else {
							n++;
						}
					}
				}
			}
		}
	}
	return result;
}