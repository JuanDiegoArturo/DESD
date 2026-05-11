--------------------------------------------------------------------------------
-- Signed saturating clip stage.
--
--   if  sample > HIGHER_BOUND  -> HIGHER_BOUND
--   if  sample < LOWER_BOUND   -> LOWER_BOUND
--   else                       -> resize(sample, TDATA_WIDTH)
--
-- Registered output, 1-cycle latency, full throughput.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_saturator is
	Generic (
		TDATA_WIDTH		: positive := 24;
		IN_WIDTH		: positive := 31;
		HIGHER_BOUND	: integer := 2**23-1;
		LOWER_BOUND		: integer := -2**23
	);
	Port (
		aclk			: in std_logic;
		aresetn			: in std_logic;

		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(IN_WIDTH-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tready	: out std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic
	);
end volume_saturator;

architecture Behavioral of volume_saturator is

	-- Bounds promoted to the input width so the comparison is well-typed
	constant HI_S : signed(IN_WIDTH-1 downto 0) := to_signed(HIGHER_BOUND, IN_WIDTH);
	constant LO_S : signed(IN_WIDTH-1 downto 0) := to_signed(LOWER_BOUND, IN_WIDTH);

	signal valid_r : std_logic := '0';
	signal last_r  : std_logic := '0';
	signal data_r  : signed(TDATA_WIDTH-1 downto 0) := (others => '0');

	signal load    : std_logic;

begin

	load          <= m_axis_tready or not valid_r;
	s_axis_tready <= load and aresetn;

	m_axis_tvalid <= valid_r;
	m_axis_tlast  <= last_r;
	m_axis_tdata  <= std_logic_vector(data_r);

	process(aclk)
		variable sample : signed(IN_WIDTH-1 downto 0);
	begin
		if rising_edge(aclk) then
			if aresetn = '0' then
				valid_r <= '0';
				last_r  <= '0';
				data_r  <= (others => '0');
			elsif load = '1' then
				valid_r <= s_axis_tvalid;
				if s_axis_tvalid = '1' then
					last_r <= s_axis_tlast;
					sample := signed(s_axis_tdata);

					if sample > HI_S then
						data_r <= to_signed(HIGHER_BOUND, TDATA_WIDTH);
					elsif sample < LO_S then
						data_r <= to_signed(LOWER_BOUND, TDATA_WIDTH);
					else
						data_r <= resize(sample, TDATA_WIDTH);
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;