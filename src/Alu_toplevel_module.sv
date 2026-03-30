`timescale 1ns/10ps

// ===============================================================================
//                                 States
// ===============================================================================
    parameter IDLE = 0;
    parameter LOADED = 1;
    
// ===============================================================================
//                                 Operations
// ===============================================================================
    parameter ADD = 3'b000;
    parameter SUB = 3'b001;
    parameter INC = 3'b010;
    parameter CAS = 3'b011;
    parameter BIT_AND = 3'b100;
    parameter BIT_OR = 3'b101;
    parameter BIT_NOT = 3'b110;
    parameter BIT_XOR = 3'b111;
    
module ALU_controller(
    input logic operate_in, clk, reset, load_NIR,
    input logic [11:0] opcode,
    output logic CAS_successful, carry_out, negative,
    output logic [7:0] anode,
    output logic [6:0] cathodes
    );

    
// ===============================================================================
//                                 Declaring Local signals
// ===============================================================================
    logic load_CIR, store, load_data, current_state, next_state, operate;
    logic [11:0] CIR, NIR;
    logic [5:0] regOpcode;
    logic [31:0] regA, regB;
    logic [31:0] y, mux1, tbstored;
    logic [31:0] reg_file [8];
    
    // initial begin 
    //     repeat(2) @(posedge clk);
    //     $readmemh("mem_file.mem", reg_file);
    // end

    LTPC ltpc(
        .clk(clk),
        .reset(reset),
        .operate_in(operate_in),
        .operate_out(operate)
    );


    display dis(
        .clk(clk),
        .reset(reset),
        .num(tbstored),
        .anode(anode),
        .cathodes(cathodes)
    );
    
// ===============================================================================
//                                 ALU Block
// ===============================================================================

    always_comb begin
    carry_out = 0; 
    negative = 0;
    CAS_successful = 0;
        case(regOpcode[5:3])
            ADD: {carry_out, y} = regA + regB;
            SUB: begin
                    negative = (regA < regB);
                    y = regA - regB;
                    if (negative)
                        y = ~y + 1;

                    // if (negative)
                    //     y = regA + (~regB + 1)
                    // else    
                    //     y = regA - regB
                end
            INC: {carry_out, y} = regA + 1;
            CAS: begin
                    CAS_successful = reg_file[regOpcode[2:0]] == regA;
                    y = regB;
                end
            BIT_AND: y = regA & regB;
            BIT_OR: y = regA | regB;
            BIT_NOT: y = ~regA;
            BIT_XOR: y = regA ^ regB;       
        endcase
    end
// ===============================================================================
//                   Loading data in A, B and Opcode Registers
// ===============================================================================
    
    always_ff @(posedge clk) begin
        if (reset) begin
                regA <= #1 0; regB <= #1 0; regOpcode <= #1 0;
            end
        else if (load_data) begin
            regA <= #1 reg_file[CIR[8:6]]; regB <= #1 reg_file[CIR[5:3]];
            regOpcode <= #1 {CIR[11:9], CIR[2:0]};
        end
    end
// ===============================================================================
//                          Loading data from NIR to CIR
// ===============================================================================

    always_ff @(posedge clk) begin
        if (reset)
            CIR <= #1 0;
        else if (load_CIR)
            CIR <= #1 NIR;
    end
// ===============================================================================
//                 Loading NIR with the user inputted Instructions
// ===============================================================================

    always_ff @(posedge clk) begin
        if (reset)
            NIR <= #1 0;
        else if (load_NIR)
            NIR <= #1 opcode;
    end
    
// ===============================================================================
//                          Storing the Output
// ===============================================================================

    always_comb begin
        if (CAS_successful)
            mux1 = y;
        else
            mux1 = reg_file[CIR[2:0]];

        if (CIR[11:9] == 3'b011)
            tbstored = mux1;
        else
            tbstored = y;
    end

    always_ff @(posedge clk) begin
        if (reset)
            reg_file <= #1 {1,2,3,4,5,6,7,8};
        else if (store)
            reg_file[CIR[2:0]] <= #1 tbstored;
    end
    
// ===============================================================================
//                              Controller FSM

// ===============================================================================
//                             State Register
// ===============================================================================

    always_ff @(posedge clk) begin
        if (reset)
            current_state <= #1 IDLE;
        else
            current_state <= #1 next_state;
    end
    
// ===============================================================================
//                            Next State Logic
// ===============================================================================

    always_comb begin
        case(current_state)
            IDLE: if (operate) next_state = LOADED; else next_state = IDLE;
            LOADED: next_state = IDLE;
        endcase
    end

// ===============================================================================
//                              Output Logic
// ===============================================================================

    always_comb begin
        case(current_state)
            IDLE: begin if (operate) {load_data, load_CIR, store} = {1'b1 ,1'b0 ,1'b0}; 
                        else {load_data, load_CIR, store} = {1'b0 ,1'b0 ,1'b0}; end
            LOADED: {load_data, load_CIR, store} = {1'b0 ,1'b1 ,1'b1};
        endcase
    end
endmodule