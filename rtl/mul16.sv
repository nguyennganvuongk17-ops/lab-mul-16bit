`timescale 1ns/1ps

module mul16 #(
    parameter int W = 16
) (
    input  wire             clk,
    input  wire             rst,

    input  wire             req_valid,
    output wire             req_ready,
    input  wire [W-1:0]     a,
    input  wire [W-1:0]     b,

    output wire             resp_valid,
    input  wire             resp_ready,
    output wire [2*W-1:0]   p
);

    // 3 trang thai FSM
    typedef enum logic [1:0] {
        IDLE,
        CALC,
        DONE
    } state_t;

    state_t state, state_next;

    // 4 thanh ghi datapath
    logic [2*W-1:0] acc;
    logic [2*W-1:0] mcand;
    logic [W-1:0]   mplier;
    logic [$clog2(W+1)-1:0] cnt;

    // Giao tiep valid/ready
    assign req_ready  = (state == IDLE);
    assign resp_valid = (state == DONE);
    assign p       = acc;

    // FSM chuyen trang thai
    always_comb begin
        state_next = state;

        case (state)
            IDLE: begin
                if (req_valid)
                    state_next = CALC;
            end

            CALC: begin
                if (cnt == W-1)
                    state_next = DONE;
            end

            DONE: begin
                if (resp_ready)
                    state_next = IDLE;
            end

            default: state_next = IDLE;
        endcase
    end

    // FSM + datapath
    always_ff @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            acc    <= '0;
            mcand  <= '0;
            mplier <= '0;
            cnt    <= '0;
        end
        else begin
            state <= state_next;

            case (state)
                IDLE: begin
                    if (req_valid) begin
                        acc    <= '0;
                        mcand  <= {{W{1'b0}}, a};
                        mplier <= b;
                        cnt    <= '0;
                    end
                end

                CALC: begin
                    if (mplier[0])
                        acc <= acc + mcand;

                    mcand  <= mcand << 1;
                    mplier <= mplier >> 1;
                    cnt    <= cnt + 1'b1;
                end

                DONE: begin
                    if (resp_ready) begin
                        acc    <= '0;
                        mcand  <= '0;
                        mplier <= '0;
                        cnt    <= '0;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
