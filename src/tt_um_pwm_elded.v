`timescale 1 ns / 100 ps
module tt_um_pwm_elded 
(
  input wire [7:0] ui_in,
  input wire [7:0] uio_in,
  input wire  ena,
  input wire  clk,
  input wire  rst_n,
  output wire [7:0] uo_out,
  output wire [7:0] uio_out,
  output wire [7:0] uio_oe
);
 
reg [31:0] q_reg, q_next;  // Registro para el contador del preescalado
reg [6:0] d_reg, d_next;   // Registro para el contador del ciclo de trabajo
reg [7:0] d_ext;           // Extensión del contador del ciclo de trabajo
reg pwm_reg1, pwm_next1;   // Registro y próximo valor de la señal de PWM1
reg pwm_reg2, pwm_next2;   // Registro y próximo valor de la señal de PWM2
reg pwm_reg3, pwm_next3;   // Registro y próximo valor de la señal de PWM2
wire tick;                 // Señal para indicar el inicio de un ciclo PWM
reg [31:0] dvsr;           // Valor fijo de dvsr
 
// Ciclos de trabajo ajustados
wire [7:1] duty_20;
wire [7:1] duty_40;
assign duty_20 = ui_in[7:1] - (ui_in[7:1] >> 2);  // 80% del ciclo de trabajo original
assign duty_40 = ui_in[7:1] - (ui_in[7:1] >> 1);  // 60% del ciclo de trabajo original
 
// Ajuste del valor del preescalador dependiendo del valor de 'sel'
always @(*) begin
    if (ui_in[0] == 1'b0) begin
        dvsr = 32'd10416;  // Para una frecuencia de 960 Hz (asumiendo un reloj de 10 MHz)
    end else begin
        dvsr = 32'd200000; // Para una frecuencia de 50 Hz (asumiendo un reloj de 10 MHz)
    end
end
 
always @(posedge clk or posedge rst_n) begin
    if (rst_n) begin
        q_reg <= 32'b0;
        d_reg <= 7'b0;
        pwm_reg1 <= 1'b0;
        pwm_reg2 <= 1'b0;
        pwm_reg3 <= 1'b0;
    end else begin
        q_reg <= q_next;
        d_reg <= d_next;
        pwm_reg1 <= pwm_next1;
        pwm_reg2 <= pwm_next2;
        pwm_reg3 <= pwm_next3;
    end
end
 
// Contador de preescalado
always @(posedge clk) begin
  if (q_reg == dvsr) begin
    q_next <= 32'b0;
  end else begin
    q_next <= q_reg + 1;
  end
end
 
assign tick = (q_reg == 32'b0);
 
// Contador del ciclo de trabajo
always @(posedge clk) begin
  if (tick) begin
    d_next <= d_reg + 1;
  end else begin
    d_next <= d_reg;
  end
end
 
always @(*) begin
  d_ext = {1'b0, d_reg};
end
 
// Circuito de comparación para generar PWM
always @(*) begin
if (ui_in[0] ==1)begin
  // Mapeo de 1 ms a 2 ms (5% a 10% de 20 ms)
  if (d_ext < (5 + (ui_in[7:1] * 5 / 15))) begin
    pwm_next1 = 1'b1;
  end else begin
    pwm_next1 = 1'b0;
  end
  if (d_ext < (5 + (duty_20 * 5 / 15))) begin
    pwm_next2 = 1'b1;
  end else begin
    pwm_next2 = 1'b0;
    end 
  if (d_ext < (5 + (duty_40 *5 / 15))) begin
    pwm_next3 = 1'b1;
  end else begin
    pwm_next3 = 1'b0;
  end
end else begin 
  if (d_ext < ui_in[7:1]) begin
    pwm_next1 = 1'b1;
  end else begin
    pwm_next1 = 1'b0;
  end
  if (d_ext < duty_20) begin
    pwm_next2 = 1'b1;
  end else begin
    pwm_next2 = 1'b0;
  end
  if (d_ext < duty_40) begin
    pwm_next3 = 1'b1;
  end else begin
    pwm_next3 = 1'b0;
  end
 end
end
 
assign uo_out[2] = pwm_reg1;
assign uo_out[1] = pwm_reg2;
assign uo_out[0] = pwm_reg3;

// Assigning values to output wires
assign uio_out = 8'b11111111;
assign uio_oe = 8'b11111111;
assign uo_out[7:3] = 5'b11111; 

endmodule
