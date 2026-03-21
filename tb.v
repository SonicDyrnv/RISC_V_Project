// Testbench
/* I will try to cover all the cases*/
// All the cases checked

`timescale 1ns/1ps

module tb;
    reg clk, rst;
    integer pass, fail;
    
    top dut (.clk(clk), .rst(rst));

    initial clk = 0;
    
    always #5 clk = ~clk;

    task check;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got === exp) begin
                $display("  Yes %-42s got=0x%08h (%0d)", name, got, got);
                pass = pass + 1;
            end else begin
                $display("  Noooo %-42s got=0x%08h (%0d) exp=0x%08h (%0d)", name, got, got, exp, exp);
                fail = fail + 1;
            end
        end
    endtask

    initial begin
        
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        pass = 0; fail = 0;
        rst = 1;
        repeat(4) @(posedge clk);
        rst = 0;
        repeat(300) @(posedge clk);

        $display("Section 1: I-type Instructions");
        check("ADDI  x1=10",                   dut.cpu_inst.rf.r1,  32'd10);
        check("ADDI  x2=6",                    dut.cpu_inst.rf.r2,  32'd6);
        check("ANDI  x3=x1&7=2",               dut.cpu_inst.rf.r3,  32'd2);
        check("ORI   x4=x1|12=14",             dut.cpu_inst.rf.r4,  32'd14);
        check("XORI  x5=x1^5=15",              dut.cpu_inst.rf.r5,  32'd15);
        check("SLTI  x6=(x1<20)=1",            dut.cpu_inst.rf.r6,  32'd1);
        check("SLLI  x7=x1<<2=40",             dut.cpu_inst.rf.r7,  32'd40);
        check("SRLI  x8=x1>>1=5",              dut.cpu_inst.rf.r8,  32'd5);

        $display("Section 2: R-type Instructions");
        check("ADD   x9=x1+x2=16",             dut.cpu_inst.rf.r9,  32'd16);
        check("SUB   x10=x1-x2=4",             dut.cpu_inst.rf.r10, 32'd4);
        check("AND   x11=x1&x2=2",             dut.cpu_inst.rf.r11, 32'd2);
        check("OR    x12=x1|x2=14",            dut.cpu_inst.rf.r12, 32'd14);
        check("XOR   x13=x1^x2=12",            dut.cpu_inst.rf.r13, 32'd12);
        check("SLT   x14=(x2<x1)=1",           dut.cpu_inst.rf.r14, 32'd1);
        check("SLL   x15=x1<<x2=640",          dut.cpu_inst.rf.r15, 32'd640);
        check("SRL   x16=128>>6=2",            dut.cpu_inst.rf.r16, 32'd2);

        $display("Section 2b: SRA / SRAI");
        check("SRA  x31=(-128)>>>6=-2",         dut.cpu_inst.rf.r31, 32'hFFFFFFFE);
        check("SRA  mem[6]=0xFFFFFFFE",          dut.dmem[6],         32'hFFFFFFFE);
        check("SRAI mem[7]=(-128)>>>2=0xFFFFFFE0",dut.dmem[7],       32'hFFFFFFE0);

        $display("Section 3: SW / LW");
        check("SW/LW x18=mem[0]=16",           dut.cpu_inst.rf.r18, 32'd16);
        check("SW/LW x19=mem[1]=4",            dut.cpu_inst.rf.r19, 32'd4);
        check("ADD   x20=x18+x19=20",          dut.cpu_inst.rf.r20, 32'd20);

        $display("Section 4: Load-Use Hazard (Stall)");
        check("SW    mem[2]=99",                dut.dmem[2],         32'd99);
        check("LW    x22=mem[2]=99",            dut.cpu_inst.rf.r22, 32'd99);
        check("ADDI  x23=x22+1=100",           dut.cpu_inst.rf.r23, 32'd100);

        $display("Section 5: BEQ Taken");
        check("x24=0  (ADDI skipped by BEQ)",  dut.cpu_inst.rf.r24, 32'd0);
        check("x25=77 (BEQ branch target)",    dut.cpu_inst.rf.r25, 32'd77);

        $display("Section 6: BEQ Not Taken");
        check("x26=33 (not skipped)",           dut.cpu_inst.rf.r26, 32'd33);
        check("x27=44 (fall through)",          dut.cpu_inst.rf.r27, 32'd44);

        $display("Section 7: JAL");
        check("x28=0x98 (JAL link=PC+4)",       dut.cpu_inst.rf.r28, 32'h00000098);
        check("x29=0    (JAL skipped instr)",   dut.cpu_inst.rf.r29, 32'd0);
        check("x30=22   (JAL target)",          dut.cpu_inst.rf.r30, 32'd22);

        $display("Section 8: BNE Taken/Not Taken");
        check("BNE taken+not: mem[3]=88",       dut.dmem[3],         32'd88);

        $display("Section 9: BLT Taken/Not Taken");
        check("BLT taken+not: mem[4]=55",       dut.dmem[4],         32'd55);

        $display("Section 10: BGE Taken/Not Taken");
        check("BGE taken+not: mem[5]=66",       dut.dmem[5],         32'd66);

        $display("  TOTAL: %0d PASSED,  %0d FAILED", pass, fail);
        if (fail == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED");

        $finish;
    end

endmodule