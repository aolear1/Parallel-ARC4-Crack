module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);

    logic [7:0] count;
    enum {Sfire, Scocked} state;

    assign rdy = (state === Scocked);
    assign addr = count;
    assign wrdata = count;
    assign wren = (state === Sfire);

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            state <= Scocked;
        end else begin

            case(state)
                Scocked: begin
                    if(en)begin
                        count <= 0;
                        state <= Sfire;
                    end else begin
                        state <= Scocked;
                    end
                end

                Sfire: begin
                    if(count == 8'd255) begin
                        state <= Scocked;
                    end else begin
                        count <= count+1;
                        state <= Sfire;
                    end
                end
            endcase
        end
    end

endmodule: init
