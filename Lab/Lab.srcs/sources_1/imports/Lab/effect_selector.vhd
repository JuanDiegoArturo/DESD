--effect selector
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2024 10:12:03 AM
-- Design Name: 
-- Module Name: effect_selector - Behavioral
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
use IEEE.NUMERIC_STD.ALL; 

entity effect_selector is 
    generic( 
        JOYSTICK_LENGHT  : integer := 10  
    ); 
    Port ( 
        clk           : in STD_LOGIC; 
        resetn        : in STD_LOGIC; 
        effect        : in STD_LOGIC; --TRIG 
        jstck_x       : in STD_LOGIC_VECTOR(JOYSTICK_LENGHT-1 downto 0); 
        jstck_y       : in STD_LOGIC_VECTOR(JOYSTICK_LENGHT-1 downto 0); 
        volume        : out STD_LOGIC_VECTOR(JOYSTICK_LENGHT-1 downto 0); 
        balance       : out STD_LOGIC_VECTOR(JOYSTICK_LENGHT-1 downto 0); 
        gain          : out STD_LOGIC_VECTOR(JOYSTICK_LENGHT-1 downto 0); 
        delay         : out STD_LOGIC_VECTOR(JOYSTICK_LENGHT-1 downto 0) 
    ); 
end effect_selector;

architecture Behavioral of effect_selector is
    signal volume_reg  : std_logic_vector(JOYSTICK_LENGHT-1 downto 0) := (others => '0');
    signal balance_reg : std_logic_vector(JOYSTICK_LENGHT-1 downto 0) := (others => '0');
    signal gain_reg    : std_logic_vector(JOYSTICK_LENGHT-1 downto 0) := (others => '0');
    signal delay_reg   : std_logic_vector(JOYSTICK_LENGHT-1 downto 0) := (others => '0');

begin

    process(clk, resetn)
    begin
        if resetn = '0' then
            volume_reg  <= (others => '0');
            balance_reg <= std_logic_vector(to_unsigned(512, JOYSTICK_LENGHT)); 
            gain_reg    <= (others => '0');
            delay_reg   <= (others => '0');
            
        elsif rising_edge(clk) then
            if effect = '1' then
                gain_reg  <= jstck_x;
                delay_reg <= jstck_y;
                
            else
                balance_reg <= jstck_x;
                volume_reg  <= jstck_y;
            end if;
        end if;
    end process;

    volume  <= volume_reg;
    balance <= balance_reg;
    gain    <= gain_reg;
    delay   <= delay_reg;

end Behavioral;
