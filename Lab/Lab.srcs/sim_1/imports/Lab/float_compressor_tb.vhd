library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_compressor_tb is
end entity float_compressor_tb;

architecture rtl of float_compressor_tb is

    component float_compressor is
        generic(
            CHANNEL_LENGHT  : positive := 24;
            OUTPUT_LENGHT  : positive := 16;
            EXPONENT_LENGTH : POSITIVE := 4
        );
        port (
            aclk   : in std_logic;
            aresetn : in std_logic;

            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast    : in std_logic;
            s_axis_tready	: out std_logic;
        
            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(OUTPUT_LENGHT-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic

        );
    end component;

    type test_vec_type is array(natural range<>) of integer;
    signal test_vec : test_vec_type(0 to 7) :=(
        0=>1,
        1=>2**22,
        2=>-2**20,
        3=>0,
        4=>-1020,
        5=>4194300,
        6=>-131700,
        7=>515
    );

    constant CHANNEL_LENGHT  : positive := 24;
    constant OUTPUT_LENGHT  : positive := 16;
    constant EXPONENT_LENGTH : POSITIVE := 4;

    signal aclk   : std_logic := '0';
    signal aresetn : std_logic;

    signal s_axis_tvalid	: std_logic :='0';
    signal s_axis_tdata	: std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal s_axis_tlast    : std_logic :='1';
    signal s_axis_tready	: std_logic;

    signal data_in_int : integer :=0;
        
    signal m_axis_tvalid	: std_logic;
    signal m_axis_tdata	: std_logic_vector(OUTPUT_LENGHT-1 downto 0);
    signal m_axis_tlast : std_logic;
    signal m_axis_tready	: std_logic;

begin
    
    aresetn<='1';
    aclk<= not aclk after 5 ns;
    m_axis_tready<='1';

    s_axis_tdata<=std_logic_vector(to_signed(data_in_int,s_axis_tdata'length));

    float_compressor_inst: float_compressor
     generic map(
        CHANNEL_LENGHT => CHANNEL_LENGHT,
        OUTPUT_LENGHT => OUTPUT_LENGHT,
        EXPONENT_LENGTH => EXPONENT_LENGTH
    )
     port map(
        aclk => aclk,
        aresetn => aresetn,
        s_axis_tvalid => s_axis_tvalid,
        s_axis_tdata => s_axis_tdata,
        s_axis_tlast => s_axis_tlast,
        s_axis_tready => s_axis_tready,
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tdata => m_axis_tdata,
        m_axis_tlast => m_axis_tlast,
        m_axis_tready => m_axis_tready
    );

    process
    begin

        wait until rising_edge(aclk);
        for I in test_vec'range loop
            data_in_int<=test_vec(I);
            s_axis_tlast<=not s_axis_tlast;
            s_axis_tvalid<='1';
            wait until s_axis_tready='1';
            wait until rising_edge(aclk);
        end loop;
        s_axis_tvalid<='0';
        wait;


        
    end process;

end architecture;