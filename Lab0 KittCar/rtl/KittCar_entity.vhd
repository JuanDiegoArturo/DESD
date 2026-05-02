---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCar is
	Generic (

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

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
    -- Constant
    constant BASE_COUNT : integer := (1_000_000 / CLK_PERIOD_NS) * MIN_KITT_CAR_STEP_MS;
    -- Signals
    signal counter : unsigned(32 downto 0) := (others => '0');
    signal max_count : unsigned(32 downto 0) := to_unsigned(BASE_COUNT,33); 
    signal led_shift_reg : std_logic_vector(NUM_OF_LEDS-1 downto 0) := (0 => '1', others => '0');
    signal direction_flag : std_logic := '1';

begin

    led <= led_shift_reg;
    
    process(clk, reset)
    begin 
        -- Reset asíncrono
        if reset = '1' then
            counter <= (others => '0');
            max_count <= to_unsigned(BASE_COUNT, 33); 
            led_shift_reg <= (0 => '1', others => '0');
            direction_flag <= '1';
        elsif rising_edge(clk) then
            max_count <= to_unsigned(BASE_COUNT * (to_integer(unsigned(sw)) + 1), 33);
            if counter >= max_count then
                counter <= (others => '0');
                if direction_flag = '1' then
                    if led_shift_reg(NUM_OF_LEDS-1) = '1' then
                        direction_flag <= '0';
                        led_shift_reg <= '0' & led_shift_reg(NUM_OF_LEDS-1 downto 1);
                    else
                        led_shift_reg <= led_shift_reg(NUM_OF_LEDS-2 downto 0) & '0';
                    end if;
                else
                    if led_shift_reg(0) = '1' then
                        direction_flag <= '1';
                        led_shift_reg <= led_shift_reg(NUM_OF_LEDS-2 downto 0) & '0';
                    else    
                        led_shift_reg <= '0' & led_shift_reg(NUM_OF_LEDS-1 downto 1);
                    end if;
                end if;
            else 
                counter <= counter + 1;
            end if;
        end if;
    
    end process;

end Behavioral;
