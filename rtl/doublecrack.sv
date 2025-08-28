module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
             output logic debug_halt);

    // your code here
    
    logic [7:0] pt_addr, pt_data, pt_q, c1_pt_addr, c2_pt_addr, c1_pt_data, c2_pt_data, c1_ct_addr, c2_ct_addr;
    logic pt_wren, c1_cracken, c2_cracken, c1_crack_rdy, c2_crack_rdy, c1_key_valid, c2_key_valid;
    logic [23:0] c1_found_key, c2_found_key;

    logic c1_ct_available, c2_ct_available;
    logic c1_ct_read, c2_ct_read;
    logic halt, c1_eof, c2_eof;

    assign debug_halt = halt;

    enum {Scocked, Sfire, Sfired} state;


    assign rdy = state == Scocked;

    assign c1_cracken = c1_crack_rdy & c2_crack_rdy & state == Sfire;
    assign c2_cracken = c1_crack_rdy & c2_crack_rdy & state == Sfire;


    /*TODO: add locking logic, setting for temp testing*/

    /* ct read coordination */
    always_comb begin
        if (c1_ct_read & !c2_ct_read) begin
            c1_ct_available = 1;
            c2_ct_available = 0;
            ct_addr = c1_ct_addr;
        end
        else if (c2_ct_read & !c1_ct_read) begin
            c1_ct_available = 0;
            c2_ct_available = 1;
            ct_addr = c2_ct_addr;
        end
        else begin
            c1_ct_available = 1;
            c2_ct_available = 0;
            ct_addr = c1_ct_addr;
        end
    end


    /*TODO: Determine what should happen after c1 finishes  and c2 does not, do we just wait for a reset? Should we halt it? Should we just set the no-op state
            to be dependent on the other modules valid signal?*/
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= Scocked;
            key_valid <= 0;
            halt <= 1'b0;
        end else begin
            case(state)
                Scocked: begin
                    if (en) begin
                        key_valid <= 0;
                        halt <= 1'b0;
                        state <= Sfire;
                    end else begin
                        state <= Scocked;
                    end
                end

                Sfire: begin
                    //if both are ready, or one is ready and the key is found
                    if (c1_crack_rdy & c2_crack_rdy |
                        ((c1_crack_rdy | c2_crack_rdy) &
                         (c1_key_valid | c2_key_valid))) begin
                        state <= Sfired;
                    end else begin
                        state <= Sfire;
                    end
                end

                Sfired: begin
                    if (c1_crack_rdy | c2_crack_rdy) begin
                        key_valid <= 1'b1;
                        halt <= 1'b1;
                        state <= Scocked;
                    end else begin
                        state <= Sfire;
                    end
                end
            endcase
        end
    end

    always_comb begin
        if (c1_key_valid & !(c1_eof | c2_eof)) begin
            pt_addr = c1_pt_addr;
            pt_data = c1_pt_data;
            pt_wren = 1'b1;
        end else if (c2_key_valid & !(c1_eof | c2_eof)) begin
            pt_addr = c2_pt_addr;
            pt_data = c2_pt_data;
            pt_wren = 1'b1;
        end else begin
            pt_addr = 8'dx;
            pt_data = 8'dx;
            pt_wren = 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!halt) begin
            if (c1_crack_rdy) begin
                key <= c1_found_key;
            end else if (c2_crack_rdy) begin
                key <= c2_found_key;
            end else begin
                key <= 24'hx;
            end
        end
    end


    // this memory must have the length-prefixed plaintext if key_valid
    pt_mem pt(.address(pt_addr),
              .clock(clk),
              .data(pt_data),
              .wren(pt_wren),
              .q(pt_q));

    crack #(.OFFSET(0), .INCREM(2)) c1( .clk(clk), .rst_n(rst_n),
                                        .en(c1_cracken), .rdy(c1_crack_rdy),
                                        .key(c1_found_key), .key_valid(c1_key_valid),
                                        .ct_addr(c1_ct_addr), .ct_rddata(ct_rddata),
                                        .pt_addr_out(c1_pt_addr), .pt_wrdata_out(c1_pt_data),
                                        .ct_available(c1_ct_available), .ct_read(c1_ct_read),
                                        .halt(halt), .eof(c1_eof));

    crack #(.OFFSET(1), .INCREM(2)) c2( .clk(clk), .rst_n(rst_n),
                                        .en(c2_cracken), .rdy(c2_crack_rdy),
                                        .key(c2_found_key), .key_valid(c2_key_valid),
                                        .ct_addr(c2_ct_addr), .ct_rddata(ct_rddata),
                                        .pt_addr_out(c2_pt_addr), .pt_wrdata_out(c2_pt_data),
                                        .ct_available(c2_ct_available), .ct_read(c2_ct_read),
                                        .halt(halt), .eof(c2_eof));


    
endmodule: doublecrack
