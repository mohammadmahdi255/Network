library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Physical_Link is
	generic
	(
		g_U2X     : std_logic                     := '1';
		g_UCD     : std_logic_vector(15 downto 0) := x"1111"
	);
	port
	(
		i_EN     : in  std_logic;
		i_CLK    : in  std_logic;
		
		i_SEND   : in std_logic;
		o_RECV   : in std_logic;
		
		i_FRAME  : in t_FRAME;
		o_FRAME  : in t_FRAME;

		o_TX_SDO : out std_logic;
		i_RX_SDI : in  std_logic
	);
end Physical_Link;

architecture RTL of Physical_Link is

	-- UART Signals
	signal r_TX_UART_STR  : std_logic                    := '0';
	signal r_TX_UART_RDY  : std_logic                    := '0';
	signal r_RX_UART_CLR  : std_logic                    := '0';
	signal r_RX_UART_RDY  : std_logic                    := '0';
	signal r_RX_UART_IDLE : std_logic                    := '0';

	signal r_TX_UART_DATA : std_logic_vector(7 downto 0) := (others => '0');
	signal r_RX_UART_DATA : std_logic_vector(7 downto 0) := (others => '0');

	-- TX CRC Signals
	signal r_TX_CRC       : std_logic_vector(31 downto 0);
	signal r_TX_CRC_RST   : std_logic := '0';
	signal r_TX_CRC_EN    : std_logic := '0';

	-- TX CRC Signals
	signal r_RX_CRC       : std_logic_vector(31 downto 0);
	signal r_RX_CRC_RST   : std_logic := '0';
	signal r_RX_CRC_EN    : std_logic := '0';

	-- Connection Controler Signals
	signal r_DL_ST        : t_DL_ST   := IDLE;
	signal r_DEST_MAC     : t_BYTE    := c_BROAD_CAST;

	-- TX PAYLOAD signals
	signal r_TX_BUFFER    : t_TX_FRAME;
	signal r_TX_BFV       : std_logic := '0';

	-- TX Transmiter signals
	signal r_TX_ST        : t_PHY_ST  := IDLE;
	signal r_TX_BUSY      : std_logic := '0';
	signal r_TX_TRF       : std_logic := '0';
	signal r_TX_FRAME     : t_TX_FRAME;

	-- RX Receiver signals
	signal r_RX_ST        : t_PHY_ST  := IDLE;
	signal r_RX_VALID     : std_logic := '0';
	signal r_RX_FRAME     : t_RX_FRAME;
	signal r_RX_PAYLOAD   : t_BYTE_VECTOR(0 to 15);
begin




end RTL;

