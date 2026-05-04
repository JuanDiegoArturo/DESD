--Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
--Date        : Mon Apr 13 13:14:01 2026
--Host        : gbonanno-b450gamingx running 64-bit Ubuntu 24.04.2 LTS
--Command     : generate_target design_1_wrapper.bd
--Design      : design_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_wrapper is
  port (
    SPI_M_0_io0_io : inout STD_LOGIC;
    SPI_M_0_io1_io : inout STD_LOGIC;
    SPI_M_0_sck_io : inout STD_LOGIC;
    SPI_M_0_ss_io : inout STD_LOGIC;
    an : out STD_LOGIC_VECTOR ( 3 downto 0 );
    dp : out STD_LOGIC;
    enable_filter : in STD_LOGIC;
    enable_reverb : in STD_LOGIC;
    led : out STD_LOGIC_VECTOR ( 15 downto 0 );
    reset : in STD_LOGIC;
    rx_lrck_0 : out STD_LOGIC;
    rx_mclk_0 : out STD_LOGIC;
    rx_sclk_0 : out STD_LOGIC;
    rx_sdin_0 : in STD_LOGIC;
    seg : out STD_LOGIC_VECTOR ( 0 to 6 );
    sys_clock : in STD_LOGIC;
    tx_lrck_0 : out STD_LOGIC;
    tx_mclk_0 : out STD_LOGIC;
    tx_sclk_0 : out STD_LOGIC;
    tx_sdout_0 : out STD_LOGIC;
    usb_uart_rxd : in STD_LOGIC;
    usb_uart_txd : out STD_LOGIC
  );
end design_1_wrapper;

architecture STRUCTURE of design_1_wrapper is
  component design_1 is
  port (
    reset : in STD_LOGIC;
    enable_filter : in STD_LOGIC;
    seg : out STD_LOGIC_VECTOR ( 0 to 6 );
    an : out STD_LOGIC_VECTOR ( 3 downto 0 );
    dp : out STD_LOGIC;
    enable_reverb : in STD_LOGIC;
    led : out STD_LOGIC_VECTOR ( 15 downto 0 );
    tx_lrck_0 : out STD_LOGIC;
    rx_sdin_0 : in STD_LOGIC;
    rx_sclk_0 : out STD_LOGIC;
    rx_lrck_0 : out STD_LOGIC;
    rx_mclk_0 : out STD_LOGIC;
    tx_sdout_0 : out STD_LOGIC;
    tx_sclk_0 : out STD_LOGIC;
    tx_mclk_0 : out STD_LOGIC;
    usb_uart_txd : out STD_LOGIC;
    usb_uart_rxd : in STD_LOGIC;
    SPI_M_0_sck_t : out STD_LOGIC;
    SPI_M_0_io1_o : out STD_LOGIC;
    SPI_M_0_ss_t : out STD_LOGIC;
    SPI_M_0_io0_o : out STD_LOGIC;
    SPI_M_0_sck_i : in STD_LOGIC;
    SPI_M_0_ss_o : out STD_LOGIC;
    SPI_M_0_io0_t : out STD_LOGIC;
    SPI_M_0_io1_t : out STD_LOGIC;
    SPI_M_0_sck_o : out STD_LOGIC;
    SPI_M_0_ss_i : in STD_LOGIC;
    SPI_M_0_io1_i : in STD_LOGIC;
    SPI_M_0_io0_i : in STD_LOGIC;
    sys_clock : in STD_LOGIC
  );
  end component design_1;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal SPI_M_0_io0_i : STD_LOGIC;
  signal SPI_M_0_io0_o : STD_LOGIC;
  signal SPI_M_0_io0_t : STD_LOGIC;
  signal SPI_M_0_io1_i : STD_LOGIC;
  signal SPI_M_0_io1_o : STD_LOGIC;
  signal SPI_M_0_io1_t : STD_LOGIC;
  signal SPI_M_0_sck_i : STD_LOGIC;
  signal SPI_M_0_sck_o : STD_LOGIC;
  signal SPI_M_0_sck_t : STD_LOGIC;
  signal SPI_M_0_ss_i : STD_LOGIC;
  signal SPI_M_0_ss_o : STD_LOGIC;
  signal SPI_M_0_ss_t : STD_LOGIC;
begin
SPI_M_0_io0_iobuf: component IOBUF
     port map (
      I => SPI_M_0_io0_o,
      IO => SPI_M_0_io0_io,
      O => SPI_M_0_io0_i,
      T => SPI_M_0_io0_t
    );
SPI_M_0_io1_iobuf: component IOBUF
     port map (
      I => SPI_M_0_io1_o,
      IO => SPI_M_0_io1_io,
      O => SPI_M_0_io1_i,
      T => SPI_M_0_io1_t
    );
SPI_M_0_sck_iobuf: component IOBUF
     port map (
      I => SPI_M_0_sck_o,
      IO => SPI_M_0_sck_io,
      O => SPI_M_0_sck_i,
      T => SPI_M_0_sck_t
    );
SPI_M_0_ss_iobuf: component IOBUF
     port map (
      I => SPI_M_0_ss_o,
      IO => SPI_M_0_ss_io,
      O => SPI_M_0_ss_i,
      T => SPI_M_0_ss_t
    );
design_1_i: component design_1
     port map (
      SPI_M_0_io0_i => SPI_M_0_io0_i,
      SPI_M_0_io0_o => SPI_M_0_io0_o,
      SPI_M_0_io0_t => SPI_M_0_io0_t,
      SPI_M_0_io1_i => SPI_M_0_io1_i,
      SPI_M_0_io1_o => SPI_M_0_io1_o,
      SPI_M_0_io1_t => SPI_M_0_io1_t,
      SPI_M_0_sck_i => SPI_M_0_sck_i,
      SPI_M_0_sck_o => SPI_M_0_sck_o,
      SPI_M_0_sck_t => SPI_M_0_sck_t,
      SPI_M_0_ss_i => SPI_M_0_ss_i,
      SPI_M_0_ss_o => SPI_M_0_ss_o,
      SPI_M_0_ss_t => SPI_M_0_ss_t,
      an(3 downto 0) => an(3 downto 0),
      dp => dp,
      enable_filter => enable_filter,
      enable_reverb => enable_reverb,
      led(15 downto 0) => led(15 downto 0),
      reset => reset,
      rx_lrck_0 => rx_lrck_0,
      rx_mclk_0 => rx_mclk_0,
      rx_sclk_0 => rx_sclk_0,
      rx_sdin_0 => rx_sdin_0,
      seg(0 to 6) => seg(0 to 6),
      sys_clock => sys_clock,
      tx_lrck_0 => tx_lrck_0,
      tx_mclk_0 => tx_mclk_0,
      tx_sclk_0 => tx_sclk_0,
      tx_sdout_0 => tx_sdout_0,
      usb_uart_rxd => usb_uart_rxd,
      usb_uart_txd => usb_uart_txd
    );
end STRUCTURE;
