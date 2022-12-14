----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/07/2020 10:40:42 AM
-- Design Name: 
-- Module Name: camera_pair_synchronizer - Behavioral
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

entity camera_pair_synchronizer is
  Port (i_camera1_capture_ready : IN STD_LOGIC;
        i_camera2_capture_ready : IN STD_LOGIC;
        o_camera_capture_ready : OUT STD_LOGIC
  );
end camera_pair_synchronizer;

architecture Behavioral of camera_pair_synchronizer is

begin
o_camera_capture_ready <= i_camera1_capture_ready and i_camera2_capture_ready;

end Behavioral;
