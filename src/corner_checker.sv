/** Corner candidate finder as a part of FAST algorithm */
module corner_checker
#(
    /** Threshold: dividng threshold to determine if contiguous pixels are similar 
      * brightness level
      */
    parameter THRESHOLD = 6,
    parameter DATA_WIDTH = 8,
    parameter CIRCUMFERENCE = 16,
    parameter CONTIGUOUS_PIXELS = 9
)
(
    /** Candidate pixel to center checking around */
    input logic [DATA_WIDTH-1:0] candidate,
    /** Contiguous pixels to check brightness against candidate pixel*/
    input logic [CIRCUMFERENCE-1:0][DATA_WIDTH-1:0] adjacent,
    output logic is_corner
);

/** Calculate min/max intensity to compare against adjacent pixels 
  * Over/underflow guarding prevents flipping of extreme brightness 
  * values to the other end of the spectrum
  * i.e. 4 - threshold = 250, which is not the intended behavior
  */
wire [DATA_WIDTH:0] thresh_dark_tmp = {1'b1, candidate} - THRESHOLD; 
wire [DATA_WIDTH:0] thresh_light_tmp = {1'b0, candidate} + THRESHOLD;
wire [DATA_WIDTH-1:0] thresh_dark = {DATA_WIDTH{thresh_dark_tmp[DATA_WIDTH]}} & thresh_dark_tmp[DATA_WIDTH-1:0];
wire [DATA_WIDTH-1:0] thresh_light = {DATA_WIDTH{thresh_light_tmp[DATA_WIDTH]}} | thresh_light_tmp[DATA_WIDTH-1:0];

/** Track whether each adjacent pixel is "darker" or "lighter" than the candidate pixel 
  * (or too close in intensity, denoted by logic 0)
  */
wire [CIRCUMFERENCE-1:0] darker;
wire [CIRCUMFERENCE-1:0] lighter;
for (genvar i = 0; i < CIRCUMFERENCE; i++) begin: hello2
    assign darker[i] = adjacent[i] < thresh_dark;
    assign lighter[i] = adjacent[i] > thresh_light;
end

/** Syntatic sugar to make it easy to perform reduction operation on consecutive pixels 
  * Probably synthesizes to optimal logic idk
  */
wire [CIRCUMFERENCE*2-1:0] a = { darker, darker };
wire [CIRCUMFERENCE*2-1:0] b = { lighter, lighter };

always_comb begin
    is_corner = 1'b0;
    for (int i = 0; i < CIRCUMFERENCE; i++ ) begin: hello3
        if ( &a[i +: CONTIGUOUS_PIXELS] || &b[i +: CONTIGUOUS_PIXELS] ) begin
            is_corner = 1'b1;
        end else begin
            is_corner = is_corner;
        end
    end
end

endmodule
