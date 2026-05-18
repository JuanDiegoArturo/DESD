----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.05.2021 19:20:17
-- Design Name: 
-- Module Name: moving_average_filter - Behavioral
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

entity moving_average is
    Generic(
        LOG2_LEN: POSITIVE := 5;            -- Perform the average over 2^LOG2_LEN samples
        CHANNEL_LENGHT  : integer := 24     -- 3 Byte for AXIS audio I2S
    );
    Port ( 
        s_axis_tready : OUT STD_LOGIC;
        s_axis_tdata : IN STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        s_axis_tlast : IN STD_LOGIC;
        s_axis_tvalid : IN STD_LOGIC;
        
        m_axis_tvalid : OUT STD_LOGIC;
        m_axis_tdata : OUT STD_LOGIC_VECTOR(CHANNEL_LENGHT-1 DOWNTO 0);
        m_axis_tready : IN STD_LOGIC;
        m_axis_tlast : OUT STD_LOGIC;
        
        enable_filter: IN STD_LOGIC;
        aclk : IN STD_LOGIC;
        aresetn : IN STD_LOGIC
    );
end moving_average;

architecture Behavioral of moving_average is
   
    constant NUM_SAMPLES : integer := 2**LOG2_LEN;
    type shift_reg_type is array (0 to NUM_SAMPLES-1) of signed(CHANNEL_LENGHT-1 downto 0);
    signal shift_reg_L : shift_reg_type := (others => (others => '0'));
    signal shift_reg_R : shift_reg_type := (others => (others => '0'));
    signal sum_L : signed(CHANNEL_LENGHT + LOG2_LEN - 1 downto 0) := (others => '0');
    signal sum_R : signed(CHANNEL_LENGHT + LOG2_LEN - 1 downto 0) := (others => '0');
    signal out_tdata  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal out_tvalid : std_logic := '0';
    
    signal out_tlast  : std_logic := '0'; 

begin

    process(aclk)
        variable new_sample : signed(CHANNEL_LENGHT-1 downto 0);
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                sum_L <= (others => '0');
                sum_R <= (others => '0');
                shift_reg_L <= (others => (others => '0'));
                shift_reg_R <= (others => (others => '0'));
                out_tvalid  <= '0';
                out_tlast   <= '0'; 
                
            else
                if s_axis_tvalid = '1' and m_axis_tready = '1' then
                    
                    if enable_filter = '1' then
                        new_sample := signed(s_axis_tdata);
                        
                        if s_axis_tlast = '0' then
                            -- Canal Izquierdo
                            sum_L <= sum_L + new_sample - shift_reg_L(NUM_SAMPLES-1);
                            shift_reg_L(1 to NUM_SAMPLES-1) <= shift_reg_L(0 to NUM_SAMPLES-2);
                            shift_reg_L(0) <= new_sample;
                            out_tdata <= std_logic_vector(sum_L(CHANNEL_LENGHT + LOG2_LEN - 1 downto LOG2_LEN));
                        else
                            -- Canal Derecho
                            sum_R <= sum_R + new_sample - shift_reg_R(NUM_SAMPLES-1);
                            shift_reg_R(1 to NUM_SAMPLES-1) <= shift_reg_R(0 to NUM_SAMPLES-2);
                            shift_reg_R(0) <= new_sample;
                            out_tdata <= std_logic_vector(sum_R(CHANNEL_LENGHT + LOG2_LEN - 1 downto LOG2_LEN));
                        end if;
                        
                    else
                        -- Bypass
                        out_tdata <= s_axis_tdata;
                    end if;
                    
                    out_tvalid <= '1';
                    out_tlast  <= s_axis_tlast; 
                else
                    out_tvalid <= '0';
                   
                end if;
            end if;
        end if;
    end process;

    
    s_axis_tready <= m_axis_tready; 
    
    m_axis_tdata  <= out_tdata;
    m_axis_tvalid <= out_tvalid;
    m_axis_tlast  <= out_tlast;  
    
end Behavioral;
