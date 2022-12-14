----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/16/2021 01:29:09 PM
-- Design Name: 
-- Module Name: camera_constant_setter - Behavioral
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

entity camera_constant_setter is
  Port (
        
        o_cam0_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "000";
        o_cam1_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "001";
        o_cam2_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "010";
        o_cam3_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "011";
        o_cam4_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "100";
        o_cam5_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "101";
        o_cam6_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "110";
        o_cam7_id : OUT STD_LOGIC_VECTOR(2 downto 0) := "111"
  );
end camera_constant_setter;

architecture Behavioral of camera_constant_setter is

begin
o_cam0_id <= "000";
o_cam1_id <= "001";
o_cam2_id <= "010";
o_cam3_id <= "011";
o_cam4_id <= "100";
o_cam5_id <= "101";
o_cam6_id <= "110";
o_cam7_id <= "111";
end Behavioral;
