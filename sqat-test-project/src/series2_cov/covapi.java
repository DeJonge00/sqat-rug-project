package series2_cov;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

public class covapi {
	public void maketestfile() {
		try(FileWriter fw = new FileWriter("outfilename", true);
			    BufferedWriter bw = new BufferedWriter(fw);
			    PrintWriter out = new PrintWriter(bw))
		{
			
		    out.println("the text");
		} catch (IOException e) {
		    e.printStackTrace();
		}
	}
}
