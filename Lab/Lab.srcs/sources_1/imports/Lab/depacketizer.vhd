library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity depacketizer is
    generic (
        TDATA_WIDTH : integer := 8;
        HEADER : std_logic_vector := X"69";
        FOOTER : std_logic_vector := X"42";
        CLK_FREQ_HZ : integer := 100000000
    );
    port (
        aclk : in std_logic;
        aresetn : in std_logic;

        s_axis_tvalid : in std_logic;
        s_axis_tdata  : in std_logic_vector(TDATA_WIDTH-1 downto 0);
        s_axis_tready : out std_logic;

        send_audio : out std_logic;
        remaining_minutes : out std_logic_vector(6 downto 0);
        remaining_seconds : out std_logic_vector(6 downto 0)
    );
end entity depacketizer;

architecture rtl of depacketizer is

    type parser_state_type is (WAIT_HEADER, WAIT_MIN, WAIT_SEC, WAIT_FOOTER);
    signal parser_state : parser_state_type := WAIT_HEADER;

    signal s_axis_tready_reg : std_logic := '0';
    signal send_audio_reg : std_logic := '0';

    signal remaining_minutes_reg : unsigned(6 downto 0) := (others => '0');
    signal remaining_seconds_reg : unsigned(6 downto 0) := (others => '0');

    signal min_reg : unsigned(6 downto 0) := (others => '0');
    signal sec_reg : unsigned(6 downto 0) := (others => '0');

    signal one_second_counter : integer range 0 to CLK_FREQ_HZ-1 := 0;

begin

    s_axis_tready <= s_axis_tready_reg;
    send_audio <= send_audio_reg;

    remaining_minutes <= std_logic_vector(remaining_minutes_reg);
    remaining_seconds <= std_logic_vector(remaining_seconds_reg);

    process(aclk)
        variable received_byte : std_logic_vector(TDATA_WIDTH-1 downto 0);
        variable min_valid : boolean;
        variable sec_valid : boolean;
        variable stop_command : boolean;
    begin
        if rising_edge(aclk) then

            if aresetn = '0' then

                parser_state <= WAIT_HEADER;
                s_axis_tready_reg <= '0';
                send_audio_reg <= '0';

                remaining_minutes_reg <= (others => '0');
                remaining_seconds_reg <= (others => '0');

                min_reg <= (others => '0');
                sec_reg <= (others => '0');

                one_second_counter <= 0;

            else

                s_axis_tready_reg <= '1';

                if send_audio_reg = '1' then

                    if one_second_counter = CLK_FREQ_HZ-1 then

                        one_second_counter <= 0;

                        if remaining_minutes_reg = 0 and remaining_seconds_reg = 0 then

                            send_audio_reg <= '0';

                        elsif remaining_minutes_reg = 0 and remaining_seconds_reg = 1 then

                            remaining_seconds_reg <= (others => '0');
                            send_audio_reg <= '0';

                        elsif remaining_seconds_reg = 0 then

                            remaining_minutes_reg <= remaining_minutes_reg - 1;
                            remaining_seconds_reg <= to_unsigned(59, 7);

                        else

                            remaining_seconds_reg <= remaining_seconds_reg - 1;

                        end if;

                    else

                        one_second_counter <= one_second_counter + 1;

                    end if;

                else

                    one_second_counter <= 0;

                end if;

                if s_axis_tvalid = '1' and s_axis_tready_reg = '1' then

                    received_byte := s_axis_tdata;

                    case parser_state is

                        when WAIT_HEADER =>

                            if received_byte = HEADER then
                                parser_state <= WAIT_MIN;
                            else
                                parser_state <= WAIT_HEADER;
                            end if;

                        when WAIT_MIN =>

                            min_reg <= resize(unsigned(received_byte), 7);
                            parser_state <= WAIT_SEC;

                        when WAIT_SEC =>

                            sec_reg <= resize(unsigned(received_byte), 7);
                            parser_state <= WAIT_FOOTER;

                        when WAIT_FOOTER =>

                            if received_byte = FOOTER then

                                min_valid := min_reg <= to_unsigned(60, 7);
                                sec_valid := sec_reg <= to_unsigned(59, 7);
                                stop_command := (min_reg = 0 and sec_reg = 0);

                                if min_valid and sec_valid then

                                    if send_audio_reg = '1' then

                                        if stop_command then
                                            send_audio_reg <= '0';
                                            remaining_minutes_reg <= (others => '0');
                                            remaining_seconds_reg <= (others => '0');
                                            one_second_counter <= 0;
                                        end if;

                                    else

                                        if not stop_command then
                                            remaining_minutes_reg <= min_reg;
                                            remaining_seconds_reg <= sec_reg;
                                            send_audio_reg <= '1';
                                            one_second_counter <= 0;
                                        end if;

                                    end if;

                                end if;

                            end if;

                            parser_state <= WAIT_HEADER;

                    end case;

                end if;

            end if;

        end if;
    end process;

end architecture rtl;