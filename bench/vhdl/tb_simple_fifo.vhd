library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library STD;
use STD.env.finish;

entity tb_simple_fifo is
end entity tb_simple_fifo;

architecture behavior of tb_simple_fifo is

	component simple_fifo is
		generic (
			FIFO_WORD	:	natural;
			FIFO_DEPTH	:	natural
		);
		port (
			clk			:	in std_logic;
			rst			:	in std_logic;
			wr_en		:	in std_logic;
			rd_en		:	in std_logic;
			data_in		:	in std_logic_vector (FIFO_WORD -1 downto 0);
			data_out	:	out std_logic_vector (FIFO_WORD -1 downto 0) := (others => '0');
			empty		:	out std_logic;
			full		:	out std_logic
		);
	end component simple_fifo;

	constant CLK_PERIOD	:	time := 10 ns;
	constant DUT_DEPTH	:	natural := 8;
	constant DUT_WORD	:	natural := 32;

	signal tb_clk		:	std_logic := '1';
	signal tb_rst		:	std_logic := '0';

	signal tb_wr_en		:	std_logic := '0';
	signal tb_rd_en		:	std_logic := '0';
	signal tb_empty		:	std_logic;
	signal tb_full		:	std_logic;
	signal tb_data_in	:	std_logic_vector (DUT_WORD -1 downto 0) := (others => '0');
	signal tb_data_out	:	std_logic_vector (DUT_WORD -1 downto 0) := (others => '0');

begin

	tb_clk <= not tb_clk after CLK_PERIOD / 2;

	dut: simple_fifo
		generic map (
			FIFO_WORD => DUT_WORD,	
			FIFO_DEPTH => DUT_DEPTH
		)
		port map (
			clk => tb_clk,
			rst => tb_rst,
			wr_en => tb_wr_en,
			rd_en => tb_rd_en,
			data_in => tb_data_in,
			data_out => tb_data_out,
			empty => tb_empty,
			full => tb_full
		);

	reset_process: process
    begin
        wait for CLK_PERIOD;
        tb_rst <= '1';
        wait for CLK_PERIOD * 2;
        tb_rst <= '0';
        wait;
    end process reset_process;


	dut_proc: process
--        variable I : natural := 0;
--       variable K : natural := 0;
	begin

		wait for CLK_PERIOD * 10;

        empty_to_full_seq: for I in 1 to DUT_DEPTH loop
    		tb_data_in <= std_logic_vector(to_unsigned(I, tb_data_in'length));
    		tb_wr_en <= '1';
    		wait for CLK_PERIOD;
    		tb_wr_en <= '0';
            
       		wait for CLK_PERIOD * 10;

            if (I = 1) then
     		    assert (tb_empty = '0' and tb_full = '0') report "Error writing to FIFO"
    		    	severity error;
            end if;
        end loop empty_to_full_seq;

        full_to_empty_seq: for K in 1 to DUT_DEPTH loop
    		tb_rd_en <= '1';
    		wait for CLK_PERIOD;
    		tb_rd_en <= '0';

    		wait for CLK_PERIOD * 10;

            assert (unsigned(tb_data_out) = K) report "Wrong data red from FIFO"
                severity error;
	   
            if (K = 8) then
        		assert (tb_empty = '1' and tb_full = '0') report "Error reading from FIFO"
        			severity error;
            end if;
        end loop full_to_empty_seq;
    

		report "End of simulation";
		report "-----------------";

		finish;

	end process dut_proc;

end architecture behavior;
