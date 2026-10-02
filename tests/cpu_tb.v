`timescale 1ns / 1ps

`define WORD_SIZE 16

module cpu_tb;

    wire readM;

    wire [`WORD_SIZE-1:0] address;

    wire [`WORD_SIZE-1:0] data;

    reg inputReady;
    reg reset_n;
    reg clk;

    wire [`WORD_SIZE-1:0] num_inst;

    wire [`WORD_SIZE-1:0] output_port;


    // Testbench drives the memory data bus.
    reg [`WORD_SIZE-1:0] memory_data;

    assign data = memory_data;


    integer passed;
    integer failed;


    cpu dut (
        .readM(readM),
        .address(address),
        .data(data),

        .inputReady(inputReady),
        .reset_n(reset_n),
        .clk(clk),

        .num_inst(num_inst),
        .output_port(output_port)
    );


    // 10 ns clock
    always #5 clk = ~clk;


    // ----------------------------------------------------
    // Load instruction before the next positive clock edge.
    // CPU latches instruction on posedge inputReady.
    // ----------------------------------------------------

    task execute_instruction;

        input [15:0] instruction;

        begin

            @(negedge clk);

            memory_data = instruction;

            #1;
            inputReady = 1'b1;

            #1;
            inputReady = 1'b0;

            // CPU executes instruction here.
            @(posedge clk);

            #1;

        end

    endtask


    task check16;

        input [8*32-1:0] name;

        input [15:0] actual;
        input [15:0] expected;

        begin

            if (actual === expected) begin

                $display(
                    "[PASS] %s : %h",
                    name,
                    actual
                );

                passed = passed + 1;

            end
            else begin

                $display(
                    "[FAIL] %s",
                    name
                );

                $display(
                    "       Expected : %h",
                    expected
                );

                $display(
                    "       Actual   : %h",
                    actual
                );

                failed = failed + 1;

            end

        end

    endtask


    initial begin

        clk = 0;

        inputReady = 0;

        reset_n = 1;

        memory_data = 16'h0000;

        passed = 0;
        failed = 0;


        // ------------------------------------------------
        // RESET
        // ------------------------------------------------

        #2;

        reset_n = 0;

        #2;

        reset_n = 1;

        #1;


        check16(
            "Reset PC",
            address,
            16'h0000
        );

        check16(
            "Reset instruction count",
            num_inst,
            16'h0000
        );

        check16(
            "Reset output port",
            output_port,
            16'h0000
        );


        // =================================================
        // 1. LHI R0, 0x12
        //
        // R0 <- 0x1200
        //
        // 0110 | rt=00 | imm=00010010
        //
        // 0x6012
        // =================================================

        execute_instruction(
            16'h6012
        );

        check16(
            "PC after LHI",
            address,
            16'h0001
        );

        check16(
            "Instruction count after LHI",
            num_inst,
            16'h0001
        );


        // =================================================
        // 2. WWD R0
        //
        // output_port <- R0
        //
        // opcode = F
        // rs = 00
        // func = 28 = 0x1C
        //
        // 0xF01C
        // =================================================

        execute_instruction(
            16'hF01C
        );

        check16(
            "WWD R0",
            output_port,
            16'h1200
        );


        // =================================================
        // 3. ADI R1, R0, 5
        //
        // R1 <- R0 + 5
        //    <- 0x1200 + 5
        //    <- 0x1205
        //
        // opcode = 4
        // rs = 0
        // rt = 1
        // imm = 5
        //
        // 0x4105
        // =================================================

        execute_instruction(
            16'h4105
        );


        // =================================================
        // 4. WWD R1
        //
        // Expected output = 0x1205
        // =================================================

        execute_instruction(
            16'hF41C
        );

        check16(
            "ADI positive immediate",
            output_port,
            16'h1205
        );


        // =================================================
        // 5. ADI R2, R1, -1
        //
        // R2 <- R1 - 1
        //    <- 0x1204
        //
        // immediate = 0xFF
        // sign extended -> 0xFFFF
        //
        // opcode = 4
        // rs = 1
        // rt = 2
        //
        // 0x46FF
        // =================================================

        execute_instruction(
            16'h46FF
        );


        // =================================================
        // 6. ADD R3, R1, R2
        //
        // R3 <- R1 + R2
        //
        // 0x1205
        // +
        // 0x1204
        // --------
        // 0x2409
        //
        // opcode = F
        // rs = 1
        // rt = 2
        // rd = 3
        // func = 0
        //
        // 0xF6C0
        // =================================================

        execute_instruction(
            16'hF6C0
        );


        // =================================================
        // 7. WWD R3
        // =================================================

        execute_instruction(
            16'hFC1C
        );

        check16(
            "ADD result",
            output_port,
            16'h2409
        );


        // =================================================
        // 8. JMP 0x00A
        //
        // PC before JMP = 7
        //
        // next_pc =
        // {pc[15:12], 12'h00A}
        //
        // expected PC = 0x000A
        //
        // 0x900A
        // =================================================

        execute_instruction(
            16'h900A
        );

        check16(
            "JMP target",
            address,
            16'h000A
        );


        check16(
            "Final instruction count",
            num_inst,
            16'h0008
        );


        // ------------------------------------------------
        // Summary
        // ------------------------------------------------

        $display("");
        $display("==============================");
        $display("CPU TEST SUMMARY");
        $display("==============================");

        $display(
            "Passed : %0d",
            passed
        );

        $display(
            "Failed : %0d",
            failed
        );

        if (failed == 0)
            $display(
                "ALL CPU TESTS PASSED"
            );
        else
            $display(
                "SOME CPU TESTS FAILED"
            );

        $display("==============================");

        $finish;

    end

endmodule
