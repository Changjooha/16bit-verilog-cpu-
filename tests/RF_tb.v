`timescale 1ns / 1ps

module RF_tb;

    reg [1:0] addr1;
    reg [1:0] addr2;
    reg [1:0] addr3;

    reg [15:0] data3;

    reg write;
    reg clk;
    reg reset;

    wire [15:0] data1;
    wire [15:0] data2;

    integer passed;
    integer failed;


    RF dut (
        .addr1(addr1),
        .addr2(addr2),
        .addr3(addr3),

        .data3(data3),

        .write(write),
        .clk(clk),
        .reset(reset),

        .data1(data1),
        .data2(data2)
    );


    // 10 ns clock
    always #5 clk = ~clk;


    task check_read;
        input [8*32-1:0] name;

        input [1:0] read_addr1;
        input [1:0] read_addr2;

        input [15:0] expected1;
        input [15:0] expected2;

        begin

            addr1 = read_addr1;
            addr2 = read_addr2;

            // Asynchronous read: no clock required
            #1;

            if ((data1 === expected1) &&
                (data2 === expected2)) begin

                $display("[PASS] %s", name);
                passed = passed + 1;

            end
            else begin

                $display("[FAIL] %s", name);

                $display(
                    "       Expected data1=%h data2=%h",
                    expected1,
                    expected2
                );

                $display(
                    "       Actual   data1=%h data2=%h",
                    data1,
                    data2
                );

                failed = failed + 1;

            end
        end
    endtask


    task write_register;

        input [1:0] address;
        input [15:0] value;

        begin

            addr3 = address;
            data3 = value;
            write = 1'b1;

            // Write occurs here
            @(posedge clk);
            #1;

            write = 1'b0;

        end

    endtask


    initial begin

        clk = 0;
        reset = 0;
        write = 0;

        addr1 = 0;
        addr2 = 0;
        addr3 = 0;
        data3 = 0;

        passed = 0;
        failed = 0;


        // ------------------------------------------------
        // Reset
        // ------------------------------------------------

        reset = 1'b1;

        @(posedge clk);
        #1;

        reset = 1'b0;

        check_read(
            "Reset R0 / R1",
            2'd0,
            2'd1,
            16'h0000,
            16'h0000
        );

        check_read(
            "Reset R2 / R3",
            2'd2,
            2'd3,
            16'h0000,
            16'h0000
        );


        // ------------------------------------------------
        // Register writes
        // ------------------------------------------------

        write_register(
            2'd0,
            16'h1234
        );

        check_read(
            "Write R0",
            2'd0,
            2'd1,
            16'h1234,
            16'h0000
        );


        write_register(
            2'd1,
            16'hABCD
        );

        check_read(
            "Write R1",
            2'd0,
            2'd1,
            16'h1234,
            16'hABCD
        );


        write_register(
            2'd2,
            16'h5678
        );

        write_register(
            2'd3,
            16'hDEAD
        );


        check_read(
            "Read R2 / R3",
            2'd2,
            2'd3,
            16'h5678,
            16'hDEAD
        );


        // ------------------------------------------------
        // Asynchronous read test
        // ------------------------------------------------

        addr1 = 2'd3;
        addr2 = 2'd0;

        #1;

        if ((data1 === 16'hDEAD) &&
            (data2 === 16'h1234)) begin

            $display(
                "[PASS] Asynchronous read"
            );

            passed = passed + 1;

        end
        else begin

            $display(
                "[FAIL] Asynchronous read"
            );

            failed = failed + 1;

        end


        // ------------------------------------------------
        // Write disabled test
        // ------------------------------------------------

        addr3 = 2'd0;
        data3 = 16'hFFFF;

        write = 1'b0;

        @(posedge clk);
        #1;

        check_read(
            "Write disabled",
            2'd0,
            2'd1,
            16'h1234,
            16'hABCD
        );


        // ------------------------------------------------
        // Summary
        // ------------------------------------------------

        $display("");
        $display("==============================");
        $display("REGISTER FILE TEST SUMMARY");
        $display("==============================");
        $display("Passed : %0d", passed);
        $display("Failed : %0d", failed);

        if (failed == 0)
            $display("ALL RF TESTS PASSED");
        else
            $display("SOME RF TESTS FAILED");

        $display("==============================");

        $finish;

    end

endmodule
