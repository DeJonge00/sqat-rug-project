package main;

public class MethodsToBeTested {
	public static void main() {
		
	}
	
	public static void method1() { //This method is tested
		method2();
	}
	
	public static void method2() { //This method is tested
	}
	
	public static void method3() { //This method is not tested
		method2();
	}
}
