`timescale 100ps / 100ps

module ALU_tb;

    reg  [15:0] A;
    reg  [15:0] B;
    reg         Cin;
    reg  [3:0]  OP;

    wire [15:0] C;
    wire        Cout;

    integer passed;
    integer failed;

    // DUT: Device Under Test
    ALU dut (
        .A(A),
        .B(B),
        .Cin(Cin),
        .OP(OP),
        .Cout(Cout),
        .C(C)
    );

    task check;
        input [8*32-1:0] name;
        input [15:0] test_A;
        input [15:0] test_B;
        input test_Cin;
        input [3:0] test_OP;
        input [15:0] expected_C;
        input expected_Cout;

        begin
            A   = test_A;
            B   = test_B;
            Cin = test_Cin;
            OP  = test_OP;

            #1;

            if ((C === expected_C) &&
                (Cout === expected_Cout)) begin

                $display("[PASS] %s", name);
                passed = passed + 1;

            end
            else begin

                $display("[FAIL] %s", name);
                $display(
                    "       A=%h B=%h Cin=%b OP=%b",
                    A, B, Cin, OP
                );

                $display(
                    "       Expected C=%h Cout=%b",
                    expected_C,
                    expected_Cout
                );

                $display(
                    "       Actual   C=%h Cout=%b",
                    C,
                    Cout
                );

                failed = failed + 1;
            end
        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        A   = 0;
        B   = 0;
        Cin = 0;
        OP  = 0;

        // ------------------------------------------------
        // Arithmetic
        // ------------------------------------------------

        check(
            "ADD basic",
            16'h0002,
            16'h0003,
            1'b0,
            4'b0000,
            16'h0005,
            1'b0
        );

        check(
            "ADD carry",
            16'hFFFF,
            16'h0001,
            1'b0,
            4'b0000,
            16'h0000,
            1'b1
        );

        check(
            "ADD with Cin",
            16'h0002,
            16'h0003,
            1'b1,
            4'b0000,
            16'h0006,
            1'b0
        );


        check(
            "SUB basic",
            16'h0005,
            16'h0003,
            1'b0,
            4'b0001,
            16'h0002,
            1'b0
        );

        check(
            "SUB borrow",
            16'h0000,
            16'h0001,
            1'b0,
            4'b0001,
            16'hFFFF,
            1'b1
        );

        check(
            "SUB with Cin",
            16'h0005,
            16'h0003,
            1'b1,
            4'b0001,
            16'h0001,
            1'b0
        );


        // ------------------------------------------------
        // Boolean
        // ------------------------------------------------

        check(
            "ID",
            16'hABCD,
            16'h0000,
            1'b0,
            4'b0010,
            16'hABCD,
            1'b0
        );

        check(
            "NAND",
            16'hFFFF,
            16'h0F0F,
            1'b0,
            4'b0011,
            16'hF0F0,
            1'b0
        );

        check(
            "NOR",
            16'h00FF,
            16'h0F00,
            1'b0,
            4'b0100,
            16'hF000,
            1'b0
        );

        check(
            "XNOR",
            16'hAAAA,
            16'h5555,
            1'b0,
            4'b0101,
            16'h0000,
            1'b0
        );

        check(
            "NOT",
            16'h1234,
            16'h0000,
            1'b0,
            4'b0110,
            16'hEDCB,
            1'b0
        );

        check(
            "AND",
            16'hF0F0,
            16'h0FF0,
            1'b0,
            4'b0111,
            16'h00F0,
            1'b0
        );

        check(
            "OR",
            16'hF000,
            16'h00FF,
            1'b0,
            4'b1000,
            16'hF0FF,
            1'b0
        );

        check(
            "XOR",
            16'hAAAA,
            16'h5555,
            1'b0,
            4'b1001,
            16'hFFFF,
            1'b0
        );


        // ------------------------------------------------
        // Shift / Rotate
        // ------------------------------------------------

        check(
            "LRS",
            16'h8001,
            16'h0000,
            1'b0,
            4'b1010,
            16'h4000,
            1'b0
        );

        check(
            "ARS positive",
            16'h7000,
            16'h0000,
            1'b0,
            4'b1011,
            16'h3800,
            1'b0
        );

        check(
            "ARS negative",
            16'h8000,
            16'h0000,
            1'b0,
            4'b1011,
            16'hC000,
            1'b0
        );

        check(
            "Rotate Right",
            16'h0001,
            16'h0000,
            1'b0,
            4'b1100,
            16'h8000,
            1'b0
        );

        check(
            "LLS",
            16'h4001,
            16'h0000,
            1'b0,
            4'b1101,
            16'h8002,
            1'b0
        );

        check(
            "ALS",
            16'h4001,
            16'h0000,
            1'b0,
            4'b1110,
            16'h8002,
            1'b0
        );

        check(
            "Rotate Left",
            16'h8001,
            16'h0000,
            1'b0,
            4'b1111,
            16'h0003,
            1'b0
        );


        // ------------------------------------------------
        // Summary
        // ------------------------------------------------

        $display("");
        $display("==============================");
        $display("ALU TEST SUMMARY");
        $display("==============================");
        $display("Passed : %0d", passed);
        $display("Failed : %0d", failed);

        if (failed == 0)
            $display("ALL ALU TESTS PASSED");
        else
            $display("SOME ALU TESTS FAILED");

        $display("==============================");

        $finish;

    end

endmodule
