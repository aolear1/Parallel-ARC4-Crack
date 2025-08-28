module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key, output logic done,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren,
            input  logic ct_available, output logic ct_read);

    logic [7:0] message_length, temp_message_length;
    logic [7:0] i, j, temp_i, s_i, s_j, temp_s_i, temp_s_j, k, temp_k;
    logic [8:0] temp_j, summed;
    enum {Sreadlen_wait, Sreadlen_wait_wait, Sloop1, Sloop2, Sloop3, Sloop3_wait, Sloop4, Sloop5, Swritelen, Scocked} state;

    logic len_read;

    assign rdy = (state == Scocked);

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            len_read <= 0;
            done <= 0;
            state <= Scocked;
        end else begin
            case (state)
                Scocked: begin
                    if (en) begin
                        i <= 0;
                        k <= 1;
                        j <= 0;
                        done <= 0;
                        if (len_read) begin
                            state <= Sloop1;
                        end else begin
                            state <= Sreadlen_wait;
                        end
                    end else begin
                        state <= Scocked;
                    end
                end

                Sreadlen_wait: begin
                    if (ct_available) begin
                        message_length <= temp_message_length;
                        len_read <= 1;
                        state <= Sloop1;
                    end else begin
                        state <= Sreadlen_wait_wait;
                    end
                end

                Sreadlen_wait_wait: begin
                    message_length <= temp_message_length;
                    len_read <= 1;
                    state <= Sloop1;
                end

                Sloop1: begin
                    i <= temp_i;
                    state <= Sloop2;
                end

                Sloop2: begin
                    s_i <= temp_s_i;
                    j <= temp_j[7:0];
                    state <= Sloop3;
                end

                Sloop3: begin
                    s_j <= temp_s_j;
                    if (ct_available)
                        state <= Sloop4;
                    else
                        state <= Sloop3_wait;
                end
                
                Sloop3_wait: begin
                    state <= Sloop4;
                end

                Sloop4: begin
                    if ((pt_wrdata >= 8'h20) & (pt_wrdata <= 8'h7E)) begin
                        state <= Sloop5;
                    end else begin
                        state <= Scocked;
                    end
                end

                Sloop5: begin
                    k <= temp_k;
                    if (k >= message_length) begin
                        done <= 1;
                        state <= Scocked;
                    end else begin
                        done <= 0;
                        state <= Sloop1;
                    end
                end
            endcase
        end

    end

    always_comb begin
        pt_wren = 0;
        s_wren = 0;
        temp_i = 0;
        temp_j = 0;
        temp_k = 0;
        temp_s_i = 0;
        temp_s_j = 0;
        s_addr = 0;
        pt_addr = 0;
        ct_addr = 0;
        s_wrdata = 0;
        pt_wrdata = 0;
        summed = 0;
        temp_message_length = 0;

        ct_read = 0;

        case(state)
                Scocked: begin
                    ct_addr = 8'd0;
                    ct_read = 0;
                end

                Sreadlen_wait: begin
                    temp_message_length = ct_rddata;
                    ct_addr = 8'd0;
                    ct_read = 1;
                end

                Sreadlen_wait_wait: begin
                    temp_message_length = ct_rddata;
                    ct_addr = 8'd0;
                    ct_read = 1;
                end

                Sloop1: begin
                    temp_i = i + 1;
                    s_addr = temp_i;
                end

                Sloop2: begin
                    pt_wren = 1;
                    pt_addr = 0;
                    pt_wrdata = message_length;
                    temp_s_i = s_rddata;
                    temp_j = (j + temp_s_i);
                    s_addr = temp_j;
                end

                Sloop3: begin
                    temp_s_j = s_rddata;
                    summed = (s_i + temp_s_j);
                    if (summed[7:0] == i)
                        s_addr = j;
                    else if (summed[7:0] == j)
                        s_addr = i;
                    else
                        s_addr = summed[7:0];

                    ct_addr = k;
                    ct_read = 1;
                end
                
                Sloop3_wait: begin
                    summed = (s_i + s_j);
                    if (summed[7:0] == i)
                        s_addr = j;
                    else if (summed[7:0] == j)
                        s_addr = i;
                    else 
                        s_addr = summed[7:0];

                    ct_addr = k;
                    ct_read = 1;
                end

                Sloop4: begin
                    s_addr = j;
                    s_wren = 1;
                    s_wrdata = s_i;
                    pt_wren = 1;
                    pt_addr = k;
                    pt_wrdata = s_rddata ^ ct_rddata;
                end

                Sloop5: begin
                    s_addr = i;
                    s_wren = 1;
                    s_wrdata = s_j;
                    temp_k = k + 1;
                end

        endcase

    end

endmodule: prga
