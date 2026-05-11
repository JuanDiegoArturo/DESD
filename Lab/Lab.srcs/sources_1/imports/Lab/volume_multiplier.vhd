--------------------------------------------------------------------------------
-- Exponential gain stage for volume_controller.
--
--   step        = unsigned(volume(VOLUME_WIDTH-1 downto VOLUME_STEP_2))
--   CENTER_STEP = 2^(VOLUME_WIDTH-VOLUME_STEP_2-1)        (unity gain)
--   if step >= CENTER_STEP:  out = sample << (step - CENTER_STEP)
--   else                  :  out = sample >> (CENTER_STEP - step)
--
-- Output is sign-extended to OUT_WIDTH bits; the volume_saturator clips it.
-- Registered output, 1-cycle latency, full throughput.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_multiplier is
	Generic (
		TDATA_WIDTH		: positive := 24;
		VOLUME_WIDTH	: positive := 10;
		VOLUME_STEP_2	: positive := 6;
		OUT_WIDTH		: positive := 31		-- = TDATA_WIDTH + 2^(VOLUME_WIDTH-VOLUME_STEP_2-1) - 1
	);
	Port (
		aclk			: in std_logic;
		aresetn			: in std_logic;

		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tready	: out std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(OUT_WIDTH-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic;

		volume			: in std_logic_vector(VOLUME_WIDTH-1 downto 0)
	);
end volume_multiplier;

architecture Behavioral of volume_multiplier is

	constant STEP_WIDTH    : positive := VOLUME_WIDTH - VOLUME_STEP_2;
	constant CENTER_STEP_U : unsigned(STEP_WIDTH-1 downto 0) := to_unsigned(2**(STEP_WIDTH-1), STEP_WIDTH);

	signal valid_r : std_logic := '0';
	signal last_r  : std_logic := '0';
	signal data_r  : signed(OUT_WIDTH-1 downto 0) := (others => '0');

	signal load    : std_logic;

begin

	-- AXI4-Stream:
	load          <= m_axis_tready or not valid_r;
	s_axis_tready <= load and aresetn;

	m_axis_tvalid <= valid_r;
	m_axis_tlast  <= last_r;
	m_axis_tdata  <= std_logic_vector(data_r);

	process(aclk)
		variable step_u   : unsigned(STEP_WIDTH-1 downto 0);
		variable extended : signed(OUT_WIDTH-1 downto 0);
	begin
		if rising_edge(aclk) then
			if aresetn = '0' then
				valid_r <= '0';
				last_r  <= '0';
				data_r  <= (others => '0');
			elsif load = '1' then
				valid_r <= s_axis_tvalid;
				if s_axis_tvalid = '1' then
					last_r   <= s_axis_tlast;
					step_u   := unsigned(volume(VOLUME_WIDTH-1 downto VOLUME_STEP_2));
					extended := resize(signed(s_axis_tdata), OUT_WIDTH);

					if step_u >= CENTER_STEP_U then
						-- Amplify: arithmetic left shift, sign preserved
						data_r <= shift_left(extended,
						                     to_integer(step_u - CENTER_STEP_U));
					else
						-- Attenuate: arithmetic right shift, sign preserved
						data_r <= shift_right(extended,
						                      to_integer(CENTER_STEP_U - step_u));
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;