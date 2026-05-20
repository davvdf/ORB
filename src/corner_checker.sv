module corner_checker
#(
    parameter THRESHOLD = 10,
    parameter DATA_WIDTH = 8,
    parameter CIRCUMFERENCE = 16,
    parameter CONTIGUOUS_PIXELS = 9
)
(
    input logic [DATA_WIDTH-1:0] candidate,
    input logic [CIRCUMFERENCE-1:0][DATA_WIDTH-1:0] adjacent,
    output logic is_corner
);


wire [DATA_WIDTH:0] thresh_dark_tmp = {1'b1, candidate} - THRESHOLD; 
wire [DATA_WIDTH:0] thresh_light_tmp = {1'b0, candidate} + THRESHOLD;

wire [DATA_WIDTH-1:0] thresh_dark = {DATA_WIDTH{thresh_dark_tmp[DATA_WIDTH]}} & thresh_dark_tmp[DATA_WIDTH-1:0];
wire [DATA_WIDTH-1:0] thresh_light = {DATA_WIDTH{thresh_light_tmp[DATA_WIDTH]}} | thresh_light_tmp[DATA_WIDTH-1:0];


wire [CIRCUMFERENCE-1:0] darker;
wire [CIRCUMFERENCE-1:0] lighter;
for (genvar i = 0; i < CIRCUMFERENCE; i++) begin: hello2
    assign darker[i] = adjacent[i] < thresh_dark;
    assign lighter[i] = adjacent[i] > thresh_light;
end

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
