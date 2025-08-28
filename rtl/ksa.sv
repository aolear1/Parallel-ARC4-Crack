module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);


    logic [7:0] i, temp_i;
    logic [7:0] j, temp_j;
    logic [1:0] imod3;
    logic [7:0] key_byte;
    logic [7:0] si, temp_si;
    logic [7:0] sj, temp_sj;

    /*mod logic */
    logic [3:0] int_A, int_C;
    logic [1:0] int_B;

    assign int_A =   {i[7], i[6]} + {i[5], i[4]}
                   + {i[3], i[2]} + {i[1], i[0]};
    assign int_C = {int_A [3], int_A[2]} + {int_A[1], int_A[0]};
    assign int_B = {int_C [3], int_C[2]} + {int_C[1], int_C[0]};
    assign imod3 = {int_B[1] & (int_B[1]^int_B[0]), int_B[0] & (int_B[1]^int_B[0])};


    enum {Sread_i, Sread_j, Swrite_i, Swrite_j, Scocked, UNDEFINED} state;

    assign rdy = (state === Scocked);

    always_comb begin
        wren = 0;
        addr = 0;
        wrdata = 0;
        temp_j = 0;
        temp_si = 0;
        temp_sj = 0;

        case(state)
            Scocked: begin
                wren = 0;
                addr = i;
            end
            Sread_i: begin
                addr = i;
            end
            Sread_j: begin
                temp_si = rddata;
                temp_j = (j + temp_si + key_byte) & 8'b11111111;
                addr = temp_j;
            end
            Swrite_i: begin
                temp_sj = rddata;
                
                addr = j;
                wren = 1;
                wrdata = si;
            end
            Swrite_j: begin
                addr = i;
                wren = 1;
                wrdata = sj;
            end
            default: begin 
                wren = 1'bx;
                addr = 8'bx;
                wrdata = 8'bx;
                temp_j = 8'bx;
                temp_si = 8'bx;
                temp_sj = 8'bx;
            end
        endcase
    end

    always_comb begin
        case(imod3)
            2'd0: key_byte = key[23:16];
            2'd1: key_byte = key[15:8];
            2'd2: key_byte = key[7:0];
				default: key_byte = 8'bx;
        endcase
    end


    always_ff @(posedge clk) begin

        if (!rst_n) begin
            state <= Scocked;
        end else begin

            case(state)
                Scocked: begin
                    if(en)begin
                        i <= 0;
                        j <= 0;
                        state <= Sread_i;
                    end else begin
                        state <= Scocked;
                        i <= 0;
                        j <= 0;
                    end
                end
                
                Sread_i: begin
                    state <= Sread_j;
                    //si <= rddata;
                    //j <= (j + rddata + key_byte) & 8'b11111111;
                end

                Sread_j: begin
                    state <= Swrite_i;
                    si <= temp_si;
                    j <= temp_j;
                end

                Swrite_i: begin
                    sj <= temp_sj;
                    state <= Swrite_j;
                end

                Swrite_j: begin
                    state <= Sread_i;
                    if(i == 8'd255) begin
                        state <= Scocked;
                    end else begin
                        state <= Sread_i;
                        i <= i+1;
                    end
                end
                default: begin
                    state <= Scocked;
                    //no op
                end
            endcase
        end
    end

endmodule
