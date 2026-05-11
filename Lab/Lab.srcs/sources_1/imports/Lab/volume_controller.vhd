--------------------------------------------------------------------------------
-- Top-level perceptual (exponential) volume control
--
-- Latency: 2 aclk cycles. Throughput: 1 sample / cycle.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_controller is
	Generic (
		TDATA_WIDTH		: positive := 24;
		VOLUME_WIDTH	: positive := 10;
		VOLUME_STEP_2	: positive := 6;		-- i.e., volume_values_per_step = 2**VOLUME_STEP_2
		HIGHER_BOUND	: integer := 2**23-1;	-- Inclusive (max value of TDATA at 24 bit signed)
		LOWER_BOUND		: integer := -2**23		-- Inclusive (min value of TDATA at 24 bit signed)
	);
	Port (
		aclk			: in std_logic; -- AXIS clock
		aresetn			: in std_logic; -- Active low synchronous reset

		s_axis_tvalid	: in std_logic; -- 
		s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tready	: out std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic;

		-- Unsigned volume index from effect_selector
		volume			: in std_logic_vector(VOLUME_WIDTH-1 downto 0) 
	);
end volume_controller;

architecture Behavioral of volume_controller is

	-- Maximum LEFT shift the multiplier can apply = (max step index) - (centre step) = 2^(STEP_WIDTH-1) - 1
	constant MAX_LSHIFT  : natural  := 2**(VOLUME_WIDTH - VOLUME_STEP_2 - 1) - 1;

	-- Width of the bus between multiplier and saturator.
	constant INTER_WIDTH : positive := TDATA_WIDTH + MAX_LSHIFT;
	-- Wide enough to hold the worst-case (TDATA_WIDTH-bit signed) << MAX_LSHIFT

	signal inter_tvalid : std_logic;
	signal inter_tdata  : std_logic_vector(INTER_WIDTH-1 downto 0);
	signal inter_tlast  : std_logic;
	signal inter_tready : std_logic;

	component volume_multiplier is
		Generic (
			TDATA_WIDTH		: positive;
			VOLUME_WIDTH	: positive;
			VOLUME_STEP_2	: positive;
			OUT_WIDTH		: positive
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
	end component;

	component volume_saturator is
		Generic (
			TDATA_WIDTH		: positive;
			IN_WIDTH		: positive;
			HIGHER_BOUND	: integer;
			LOWER_BOUND		: integer
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
	end component;

begin

	u_mult : volume_multiplier
		generic map (
			TDATA_WIDTH   => TDATA_WIDTH,
			VOLUME_WIDTH  => VOLUME_WIDTH,
			VOLUME_STEP_2 => VOLUME_STEP_2,
			OUT_WIDTH     => INTER_WIDTH
		)
		port map (
			aclk          => aclk,
			aresetn       => aresetn,

			s_axis_tvalid => s_axis_tvalid,
			s_axis_tdata  => s_axis_tdata,
			s_axis_tlast  => s_axis_tlast,
			s_axis_tready => s_axis_tready,

			m_axis_tvalid => inter_tvalid,
			m_axis_tdata  => inter_tdata,
			m_axis_tlast  => inter_tlast,
			m_axis_tready => inter_tready,

			volume        => volume
		);

	u_sat : volume_saturator
		generic map (
			TDATA_WIDTH  => TDATA_WIDTH,
			IN_WIDTH     => INTER_WIDTH,
			HIGHER_BOUND => HIGHER_BOUND,
			LOWER_BOUND  => LOWER_BOUND
		)
		port map (
			aclk          => aclk,
			aresetn       => aresetn,

			s_axis_tvalid => inter_tvalid,
			s_axis_tdata  => inter_tdata,
			s_axis_tlast  => inter_tlast,
			s_axis_tready => inter_tready,

			m_axis_tvalid => m_axis_tvalid,
			m_axis_tdata  => m_axis_tdata,
			m_axis_tlast  => m_axis_tlast,
			m_axis_tready => m_axis_tready
		);

end Behavioral;