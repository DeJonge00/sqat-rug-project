package main;

public class MethodsToBeTested {
	public static void main() { //not tested
		
	}
	
	public static void method1() { //tested
		method2();
	}
	
	public static void method2() { //tested
	}
	
	public static void method3() { //not tested
		method2();
	}
	
	public static void method4(int a) { //tested
		method4(42);
	}
	
	public static int method5() { //tested
		method4(3);
		return 5;
	}
}


/* expected coverage: 4/6 = 66% */