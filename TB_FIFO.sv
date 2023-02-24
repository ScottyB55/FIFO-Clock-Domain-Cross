`timescale 1ns/1ns

module cdc_fifo_tb;
	
	parameter DATA_WIDTH = 8;

	// Inputs
	reg clock_write;
	reg clock_read;
    reg reset;
    reg [DATA_WIDTH-1:0] write_data;
    reg write_enable;
	reg read_next;

	// Outputs
    wire read_empty;
    wire write_full;
    wire [DATA_WIDTH-1:0] read_data;

	// Good ref https://www.realdigital.org/doc/43c79714a7f3d0bbb8098d60c63fde48
	cdc_fifo #( .DATA_WIDTH(DATA_WIDTH) ) dut (
		.clock_write(clock_write),
		.clock_read(clock_read),
		.reset(reset),
		.write_data(write_data),
		.write_enable(write_enable),
		.read_next(read_next),
		.read_empty(read_empty),
		.write_full(write_full),
		.read_data(read_data)
	);
	
	// Note: we can access and assert signals within the dut like this
	// assert(dut.registerA === 2'b01);

	// Write clock generation
	initial begin
		clock_write = 1;
		while (1) begin
			#5;
			clock_write = ~clock_write;
			// Rising edge occurs @ multiples of 10
		end
	end
	
	// Read clock generation
	initial begin
		clock_read = 1;
		while (1) begin
			#3;
			clock_read = ~clock_read;
			// Rising edge occurs @ multiples of 6
		end
	end

	// Test write, read, and reset
	initial begin
		
		/* Key Awareness
		 * The first read will always get a value of zero
		 * 
		 */
	
		// Assert reset
		reset			= 1;
		write_data		= 0;
		write_enable	= 0;
		read_next		= 0;
		#11; // change inputs and assert outputs shortly after the clock
		assert(read_empty	=== 1);
		assert(write_full	=== 0);
		assert(read_data	=== 0);
		
		// Assert that the stack fills up
		reset 			= 0;
		write_enable	= 1;
		
		for (int i = 1; i <= 14; i = i + 1) begin
			write_data = i;	//left bits chop off by default
			#10;
		end
		
		// Assert that the stack is not full after 14 writes and 0 reads
		assert(read_empty	=== 0);
		assert(write_full	=== 0);
		assert(read_data	=== 1);
		
		write_data = 15;
		#10;
		
		// Assert that the stack is full after 15 writes and 0 reads
		assert(read_empty	=== 0);
		assert(write_full	=== 1);
		assert(read_data	=== 1);
		
		// See if attempting to write this will corrupt the program
		write_data = 16;
		#10;
		
		// Assert that the stack is still full after 15 writes, a false write, and 0 reads
		assert(read_empty	=== 0);
		assert(write_full	=== 1);
		assert(read_data	=== 1);
		
		
		// Now start reading data back from the FIFO and assert that the data is correct
		write_enable	= 0;
		read_next		= 1;
		for (int i = 2; i <= 15; i = i + 1) begin
			#6;
			assert(read_data === i);
		end
		
		// Let's see how this is working so far		
		$finish;
	end
endmodule