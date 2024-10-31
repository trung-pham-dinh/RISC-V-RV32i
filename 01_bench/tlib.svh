// TASK: Clock Generator
task tsk_clock_gen(ref logic i_clk);
  begin
    i_clk = 1'b1;
    forever #10 i_clk = !i_clk;
  end
endtask

task tsk_button_gen(ref logic[3:0] i_io_btn);
  begin
    #1; // add this FUCKING delay to avoid race condition while simulation !!!!!!!!!!!!!!!!!!!!!
    i_io_btn = '0;
    forever begin
      i_io_btn[0] = 1'($urandom%2);
      i_io_btn[1] = 1'($urandom%2);
      i_io_btn[2] = 1'($urandom%2);
      i_io_btn[3] = 1'($urandom%2);
      #10;
      #(($urandom%15) * 10); 
    end
  end
endtask

// TASK: Reset is low active for a period of "RESETPERIOD"
task tsk_reset(ref logic i_rst_n, input int RESETPERIOD);
  begin
    i_rst_n = 1'b0;
    #RESETPERIOD i_rst_n = 1'b1;
  end
endtask

// TASK: Timeout, assume after a period of "FINISH",
// the design is supposed to be "PASSED"
task tsk_timeout(input int FINISH);
  begin
    #FINISH $display("\nTimeout...\n\nDUT is considered\tP A S S E D\n");
            $finish;
  end
endtask

//
