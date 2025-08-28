module crack #(parameter OFFSET = 0, INCREM = 1)(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
             output logic [7:0] pt_addr_out, output logic [7:0] pt_wrdata_out,
             input logic ct_available, output logic ct_read,
             input logic halt, output logic eof);



    logic arc_en, arc_rdy, pt_wren, valid, arc4_done, a4_pt_wren;
    logic [7:0] pt_addr, pt_data, pt_q, a4_pt_addr, crack_pt_addr;
    logic [7:0] count, len, temp_len;

    logic [23:0] curr_key;

    enum {Snoop, Scocked, Sfire, Snoinc, SpropogateDelay, Sreadlen, SpropogateWrite} state;

    assign key_valid = valid;

    assign arc_en = arc_rdy & ((state == Snoinc) | (state == Sfire));
    assign rdy = (state == Scocked);

    always_ff @(posedge clk) begin
        if (!rst_n | halt) begin
            eof <= 0;
            valid <= 0;
            curr_key <= 24'h000000 + OFFSET;
            state <= Scocked;
        end else begin
            case (state)
                Scocked: begin
                    if(en) begin
                        eof <= 0;
                        valid <= 0;
                        key <= 0;
                        curr_key <= 24'h000000 + OFFSET;
                        state <= Snoinc;
                    end else begin
                        state <= Scocked;
                    end
                end

                Snoinc: begin
                    if (arc_rdy) begin
                        state <= Sfire;
                    end else begin
                        state <= Snoinc;
                    end
                end
                Sfire: begin
                    if (arc_rdy) begin
                        if (arc4_done) begin
                            key <= curr_key;
                            state <= SpropogateDelay;
                        end else if (curr_key == 24'hFFFFFF) begin
                            key <= curr_key;
                            state <= SpropogateDelay;
                            //state <= Scocked;
                        end else begin
                            curr_key <= curr_key + INCREM;
                            state <= Sfire;
                        end
                    end else begin
                        state <= Sfire;
                    end
                end

                SpropogateDelay: begin
                    valid <= 1;
                    count <= 0;
                    state <= Sreadlen;
                end

                /*This state saves length and writes it*/
                Sreadlen: begin
                    len <= temp_len;
                    count <= count + 1;
                    state <= SpropogateWrite;
                end

                /*Rest of the message written*/
                SpropogateWrite: begin
                    if(count == len) begin
                        state <= Scocked;
                        eof <= 1;
                    end else begin
                        count <= count+1;
                        state <= SpropogateWrite;
                    end
                end
            endcase
        end
    end

    always_comb begin
        crack_pt_addr = 8'd0;
        pt_addr_out = 8'd0;
        pt_wrdata_out = 8'd0;
        temp_len = 8'd0;
        case(state)
            SpropogateDelay: begin
                crack_pt_addr = 8'd0;
                pt_addr_out = 8'd0;
                pt_wrdata_out = 8'd0;
            end

            Sreadlen: begin
                crack_pt_addr = count + 1;
                pt_addr_out = count;
                pt_wrdata_out = pt_q;
                temp_len = pt_q;
            end

            SpropogateWrite: begin
                crack_pt_addr = count + 1;
                pt_addr_out = count;
                pt_wrdata_out = pt_q;
            end
        endcase
    end

    assign pt_addr = (state == Sfire) ? a4_pt_addr : crack_pt_addr;
    assign pt_wren = (state == Sfire) ? a4_pt_wren : 1'b0;

    pt_mem pt(.address(pt_addr),
             .clock(clk),
             .data(pt_data),
             .wren(pt_wren),
             .q(pt_q));

    arc4 a4(.clk(clk),
            .rst_n(rst_n),
            .en(arc_en),
            .rdy(arc_rdy),
            .key(curr_key), .done(arc4_done),
            .ct_addr(ct_addr), .ct_rddata(ct_rddata),
            .pt_addr(a4_pt_addr), .pt_rddata(pt_q), .pt_wrdata(pt_data), .pt_wren(a4_pt_wren),
            .ct_available(ct_available), .ct_read(ct_read),
            .halt(halt));

endmodule: crack
