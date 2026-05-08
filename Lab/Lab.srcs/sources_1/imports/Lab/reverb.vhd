----------------------------------------------------------------------------------
-- Stereo feedback reverberator
-- Implements the formula required for the lab:
    -- mul_res = gain_in * y[n-delay_in]
    -- data_gain = mul_res / 2^GAIN_LENGHT
    -- sum_res = x[n] + data_gain
    -- y[n] = sat(sum_res)

-- x[n]is the current AXIS input sample
-- y[n] is the corresponding output sample
-- y[n - delay_in] comes from the delay block

-- Stereo: instantiates two delay blocks (one per channel)

-- Assumptions:
    -- s_axis_tlast follows lab's convention (0=left, 1=right)
    -- the delay's data_out is stable and valid at the cycle after delay_in changes
    -- Keep feeding y[n] into the delay buffers in bypass mode
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reverb is
    generic(
        LOG2_DELAY_INCR : integer :=1;              -- CONSTANT DO NOT TOUCH (internal delay parameter)
        CHANNEL_LENGHT  : integer := 24;            -- 3 byte for audio (32 bit signed audio samples)
        DELAY_LENGHT  : integer := 10;              -- JSTK y-axis dimension 
        DELAY_INIT : integer := 882;                -- 20 ms initial delay forwarded to each delay block                    INIT VALUE  DO NOT TOUCH
        GAIN_LENGHT : integer := 10;                -- JSTK axis dimension (gain_in width)
        GAIN_INIT_FRAC : integer := 614;            --614/(2^10) ~= 0.6         INIT VALUE  DO NOT TOUCH
        HIGHER_BOUND	: integer := 2**23-1;	    -- Inclusive upper saturation bound (max value of TDATA at 24 bit signed)
		LOWER_BOUND		: integer := -2**23		    -- Inclusive lower saturation bound (min value of TDATA at 24 bit signed)
    );
    Port (
        
            aclk			: in std_logic;     -- AXIS clock (same for input and output)
            aresetn			: in std_logic;     -- Active low synchronous reset
            
            enable_reverb   : in std_logic;     -- 1 = effect on, 0 = pass-through (Driven with SW1)

            delay_in        : in std_logic_vector(DELAY_LENGHT-1 downto 0); -- Current delay length unsigned from JSTK Y-axis

            gain_in         : in std_logic_vector(GAIN_LENGHT-1 downto 0);  -- Current feedback gain unsigned from JSTK X-axis
    
            -- Stereo input stream (TLAST = 0 LEFT, TLAST = 1 RIGHT)
            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast    : in std_logic;
            s_axis_tready	: out std_logic;
                
            -- Reverberated output stream, same channel convention
            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic
        );
end reverb;

architecture Behavioral of reverb is -- Provided, encrypted
    component delay is
        generic(
            CHANNEL_LENGHT  : integer;
            DELAY_LENGHT  : integer;
            DELAY_INIT : integer;
            LOG2_DELAY_INCR : integer
        );
        Port (
            
                aclk			: in std_logic;
                aresetn			: in std_logic;
                
                delay_in        : in std_logic_vector(DELAY_LENGHT-1 downto 0);
        
                data_in	        : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
                data_in_valid	: in std_logic;
        
                data_out	    : out std_logic_vector(CHANNEL_LENGHT-1 downto 0)
        );
    end component;

-- AXIS FSM
type state_t is (S_RECV, S_COMPUTE, S_SEND);
signal state: state_t := S_RECV;

-- Latched per-sample inputs 
signal x_n_reg : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0'); -- 24 bit signed sample
signal channel_reg : std_logic := '0'; -- '0' = Left (TLAST=0), '1' = Right (TLAST=1)

-- Output sample register
signal y_n_reg : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
signal y_n_slv : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

-- Delay block connections (one buffer per channel)
signal delay_l_data_out : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
signal delay_r_data_out : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
signal delay_l_valid : std_logic;
signal delay_r_valid : std_logic;

begin

-- Two delay buffers; gated by channel_reg on the write side
-- Both see the same delay_in input from the joystick on the read side

delay_left : delay
    generic map (
        CHANNEL_LENGHT => CHANNEL_LENGHT,
        DELAY_LENGHT => DELAY_LENGHT,
        DELAY_INIT => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map (
        aclk => aclk,
        aresetn => aresetn,
        delay_in => delay_in,
        data_in => y_n_slv,
        data_in_valid => delay_l_valid,
        data_out => delay_l_data_out
    );

delay_right : delay
    generic map (
        CHANNEL_LENGHT => CHANNEL_LENGHT,
        DELAY_LENGHT => DELAY_LENGHT,
        DELAY_INIT => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map (
        aclk => aclk,
        aresetn => aresetn,
        delay_in => delay_in,
        data_in => y_n_slv,
        data_in_valid => delay_r_valid,
        data_out => delay_r_data_out
    );

-- Combinational outputs
y_n_slv <= std_logic_vector(y_n_reg);
s_axis_tready <= '1' when (state = S_RECV) else '0';
m_axis_tvalid <= '1' when (state = S_SEND) else '0';
m_axis_tdata <= std_logic_vector(y_n_reg);
m_axis_tlast <= channel_reg; -- Output TLAST the same as input TLAST (channel_reg)

-- Pulse data_in_valid for the relevant delay on the m_axis handshake
delay_l_valid <= '1' when (state = S_SEND and channel_reg = '0' and m_axis_tready = '1') else '0';
delay_r_valid <= '1' when (state = S_SEND and channel_reg = '1' and m_axis_tready = '1') else '0';

-- 3 state FSM sequential process to decouple handshake from arithmetic to allow zero combinational paths between input and output 
-- Each AXIS sample takes 3 cycles plus any wait for tready.
process(aclk)
    variable y_delayed : signed(CHANNEL_LENGHT-1 downto 0);
    variable gain_sgn : signed(GAIN_LENGHT downto 0);
    variable mul_res : signed(CHANNEL_LENGHT+GAIN_LENGHT downto 0);
    variable data_gain : signed(CHANNEL_LENGHT-1 downto 0);
    variable sum_res : signed(CHANNEL_LENGHT downto 0); -- 25 signed, cannot overflow 

begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            state <= S_RECV;
            x_n_reg <= (others => '0');
            channel_reg <= '0';
            y_n_reg <= (others => '0');
        else 
            case state is 

                when S_RECV =>
                    -- JSTK changes orders of magnitude slower than audio sample rate
                    -- So the delay sees delay_in continously and it's read pointer is already setteled when we sample data_out
                    if s_axis_tvalid = '1' then -- On a valid handshake
                        x_n_reg <= signed(s_axis_tdata); -- latches current sample
                        channel_reg <= s_axis_tlast; -- L/R channel determined by TLAST
                        state <= S_COMPUTE; -- Move to compute state
                    end if;
                
                when S_COMPUTE => -- Performs the multiply / shift / add / saturate
                    if enable_reverb = '1' then
                        -- Pick this channel's delayed sample
                        if channel_reg = '0' then
                            y_delayed := signed(delay_l_data_out);
                        else
                            y_delayed := signed(delay_r_data_out);
                        end if;
                        
                        -- zero-extend gain to signed (gain is unsigned, never negative)
                        gain_sgn := signed('0' & gain_in); 

                        -- mul_res = gain_in * y[n-delay_in]
                        mul_res := gain_sgn * y_delayed;

                        -- data_gain = mul_res / 2^GAIN_LENGHT
                        -- implemented as an arithmetic shift right so it preserves the sign of the feedback term
                        data_gain := resize(shift_right(mul_res, GAIN_LENGHT), CHANNEL_LENGHT);

                        -- sum_res = x[n] + data_gain (extended by 1 bit so it cannot overflow)
                        sum_res := resize(x_n_reg, CHANNEL_LENGHT+1) + resize(data_gain, CHANNEL_LENGHT+1);

                        -- Saturate to TDATA range if necessary and register the result to y_n_reg
                        if sum_res > to_signed(HIGHER_BOUND, sum_res'length) then
                            y_n_reg <= to_signed(HIGHER_BOUND, CHANNEL_LENGHT);
                        elsif sum_res < to_signed(LOWER_BOUND, sum_res'length) then
                            y_n_reg <= to_signed(LOWER_BOUND, CHANNEL_LENGHT);
                        else
                            y_n_reg <= resize(sum_res, CHANNEL_LENGHT);
                        end if;
                    else -- (enable_reverb = '0')
                        -- Bypass: y[n] = x[n] and still feeds the delay with the pass-through sample
                        -- Toggling SW1 = 1 produces a reverb tail based on the most recent 10ms of audio
                        y_n_reg <= x_n_reg;
                    end if;
                    state <= S_SEND;
                
                when S_SEND =>
                    -- Wait for master to accept the sample with m_axis_tready, then go back to receiving the next sample
                    if m_axis_tready = '1' then 
                        state <= S_RECV; 
                    end if;

            end case;
        end if;
    end if;
end process;
end Behavioral;
