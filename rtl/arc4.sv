module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key, output logic done,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren,
            input  logic ct_available, output logic ct_read,
            input logic halt);


    enum {Scocked, Spreinit, Sinit, Sksa, Sprga, Swait} state;

    /*Enable and Ready*/
    logic en_init, en_ksa, en_prga, rdy_init, rdy_ksa, rdy_prga, prga_done;

    assign en_init = rdy_init & state == Spreinit;
    assign en_ksa  = rdy_ksa  & state == Sinit & rdy_init;
    assign en_prga = rdy_prga & state == Sksa & rdy_ksa;

    /*Address, ReadData, WriteData and Write Enable*/
    logic [7:0] prga_s_addr, ksa_s_addr, init_s_addr, prga_ct_addr, prga_pt_addr;
    logic [7:0] prga_s_rddata, prga_s_wrdata, ksa_s_rddata, ksa_s_wrdata, init_s_wrdata;
    logic prga_s_wren, ksa_s_wren, init_s_wren;

    /*Inputs into the s_mem module*/
    logic [7:0] s_data, s_addr, s_q;
    logic s_wren;

    assign rdy = (state == Scocked);

    always_comb begin

        case(state)

            Sinit: begin
                s_wren = init_s_wren;
                s_data = init_s_wrdata;
                s_addr = init_s_addr;
            end

            Sksa: begin
                s_wren = ksa_s_wren;
                s_data = ksa_s_wrdata;
                s_addr = ksa_s_addr;
            end

            Sprga: begin
                s_wren = prga_s_wren;
                s_data = prga_s_wrdata;
                s_addr = prga_s_addr;
            end

            default: begin
                s_wren = 1'd0;
                s_data = 8'bx;
                s_addr = 8'bx;
            end
        endcase

    end

    assign ksa_s_rddata  = s_q;
    assign prga_s_rddata = s_q;


    always_ff @(posedge clk) begin
        if(!rst_n | halt) begin
            done <= 0;
            state <= Scocked;
        end else begin
            case(state)
                Scocked: begin
                    if (en & !done) begin
                        done <= 0;
                        state <= Spreinit;
                    end else begin
                        state <= Scocked;
                    end
                end

                Spreinit: begin
                    if(rdy_init) begin
                        state <= Sinit;
                    end else begin
                        state <= Sksa;
                    end
                end

                Sinit: begin
                    if(rdy_init & rdy_ksa) begin
                        state <= Sksa;
                    end else begin
                        state <= Sinit;
                    end
                end

                Sksa: begin
                    if(rdy_ksa & rdy_prga) begin
                        state <= Sprga;
                    end else begin
                        state <= Sksa;
                    end
                end

                Sprga: begin
                    if(rdy_prga) begin
                        done <= prga_done;
                        state <= Scocked;
                    end else begin
                        state <= Sprga;
                    end
                end

            endcase
        end

    end


    s_mem s(.address(s_addr),
            .clock(clk),
            .data(s_data),
            .wren(s_wren),
            .q(s_q));

    init i(.clk(clk), .rst_n(rst_n),
            .en(en_init), .rdy(rdy_init),
            .addr(init_s_addr), .wrdata(init_s_wrdata), .wren(init_s_wren));

    ksa k(.clk(clk),
          .rst_n(rst_n),
          .en(en_ksa),
          .rdy(rdy_ksa),
          .key(key),
          .addr(ksa_s_addr),
          .rddata(ksa_s_rddata),
          .wrdata(ksa_s_wrdata),
          .wren(ksa_s_wren));

    prga p(.clk(clk),
           .rst_n(rst_n),
           .en(en_prga),
           .rdy(rdy_prga),
           .key(key), .done(prga_done),
           .s_addr(prga_s_addr), .s_rddata(prga_s_rddata), .s_wrdata(prga_s_wrdata),
           .s_wren(prga_s_wren),
           .ct_addr(ct_addr), .ct_rddata(ct_rddata),
           .pt_addr(pt_addr), .pt_rddata(pt_rddata), .pt_wrdata(pt_wrdata), .pt_wren(pt_wren),
           .ct_available(ct_available), .ct_read(ct_read));

endmodule: arc4
