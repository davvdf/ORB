module sobel
#(
    parameter DATA_WIDTH = 8,
    parameter WINDOW_SIZE = 7
)
(
    input logic  [DATA_WIDTH-1:0][WINDOW_SIZE-1:0][WINDOW_SIZE-1:0] window,
    output logic [DATA_WIDTH-1:0] gradient
);

localparam int KERNEL_SIZE = 3;
localparam int MAX_DATA_VAL = $pow(2, DATA_WIDTH) - 1;

localparam int MAX_MULT_VAL = MAX_DATA_VAL * -2;
localparam int MULT_BITWIDTH = $clog2(MAX_DATA_VAL*2) + 1; // to store -511 we need 10 bits 
//localparam int KERNEL_ELEMENTS  = $pow(KERNEL_SIZE, 2);

localparam [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][2:0] gradient_x = '{'{-3'd1, 3'd0, 3'd1}, '{-3'd2, 3'd0, 3'd2}, '{-3'd1, 3'd0, 3'd1}};
localparam [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][2:0] gradient_y = '{'{-3'd1, -3'd2, -3'd1}, '{3'd0, 3'd0, 3'd0}, '{3'd1, 3'd2, 3'd1}};

// localparam int tot_Size = KERNEL_SIZE * KERNEL_ELEMENTS;
// localparam [tot_Size-1:0] gradient_xx = {-3'd1, 3'd0, 3'd1, -3'd2, 3'd0, 3'd2, -3'd1, 3'd0, 3'd1};


logic [KERNEL_SIZE-1:0][KERNEL_SIZE-1:0][MULT_BITWIDTH-1:0] patch;

for (genvar i = 0; i < KERNEL_SIZE; ++i) begin
     
    for (genvar j = 0; j < KERNEL_SIZE; ++j) begin
        
    end
    
end



endmodule