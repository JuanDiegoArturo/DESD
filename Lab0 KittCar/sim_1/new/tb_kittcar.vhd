---------- DEFAULT LIBRARY ---------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity tb_KittCarPWM is
end tb_KittCarPWM;

architecture Behavioral of tb_KittCarPWM is

    -- Constant Definition for the Test Bench
    constant CLK_PERIOD : time := 10 ns; -- Reloj de 100 MHz (10ns por ciclo)
    
    -- Signal Definition for the Test Bench
    signal reset_tb : std_logic := '1';
    signal clk_tb   : std_logic := '0';
    signal sw_tb    : std_logic_vector(15 downto 0) := (others => '0');
    signal led_tb   : std_logic_vector(15 downto 0);

begin
    uut: entity work.KittCarPWM
        generic map (
            CLK_PERIOD_NS        => 10,
            MIN_KITT_CAR_STEP_MS => 1, 
            NUM_OF_SWS           => 16,
            NUM_OF_LEDS          => 16,
            TAIL_LENGTH          => 4   -- Longitud de la cola Kitt
        )
        port map (
            reset => reset_tb,
            clk   => clk_tb,
            sw    => sw_tb,
            led   => led_tb
        );

   --clock
    process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    --Procesos
    process
    begin
        -- Aplicar Reset inicial
        reset_tb <= '1';
        wait for 100 ns;
        reset_tb <= '0';

        -- Caso 1: Velocidad máxima (Switches en 0)
        -- max_count = BASE_COUNT * (0 + 1)
        sw_tb <= x"0000"; 
        wait for 2 ms; 

        -- Caso 2: Velocidad reducida (Switches en 1)
        -- max_count = BASE_COUNT * (1 + 1) -> mitad de velocidad
        sw_tb <= x"0001";
        wait for 4 ms;

        -- stop
        wait;
    end process;

end Behavioral;