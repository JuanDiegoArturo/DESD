----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.05.2021 15:42:35
-- Design Name: 
-- Module Name: led_level_controller - Behavioral
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

entity led_level_controller is
    generic(
        NUM_LEDS : positive := 16;
        CHANNEL_LENGHT  : positive := 24;   -- 3 Byte for AXIS audio I2S
        refresh_time_ms: positive :=1;      -- refresh the LEDS every refresh_time_ms
        clock_period_ns: positive :=10      -- base time
    );
    Port (
        
        aclk			: in std_logic;
        aresetn			: in std_logic;
        
        led    : out std_logic_vector(NUM_LEDS-1 downto 0);

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tready	: out std_logic

    );
end led_level_controller;

architecture Behavioral of led_level_controller is

    constant REFRESH_COUNT_MAX : integer :=
        (refresh_time_ms * 10000) / clock_period_ns;

    constant MAX_INPUT_VALUE : integer := ((2**(CHANNEL_LENGHT-1))/2)-1;

    constant STEP_SIZE : integer :=
        MAX_INPUT_VALUE / NUM_LEDS;


    signal refresh_counter : integer range 0 to REFRESH_COUNT_MAX := 0;

    signal peak_value : integer := 0;

    signal left_sample  : integer := 0;
    signal right_sample : integer := 0;

    signal sample_signed : signed(CHANNEL_LENGHT-1 downto 0);
    signal sample_abs    : integer := 0;

    signal led_reg : std_logic_vector(NUM_LEDS-1 downto 0);


begin

    s_axis_tready <= '1';

    led <= led_reg;
    
    sample_signed <= signed(s_axis_tdata);
    
    sample_abs<=to_integer(abs(sample_signed));

    process(aclk)
    
         variable avg_sample  : integer;
         variable num_leds_on : integer range 0 to NUM_LEDS;
    
    begin
    
         if rising_edge (aclk) then
         
            if aresetn='0' then
            
                refresh_counter <= 0;

                peak_value <= 0;

                left_sample  <= 0;
                right_sample <= 0;

                led_reg <= (others => '0');
            
            else
            
                if s_axis_tvalid='1' then
                    
                    if s_axis_tlast='0' then 
                        left_sample<=sample_abs;
                    else  
                        right_sample<=sample_abs;
                    end if;
                    
                    avg_sample:=(left_sample+right_sample)/2;
                    
                    if avg_sample > peak_value then
                        peak_value <= avg_sample;
                    end if;
                    
                    
                    if refresh_counter = REFRESH_COUNT_MAX-1 then
                    
                        refresh_counter<=0;
                        
                        num_leds_on := peak_value / STEP_SIZE;
                        
                        if num_leds_on > NUM_LEDS then
                            num_leds_on := NUM_LEDS;
                        end if;
                        
                         for i in 0 to NUM_LEDS-1 loop

                            if i < num_leds_on then
                                led_reg(i) <= '1';
                            else
                                led_reg(i) <= '0';
                            end if;
                        end loop;
                        
                        peak_value <= 0;
                    
                    else
                    
                        refresh_counter <= refresh_counter + 1;

                    end if;
                                      
                end if;
            
                
                        
            end if;            
         
         end if;
    
    end process;
end Behavioral;
