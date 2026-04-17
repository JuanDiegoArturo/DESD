---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCarPWM is
	Generic (

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

		NUM_OF_SWS				:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of input switches
		NUM_OF_LEDS				:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of output LEDs

		TAIL_LENGTH				:	INTEGER	RANGE	1 TO 16	:= 4	-- Tail length
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
end KittCarPWM;

architecture Behavioral of KittCarPWM is

-- Signal Definition for the KittCar
constant BASE_COUNT : integer := (1_000_000 / CLK_PERIOD_NS) * MIN_KITT_CAR_STEP_MS;
-- Convierte el tiempo base (deltaT0) a cantidad de ciclos de reloj.
signal counter : unsigned(32 downto 0) := (others => '0');
-- Cuenta ciclos hasta del reloj hasta que toque mover el carro.
signal max_count : unsigned(32 downto 0) := to_unsigned(BASE_COUNT, 33);
-- Depende de los switches, dice cuantos ciclos esperar antes de mover la cabeza.
signal head_pos: integer range 0 to NUM_OF_LEDS-1 := 0;
-- Ya no guardo todo el padron de LEDs en un shift register, ahora solo guardo la posición de la cabeza
signal direction_flag : std_logic := '1';
-- 1 hacia la izquierda, 0 hacia la derecha.

-- Signal Definition for the PWM
signal pwm_counter : integer range 0 to TAIL_LENGTH - 1 :=0;
-- Contador del PWM que recorre los niveles 0, 1, 2, ..., TAIL_LENGHT.
signal led_int : std_logic_vector(NUM_OF_LEDS-1 downto 0) := (others => '0');
-- Vector interno que se calcula con la cola del PWM, luego se conecta a la salida led.

begin
    led <= led_int;
    -- led_int es la salida calculada internamente, led el puerto físico que sale a la placa.
        process(clk, reset)
        begin
            if reset = '1' then
                counter <= (others => '0');
                max_count <= to_unsigned(BASE_COUNT , 33);
                head_pos <= 0;
                direction_flag <= '1';
                pwm_counter <= 0;
            elsif rising_edge(clk) then 
                max_count <= to_unsigned(BASE_COUNT * (to_integer(unsigned(sw))+1), 33); --Asignación # ciclos con sw
                -- If correspondiente al contador del PWM
                if pwm_counter = TAIL_LENGTH - 1 then
                    pwm_counter <= 0;
                else
                    pwm_counter <= pwm_counter + 1;
                end if; -- Contador para decidir si cada LED debe verse encendido, 3/4, 1/2, ... o apagado
                -- Ahora IF correspondiente al control de movimiento de la cabeza
                if counter >= max_count then
                    counter <= (others => '0'); -- Contador KittCar tiempo deseado, lo reinicia y mueve la cabeza un paso
                    -- Movimiento básicamente cada counter max
                    if direction_flag = '1' then -- Si la cabeza va hacia la izquierda
                        if head_pos = NUM_OF_LEDS - 1 then -- Si ya llegó al extremo izquierdo
                            direction_flag <= '0'; -- Cambiar la dirección
                            head_pos <= NUM_OF_LEDS - 2; -- Rebote sin repetir el extremo
                        else -- si no estoy en el extremo simplemente avanzo
                            head_pos <= head_pos +1;
                        end if;
                    else
                        if head_pos = 0 then
                            direction_flag <= '1';
                            head_pos <= 1;
                        else
                            head_pos <= head_pos -1;
                        end if;
                    end if;
                else
                    counter <= counter +1; -- seguir contando si no se ha alcanzado el número de ciclos deseados. (no hay movimiento)    
                end if;
         end if;
         -- Hasta aquí tenemos el KittCar, ahora falta encender la colita papa
        end process;
        
        process(head_pos, direction_flag, pwm_counter)
        -- Cada que cambie la posición de la cabeza, la dirección o el PWM recalcula led_int (vector salida)
            variable distance : integer; -- Distancia entre un led cualquiera y la cabeza
            variable brightness_level : integer; -- Nivel de brillo que le corresponde a ese LED.
        begin 
            led_int <= (others => '0');
            for i in 0 to NUM_OF_LEDS-1 loop -- revisar led por led y mirar si forma parte de cabeza o cola
                if direction_flag = '1' then
                    distance := head_pos - i; -- Cabeza hacia indices mayores
                else 
                    distance := i - head_pos; -- Cabeza hacia indices menores
                end if;
                
                if (distance >=0) and (distance < TAIL_LENGTH) then
                    brightness_level := TAIL_LENGTH - distance; 
                    --Cola lineal
                    if pwm_counter < brightness_level then 
                        led_int(i) <= '1';
                    end if;
                end if;
            end loop;
        end process;
        
      
end Behavioral;
