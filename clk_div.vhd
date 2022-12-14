----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/07/2020 10:33:15 AM
-- Design Name: 
-- Module Name: clk_div - Behavioral
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

entity clk_div is
  Port (in_clk : IN STD_LOGIC;
        o_baudclk : OUT STD_LOGIC;
        o_sysclk : OUT STD_LOGIC
  );
end clk_div;

architecture Behavioral of clk_div is
signal baudclk : STD_LOGIC := '0';
constant BAUDCLK_CNT_MAX : integer := 620; -- should be 208 for 115200 at 24 MHz sysclk 620 for 9600
signal baudclk_cnt : integer range 0 to BAUDCLK_CNT_MAX := 0;
signal sysclk : STD_LOGIC := '0';
constant SYSCLK_CNT_MAX : integer := 12; -- internal system clock runs at 1/24 frequency of Cmod A7 board clock (24 MHz)
signal sysclk_cnt : integer range 0 to SYSCLK_CNT_MAX := 0;
begin
o_baudclk <= baudclk;
o_sysclk <= sysclk;
process(in_clk)
begin
    if(rising_edge(in_clk)) then
        baudclk_cnt <= baudclk_cnt + 1;
        sysclk_cnt <= sysclk_cnt + 1;
        if(baudclk_cnt = BAUDCLK_CNT_MAX) then
            baudclk_cnt <= 0;
            baudclk <= not baudclk;
        end if;
        if(sysclk_cnt = SYSCLK_CNT_MAX) then
            sysclk_cnt <= 0;
            sysclk <= not sysclk;
        end if;
    end if;
end process;

end Behavioral;
