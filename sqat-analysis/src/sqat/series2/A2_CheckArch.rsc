module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;
import String;


/*

This assignment has two parts:
- write a dicto file (see example.dicto for an example)
  containing 3 or more architectural rules for Pacman
  
- write an evaluator for the Dicto language that checks for
  violations of these rules. 

Part 1  

An example is: ensure that the game logic component does not 
depend on the GUI subsystem. Another example could relate to
the proper use of factories.   

Make sure that at least one of them is violated (perhaps by
first introducing the violation).

Explain why your rule encodes "good" design.
  
Part 2:  
 
Complete the body of this function to check a Dicto rule
against the information on the M3 model (which will come
from the pacman project). 

A simple way to get started is to pattern match on variants
of the rules, like so:

switch (rule) {
  case (Rule)`<Entity e1> cannot depend <Entity e2>`: ...
  case (Rule)`<Entity e1> must invoke <Entity e2>`: ...
  ....
}

Implement each specific check for each case in a separate function.
If there's a violation, produce an error in the `msgs` set.  
Later on you can factor out commonality between rules if needed.

The messages you produce will be automatically marked in the Java
file editors of Eclipse (see Plugin.rsc for how it works).

Tip:
- for info on M3 see series2/A1a_StatCov.rsc.

Questions
- how would you test your evaluator of Dicto rules? (sketch a design)
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
*/

loc getEntityLocation(Entity e) {
	println(e);
	if(contains("<e>", "::")) {
		str name = replaceAll(replaceAll("<e>", ".", "/"), "::", "/") + "()";
		return |java+method:///| + name;
	}
	return |java+class:///| + replaceAll("<e>", ".", "/");
}

bool isMethod(Entity e) {
	return contains("<e>", "::");
}

// 	Class depends on class
set[loc] findDependancies(loc file, M3 m3) {
	set[loc] foundDependancies = {};
	//println(file);
	for(<loc src, loc name> <- m3@uses) {
		if(src == file) {
			foundDependancies += name;
			println(same);
		}
	}
	return foundDependancies;
}

Message mustDepend(Entity e1, Entity e2, M3 m3) {
	loc file = getEntityLocation(e1);
	if(getEntityLocation(e2) notin findDependancies(file, m3)) {
		return warning("<e1> does not depend on <e2> (must depend)", file);
	}
	return {};
}

Message cannotDepend(Entity e1, Entity e2, M3 m3) {
	return {};
}

Message canOnlyDepend(Entity e1, Entity e2, M3 m3) {
	return {};
}

// 	Class inherits class
set[loc] findInherits(loc file, m3) {
	set[loc] foundInherits = {};
	for(<loc from, loc to> <- m3@extends) {
		if(from == file) {
			foundInherits += to;
		}
	}
	return foundInherits;
}

Message mustInherit(Entity e1, str modality, Entity e2, M3 m3) {
	Message warnings = {};
	loc file = getEntityLocation(e1);
	if(getEntityLocation(e2) notin findInherits(file, m3)) {
		return warning("<e1> does not inherit from <e2> (must inherit)", file);
	}
	return warnings;
}

Message cannotInherit(Entity e1, Entity e2, M3 m3) {
	Message warnings = {};
	
	loc file = getEntityLocation(e1);
	if(getEntityLocation(e2) notin findInherits(file, m3)) {
		warnings += warning("<e1> inherits from <e2> (cannot inherit)", file);
	}
	return warnings;
}

Message canOnlyInherit(Entity e1, Entity e2, M3 m3) {
	Message warnings = {};
	getEntityLocation(e1);
	for(loc l <- findInherits(file, m3)) {
		if(getEntityLocation(e2) != l) {
			return warning("<e1> inherits from something other than <e2> (can only inherit)", file);
		}
	}
	return warnings;
}

// Class/method invokes method
set[loc] classInvokesMethods(loc class, M3 m3) {
	set[loc] methodsInvoked = {};
	set[loc] methodsInClass = {};
	for(<loc name, loc src> <- m3@declarations) {
		if(src == class) {
			methodsInClass += name;
			print("MethodInClass: ");
			println(to);
		}
	}
	for(loc method <- methodsInClass) {
		methodsInvoked += methodInvokesMethods(method, m3);
	}
	return methodsInvoked;
}

set[loc] methodInvokesMethods(loc method, M3 m3) {
	set[loc] methods = {};
	for(<loc from, loc to> <- m3@methodInvocation) {
		if(from == method) {
			methods += to;
			print("MethidInMethod");
			println(to);
		}
	}
	return methods;
}

Message mustInvoke(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(!isMethod(e2)) {
		return  warning("<e2> is not a method", l2);
	}
	if(isMethod(e1)) {
		if(l2 notin methodInvokesMethods(l1, m3)) {
			return warning("<e1> does not invoke <e2> (mustInvoke)", l1);
		}
	} else {
		if(l2 notin classInvokesMethods(l1, m3)) {
			return warning("<e1> does not invoke <e2> (mustInvoke)", l1);
		}
	}
	return warning("Rule accepted", l1);
}


// Start of general functions
set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
  set[Message] msgs = {};
  
  switch (rule) {
  	case (Rule)`<Entity e1> must invoke <Entity e2>`: msgs += mustInvoke(e1, e2, m3);
  	case (Rule)`<Entity e1> must depend <Entity e2>`: msgs += mustDepend(e1, e2, m3);
  	case (Rule)`<Entity e1> must inherit <Entity e2>`: msgs += mustInherit(e1, e2, m3);
  	case (Rule)`<Entity e1> cannot inherit <Entity e2>`: msgs += cannotInherit(e1, e2, m3);
  	case (Rule)`<Entity e1> can only inherit <Entity e2>`: msgs += canOnlyInherit(e1, e2, m3);
  	}
  
  return msgs;
}

set[Message] q() {
	M3 m3 = createM3FromEclipseProject(|project://jpacman-framework|);
	return eval(parse(#start[Dicto], |project://sqat-analysis/src/sqat/series2/example.dicto|), m3);
}

