module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;
import String;
import ToString;


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
	We will make an example project (sqat-test-project) with multiple classes. 
	We will make tests of the form <class1> <dictorule> <class2>.
	We won't need multiple packages, because those are not supported in the dicto grammar.
	
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
  	For the "invoke" modality, we now check all methods with the same name. In order to 
  	make a difference between multiple function with the same name, but other parameters, 
*/

loc getEntityLocation(Entity e) {
	if(contains("<e>", "::")) {
		return |java+method:///| + replaceAll(replaceAll("<e>", ".", "/"), "::", "/");
	}
	return |java+class:///| + replaceAll("<e>", ".", "/");
}

bool isMethod(Entity e) {
	return contains("<e>", "::");
}

// 	Class depends on class
set[loc] findDependancies(loc file, M3 m3) {
	set[loc] foundDependancies = {};
	println(file);
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

Message mustInherit(Entity e1, Entity e2, M3 m3) {
	loc file = getEntityLocation(e1);
	if(getEntityLocation(e2) notin findInherits(file, m3)) {
		return warning("<e1> does not inherit from <e2> (must inherit)", file);
	}
	return warning("Rule accepted", file);
}

Message cannotInherit(Entity e1, Entity e2, M3 m3) {
	loc file = getEntityLocation(e1);
	if(getEntityLocation(e2) in findInherits(file, m3)) {
		return warning("<e1> inherits from <e2> (cannot inherit)", file);
	}
	return warning("Rule accepted", file);
}

Message canOnlyInherit(Entity e1, Entity e2, M3 m3) {
	getEntityLocation(e1);
	loc file = getEntityLocation(e1);
	for(loc l <- findInherits(file, m3)) {
		if(getEntityLocation(e2) != l) {
			return warning("<e1> inherits from something other than <e2> (can only inherit)", file);
		}
	}
	return warning("Rule accepted", file);
}

// Class/method invokes method
set[loc] classInvokesMethods(loc class, M3 m3) {
	set[loc] methodsInvoked = {};
	set[loc] methodsInClass = {};
	for(<loc name, loc src> <- m3@declarations) {
		if(src == class) {
			methodsInClass += name;
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
		if((split("///", split("(", toString(from))[0])[-1]) == (split("|", split("///", "<method>")[-1])[0])) {
			methods += to;
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
		for(loc l <- methodInvokesMethods(l1, m3)) {
			if((split("///", split("|", toString(l2))[1])[-1]) == (split("///", split("(", toString(l))[0])[-1])) {
				return warning("Rule accepted", l);
			}
		}
		return warning("<e1> does not invoke <e2> (mustInvoke)", l1);
	} 
	for(loc l <- classInvokesMethods(l1, m3)) {
		if((split("///", split("|", toString(l2))[1])[-1]) == (split("///", split("(", toString(l))[0])[-1])) {
			return warning("Rule accepted", l);
		}
	}
	return warning("<e1> does not invoke <e2> (mustInvoke)", l1);
}

Message cannotInvoke(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(!isMethod(e2)) {
		return  warning("<e2> is not a method", l2);
	}
	if(isMethod(e1)) {
		for(loc l <- methodInvokesMethods(l1, m3)) {
			if((split("///", split("|", toString(l2))[1])[-1]) == (split("///", split("(", toString(l))[0])[-1])) {
				return warning("<e1> invokes <e2> (cannotInvoke)", l);
			}
		}
		return warning("Rule accepted", l1);
	} 
	for(loc l <- classInvokesMethods(l1, m3)) {
		if((split("///", split("|", toString(l2))[1])[-1]) == (split("///", split("(", toString(l))[0])[-1])) {
			return warning("<e1> invokes <e2> (cannotInvoke)", l);
		}
	}
	return warning("Rule accepted", l1);
}

Message canOnlyInvoke(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(!isMethod(e2)) {
		return  warning("<e2> is not a method", l2);
	}
	if(isMethod(e1)) {
		for(loc l <- methodInvokesMethods(l1, m3)) {
			if((split("///", split("|", toString(l2))[1])[-1]) != (split("///", split("(", toString(l))[0])[-1])) {
				return warning("<e1> invokes <e2> (canOnlyInvoke)", l);
			}
		}
		return warning("Rule accepted", l1);
	} 
	for(loc l <- classInvokesMethods(l1, m3)) {
		if((split("///", split("|", toString(l2))[1])[-1]) != (split("///", split("(", toString(l))[0])[-1])) {
			return warning("<e1> invokes <e2> (canOnlyInvoke)", l);
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
  	case (Rule)`<Entity e1> cannot invoke <Entity e2>`: msgs += cannotInvoke(e1, e2, m3);
  	case (Rule)`<Entity e1> can only invoke <Entity e2>`: msgs += canOnlyInvoke(e1, e2, m3);
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


set[Message] test1() {
	return eval((Rule)`a2_checkarch_tests.A2_checkarch2 cannot inherit a2_checkarch_tests.A2_checkarch1`, testM3());
}
// Tests

M3 testM3() = createM3FromEclipseProject(|project://sqat-test-project/src|);
//testing invoke
test bool mustInvoke_Invokes() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method must invoke a2_checkarch_tests.A2_checkarch1::method`, testM3())
	== {warning("Rule accepted", |java+method:///a2_checkarch_tests/A2_checkarch1/method()|)};
test bool mustInvoke_DoesntInvoke() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method must invoke a2_checkarch_tests.A2_checkarch1::method2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2::method does not invoke a2_checkarch_tests.A2_checkarch1::method2 (mustInvoke)", |java+method:///a2_checkarch_tests/A2_checkarch2/method|)};
test bool cannotInvoke_DoesntInvoke() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method cannot invoke a2_checkarch_tests.A2_checkarch1::method2`, testM3())
	== {warning("Rule accepted", |java+method:///a2_checkarch_tests/A2_checkarch2/method|)};
test bool cannotInvoke_Invokes() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method cannot invoke a2_checkarch_tests.A2_checkarch1::method`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2::method invokes a2_checkarch_tests.A2_checkarch1::method (cannotInvoke)", |java+method:///a2_checkarch_tests/A2_checkarch1/method()|)};
//testing inherit
test bool mustInherit_Inherits() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 must inherit a2_checkarch_tests.A2_checkarch1`, testM3())
	== {warning("Rule accepted", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool mustInherit_DoesntInherit() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 must inherit a2_checkarch_tests.A2_checkarch2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch1 does not inherit from a2_checkarch_tests.A2_checkarch2 (must inherit)", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool cannotInherit_DoesntInherit() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 cannot inherit a2_checkarch_tests.A2_checkarch2`, testM3())
	== {warning("Rule accepted", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool cannotInherit_Inherits() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 cannot inherit a2_checkarch_tests.A2_checkarch1`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2 inherits from a2_checkarch_tests.A2_checkarch1 (cannot inherit)", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool canOnlyInherit_OnlyInherits() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 can only inherit a2_checkarch_tests.A2_checkarch1`, testM3())
	== {warning("Rule accepted", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool canOnlyInherit_DoesntInherit() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 can only inherit a2_checkarch_tests.A2_checkarch2`, testM3())
	== {warning("Rule accepted", |java+class:///a2_checkarch_tests/A2_checkarch1|)};


