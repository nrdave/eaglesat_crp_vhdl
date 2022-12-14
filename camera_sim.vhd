----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/14/2020 03:05:31 PM
-- Design Name: 
-- Module Name: camera_sim - Behavioral
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

entity camera_sim is
  Port (clk : IN STD_LOGIC;
        tx : OUT STD_LOGIC;
        send_bytecnt : IN integer;
        waiting_to_send : OUT STD_LOGIC;
        sending : OUT STD_LOGIC;
        needs_ack : IN STD_LOGIC;
        send_ack : IN STD_LOGIC
  );
end camera_sim;

architecture Behavioral of camera_sim is
type tx_state_type is (init, send_data, increment_data, wait_opening, transmit_wait, fin);
signal tx_state : tx_state_type := init;
type packet_format is array(0 to 5) of STD_LOGIC_VECTOR(7 downto 0);

signal packet_index : integer range 0 to 5 := 0;
constant ACK : packet_format := (x"aa",x"0E",x"00",x"00",x"00",x"00");
-- Tx and Rx shift registers and counters
signal tx_shift_reg : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
constant PACKET_SIZE :integer := 9;
constant WAIT_TIME : integer := 3;
signal wait_opening_cnt : integer := 0;
constant OPEN_MAX : integer := 20;
signal tx_shift_cnt : integer range 0 to PACKET_SIZE := 0;
begin
waiting_to_send <= '1' when tx_state = wait_opening else '0';
tx_proc : process(clk)
begin
    if(rising_edge(clk)) then
        tx_FSM : case tx_state is
            when init =>
                tx <= '1';
                packet_index <= 0;
                tx_shift_reg <= (others => '0');
                tx_shift_cnt <= 0;
                wait_opening_cnt <= 0;
                sending <= '0';
                if(send_ack = '1') then
                    -- load shift registers
                    tx_shift_reg(0) <= '0';
                    tx_shift_reg(8 downto 1) <= ACK(packet_index);
                    tx_shift_reg(9) <= '1';
                    tx_state <= wait_opening;
                end if;
            when wait_opening =>
                wait_opening_cnt <= wait_opening_cnt + 1;
                if(wait_opening_cnt = OPEN_MAX) then
                    tx_state <= send_data;
                end if;
                if(not(send_bytecnt = 5)) then
                    wait_opening_cnt <= 0;
                end if;
            when send_data =>
                sending <= '1';
                -- shift the register
                tx <= tx_shift_reg(0);
                tx_shift_reg(8 downto 0) <= tx_shift_reg(9 downto 1);
                
                -- increment counter
                tx_shift_cnt <= tx_shift_cnt + 1;
                if(tx_shift_cnt = PACKET_SIZE) then
                    tx_state <= transmit_wait;
                    tx_shift_cnt <= 0;
                end if;
            when transmit_wait =>
                -- Wait 4 BAUD cycles, as per UART standard
                tx_shift_cnt <= tx_shift_cnt + 1;
                tx <= '1';
                if(tx_shift_cnt = WAIT_TIME) then
                    tx_shift_cnt <= 0;
                    if(packet_index = 5) then
                        tx_state <= fin;
                    else
                        tx_state <= increment_data;
                        packet_index <= packet_index + 1;
                    end if;
                end if;
            when fin =>
                if(send_ack = '0') then
                    tx_state <= init;
                end if;
            when increment_data =>
                tx_shift_reg <= (others => '0');
                tx_shift_cnt <= 0;
                tx_shift_reg(0) <= '0';
                tx_shift_reg(8 downto 1) <= ACK(packet_index);
                tx_shift_reg(9) <= '1';
                tx_state <= send_data;
            when others =>
            
                tx_state <= init;
        end case tx_FSM;
    end if;
end process tx_proc;

end Behavioral;
