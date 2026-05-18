--joystick
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity digilent_jstk2 is
	generic (
		DELAY_US		: integer := 25;			-- CONSTANT DO NOT TOUCH
		CLKFREQ		 	: integer := 100_000_000;	-- Base time
		SPI_SCLKFREQ 	: integer := 66_666			-- Base time
	);
	Port ( 
		aclk 			: in  STD_LOGIC;
		aresetn			: in  STD_LOGIC;

		m_axis_tvalid	: out STD_LOGIC;
		m_axis_tdata	: out STD_LOGIC_VECTOR(7 downto 0);
		m_axis_tready	: in STD_LOGIC;

		s_axis_tvalid	: in STD_LOGIC;
		s_axis_tdata	: in STD_LOGIC_VECTOR(7 downto 0);

		jstk_x			: out std_logic_vector(9 downto 0);
		jstk_y			: out std_logic_vector(9 downto 0);
		btn_jstk		: out std_logic;
		btn_trigger		: out std_logic;

		led_r			: in std_logic_vector(7 downto 0);
		led_g			: in std_logic_vector(7 downto 0);
		led_b			: in std_logic_vector(7 downto 0)
	);
end digilent_jstk2;

architecture Behavioral of digilent_jstk2 is
   --COSNTANTES SPI
	constant CMDSETLEDRGB : std_logic_vector(7 downto 0) := x"84";

	constant DELAY_CYCLES : integer := 
		DELAY_US * (CLKFREQ / 1_000_000) + CLKFREQ / SPI_SCLKFREQ;

	constant POLLING_CYCLES : integer := CLKFREQ / 100; -- 100 Hz

	--TX
	type state_type is (IDLE, CMD, R, G, B, DUMMY);
	signal state : state_type := IDLE;

	
	signal counter : integer range 0 to POLLING_CYCLES := 0;
	signal start_tx : std_logic := '0';

	
	type rx_array is array (0 to 4) of std_logic_vector(7 downto 0);
	signal rx_regs : rx_array := (others => (others => '0'));
	signal rx_count : integer range 0 to 4 := 0;

begin

	process(aclk, aresetn)
	begin
		if aresetn = '0' then
			counter <= 0;
			start_tx <= '0';
		elsif rising_edge(aclk) then
			start_tx <= '0';

			if counter = POLLING_CYCLES - 1 then
				counter <= 0;
				start_tx <= '1';
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;

	--transmision
	process(aclk, aresetn)
	begin
		if aresetn = '0' then
			state <= IDLE;
			m_axis_tvalid <= '0';
			m_axis_tdata <= (others => '0');
		elsif rising_edge(aclk) then

			case state is

				when IDLE =>
					if start_tx = '1' then
						state <= CMD;
						m_axis_tvalid <= '1';
						m_axis_tdata <= CMDSETLEDRGB;
					else
						m_axis_tvalid <= '0';
					end if;

				when CMD =>
					if m_axis_tready = '1' then
						state <= R;
						m_axis_tdata <= led_r;
					end if;

				when R =>
					if m_axis_tready = '1' then
						state <= G;
						m_axis_tdata <= led_g;
					end if;

				when G =>
					if m_axis_tready = '1' then
						state <= B;
						m_axis_tdata <= led_b;
					end if;

				when B =>
					if m_axis_tready = '1' then
						state <= DUMMY;
						m_axis_tdata <= x"00";
					end if;

				when DUMMY =>
					if m_axis_tready = '1' then
						m_axis_tvalid <= '0';
						state <= IDLE;
					end if;

			end case;
		end if;
	end process;

	--recepcion 
	process(aclk, aresetn)
	begin
		if aresetn = '0' then
			rx_count <= 0;
			jstk_x <= (others => '0');
			jstk_y <= (others => '0');
			btn_jstk <= '0';
			btn_trigger <= '0';

		elsif rising_edge(aclk) then

			if s_axis_tvalid = '1' then

				rx_regs(rx_count) <= s_axis_tdata;

				if rx_count = 4 then
					rx_count <= 0;

					
					jstk_x <= rx_regs(1)(1 downto 0) & rx_regs(0);
					jstk_y <= rx_regs(3)(1 downto 0) & rx_regs(2);

					
					btn_jstk <= s_axis_tdata(0);
					btn_trigger <= s_axis_tdata(1);

				else
					rx_count <= rx_count + 1;
				end if;

			end if;

		end if;
	end process;

end Behavioral;