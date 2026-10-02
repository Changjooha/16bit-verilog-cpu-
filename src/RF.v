`timescale 100ps / 100ps

module RF(
    input [1:0] addr1,
    input [1:0] addr2,
    input [1:0] addr3,

    input [15:0] data3,

    input write,
    input clk,
    input reset,

    output reg [15:0] data1,
    output reg [15:0] data2
);

    reg [15:0] regfile [0:3];

    // Asynchronous read
    always @(*) begin
        data1 = regfile[addr1];
        data2 = regfile[addr2];
    end

    // Synchronous write/reset
    always @(posedge clk) begin

        if (reset) begin
            regfile[0] <= 16'h0000;
            regfile[1] <= 16'h0000;
            regfile[2] <= 16'h0000;
            regfile[3] <= 16'h0000;
        end

        else if (write) begin
            regfile[addr3] <= data3;
        end
    end

endmodule
