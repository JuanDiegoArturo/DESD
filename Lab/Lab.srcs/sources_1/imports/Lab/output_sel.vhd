--output selector
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity output_sel is
    Generic (
        TDATA_WIDTH   : positive := 24;       -- 3 byte para audio
        LED_WIDTH     : positive := 8;
        HIGHER_BOUND  : integer  := 2**23 - 1; -- Máximo valor TDATA signed 24-bit
        LOWER_BOUND   : integer  := -2**23     -- Mínimo valor TDATA signed 24-bit
    );
    Port (
        aclk          : in  std_logic;
        aresetn       : in  std_logic;
        
        -- Interfaz AXI4-Stream
        s_axis_tdata  : in  std_logic_vector(TDATA_WIDTH-1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tlast  : in  std_logic;
        s_axis_tready : out std_logic;
        
        m_axis_tdata  : out std_logic_vector(TDATA_WIDTH-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tlast  : out std_logic;
        m_axis_tready : in  std_logic;
        
        
        toggle        : in  std_logic;
        led_r         : out std_logic_vector(LED_WIDTH-1 downto 0);
        led_g         : out std_logic_vector(LED_WIDTH-1 downto 0);
        led_b         : out std_logic_vector(LED_WIDTH-1 downto 0)
    );
end entity output_sel;

architecture rtl of output_sel is

    type state_type is (ST_L_R, ST_MUTE, ST_L_L, ST_R_R, ST_LPR_LPR, ST_LMR_LMR, ST_LPR_LMR, ST_LMR_LPR);
    signal state_reg : state_type := ST_L_R;
    
    signal toggle_old : std_logic := '0';
    
    -- canales
    signal left_reg  : signed(TDATA_WIDTH-1 downto 0) := (others => '0');
    signal right_reg : signed(TDATA_WIDTH-1 downto 0) := (others => '0');

begin
    s_axis_tready <= m_axis_tready;
    m_axis_tvalid <= s_axis_tvalid;
    m_axis_tlast  <= s_axis_tlast;
    
    process(aclk)
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                state_reg <= ST_L_R;
                toggle_old <= '0';
            else
                toggle_old <= toggle;
                -- toggle cambio 
                if toggle = '1' and toggle_old = '0' then
                    case state_reg is
                        when ST_L_R     => state_reg <= ST_MUTE;
                        when ST_MUTE    => state_reg <= ST_L_L;
                        when ST_L_L     => state_reg <= ST_R_R;
                        when ST_R_R     => state_reg <= ST_LPR_LPR;
                        when ST_LPR_LPR => state_reg <= ST_LMR_LMR;
                        when ST_LMR_LMR => state_reg <= ST_LPR_LMR;
                        when ST_LPR_LMR => state_reg <= ST_LMR_LPR;
                        when ST_LMR_LPR => state_reg <= ST_L_R;
                    end case;
                end if;
            end if;
        end if;
    end process;

    
    process(aclk)
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                left_reg  <= (others => '0');
                right_reg <= (others => '0');
            elsif s_axis_tvalid = '1' and m_axis_tready = '1' then
                if s_axis_tlast = '0' then
                    left_reg <= signed(s_axis_tdata);
                else
                    right_reg <= signed(s_axis_tdata);
                end if;
            end if;
        end if;
    end process;

    -- output selector
    process(state_reg, s_axis_tdata, s_axis_tlast, left_reg, right_reg)
        variable data_in : signed(TDATA_WIDTH-1 downto 0);
        variable l_plus_r : signed(TDATA_WIDTH downto 0); -- Bit extra para suma
        variable l_minus_r : signed(TDATA_WIDTH downto 0);
    begin
        data_in := signed(s_axis_tdata);
        l_plus_r  := (left_reg & '0') ; -- Simplificado: Suma se divide por 2 [2]
        
        case state_reg is
            when ST_L_R => -- NORMAL STEREO
                m_axis_tdata <= s_axis_tdata;
                led_r <= x"FF"; led_g <= x"FF"; led_b <= x"FF"; -- BLANCO
                
            when ST_MUTE => -- SILENCE ON BOTH CHANNELS
                m_axis_tdata <= (others => '0'); 
                led_r <= x"FF"; led_g <= x"FF"; led_b <= x"00"; -- YELLOW
                
            when ST_L_L => --LEFT SIGNAL ON BOTH EARS
                m_axis_tdata <= std_logic_vector(left_reg); 
                led_r <= x"FF"; led_g <= x"00"; led_b <= x"FF"; -- MAGENTA
                
            when ST_R_R => --RIGTH SIGNAL ON BOTH EARS
                if s_axis_tlast = '1' then m_axis_tdata <= s_axis_tdata;
                else m_axis_tdata <= std_logic_vector(right_reg);
                end if;
                led_r <= x"FF"; led_g <= x"00"; led_b <= x"00"; -- Rojo
                
            when ST_LPR_LPR => --MONO MIX IN BOTH EARS
                m_axis_tdata <= std_logic_vector(resize((left_reg + data_in)/2, TDATA_WIDTH));
                led_r <= x"00"; led_g <= x"FF"; led_b <= x"FF"; -- Cian
                
            when ST_LMR_LMR => -- MID - REMOVED IN BOTH EARS (VOCALS OFTEN DISAPPEAR)
                if s_axis_tlast = '0' then -- Izquierdo (L-R_prev)/2
                    m_axis_tdata <= std_logic_vector(resize((data_in - right_reg)/2, TDATA_WIDTH));
                else -- Derecho (L_prev-R)/2
                    m_axis_tdata <= std_logic_vector(resize((left_reg - data_in)/2, TDATA_WIDTH));
                end if;
                led_r <= x"00"; led_g <= x"FF"; led_b <= x"00"; -- Verde
                
            when ST_LPR_LMR => --MID IN LEFT,MID REMOVED IN RIGTH
                if s_axis_tlast = '0' then m_axis_tdata <= std_logic_vector(resize((data_in + right_reg)/2, TDATA_WIDTH));
                else m_axis_tdata <= std_logic_vector(resize((left_reg - data_in)/2, TDATA_WIDTH));
                end if;
                led_r <= x"00"; led_g <= x"00"; led_b <= x"FF"; -- Azul
                
            when ST_LMR_LPR =>
                if s_axis_tlast = '0' then m_axis_tdata <= std_logic_vector(resize((data_in - right_reg)/2, TDATA_WIDTH));
                else m_axis_tdata <= std_logic_vector(resize((left_reg + data_in)/2, TDATA_WIDTH));
                end if;
                led_r <= x"00"; led_g <= x"00"; led_b <= x"00"; -- Apagado
                
            when others =>
                m_axis_tdata <= s_axis_tdata;
                led_r <= x"00"; led_g <= x"00"; led_b <= x"00";
        end case;
    end process;

end architecture;