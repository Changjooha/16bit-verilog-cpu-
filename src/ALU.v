`timescale 100ps / 100ps

module ALU(
    input [15:0] A,
    input [15:0] B,
    input Cin,
    input [3:0] OP,

    output reg Cout,
    output reg [15:0] C
);

    reg [16:0] temp;

    always @(*) begin

        C = 16'h0000;
        Cout = 1'b0;
        temp = 17'h00000;

        case (OP)

            // ADD
            4'b0000: begin
                temp =
                    {1'b0, A} +
                    {1'b0, B} +
                    Cin;

                C = temp[15:0];
                Cout = temp[16];
            end

            // SUB
            // C = A - (B + Cin)
            4'b0001: begin
                temp = {1'b0, B} + Cin;

                C = A - temp[15:0];

                // Borrow
                Cout = ({1'b0, A} < temp);
            end

            // ID
            4'b0010: begin
                C = A;
            end

            // NAND
            4'b0011: begin
                C = ~(A & B);
            end

            // NOR
            4'b0100: begin
                C = ~(A | B);
            end

            // XNOR
            4'b0101: begin
                C = ~(A ^ B);
            end

            // NOT
            4'b0110: begin
                C = ~A;
            end

            // AND
            4'b0111: begin
                C = A & B;
            end

            // OR
            4'b1000: begin
                C = A | B;
            end

            // XOR
            4'b1001: begin
                C = A ^ B;
            end

            // Logical Right Shift
            4'b1010: begin
                C = A >> 1;
            end

            // Arithmetic Right Shift
            4'b1011: begin
                C = $signed(A) >>> 1;
            end

            // Rotate Right
            4'b1100: begin
                C = {A[0], A[15:1]};
            end

            // Logical Left Shift
            4'b1101: begin
                C = A << 1;
            end

            // Arithmetic Left Shift
            4'b1110: begin
                C = $signed(A) <<< 1;
            end

            // Rotate Left
            4'b1111: begin
                C = {A[14:0], A[15]};
            end

            default: begin
                C = 16'h0000;
                Cout = 1'b0;
            end

        endcase
    end

endmodule
