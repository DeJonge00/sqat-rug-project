package test;
import main.MethodsToBeTested;

public class TestMethods {
	public static void test1() {
		MethodsToBeTested.method1();
	}
	
	public static void test2() {
		//This one does nothing
	}
	
	public static void test3() {
		MethodsToBeTested.method4(MethodsToBeTested.method5());
	}
}
