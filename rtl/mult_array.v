module mult_array (input [3:0] a,b,
		   input rst_n,clk,
		   output reg [7:0] p);

	reg [3:0] a_reg, b_reg;				    // Input and output registers
	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin                             // Active low asynchronous reset
			a_reg <= 4'b0000;
			b_reg <= 4'b0000;
		end 
		else begin
			a_reg <= a;
			b_reg <= b;
		end
	end	
	// Partial Products

	wire [3:0] pp0, pp1, pp2, pp3;
	assign pp0 = {4{b_reg[0]}} & a_reg;
	assign pp1 = {4{b_reg[1]}} & a_reg;
	assign pp2 = {4{b_reg[2]}} & a_reg;
	assign pp3 = {4{b_reg[3]}} & a_reg;
	
	wire [7:0] p_comb;
	wire [3:0] r0;
	assign p_comb[0] = pp0[0];
	assign r0 = {1'b0, pp0[3], pp0[2], pp0[1]};

	wire [3:0] s1; // sum (row1)
	wire [4:0] c1; // carry (row1)
	wire [3:0] r1; // row1 bits to be sent
	assign c1[0] = 1'b0; // Initial cin = 0

	full_adder fa1 (.a(pp1[0]), .b(r0[0]), .cin(c1[0]), .sum(s1[0]), .cout(c1[1]));
	full_adder fa2 (.a(pp1[1]), .b(r0[1]), .cin(c1[1]), .sum(s1[1]), .cout(c1[2]));
	full_adder fa3 (.a(pp1[2]), .b(r0[2]), .cin(c1[2]), .sum(s1[2]), .cout(c1[3]));
	full_adder fa4 (.a(pp1[3]), .b(r0[3]), .cin(c1[3]), .sum(s1[3]), .cout(c1[4]));
	
	assign p_comb[1] = s1[0];
	assign r1 = {c1[4], s1[3], s1[2], s1[1]};

	wire [3:0] s2; // sum (row2)
	wire [4:0] c2; // carry (row2)
	wire [3:0] r2; // row2 bits to be sent
	assign c2[0] = 1'b0; // Initial cin = 0

	full_adder fa5 (.a(pp2[0]), .b(r1[0]), .cin(c2[0]), .sum(s2[0]), .cout(c2[1]));
	full_adder fa6 (.a(pp2[1]), .b(r1[1]), .cin(c2[1]), .sum(s2[1]), .cout(c2[2]));
	full_adder fa7 (.a(pp2[2]), .b(r1[2]), .cin(c2[2]), .sum(s2[2]), .cout(c2[3]));
	full_adder fa8 (.a(pp2[3]), .b(r1[3]), .cin(c2[3]), .sum(s2[3]), .cout(c2[4]));

	assign p_comb[2] = s2[0];
	assign r2 = {c2[4], s2[3], s2[2], s2[1]};

	wire [3:0] s3;
	wire [4:0] c3;
	//wire [3:0] r3;
	assign c3[0] = 1'b0;

	full_adder fa9 (.a(pp3[0]), .b(r2[0]), .cin(c3[0]), .sum(s3[0]), .cout(c3[1]));
	full_adder fa10 (.a(pp3[1]), .b(r2[1]), .cin(c3[1]), .sum(s3[1]), .cout(c3[2]));
	full_adder fa11 (.a(pp3[2]), .b(r2[2]), .cin(c3[2]), .sum(s3[2]), .cout(c3[3]));
	full_adder fa12 (.a(pp3[3]), .b(r2[3]), .cin(c3[3]), .sum(s3[3]), .cout(c3[4]));

	assign p_comb[3] = s3[0];
	//assign r3 = {c3[4], s[3], s[2], s[1]};
	assign p_comb [7:4] = {c3[4], s3[3], s3[2], s3[1]};

	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			p <= 8'b00000000;
		end
		else begin
			p <= p_comb;
		end
	end

endmodule
