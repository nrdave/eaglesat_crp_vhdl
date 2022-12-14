----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/07/2020 10:06:44 AM
-- Design Name: 
-- Module Name: singlecam_reset_concat - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity singlecam_reset_concat is
  Port (i_configmgr_reset_done: IN STD_LOGIC;
        i_thresh_reset_done : IN STD_LOGIC;
        i_img_reset_done : IN STD_LOGIC;
        i_syncmgr_reset_done : IN STD_LOGIC;
        i_fifo_reset_done : IN STD_LOGIC;
        o_camera_reset_done : OUT STD_LOGIC;
        i_sync_error : IN STD_LOGIC;
        i_config_error: IN STD_LOGIC;
        o_camera_init_error: OUT STD_LOGIC);
end singlecam_reset_concat;

architecture Behavioral of singlecam_reset_concat is

begin
o_camera_reset_done<=i_configmgr_reset_done and i_thresh_reset_done and i_syncmgr_reset_done and i_img_reset_done and i_fifo_reset_done;
o_camera_init_error <= i_config_error or i_sync_error;
end Behavioral;
