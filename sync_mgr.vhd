----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/14/2020 01:41:34 PM
-- Design Name: 
-- Module Name: sync_mgr - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sync_mgr is
  Port (i_clk : IN STD_LOGIC; -- Logic clock
        o_cmd_ready : OUT STD_LOGIC := '0'; -- HIGH when a command is ready to be sent
        o_cmd : OUT STD_LOGIC_VECTOR(7 downto 0); -- Command data out
        i_cmd_ack : IN STD_LOGIC; -- ACK from the uart manager indicating that transmission of a command is complete.
        o_camera_is_init : OUT STD_LOGIC; -- Signal indicating camera initialization status
        o_camera_init_err : OUT STD_LOGIC; -- Signal indicating initialization error, such as sync timeout
        i_camera_en : IN STD_LOGIC; -- HIGH when camera is enabled. Will begin configuration when this is high.
        i_camera_rst : IN STD_LOGIC;
        o_reset_done : OUT STD_LOGIC;
        i_uart_resp : IN STD_LOGIC_VECTOR(7 downto 0);
        here : OUT STD_LOGIC;
        sync_num : OUT STD_LOGIC_VECTOR(7 downto 0);
        bytecnt : OUT integer;
        i_uart_resp_syn : IN STD_LOGIC
        );
end sync_mgr;

architecture Behavioral of sync_mgr is
type packet_format is array(0 to 5) of STD_LOGIC_VECTOR(7 downto 0);
-- Packet initialization
signal sync_packet : packet_format := (x"aa",x"0d",x"00",x"00",x"00",x"00");


signal resp_packet : packet_format;

constant ACK : packet_format := (x"aa",x"0E",x"00",x"00",x"00",x"00");
constant NAK : packet_format := (x"aa",x"0F",x"00",x"00",x"00",x"00");
-- FSM initialization
type state_type is (init, sync, sync_pause, sync_done, errstate, send_packet, send_data, interpret_resp, wait_transmit, get_resp, wait_resp, increase_wait,resetall);
signal current_state : state_type := init;
signal return_state : state_type := init;
signal uart_state : state_type := init;
-- receive and transmit vectors
signal rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

signal byte_counter : integer range 0 to 6 := 0;
signal rx_byte_counter : integer range 0 to 6 := 0;
signal sync_counter : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
constant SYNC_WAIT_MAX : integer := 400000;
constant PACKET_SIZE : integer :=6;
signal sync_retry_cnt : integer range 0 to 60 := 0;
signal sync_delay_cnt : integer range 0 to SYNC_WAIT_MAX := 0;

signal sync_wait_increase_cnt : integer range 0 to 60 := 0;
signal sync_wait_increase_total : integer range 0 to 65 := 5;
signal in_reset : STD_LOGIC := '0';
signal cmd_ready : STD_LOGIC := '0';
begin
here <= '1' when current_state = errstate else '0';
bytecnt <= byte_counter;
main_proc : process(i_clk)
begin
    if(rising_edge(i_clk)) then
        FSM : case current_state is 
            when init =>
                sync_wait_increase_cnt <= 0;
                sync_wait_increase_total <= 5;
                byte_counter <= 0;
                sync_counter <= (others => '0');
                sync_retry_cnt <= 0;
                sync_delay_cnt <= 0;
                cmd_ready <= '0';
                in_reset<='0';
                rx_byte_counter <= 0;
                o_cmd <= (others => '0');
                o_camera_is_init <= '0';
                o_camera_init_err <= '0';
                if(i_camera_en = '1' and i_camera_rst = '0' and in_reset = '0') then
                    current_state <= send_packet;
                    in_reset <= '1';
                    o_cmd <= sync_packet(byte_counter);
                    byte_counter <= byte_counter + 1;
                    cmd_ready <= '1';
                end if;
            when wait_transmit =>
                if(i_cmd_ack = '0') then
                    if(byte_counter >= PACKET_SIZE) then
                        current_state <= wait_resp;
                    else
                        o_cmd <= sync_packet(byte_counter);
                        byte_counter <= byte_counter + 1;
                        cmd_ready <= '1';
                        current_state <= send_packet;
                    end if;
                end if;
            when send_packet =>
                if(sync_retry_cnt = 60) then
                    current_state <= errstate;
                end if;
                if(i_camera_rst = '1') then
                    current_state <= init;
                end if;
                if(i_cmd_ack = '1') then
                    cmd_ready <= '0';
                    current_state <= wait_transmit;
                end if;
            when wait_resp =>
                sync_delay_cnt <= sync_delay_cnt + 1;
                
                if(sync_delay_cnt >= SYNC_WAIT_MAX) then
                    sync_delay_cnt <= 0;
                    sync_wait_increase_cnt <= sync_wait_increase_cnt + 1;
                    if(sync_wait_increase_cnt = sync_wait_increase_total) then
                        -- Timeout, retry sync
                        sync_wait_increase_total <= sync_wait_increase_total + 1;
                        sync_retry_cnt <= sync_retry_cnt + 1;
                        sync_wait_increase_cnt <= 0;
                        sync_packet(3) <= x"00";
                        --sync_counter <= sync_counter + '1';
                        current_state <= send_packet;
                        o_cmd <= sync_packet(0);
                        byte_counter <= 1;
                        cmd_ready <= '1';
                    end if;
                end if;
                if(i_uart_resp_syn = '1') then
                    resp_packet(rx_byte_counter) <= i_uart_resp;
                    rx_byte_counter <= rx_byte_counter + 1;
                    if(rx_byte_counter = PACKET_SIZE) then
                        current_state <= interpret_resp;
                    else 
                        current_state <= get_resp;
                    end if;
                end if;
            when get_resp =>
                if(i_uart_resp_syn = '0') then
                    -- restart timeout counter
                    sync_delay_cnt <= 0;
                    current_state <= wait_resp;
                end if;
            when interpret_resp =>
                if(resp_packet(0) = ACK(0) and resp_packet(1)= ACK(1)) then
                    -- Sucessful sync
                    current_state <= sync_done;
                    sync_num <= resp_packet(3);
                elsif(resp_packet(0)= ACK(0) and resp_packet(1)=x"0F") then
                    o_camera_init_err <= '1';
                    current_state <= errstate;
                else
                    sync_wait_increase_cnt <= 0;
                    sync_retry_cnt <= sync_retry_cnt + 1;
                    sync_packet(3) <= x"00"; --sync_packet(3) + '1';
                    current_state <= send_packet;
                    o_cmd <= sync_packet(0);
                    byte_counter <= 1;
                    rx_byte_counter <= 0;
                    cmd_ready <= '1';
                end if;
            when sync_done =>
                o_camera_is_init <= '1';
                
                if(i_camera_en = '0' or i_camera_rst = '1') then
                    current_state <= init;
                end if;
            when errstate =>
                o_camera_init_err <= '1';
                if(i_camera_en = '0' or i_camera_rst = '1') then
                    current_state <= resetall;
                end if;
            when resetall =>
                rx_data <= (others => '0');
                tx_data <= (others => '0');
                byte_counter <= 0;
                rx_byte_counter <= 0;
                sync_counter <= (others => '0');
                sync_retry_cnt <= 0;
                sync_delay_cnt <= 0;
                sync_wait_increase_cnt <= 0;
                sync_wait_increase_total <= 5;
                o_camera_init_err <= '0';
                current_state <= init;
            when others =>
                current_state <= init;
        end case FSM;
    end if;
end process main_proc;
o_cmd_ready <= '0' when current_state = init else cmd_ready;
end Behavioral;
