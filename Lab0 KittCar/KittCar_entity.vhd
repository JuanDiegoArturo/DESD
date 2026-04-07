---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCar is
	Generic (

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (?t0 [ms])

		NUM_OF_SWS		:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of input switches
		NUM_OF_LEDS		:	INTEGER	RANGE	1 TO 16 := 16	-- Number of output LEDs

	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		-------- LEDs/SWs ----------
		sw		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		led	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
		----------------------------

	);
end KittCar;

architecture Behavioral of KittCar is

constant BASE_COUNT : integer := (1_000_000 / CLK_PERIOD_NS) * MIN_KITT_CAR_STEP_MS;	-- Number of clock cycles in ?t0

signal counter : unsigned(32 downto 0) := (others => '0'); -- Clock cycle counter
signal max_count : unsigned(32 downto 0) := to_unsigned(BASE_COUNT, 33);	-- Maximum count of clock cycles to wait before shifting LEDs  

-- With all 16 switches ON, the maximum value of max_count is (2^16-1)*BASE_COUNT = 6.553.600.000 
-- This number needs 33 bits to be represented

signal led_shift_reg : std_logic_vector(NUM_OF_LEDS-1 downto 0) := (others => '0');	-- Register to hold the current LED state
signal direction_flag : std_logic := '1';	-- '1' for left, '0' for right

begin

	process(clk, reset) -- Sequential process 
	begin
		if reset = '1' then -- asynchronous reset
			counter <= (others => '0');
			led_shift_reg <= (others => '0');
			led_shift_reg(0) <= '1';	-- Set the rightmost LED ON
			direction_flag <= '1';	-- Set initial direction to the left
		
		elsif rising_edge(clk) then
			max_count <= to_unsigned(BASE_COUNT * (to_integer(unsigned(sw))+1),33);	-- Update based on switch input to modulate speed 
			if counter >= max_count then
				counter <= (others => '0');	-- Reset counter
				if direction_flag = '1' then
					if led_shift_reg(NUM_OF_LEDS-1) = '1' then -- If the last LED is ON, change direction
						direction_flag <= '0'; -- Bounce back to the right
					else
						led_shift_reg <= led_shift_reg(NUM_OF_LEDS-2 downto 0) & '0'; -- Shift left on the next clock cycle
					end if;					
				else
					if led_shift_reg(0) = '1' then
						direction_flag <= '1'; -- Bounce back to the left
					else
						led_shift_reg <= '0' & led_shift_reg(NUM_OF_LEDS-1 downto 1); -- Shift right on the next clock cycle
					end if;
				end if;
			else
				counter <= counter + 1;	-- Increment counter to wait clock cycles
			end if;
		end if;
	end process;

	led <= led_shift_reg;	-- Output the current LED state, this is a concurrent assignment. Doesn't need clock

end Behavioral;
