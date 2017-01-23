module sqat::series2::A2_CheckArch

import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;


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

loc getEntityLocation(Entity e1) {
	return |java+class:///| + replaceAll("<e1>", ".", "/");
}

// 	Import
set[loc] findImports(loc javafile) {
	set[loc] foundImports = {};
	
	return foundImports;
}

// 	Inherits
set[loc] findInherits(loc javafile, m3) {
	set[loc] foundInherits = {};
	for(<loc from, loc to> <- m3@extends) {
		if(from == javafile) {
			foundInherits += to;
		}
	}
	return foundInherits;
}

Message mustInherit(Entity e1, Entity e2, M3 m3) {
	if(getEntityLocation(e2) notin findInherits(getEntityLocation(e1), m3)) {
		return "Warning: <e1> does not inherit from <e2> (must inherit)";
	}
	return {};
}

Message cannotInherit(Entity e1, Entity e2, M3 m3) {
	if(getEntityLocation(e2) in findInherits(getEntityLocation(e1), m3)) {
		return "Warning: <e1> inherits from <e2> (cannot inherit)";
	}
	return {};
}

Message canOnlyInherit(Entity e1, Entity e2, M3 m3) {
	for(loc l <- findInherits(getEntityLocation(e1), m3)) {
		if(getEntityLocation(e2) != l) {
			return "Warning: <e1> inherits from something other than <e2> (can only inherit)";
		}
	}
	return {};
}

set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
  set[Message] msgs = {};
  
  switch (rule) {
  	case (Rule)`<Entity e1> must inherit <Entity e2>`: msgs += mustInherit(e1, e2, m3);
	}
  
  return msgs;
}

set[loc] q() {
	M3 m3 = createM3FromEclipseProject(|project://jpacman-framework|);
	return findInherits(|java+class:///nl/tudelft/jpacman/npc/NPC|,m3); 
	
}

