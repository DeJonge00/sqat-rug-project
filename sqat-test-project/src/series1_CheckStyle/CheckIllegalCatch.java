package series1_CheckStyle;

// This class has two catch statements that should be picked up by checkIllegalCatch()
public class CheckIllegalCatch {
	public CheckIllegalCatch() {
		try {
			try {
				
			} catch (java.lang.Exception e) {
				
			}
		} catch (java.lang.Throwable e) {
			
		}
	}
}
