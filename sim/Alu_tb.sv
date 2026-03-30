`timescale 1ns/10ps

    parameter ADD = 3'b000;
    parameter SUB = 3'b001;
    parameter INC = 3'b010;
    parameter CAS = 3'b011;
    parameter BIT_AND = 3'b100;
    parameter BIT_OR = 3'b101;
    parameter BIT_NOT = 3'b110;
    parameter BIT_XOR = 3'b111;

module ALU_controller_tb;

    logic operate, clk, reset, load_NIR;
    logic [11:0] opcode;
    logic CAS_successful, carry_out, negative;
    logic [7:0] anode;
    logic [6:0] cathodes;

    ALU_controller UUT(
        .operate_in(operate),
        .clk(clk),
        .reset(reset),
        .load_NIR(load_NIR),
        .opcode(opcode),
        .CAS_successful(CAS_successful),
        .carry_out(carry_out),
        .negative(negative),
        .anode(anode),
        .cathodes(cathodes)
    );    
    
    task driver(input logic [11:0] op_code = $random);
        opcode <= op_code;
        load_NIR <= #1 1;
        @(posedge clk);
        operate <= #1 1;
        load_NIR <= #1 0;
        @(posedge clk);
        operate <= #1 0;
    endtask

    task monitor;
        logic [11:0] M_regOpcode;
        logic [31:0] M_regA, M_regB, M_expected, dst_output, CAS_old_value;
        logic M_carry_out, M_negative, M_CAS_successful;

        M_regOpcode = UUT.CIR;
        M_regA = UUT.reg_file[UUT.CIR[8:6]];
        M_regB = UUT.reg_file[UUT.CIR[5:3]];
        CAS_old_value = UUT.reg_file[UUT.CIR[2:0]];

        M_carry_out = 0; 
        M_negative = 0;
        M_CAS_successful = 0;
        case(UUT.CIR[11:9])
            ADD: {M_carry_out, M_expected} = M_regA + M_regB;
            SUB: begin
                    M_negative = (M_regA < M_regB);
                    M_expected = M_regA - M_regB;
                    if (M_negative)
                        M_expected = ~M_expected + 1;
                end
            INC: {M_carry_out, M_expected} = M_regA + 1;
            CAS: begin
                    M_CAS_successful = UUT.reg_file[UUT.CIR[2:0]] == M_regA;
                    M_expected = M_regB;
                end
            BIT_AND: M_expected = M_regA & M_regB;
            BIT_OR: M_expected = M_regA | M_regB;
            BIT_NOT: M_expected = ~M_regA;
            BIT_XOR: M_expected = M_regA ^ M_regB;
        endcase

        repeat(2) @(posedge clk);
        dst_output = UUT.reg_file[M_regOpcode[2:0]];


        case(M_regOpcode[11:9])
            CAS: begin
                if (CAS_successful == M_CAS_successful)begin
                    if(M_CAS_successful == 1 && dst_output == M_expected) begin
                        $display("PASS: Op = %d, A = %d, B = %d", M_regOpcode[11:9], M_regA, M_regB);
                        $display("          Got = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", dst_output, M_carry_out, M_negative, M_CAS_successful);            
                    end
                    else if (M_CAS_successful == 0 && dst_output == CAS_old_value) begin
                        $display("PASS: Op = %d, A = %d, B = %d", M_regOpcode[11:9], M_regA, M_regB);
                        $display("          Got = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", dst_output, M_carry_out, M_negative, M_CAS_successful);
                    end
                    else begin
                        $display("FAIL: Op = %d, A = %d, B = %d", M_regOpcode[11:9], M_regA, M_regB);
                        $display("          Expected = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", M_expected, M_carry_out, M_negative, M_CAS_successful);
                        $display("          Got = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", dst_output, carry_out, negative, CAS_successful);
                    end
                end
            end
            default: begin
                if ((M_expected == dst_output) && (carry_out == M_carry_out) && (negative == M_negative) && (CAS_successful == M_CAS_successful)) begin
                    $display("PASS: Op = %d, A = %d, B = %d", M_regOpcode[11:9], M_regA, M_regB);
                    $display("          Got = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", dst_output, M_carry_out, M_negative, M_CAS_successful);
                end
                else begin
                    $display("FAIL: Op = %d, A = %d, B = %d", M_regOpcode[11:9], M_regA, M_regB);
                    $display("          Expected = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", M_expected, M_carry_out, M_negative, M_CAS_successful);
                    $display("          Got = %d, Carry Out = %b, Negative = %b, CAS Successful = %b\n", dst_output, carry_out, negative, CAS_successful);
                end
            end
        endcase
        
            
    endtask

    task Resetting;
        reset = 1;
        @(posedge clk);
        reset = #1 0;
    endtask

    task random_test(int tests);
        for (int i = 0; i < tests; i++) begin
            driver();
            monitor();
        end
    endtask

    task direct_test(input logic [11:0] new_opcode);
        driver(new_opcode);
        monitor();
    endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        Resetting();
        random_test(1);
    end

endmodule