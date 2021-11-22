library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity simple_fifo is
	generic (
		FIFO_WORD			:	natural := 2;
		FIFO_DEPTH			:	natural := 5
	);
	port (
		clk					:	in std_logic;
		rst					:	in std_logic;
		wr_en				:	in std_logic;
		rd_en				:	in std_logic;
		data_in				:	in std_logic_vector (FIFO_WORD -1 downto 0);
		data_out			:	out std_logic_vector (FIFO_WORD -1 downto 0) := (others => '0');
		empty				:	out std_logic := '0';
		full				:	out std_logic := '0'
	);
end entity simple_fifo;

architecture synthesis of simple_fifo is

	signal wr_en_reg		: std_logic := '0';
	signal rd_en_reg		: std_logic := '0';
	signal empty_flag_reg	: std_logic := '1';
	signal full_flag_reg	: std_logic := '0';	

	type fifo_data_type is array (0 to FIFO_DEPTH -1) of std_logic_vector (FIFO_WORD -1 downto 0);
	signal fifo_data		: fifo_data_type := (others => (others => '0'));
	
	constant POINTER_SIZE	: natural := natural(CEIL(LOG2(real(FIFO_DEPTH)))); -- +1; 
	signal read_pointer		: std_logic_vector (POINTER_SIZE downto 0) := (others => '0');
	signal write_pointer	: std_logic_vector (POINTER_SIZE downto 0) := (others => '0');
	signal data_out_reg		: std_logic_vector (FIFO_WORD - 1 downto 0) := (others => '0');

    signal read_flag        : std_logic := '0';
    signal write_flag       : std_logic := '0';
    signal acc_confl_flag   : std_logic := '0';
    signal acc_counter      : std_logic_vector (FIFO_DEPTH downto 0) := (0 => '1', others => '0');

begin

    --
    -- CONTINOUS SIGNAL ASSIGNMENTS
    --
	empty <= empty_flag_reg;
	full <= full_flag_reg;
	data_out <= data_out_reg;

    read_flag <= rd_en and (not rd_en_reg);
    write_flag <= wr_en and (not wr_en_reg);
    acc_confl_flag <= read_flag and write_flag;

	flag_proc: process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				wr_en_reg <= '0';
				rd_en_reg <= '0';
				empty_flag_reg <= '1';
				full_flag_reg <= '0';
                acc_counter <= (0 => '1', others => '0');
			else
				wr_en_reg <= wr_en;
				rd_en_reg <= rd_en;

--				if (unsigned(read_pointer) = unsigned(write_pointer) and unsigned(write_pointer) = 0) then
--                if (unsigned(read_pointer) = unsigned(write_pointer)) then
                if (acc_counter(0) = '1') then
					empty_flag_reg <= '1';
				else
					empty_flag_reg <= '0';
				end if;

--				if (unsigned(write_pointer) - unsigned(read_pointer) >= FIFO_DEPTH -1) then
--                if (unsigned(write_pointer) >= FIFO_DEPTH - 1 and unsigned(read_pointer) = 0) then
                if (acc_counter(FIFO_DEPTH) >= '1') then
					full_flag_reg <= '1';
				else
					full_flag_reg <= '0';
				end if;

                if (write_flag = '1') then
                    acc_counter <= std_logic_vector (shift_left(unsigned(acc_counter), 1));
                elsif (read_flag = '1') then
                    acc_counter <= std_logic_vector (shift_right(unsigned(acc_counter), 1));
                else
                    acc_counter <= acc_counter;
                end if;

			end if;
		end if;
	end process flag_proc;

	data_proc: process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				fifo_data <= (others => (others => '0'));
				data_out_reg <= (others => '0');
				read_pointer <= (others => '0');
				write_pointer <= (others => '0');
			else
				if (write_flag = '1' and full_flag_reg = '0' and acc_confl_flag = '0') then
					fifo_data(to_integer(unsigned(write_pointer))) <= data_in;
					if (unsigned(write_pointer) >= FIFO_DEPTH - 1) then
						write_pointer <= std_logic_vector(to_unsigned(0, write_pointer'length));
					else 
						write_pointer <= std_logic_vector (unsigned(write_pointer) +1);
					end if;
				elsif (read_flag = '1' and empty_flag_reg = '0' and acc_confl_flag = '0') then
					data_out_reg <= fifo_data(to_integer(unsigned(read_pointer)));
					if (unsigned(read_pointer) >= FIFO_DEPTH - 1) then
						read_pointer <= std_logic_vector(to_unsigned(0, read_pointer'length));
					else
						read_pointer <= std_logic_vector(unsigned(read_pointer) +1);
					end if;
				else
					fifo_data <= fifo_data;
					-- data_out <= (others => '0');
					data_out_reg <= data_out_reg;
					read_pointer <= read_pointer;
					write_pointer <= write_pointer;
				end if;

			end if;
		end if;
	end process data_proc;

end architecture synthesis;
		
