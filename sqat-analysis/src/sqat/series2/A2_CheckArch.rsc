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
  	We made three sets of rules:
  	1. The first four rules ensure proper inheritance between
  	Ghost and the individual ghosts
  	2. The second set ensures proper use of factories, not
  	calling the constructors themselves (of game and ghosts)
  	3. The third set ensures that the ghostfactory itself
  	calls the correct methods for building the ghosts
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
	We will have two classes (one inheriting the other), each with methods that might 
	refer to eachother.
	
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
  	1. Since Dicto has no grammar for packages, we cannot see how packages interact with eachother, 
  	without looking at all included classes and methods. Including packages in the grammar would save
    time and mistakes if you would want packages checked.
  	2. For the "invoke" modality, we now check all methods with the same name. In order to 
  	make a difference between multiple function with the same name, but other parameters, 
  	we need to add to the grammar a way to differentiate between those functions.
  	3. The 'can only' restriction limits to only one class/method. It would be beneficial
  	to have an extension to this such that it can be applied to 2 or more methods/classes.
  	This prevents having to write all the functions that should be excluded otherwise.
  	(This is slow and may cause errors if not checked regularly.)
*/

loc getEntityLocation(Entity e) { // Entity -> loc 
	if(contains("<e>", "::")) {
		return |java+method:///| + replaceAll(replaceAll("<e>", ".", "/"), "::", "/");
	}
	// Not a method = a class (dicto grammar)
	return |java+class:///| + replaceAll("<e>", ".", "/");
}

loc getConstructorLocation(Entity e) { // Entity -> loc
	return |java+constructor:///| + replaceAll(replaceAll("<e>", ".", "/"), "::", "/");
}

bool isMethod(Entity e) {
	return contains("<e>", "::");
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
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(isMethod(e1)) {
		return warning("<e1> is not a class (mustInherit)", l1);
	}
	if(isMethod(e2)) {
		return warning("<e2> is not a class (mustInherit)", l2);
	}
	if(l2 notin findInherits(l1, m3)) {
		return warning("<e1> does not inherit from <e2> (must inherit)", l1);
	}
	return warning("Rule mustInherit accepted", l1);
}

Message cannotInherit(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(isMethod(e1)) {
		return warning("<e1> is not a class (mustInherit)", l1);
	}
	if(isMethod(e2)) {
		return warning("<e2> is not a class (mustInherit)", l2);
	}
	if(l2 in findInherits(l1, m3)) {
		return warning("<e1> inherits from <e2> (cannot inherit)", l1);
	}
	return warning("Rule cannotInherit accepted", l1);
}

Message canOnlyInherit(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(isMethod(e1)) {
		return warning("<e1> is not a class (mustInherit)", l1);
	}
	if(isMethod(e2)) {
		return warning("<e2> is not a class (mustInherit)", l2);
	}
	for(loc l <- findInherits(l1, m3)) {
		if(l2 != l) {
			return warning("<e1> inherits from something other than <e2> (can only inherit)", l1);
		}
	}
	return warning("Rule canOnlyInherit accepted", l1);
}

// Class/method invokes method
// Input: class Output: set of methods invoked in that class
set[loc] classInvokesMethods(loc class, M3 m3) { 
	set[loc] methodsInvoked = {};
	set[loc] methodsInClass = {};
	for(<loc name, loc src> <- m3@declarations) {
		if(split(".", split("/", src.uri)[-1])[0] == split("/", class.uri)[-1]) {
			methodsInClass += name;
		}
	}
	for(loc method <- methodsInClass) {
		methodsInvoked += methodInvokesMethods(method, m3);
	}
	return methodsInvoked;
}

// Input: method, Output: set of methods invoked in that method
set[loc] methodInvokesMethods(loc method, M3 m3) {
	set[loc] methods = {};
	for(<loc from, loc to> <- m3@methodInvocation) {
		if((split("///", split("(", from.uri)[0])[-1]) == (split("///", split("(", method.uri)[0])[-1])) {
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
	set[loc] methods;
	if(isMethod(e1)) {
		methods = methodInvokesMethods(l1, m3);
	} else {
		methods = classInvokesMethods(l1, m3);
	}
	for(loc l <- methods) {
		if((split("///", l2.uri)[-1]) == (split("(", split("///", l.uri)[-1])[0])) {
			return warning("Rule mustInvoke accepted", l1);
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
	set[loc] methods;
	if(isMethod(e1)) {
		methods = methodInvokesMethods(l1, m3);
	} else {
		methods = classInvokesMethods(l1, m3);
	}
	for(loc l <- methods) {
		if((split("///", l2.uri)[-1]) == (split("///", split("(", l.uri)[0])[-1])) {
			return warning("<e1> invokes <e2> (cannotInvoke)", l1);
		}
	}
	return warning("Rule cannotInvoke accepted", l1);
}

Message canOnlyInvoke(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getEntityLocation(e2);
	if(!isMethod(e2)) {
		return  warning("<e2> is not a method", l2);
	}
	set[loc] methods;
	if(isMethod(e1)) {
		methods = methodInvokesMethods(l1, m3);
	} else {
		methods = classInvokesMethods(l1, m3);
	}
	for(loc l <- methods) {
		if((split("///", l2.uri)[-1]) != (split("///", split("(", l.uri)[0])[-1])) {
			return warning("<e1> invokes <e2> (canOnlyInvoke)", l1);
		}
	}
	return warning("Rule canOnlyInvoke accepted", l1);
}

// Class/method instantiate class
Message mustInstantiate(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getConstructorLocation(e2);
	if(!isMethod(e2)) {
		return warning("<e2> is not a constructor (mustInstantiate)", l2);
	}
	set[loc] methods;
	if(isMethod(e1)) {
		methods = methodInvokesMethods(l1, m3);
	} else {
		methods = classInvokesMethods(l1, m3);
	}
	for(loc l <- methods) {
		if(l2.uri == split("(", l.uri)[0]) {
			return warning("Rule mustInstantiate accepted", l1);
		}
	}
	return warning("<e1> does not instantiate <e2> (mustInstantiate)", l1);
}

Message cannotInstantiate(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getConstructorLocation(e2);
	if(!isMethod(e2)) {
		return warning("<e2> is not a constructor (mustInstantiate)", l2);
	}
	set[loc] methods;
	if(isMethod(e1)) {
		methods = methodInvokesMethods(l1, m3);
	} else {
		methods = classInvokesMethods(l1, m3);
	}
	for(loc l <- methods) {
		if(l2.uri == split("(", l.uri)[0]) {
			return warning("<e1> instantiates <e2> (cannotInstantiate)", l1);
		}
	}
	return warning("Rule cannotInstantiate accepted", l1);
}

Message canOnlyInstantiate(Entity e1, Entity e2, M3 m3) {
	loc l1 = getEntityLocation(e1);
	loc l2 = getConstructorLocation(e2);
	if(!isMethod(e2)) {
		return warning("<e2> is not a constructor (canOnlyInstantiate)", l2);
	}
	set[loc] methods;
	if(isMethod(e1)) {
		methods = methodInvokesMethods(l1, m3);
	} else {
		methods = classInvokesMethods(l1, m3);
	}
	for(loc l <- methods) {
		// Extra check 'Is l a consructor?' needed
		if(split(":///", l.uri)[0] == "java+constructor" && l2.uri != split("(", l.uri)[0]) {
			return warning("<e1> instantiates more than only <e2> (canOnlyInstantiate)", l1);
		}
	}
	return warning("Rule canOnlyInstantiate accepted", l1);
}

// Start of general functions
set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
  set[Message] msgs = {};
  
  // Switch methods depending on the Dicto-rule
  switch (rule) {
  	case (Rule)`<Entity e1> must invoke <Entity e2>`: msgs += mustInvoke(e1, e2, m3);
  	case (Rule)`<Entity e1> cannot invoke <Entity e2>`: msgs += cannotInvoke(e1, e2, m3);
  	case (Rule)`<Entity e1> can only invoke <Entity e2>`: msgs += canOnlyInvoke(e1, e2, m3);
  	case (Rule)`<Entity e1> must inherit <Entity e2>`: msgs += mustInherit(e1, e2, m3);
  	case (Rule)`<Entity e1> cannot inherit <Entity e2>`: msgs += cannotInherit(e1, e2, m3);
  	case (Rule)`<Entity e1> can only inherit <Entity e2>`: msgs += canOnlyInherit(e1, e2, m3);
  	case (Rule)`<Entity e1> must instantiate <Entity e2>`: msgs += mustInstantiate(e1, e2, m3);
  	case (Rule)`<Entity e1> cannot instantiate <Entity e2>`: msgs += cannotInstantiate(e1, e2, m3);
  	case (Rule)`<Entity e1> can only instantiate <Entity e2>`: msgs += canOnlyInstantiate(e1, e2, m3);
  }
  
  return msgs;
}

// Main method for evaluating jpacman with the example.dicto
M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework/src|);

set[Message] q() {
	return eval(parse(#start[Dicto], |project://sqat-analysis/src/sqat/series2/example.dicto|), jpacmanM3());
}

// Tests
M3 testM3() = createM3FromEclipseProject(|project://sqat-test-checkArch/src|);
//testing invoke
	//methods
test bool method_mustInvoke_Invokes() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method must invoke a2_checkarch_tests.A2_checkarch1::method`, testM3())
	== {warning("Rule mustInvoke accepted",|java+method:///a2_checkarch_tests/A2_checkarch2/method|)};
test bool method_mustInvoke_DoesntInvoke() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method must invoke a2_checkarch_tests.A2_checkarch1::method2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2::method does not invoke a2_checkarch_tests.A2_checkarch1::method2 (mustInvoke)", |java+method:///a2_checkarch_tests/A2_checkarch2/method|)};
test bool method_cannotInvoke_DoesntInvoke() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method cannot invoke a2_checkarch_tests.A2_checkarch1::method2`, testM3())
	== {warning("Rule cannotInvoke accepted", |java+method:///a2_checkarch_tests/A2_checkarch2/method|)};
test bool method_cannotInvoke_Invokes() = eval((Rule)`a2_checkarch_tests.A2_checkarch2::method cannot invoke a2_checkarch_tests.A2_checkarch1::method`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2::method invokes a2_checkarch_tests.A2_checkarch1::method (cannotInvoke)",|java+method:///a2_checkarch_tests/A2_checkarch2/method|)};
	//classes
test bool class_mustInvoke_Invokes() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 must invoke a2_checkarch_tests.A2_checkarch1::method`, testM3())
	== {warning("Rule mustInvoke accepted",|java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool class_mustInvoke_DoesntInvoke() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 must invoke a2_checkarch_tests.A2_checkarch1::method2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2 does not invoke a2_checkarch_tests.A2_checkarch1::method2 (mustInvoke)", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool class_cannotInvoke_DoesntInvoke() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 cannot invoke a2_checkarch_tests.A2_checkarch1::method2`, testM3())
	== {warning("Rule cannotInvoke accepted", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool class_cannotInvoke_Invokes() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 cannot invoke a2_checkarch_tests.A2_checkarch1::method`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2 invokes a2_checkarch_tests.A2_checkarch1::method (cannotInvoke)", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
//testing inherit
test bool mustInherit_Inherits() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 must inherit a2_checkarch_tests.A2_checkarch1`, testM3())
	== {warning("Rule mustInherit accepted", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool method_mustInherit_DoesntInherit() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 must inherit a2_checkarch_tests.A2_checkarch2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch1 does not inherit from a2_checkarch_tests.A2_checkarch2 (must inherit)", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool cannotInherit_DoesntInherit() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 cannot inherit a2_checkarch_tests.A2_checkarch2`, testM3())
	== {warning("Rule cannotInherit accepted", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool cannotInherit_Inherits() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 cannot inherit a2_checkarch_tests.A2_checkarch1`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2 inherits from a2_checkarch_tests.A2_checkarch1 (cannot inherit)", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool canOnlyInherit_OnlyInherits() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 can only inherit a2_checkarch_tests.A2_checkarch1`, testM3())
	== {warning("Rule canOnlyInherit accepted", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool canOnlyInherit_DoesntInherit() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 can only inherit a2_checkarch_tests.A2_checkarch2`, testM3())
	== {warning("Rule canOnlyInherit accepted", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
//test instantiate
	//methods
test bool method_mustInstantiate_Instantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1::method must instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule mustInstantiate accepted",|java+method:///a2_checkarch_tests/A2_checkarch1/method|)};
test bool method_mustInstantiate_DoesntInstantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1::method2 must instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch1::method2 does not instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2 (mustInstantiate)", |java+method:///a2_checkarch_tests/A2_checkarch1/method2|)};
test bool method_cannotInstantiate_DoesntInstantiate() = eval((Rule)`a2_checkarch_tests.A2_checkarch1::method2 cannot instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule cannotInstantiate accepted", |java+method:///a2_checkarch_tests/A2_checkarch1/method2|)};
test bool method_cannotInstantiate_Instantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1::method cannot instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch1::method instantiates a2_checkarch_tests.A2_checkarch2::A2_checkarch2 (cannotInstantiate)",|java+method:///a2_checkarch_tests/A2_checkarch1/method|)};
test bool method_canOnlyInstantiate_Instantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1::method can only instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule canOnlyInstantiate accepted", |java+method:///a2_checkarch_tests/A2_checkarch1/method|)};
test bool method_canOnlyInstantiate_DoesntInstantiateAnything() = eval((Rule)`a2_checkarch_tests.A2_checkarch1::method2 can only instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule canOnlyInstantiate accepted", |java+method:///a2_checkarch_tests/A2_checkarch1/method2|)};
	//classes
test bool class_mustInstantiate_Instantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 must instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule mustInstantiate accepted",|java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool class_mustInstantiate_DoesntInstantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 must instantiate a2_checkarch_tests.A2_checkarch1::A2_checkarch2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch2 does not instantiate a2_checkarch_tests.A2_checkarch1::A2_checkarch2 (mustInstantiate)", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool class_cannotInstantiate_DoesntInstantiate() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 cannot instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule cannotInstantiate accepted", |java+class:///a2_checkarch_tests/A2_checkarch2|)};
test bool class_cannotInstantiate_Instantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 cannot instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("a2_checkarch_tests.A2_checkarch1 instantiates a2_checkarch_tests.A2_checkarch2::A2_checkarch2 (cannotInstantiate)", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool class_canOnlyInstantiate_Instantiates() = eval((Rule)`a2_checkarch_tests.A2_checkarch1 can only instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule canOnlyInstantiate accepted", |java+class:///a2_checkarch_tests/A2_checkarch1|)};
test bool class_canOnlyInstantiate_DoesntInstantiateAnything() = eval((Rule)`a2_checkarch_tests.A2_checkarch2 can only instantiate a2_checkarch_tests.A2_checkarch2::A2_checkarch2`, testM3())
	== {warning("Rule canOnlyInstantiate accepted",|java+class:///a2_checkarch_tests/A2_checkarch2|)};
	
	
	
	
	
	