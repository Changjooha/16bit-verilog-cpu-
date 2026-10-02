`timescale 1ns / 1ps 
`define WORD_SIZE 16

// 16-bit educational CPU
// Supported instructions: ADD, ADI, LHI, JMP, WWD

module cpu (
    output readM,
    output [`WORD_SIZE-1:0] address,
    inout  [`WORD_SIZE-1:0] data,
    input  inputReady,
    input  reset_n,
    input  clk,

    output [`WORD_SIZE-1:0] num_inst,
    output [`WORD_SIZE-1:0] output_port
);

    // Processor state
    reg [`WORD_SIZE-1:0] pc;
    reg [`WORD_SIZE-1:0] num_inst_reg;
    reg [`WORD_SIZE-1:0] output_port_reg;

    // Four 16-bit general-purpose registers
    reg [`WORD_SIZE-1:0] regfile [0:3];

    // Instruction register
    reg [`WORD_SIZE-1:0] instruction;
    reg instruction_valid;

    // Decoded instruction fields
    wire [3:0] opcode;
    wire [1:0] rs;
    wire [1:0] rt;
    wire [1:0] rd;
    wire [5:0] func;
    wire [7:0] imm;
    wire [11:0] target;

    // Combinational control signals
    reg [`WORD_SIZE-1:0] next_pc;
    reg [`WORD_SIZE-1:0] write_data;
    reg [1:0] write_addr;
    reg write_enable;

    reg output_enable;
    reg [`WORD_SIZE-1:0] next_output_port;

    // Memory interface
    assign readM = 1'b1;
    assign address = pc;

    // The memory drives the data bus during reads.
    assign data = {`WORD_SIZE{1'bz}};

    assign num_inst = num_inst_reg;
    assign output_port = output_port_reg;

    // Instruction decoding
    assign opcode = instruction[15:12];
    assign rs     = instruction[11:10];
    assign rt     = instruction[9:8];
    assign rd     = instruction[7:6];
    assign func   = instruction[5:0];

    assign imm    = instruction[7:0];
    assign target = instruction[11:0];

    // Latch an instruction when memory signals that data is ready.
    always @(posedge inputReady or negedge reset_n) begin
        if (!reset_n) begin
            instruction <= 16'h0000;
            instruction_valid <= 1'b0;
        end
        else begin
            instruction <= data;
            instruction_valid <= 1'b1;
        end
    end

    // Datapath and control logic
    always @(*) begin

        // Default behavior
        next_pc = pc + 1;

        write_enable = 1'b0;
        write_addr = 2'b00;
        write_data = 16'h0000;

        output_enable = 1'b0;
        next_output_port = output_port_reg;

        case (opcode)

            // ADI: rt <- rs + sign-extended immediate
            4'h4: begin
                write_enable = 1'b1;
                write_addr = rt;

                write_data =
                    regfile[rs] +
                    {{8{imm[7]}}, imm};
            end

            // LHI: rt <- immediate << 8
            4'h6: begin
                write_enable = 1'b1;
                write_addr = rt;

                write_data = {imm, 8'h00};
            end

            // JMP
            4'h9: begin
                next_pc = {pc[15:12], target};
            end

            // R-type instruction
            4'hF: begin

                // ADD
                if (func == 6'd0) begin
                    write_enable = 1'b1;
                    write_addr = rd;

                    write_data =
                        regfile[rs] +
                        regfile[rt];
                end

                // WWD
                else if (func == 6'd28) begin
                    output_enable = 1'b1;
                    next_output_port = regfile[rs];
                end
            end

            default: begin
            end

        endcase
    end

    // Sequential processor state update
    always @(posedge clk or negedge reset_n) begin

        if (!reset_n) begin

            pc <= 16'h0000;
            num_inst_reg <= 16'h0000;
            output_port_reg <= 16'h0000;

            regfile[0] <= 16'h0000;
            regfile[1] <= 16'h0000;
            regfile[2] <= 16'h0000;
            regfile[3] <= 16'h0000;

        end
        else if (instruction_valid) begin

            pc <= next_pc;

            num_inst_reg <=
                num_inst_reg + 1'b1;

            if (write_enable) begin
                regfile[write_addr] <= write_data;
            end

            if (output_enable) begin
                output_port_reg <= next_output_port;
            end
        end
    end

endmodule
