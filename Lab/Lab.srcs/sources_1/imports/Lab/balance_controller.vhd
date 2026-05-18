library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity balance_controller is
	generic (
		TDATA_WIDTH		: positive := 24;	-- Audio, 3 bytes
		BALANCE_WIDTH	: positive := 10;
		BALANCE_STEP_2	: positive := 6		-- i.e., balance_values_per_step = 2**VOLUME_STEP_2
	);
	Port (
		aclk			: in std_logic;
		aresetn			: in std_logic;

		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
		s_axis_tready	: out std_logic;
		s_axis_tlast	: in std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
		m_axis_tready	: in std_logic;
		m_axis_tlast	: out std_logic;

		balance			: in std_logic_vector(BALANCE_WIDTH-1 downto 0)
	);
end balance_controller;

architecture Behavioral of balance_controller is


signal bal_num: integer range -512 to 512;


begin

s_axis_tready <= m_axis_tready;
m_axis_tlast <= s_axis_tlast;
process(aclk)
variable l_gain : integer range 0 to 86;
variable r_gain : integer range 0 to 86;
begin
    if rising_edge(aclk) then
        
        if aresetn='0' then
            m_axis_tvalid<='0';
            m_axis_tdata<=(Others =>'0');
            
            
        else
            
            if signed(balance)<0 then
            l_gain:=0;
            r_gain:=abs(to_integer(signed(balance)))/(2**BALANCE_STEP_2);
            
            
            elsif signed(balance)>0 then
            
            l_gain:=abs(to_integer(signed(balance)))/(2**BALANCE_STEP_2);
            r_gain:=0;
            
            elsif signed(balance)=0 then
            
            l_gain:=0;
            r_gain:=0;
            
            end if;
        
            if s_axis_tvalid='1' and m_axis_tready='1' then 
                         
 
                --ezkerra / left
                if s_axis_tlast='0' then
                
                    if l_gain=0 then
                        m_axis_tdata<=s_axis_tdata;
                    
                    else
                        m_axis_tdata<=std_logic_vector(shift_right(signed(s_axis_tdata),l_gain));
                    end if;
                
                end if;
                
                --eskubia / right
                if s_axis_tlast='1' then 
                
                    if r_gain=0 then
                        m_axis_tdata<=s_axis_tdata;
                    
                    else
                        m_axis_tdata<=std_logic_vector(shift_right(signed(s_axis_tdata),r_gain));
                    end if;

                
                end if;
                m_axis_tvalid <= '1';
                
            else
            m_axis_tvalid <= '0';
                            
            end if;           
        
        end if;
        
        
    end if;  
    
end process;

end Behavioral;
