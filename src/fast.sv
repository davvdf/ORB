module corners
#(
    parameter byte unsigned THRESHOLD = 10
)
(
    input [7:0] candidate,
    input [15:0][7:0] adjacent,
    output corner
);


wire [8:0] thresh_dark_tmp = {1'b1, candidate} - THRESHOLD; 
wire [8:0] thresh_light_tmp = {1'b0, candidate} + THRESHOLD;

wire [7:0] thresh_dark = {8{thresh_dark_tmp[8]}} & thresh_dark_tmp[7:0];
wire [7:0] thresh_light = {8{thresh_light_tmp[8]}} | thresh_light_tmp[7:0];




wire [15:0] darker;
wire [15:0] lighter;
genvar i;
for (i = 0; i < 16; i++) begin: hello2
    assign darker[i] = adjacent[i] > thresh_dark;
    assign lighter[i] = adjacent[i] > thresh_light;
end

wire [31:0] a = { darker, darker };
wire [31:0] b = { lighter, lighter };
function check_corner();
    check_corner = 1'b0;
    for (int i = 0; i < 16; i++ ) begin: hello3
        if ( &a[i +: 9] || &b[i +: 9] ) begin
            check_corner = 1'b1;
        end
    end
endfunction

assign corner = check_corner();

endmodule
