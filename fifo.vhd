----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/16/2020 11:22:29 AM
-- Design Name: 
-- Module Name: fifo - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo is
  Port (i_clk : IN STD_LOGIC;
        i_in_data_syn : IN STD_LOGIC;
        i_in_data : IN STD_LOGIC_VECTOR(39 downto 0);
        o_in_data_ack : OUT STD_LOGIC;
        i_out_data_req : IN STD_LOGIC;
        o_fifo_full : OUT STD_LOGIC;
        o_out_data_syn : OUT STD_LOGIC;
        o_fifo_empty : OUT STD_LOGIC;
        o_fifo_index_out : OUT UNSIGNED(31 downto 0);
        i_camera_reset : IN STD_LOGIC;
        o_reset_done : OUT STD_LOGIC;
        o_out_data : OUT STD_LOGIC_VECTOR(39 downto 0);
        i_out_data_ack : IN STD_LOGIC
  );
end fifo;

architecture Behavioral of fifo is
constant FIFO_MAX : integer := 3000;
type fifo_type is array (0 to FIFO_MAX) of STD_LOGIC_VECTOR(39 downto 0);
signal big_fifo : fifo_type;
signal fifo_empty : STD_LOGIC := '1';
signal reset_done : STD_LOGIC := '0';
signal fifo_full : STD_LOGIC := '0';
signal fifo_index : integer range 0 to FIFO_MAX := 0;
type state_type is (init, get_data, send_data, reset);
signal current_state : state_type := init;
begin
fifo_empty <= '1' when fifo_index = 0 else '0';
fifo_full <= '1' when fifo_index = FIFO_MAX else '0';
o_fifo_empty <= fifo_empty;
o_fifo_index_out <= to_UNSIGNED(fifo_index,32);
o_fifo_full <= fifo_full;
main_proc : process(i_clk)
begin
    if(rising_edge(i_clk)) then
        case current_state is
            when init =>
                o_in_data_ack <= '0';
                o_out_data_syn <= '0';
                o_out_data <= (others => '0');
                if(i_in_data_syn = '1' and fifo_full = '0') then
                    current_state <= get_data;
                    reset_done <= '0';
                end if;
                if(i_out_data_req = '1' and fifo_empty = '0') then
                    current_state <= send_data;
                end if;
            when get_data =>
                big_fifo(fifo_index) <= i_in_data;
                o_in_data_ack <= '1';
                
                if(i_in_data_syn = '0') then
                    fifo_index <= fifo_index + 1;
                    current_state <= init;
                end if;
            
            when send_data =>
                o_out_data <= big_fifo(fifo_index -1);
                o_out_data_syn <= '1';
                if(i_out_data_ack = '1') then
                    current_state <= init;
                    fifo_index <= fifo_index - 1;
                end if;
            when others =>
                current_state <= init;
        end case;
    end if;
end process main_proc;

end Behavioral;
