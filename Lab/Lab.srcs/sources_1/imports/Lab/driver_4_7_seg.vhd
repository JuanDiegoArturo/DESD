library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity driver_4_7seg is
    generic (
        mux_time_ms     : positive := 1;
        clock_period_ns : positive := 10
    );
    port (
        clk    : in std_logic;
        resetn : in std_logic;

        num1 : in std_logic_vector(3 downto 0);
        num2 : in std_logic_vector(3 downto 0);
        num3 : in std_logic_vector(3 downto 0);
        num4 : in std_logic_vector(3 downto 0);

        an  : out std_logic_vector(3 downto 0);
        seg : out std_logic_vector(0 to 6);
        dp  : out std_logic
    );
end entity driver_4_7seg;

architecture Behavioral of driver_4_7seg is

    signal num   : std_logic_vector(3 downto 0) := (others => '0');
    signal seg_s : std_logic_vector(0 to 6) := (others => '1');

    constant MUX_LIMIT : positive := (mux_time_ms * 1000000) / clock_period_ns;

    signal mux_counter : integer range 0 to MUX_LIMIT-1 := 0;
    signal digit_sel   : unsigned(1 downto 0) := (others => '0');

begin

    with num select seg_s <=
        "0000001" when "0000",
        "1001111" when "0001",
        "0010010" when "0010",
        "0000110" when "0011",
        "1001100" when "0100",
        "0100100" when "0101",
        "0100000" when "0110",
        "0001111" when "0111",
        "0000000" when "1000",
        "0000100" when "1001",
        "0001000" when "1010",
        "1100000" when "1011",
        "0110001" when "1100",
        "1000010" when "1101",
        "0110000" when "1110",
        "0111000" when "1111",
        "1111111" when others;

    process(clk)
    begin
        if rising_edge(clk) then

            if resetn = '0' then
                mux_counter <= 0;
                digit_sel   <= (others => '0');
            else
                if mux_counter = MUX_LIMIT-1 then
                    mux_counter <= 0;
                    digit_sel   <= digit_sel + 1;
                else
                    mux_counter <= mux_counter + 1;
                end if;
            end if;

        end if;
    end process;

    process(digit_sel, num1, num2, num3, num4)
    begin

        case digit_sel is

            when "00" =>
                an  <= "1110";
                num <= num1;

            when "01" =>
                an  <= "1101";
                num <= num2;

            when "10" =>
                an  <= "1011";
                num <= num3;

            when others =>
                an  <= "0111";
                num <= num4;

        end case;

    end process;

    seg <= seg_s;
    dp  <= '1';

end architecture Behavioral;