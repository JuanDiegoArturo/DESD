library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity binary_to_decimal is
    port (
        clk : in std_logic;
        binary_num : in std_logic_vector(6 downto 0);
        decade_digit : out std_logic_vector(3 downto 0);
        unit_digit : out std_logic_vector(3 downto 0)
    );
end binary_to_decimal;

architecture rtl of binary_to_decimal is
begin

    process(clk)
        variable value_int : integer range 0 to 127;
        variable decade_int : integer range 0 to 9;
        variable unit_int : integer range 0 to 9;
    begin
        if rising_edge(clk) then

            value_int := to_integer(unsigned(binary_num));

            if value_int >= 60 then
                decade_int := 6;
                unit_int := 0;
            elsif value_int >= 50 then
                decade_int := 5;
                unit_int := value_int - 50;
            elsif value_int >= 40 then
                decade_int := 4;
                unit_int := value_int - 40;
            elsif value_int >= 30 then
                decade_int := 3;
                unit_int := value_int - 30;
            elsif value_int >= 20 then
                decade_int := 2;
                unit_int := value_int - 20;
            elsif value_int >= 10 then
                decade_int := 1;
                unit_int := value_int - 10;
            else
                decade_int := 0;
                unit_int := value_int;
            end if;

            decade_digit <= std_logic_vector(to_unsigned(decade_int, 4));
            unit_digit <= std_logic_vector(to_unsigned(unit_int, 4));

        end if;
    end process;

end rtl;