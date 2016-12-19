package series1_numberOfLines;

public class TestA2 {
	
	public void testDummy() {
		System.out.print("Hallo");
	}
	
	public void testIf() {
		if(true) {
			System.out.print("Hallo");
		}
	}
	
	public void testIfElse() {
		if(true) {
			System.out.print("Hallo");
		} else {
			System.out.print("Hallo");
		}
	}
	
	public void testDo() {
		do {
			System.out.print("Hallo");
		} while (true);
	}
	
	public void testWhile() {
		while(true) {
			System.out.print("Hallo");
		}
	}
	
	public void testFor() {
		for(int x = 0; x < 2; x++) {
			System.out.print("Hallo");
		}
	}
	
	public void testForeach() {
		int[] l = {0};
		for(Integer i : l) {
			System.out.print("Hallo");
		}
	}
	
	public void testCase(int i) {
		switch(i) {
			case 0:
				System.out.print("Hallo");
				break;
			default:
				break;
		}
	}
	
	public void testCatch(int i) {
		int x;
		int arr[] = {0};
		try {
			x = arr[i];
		} catch (IndexOutOfBoundsException e) {
			System.out.print("Catch");
		}
	}
	
	public void testAnd() {
		if(true && true) {
			System.out.print("Hallo");
		}
	}
	
	public void testOr() {
		if(true || false) {
			System.out.print("Hallo");
		}
	}
	
	public void testConditional(int a, int b) {
		a = (a > b) ? a : b;
	}
}
