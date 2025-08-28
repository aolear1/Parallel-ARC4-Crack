module top(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

    logic [7:0] ct_addr, ct_data, ct_q;
    logic key_valid, db_crack_rdy, db_cracken, bad_key;
    logic [23:0] found_key;

    assign bad_key = found_key == 24'hFFFFFF;

    logic debug_halt;
    assign LEDR[2] = debug_halt;
    assign LEDR[1] = key_valid;
    assign LEDR[0] = db_crack_rdy;

    ct_mem ct(.address(ct_addr),
            .clock(CLOCK_50),
            .data(ct_data),
            .wren(ct_wren),
            .q(ct_q));

    assign db_cracken = db_crack_rdy & !key_valid;


    doublecrack dc(.clk(CLOCK_50), .rst_n(KEY[3]),
                   .en(db_cracken), .rdy(db_crack_rdy),
                   .key(found_key), .key_valid(key_valid),
                   .ct_addr(ct_addr), .ct_rddata(ct_q),
                   .debug_halt(debug_halt));

    hex7seg h5(.clk (CLOCK_50), .HEX0(HEX5), .hex(found_key[23:20]), .key_valid(key_valid), .no_key(bad_key));
    hex7seg h4(.clk (CLOCK_50), .HEX0(HEX4), .hex(found_key[19:16]), .key_valid(key_valid), .no_key(bad_key));
    hex7seg h3(.clk (CLOCK_50), .HEX0(HEX3), .hex(found_key[15:12]), .key_valid(key_valid), .no_key(bad_key));
    hex7seg h2(.clk (CLOCK_50), .HEX0(HEX2), .hex(found_key[11:8]), .key_valid(key_valid), .no_key(bad_key));
    hex7seg h1(.clk (CLOCK_50), .HEX0(HEX1), .hex(found_key[7:4]), .key_valid(key_valid), .no_key(bad_key));
    hex7seg h0(.clk (CLOCK_50), .HEX0(HEX0), .hex(found_key[3:0]), .key_valid(key_valid), .no_key(bad_key));



endmodule: top



module hex7seg(input logic clk, input logic [3:0] hex, output logic [6:0] HEX0, input logic key_valid, input logic no_key);

   //Simple case block that matches the output to each input
    always_ff @(posedge clk) begin
        if (key_valid) begin
            if (no_key) begin
                HEX0 <= 7'b0111111;
            end else begin
                case(hex)
                    4'h0: HEX0 <= 7'b1000000;
                    4'h1: HEX0 <= 7'b1111001;
                    4'h2: HEX0 <= 7'b0100100;
                    4'h3: HEX0 <= 7'b0110000;
                    4'h4: HEX0 <= 7'b0011001;
                    4'h5: HEX0 <= 7'b0010010;
                    4'h6: HEX0 <= 7'b0000010;
                    4'h7: HEX0 <= 7'b1111000;
                    4'h8: HEX0 <= 7'b0000000;
                    4'h9: HEX0 <= 7'b0011000;
                    4'hA: HEX0 <= 7'b0001000;
                    4'hB: HEX0 <= 7'b0000011;
                    4'hC: HEX0 <= 7'b1000110;
                    4'hD: HEX0 <= 7'b0100001;
                    4'hE: HEX0 <= 7'b0000110;
                    4'hF: HEX0 <= 7'b0001110;
                    //default case (blank)
                    default: HEX0 <= 7'b0111111;
                endcase
            end
        end else begin
            HEX0 <= 7'b1111111;
        end
  end

endmodule
