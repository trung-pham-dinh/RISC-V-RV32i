// TASK: Clock Generator
task tsk_clock_gen(ref logic i_clk);
  begin
    i_clk = 1'b1;
    forever #10 i_clk = !i_clk;
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
