module cdc_fifo #(parameter DATA_WIDTH = 8) (
    input wire clock_write,
	input wire clock_read,
    input wire reset,
    input wire [DATA_WIDTH-1:0] write_data,
    input wire write_enable,
	input wire read_next,
    output wire read_empty,
    output wire write_full,
    output reg [DATA_WIDTH-1:0] read_data
);

	// Params
	parameter ADDR_WIDTH = 4;   // Address width of the FIFO

	// The number of addresses in the stack
	localparam STACK_NUM_ADDY = 16;//2 ** ADDR_WIDTH; TODO revert back

	// Local variables. Read Pointer and Sync Registers
	reg [ADDR_WIDTH-1:0] read_ptr_next;
	reg [ADDR_WIDTH-1:0] read_ptr_next_pipe;
	reg [ADDR_WIDTH-1:0] read_ptr_next_write_side;
	
	// Local variables. Write Pointer and Sync Registers
	reg [ADDR_WIDTH-1:0] write_ptr_next;
	reg [ADDR_WIDTH-1:0] write_ptr_next_pipe;
	reg [ADDR_WIDTH-1:0] write_ptr_next_read_side;
	
	// 2D array
	reg [DATA_WIDTH-1:0] fifo_data [STACK_NUM_ADDY-1:0];
	
	// The FIFO is empty (from the read side) when the read_pointer_next equals the write_ptr_next
	assign read_empty = (read_ptr_next == write_ptr_next_read_side);
	
	// The FIFO is full (from the write side) when the write_ptr_next + 1 equals the read_ptr_next_write_side
	// This represents right before we are about to loop back around
	// Note the natural loop-around overflow through chopping off the bits
	// TODO: potentially chop the bits here
	wire [ADDR_WIDTH-1:0] write_ptr_next_plus1, read_ptr_next_plus1;
	assign write_ptr_next_plus1 = write_ptr_next + 1;
	assign read_ptr_next_plus1 = read_ptr_next + 1;

	assign write_full = (write_ptr_next_plus1 == read_ptr_next_write_side);
	
	// Just here for looping
	integer i;

	// Handle what happens on the edge of the write clock
	always @(posedge clock_write) begin
		// Handle the reset case
		if (reset == 1) begin
			// Reset the clock domain sync registers
			read_ptr_next_pipe <= 0;
			read_ptr_next_write_side <= 0;
			// Reset the fifo data registers
			
			for (i=0; i<=STACK_NUM_ADDY; i = i + 1) begin
				fifo_data[i] <= 0;
			end
			// Reset the write pointer
			write_ptr_next <= 0;
		end
		
		// Handle the typical case (no reset)
		else begin
			// Get the read pointer over to the write clock domain
			read_ptr_next_pipe <= read_ptr_next;
			read_ptr_next_write_side <= read_ptr_next_pipe;
			
			// If the fifo isn't full and the write is enabled
			// Load the new data and increment the write pointer
			if ((write_full == 0) && (write_enable == 1)) begin
				fifo_data[write_ptr_next] <= write_data;
				write_ptr_next <= write_ptr_next_plus1;//[ADDR_WIDTH:0]; TODO add this back?
			end
		end
	end
	
	// Handle what happens on the edge of the read clock
	always @(posedge clock_read) begin
		// Handle the reset case
		if (reset == 1) begin
			// Reset the clock domain sync registers
			write_ptr_next_pipe <= 0;
			write_ptr_next_read_side <= 0;
			// Reset the read pointer
			read_ptr_next <= 0;
		end
		
		// Handle the typical case (no reset)
		else begin
			// Get the write pointer over to the read clock domain
			write_ptr_next_pipe <= write_ptr_next;
			write_ptr_next_read_side <= write_ptr_next_pipe;
			
			// If the fifo isn't empty and the read is enabled
			// increment the read pointer
			if ((read_empty == 0) && (read_next == 1)) begin
				read_ptr_next <= read_ptr_next_plus1;//[ADDR_WIDTH-1:0]; TODO add this back?
			end
		end
	end
	
	// Output the read data test
	reg [ADDR_WIDTH-1:0] temp;
	always @(*) begin
		temp = read_ptr_next;//-1
		read_data = fifo_data[temp];//[ADDR_WIDTH-1:0]; TODO add this back?
	end
	
endmodule
