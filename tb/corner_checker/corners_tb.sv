module corners_tb;
 
  // -------------------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------------------
  localparam byte unsigned THRESHOLD = 10;
  localparam int           RING      = 16;   // pixels in Bresenham ring
  localparam int           ARC       = 9;    // consecutive pixels required
 
  // -------------------------------------------------------------------------
  // DUT ports
  // -------------------------------------------------------------------------
  logic        [7:0]            candidate;
  logic [15:0] [7:0]            adjacent;
  logic                         is_corner;
 
  // -------------------------------------------------------------------------
  // DUT instantiation
  // -------------------------------------------------------------------------
  corner_checker #(
    .THRESHOLD (THRESHOLD)
  ) dut (
    .candidate (candidate),
    .adjacent  (adjacent),
    .is_corner (is_corner)
  );
 
  // =========================================================================
  // Reference model  (CORRECTED FAST algorithm)
  // =========================================================================
  function automatic logic ref_model (
    input logic [7:0]         cand,
    input logic [15:0] [7:0]  adj
  );
    logic [8:0]  td_tmp, tl_tmp;
    logic [7:0]  t_dark, t_light;
    logic [15:0] darker, lighter;
    logic [31:0] a, b;
 
    // Threshold computation (mirrors RTL exactly)
    td_tmp  = {1'b1, cand} - 9'(THRESHOLD);          // clamped-sub
    tl_tmp  = {1'b0, cand} + 9'(THRESHOLD);          // clamped-add
 
    t_dark  = {8{td_tmp[8]}} & td_tmp[7:0];          // 0 when underflow
    t_light = {8{tl_tmp[8]}} | tl_tmp[7:0];          // FF when overflow
 
    // CORRECTED pixel classification
    //   darker : adj[i] < t_dark   (pixel is significantly darker)
    //   lighter: adj[i] > t_light  (pixel is significantly lighter)
    for (int i = 0; i < RING; i++) begin
      darker [i] = adj[i] < t_dark;    // BUG-2 fix: was `>`
      lighter[i] = adj[i] > t_light;
    end
 
    // Doubled ring for circular arc detection
    a = {darker,  darker};
    b = {lighter, lighter};
 
    // Any window of ARC consecutive pixels all on the same side?
    ref_model = 1'b0;
    for (int i = 0; i < RING; i++) begin
      if (&a[i +: ARC] || &b[i +: ARC])
        ref_model = 1'b1;
    end
  endfunction
 
  // =========================================================================
  // Helper: build a uniform 16-pixel array
  // =========================================================================
  function automatic logic [15:0][7:0] all_px (input logic [7:0] val);
    for (int i = 0; i < RING; i++) all_px[i] = val;
  endfunction
 
  // =========================================================================
  // Helper: build a ring with `count` consecutive pixels set to `hot`,
  //         starting at index `start` (wraps), rest set to `base`.
  // =========================================================================
  function automatic logic [15:0][7:0] ring_pat (
    input logic [7:0] hot, base,
    input int         start, count
  );
    for (int i = 0; i < RING; i++)
      ring_pat[i] = (((i - start + RING) % RING) < count) ? hot : base;
  endfunction
 
  // =========================================================================
  // Scoreboard
  // =========================================================================
  int pass_cnt = 0;
  int fail_cnt = 0;
 
  task automatic check (
    input string       tname,
    input logic [7:0]  cand,
    input logic [15:0][7:0] adj,
    input logic        expect_corner  // from reference model
  );
    candidate = cand;
    adjacent  = adj;
    #1;   // combinational settle time
 
    if (is_corner === expect_corner) begin
      $display("  PASS  [%s]  candidate=%3d  is_corner=%b", tname, cand, is_corner);
      pass_cnt++;
    end else begin
      $display("  FAIL  [%s]  candidate=%3d  got=%b  expected=%b",
               tname, cand, is_corner, expect_corner);
      fail_cnt++;
    end
  endtask
 
  // Convenience: auto-compute expected from reference model
  task automatic run (
    input string       tname,
    input logic [7:0]  cand,
    input logic [15:0][7:0] adj
  );
    check(tname, cand, adj, ref_model(cand, adj));
  endtask
 
  // =========================================================================
  // Test stimulus
  // =========================================================================
  initial begin
    $display("============================================================");
    $display(" FAST Corner Detector – Testbench");
    $display(" THRESHOLD = %0d,  ring = %0d px,  required arc = %0d px",
             THRESHOLD, RING, ARC);
    $display("============================================================");
 
    // ------------------------------------------------------------------
    // Group 1: Trivial / uniform rings
    // ------------------------------------------------------------------
    $display("\n-- Group 1: Uniform rings --");
 
    // All pixels identical to candidate → no corner
    run("uniform_same",    8'd128, all_px(8'd128));
 
    // All lighter by just more than threshold → IS a corner
    run("all_lighter",     8'd100, all_px(8'd111));   // 100+10=110; 111>110 ✓
 
    // All darker by just more than threshold → IS a corner
    run("all_darker",      8'd100, all_px(8'd89));    // 100-10=90;  89<90 ✓
 
    // All exactly at light threshold (not strictly >) → NOT a corner
    run("all_at_thresh+",  8'd100, all_px(8'd110));
 
    // All exactly at dark threshold (not strictly <) → NOT a corner
    run("all_at_thresh-",  8'd100, all_px(8'd90));
 
    // ------------------------------------------------------------------
    // Group 2: Exactly ARC=9 consecutive lighter pixels
    // ------------------------------------------------------------------
    $display("\n-- Group 2: Exactly 9 consecutive lighter pixels --");
 
    run("9_lighter_at_0",  8'd100, ring_pat(8'd200, 8'd50, 0,  9));
    run("9_lighter_at_4",  8'd100, ring_pat(8'd200, 8'd50, 4,  9));
    run("9_lighter_at_8",  8'd100, ring_pat(8'd200, 8'd50, 8,  9));
    run("9_lighter_at_12", 8'd100, ring_pat(8'd200, 8'd50, 12, 9));  // wraps
 
    // ------------------------------------------------------------------
    // Group 3: Exactly ARC=9 consecutive darker pixels
    // ------------------------------------------------------------------
    $display("\n-- Group 3: Exactly 9 consecutive darker pixels --");
 
    run("9_darker_at_0",   8'd150, ring_pat(8'd50,  8'd200, 0,  9));
    run("9_darker_at_7",   8'd150, ring_pat(8'd50,  8'd200, 7,  9));
    run("9_darker_at_12",  8'd150, ring_pat(8'd50,  8'd200, 12, 9)); // wraps
 
    // ------------------------------------------------------------------
    // Group 4: Only 8 consecutive – should NOT be a corner
    // ------------------------------------------------------------------
    $display("\n-- Group 4: Only 8 consecutive (not enough) --");
 
    run("8_lighter",       8'd100, ring_pat(8'd200, 8'd50, 0, 8));
    run("8_darker",        8'd150, ring_pat(8'd50,  8'd200, 0, 8));
 
    // ------------------------------------------------------------------
    // Group 5: 10 consecutive (> required) – still IS a corner
    // ------------------------------------------------------------------
    $display("\n-- Group 5: 10 consecutive lighter --");
 
    run("10_lighter_at_0", 8'd100, ring_pat(8'd200, 8'd50, 0, 10));
    run("10_lighter_wrap", 8'd100, ring_pat(8'd200, 8'd50, 11, 10));
 
    // ------------------------------------------------------------------
    // Group 6: Alternating – never 9 consecutive
    // ------------------------------------------------------------------
    $display("\n-- Group 6: Alternating bright / dark --");
    begin
      logic [15:0][7:0] alt;
      for (int i = 0; i < RING; i++)
        alt[i] = (i[0]) ? 8'd200 : 8'd50;
      run("alternating",   8'd128, alt);
    end
 
    // ------------------------------------------------------------------
    // Group 7: Threshold clamping edge cases
    // ------------------------------------------------------------------
    $display("\n-- Group 7: Threshold clamping --");
 
    // candidate very low – dark threshold clamps to 0
    run("cand_5_all_0",    8'd5,   all_px(8'd0));     // 0 not < 0; not darker
    run("cand_5_all_200",  8'd5,   all_px(8'd200));   // 200 > 15 → lighter
 
    // candidate very high – light threshold clamps to 255
    run("cand_250_all_255",8'd250, all_px(8'd255));   // 255 not > 255; not lighter
    run("cand_250_all_0",  8'd250, all_px(8'd0));     // 0 < 240 → darker
 
    // candidate = 0
    run("cand_0_all_50",   8'd0,   all_px(8'd50));    // lighter? 50 > 10 → yes
    run("cand_0_all_0",    8'd0,   all_px(8'd0));     // not lighter, not darker
 
    // candidate = 255
    run("cand_255_all_200",8'd255, all_px(8'd200));   // darker? 200 < 245 → yes
    run("cand_255_all_255",8'd255, all_px(8'd255));   // not darker, not lighter
 
    // ------------------------------------------------------------------
    // Group 8: Mixed arcs – lighter arc and darker arc, neither >= 9
    // ------------------------------------------------------------------
    $display("\n-- Group 8: Split arcs (5 lighter + 5 darker, not adjacent) --");
    begin
      logic [15:0][7:0] split;
      for (int i = 0; i < RING; i++) begin
        if      (i < 5)  split[i] = 8'd200;  // 5 lighter
        else if (i < 8)  split[i] = 8'd128;  // 3 neutral
        else if (i < 13) split[i] = 8'd50;   // 5 darker
        else             split[i] = 8'd128;  // neutral
      end
      run("split_5_5",     8'd128, split);
    end
 
    // ------------------------------------------------------------------
    // Group 9: Random-style stress
    // ------------------------------------------------------------------
    $display("\n-- Group 9: Pseudo-random stress (16 cases) --");
    begin
      logic [15:0][7:0] pix;
      logic [7:0] cand;
      logic [63:0] lfsr = 64'hDEAD_BEEF_CAFE_1234;
 
      repeat (16) begin
        // 64-bit Fibonacci LFSR for cheap pseudo-random values
        lfsr = {lfsr[62:0], lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59]};
        cand = lfsr[7:0];
        for (int i = 0; i < RING; i++) begin
          lfsr = {lfsr[62:0], lfsr[63] ^ lfsr[62] ^ lfsr[60] ^ lfsr[59]};
          pix[i] = lfsr[7:0];
        end
        run($sformatf("random_cand_%3d", cand), cand, pix);
      end
    end
 
    // ------------------------------------------------------------------
    // Summary
    // ------------------------------------------------------------------
    $display("\n============================================================");
    $display(" Results: %0d passed,  %0d failed  (total %0d)",
             pass_cnt, fail_cnt, pass_cnt + fail_cnt);
    if (fail_cnt == 0)
      $display(" All tests PASSED.");
    else begin
      $display(" FAILURES detected – see FAIL lines above.");
      $display(" Note: BUG-1 (is_corner never set to 1) will cause most");
      $display("       corner cases to report FAIL against the ref model.");
    end
    $display("============================================================");
    $finish;
  end
    
    initial begin
  $dumpfile("corners_tb.fst");
  $dumpvars(0, corners_tb);
end
endmodule