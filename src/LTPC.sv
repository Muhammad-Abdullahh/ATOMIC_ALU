`timescale 1ns/10ps

// ===============================================================================
//                                  States
// ===============================================================================

    parameter S0 = 0;
    parameter S1 = 1;

module LTPC(
    input logic clk, reset,
    input logic operate_in,
    output logic operate_out
    );

    logic current_state, next_state;

// ===============================================================================
//                              State Register
// ===============================================================================

    always_ff @(posedge clk) begin
        if (reset)
            current_state <= #1 S0;
        else
            current_state <= #1 next_state;
    end

// ===============================================================================
//                             Next State Logic
// ===============================================================================

    always_comb begin
        case(current_state)
            S0: begin if (operate_in) next_state = S1;
                else next_state = S0; end
            S1: begin if (operate_in) next_state = S1;
                else next_state = S0; end
        endcase
    end

// ===============================================================================
//                              Output Logic
// ===============================================================================
    always_comb begin
        case(current_state)
            S0: begin if (operate_in) operate_out = 1;
                else operate_out = 0; end
            S1: operate_out = 0;
        endcase
    end
endmodule