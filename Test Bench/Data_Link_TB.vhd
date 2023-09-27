
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY Data_Link_TB IS
END Data_Link_TB;
 
ARCHITECTURE behavior OF Data_Link_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Data_Link
    PORT(
		i_EN      : in  std_logic;
		i_CLK     : in  std_logic;
		
		-- Data Link Control Pins
		i_PKT_SEND : in std_logic;

		-- Data Link Status Pins
		o_RX_RECV : out  std_logic;

		-- FIFO TX buffer pins
		i_TX_DATA    : in  std_logic_vector (7 downto 0);
		o_TX_RD_EN   : out std_logic;

		-- FIFO RX buffer pins
		o_RX_DATA    : out std_logic_vector (7 downto 0);
		o_RX_WR_EN   : out std_logic;

		-- UART TX Pins
		o_TX_STR  : out std_logic;
		i_TX_RDY  : in  std_logic;
		o_TX_DATA : out std_logic_vector (7 downto 0);

		-- UART RX Pins
		o_RX_CLR  : out std_logic;
		i_RX_RDY  : in  std_logic;
		i_RX_DATA : in std_logic_vector (7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_EN : std_logic := '0';
   signal i_CLK : std_logic := '0';
   signal i_PKT_SEND : std_logic := '0';
   signal i_TX_DATA : std_logic_vector(7 downto 0) := (others => '0');
   signal i_TX_RDY : std_logic := '0';
   signal i_RX_RDY : std_logic := '0';
   signal i_RX_DATA : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal o_RX_RECV : std_logic;
   signal o_TX_RD_EN : std_logic;
   signal o_RX_DATA : std_logic_vector(7 downto 0);
   signal o_RX_WR_EN : std_logic;
   signal o_TX_STR : std_logic;
   signal o_TX_DATA : std_logic_vector(7 downto 0);
   signal o_RX_CLR : std_logic;
   signal b_TX_RDY : std_logic;
   signal o_ERR_SIG : std_logic;
   
   signal i_U2X : std_logic;
   signal i_UCD : std_logic_vector(15 downto 0);
   signal o_TX_SDO : std_logic;
   signal i_RX_SDI : std_logic;

   -- Clock period definitions
   constant i_CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Data_Link PORT MAP (
		i_EN => i_EN,
		i_CLK => i_CLK,

		i_PKT_SEND => i_PKT_SEND,

		o_RX_RECV => o_RX_RECV,

		i_TX_DATA => i_TX_DATA,
		o_TX_RD_EN => o_TX_RD_EN,

		o_RX_DATA => o_RX_DATA,
		o_RX_WR_EN => o_RX_WR_EN,

		o_TX_STR => o_TX_STR,
		i_TX_RDY => i_TX_RDY,
		o_TX_DATA => o_TX_DATA,

		o_RX_CLR => o_RX_CLR,
		i_RX_RDY => i_RX_RDY,
		i_RX_DATA => i_RX_DATA
        );
	
	UART_uut : entity Work.UART 
		generic map(WIDTH => 8)
		port map (
			i_EN => i_EN, 
			i_CLK  => i_CLK,

			i_U2X  => i_U2X,
			i_UCD  => i_UCD,
			i_PARITY_EN => '0',

			i_TX_STR => o_TX_STR,
			o_TX_RDY => i_TX_RDY,
			i_RX_CLR => o_RX_CLR,
			o_RX_RDY => i_RX_RDY,
			o_RX_DV  => open,

			i_TX_DATA => o_TX_DATA,
			o_RX_DATA => i_RX_DATA,

			o_TX_SDO => o_TX_SDO,
			i_RX_SDI => i_RX_SDI
		);

   -- Clock process definitions
   i_CLK_process :process
   begin
		i_CLK <= '0';
		wait for i_CLK_period/2;
		i_CLK <= '1';
		wait for i_CLK_period/2;
   end process;
 
	i_RX_SDI <= o_TX_SDO;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		i_EN <= '1';
		i_U2X <= '1';
		i_UCD <= x"0000";
		i_TX_DATA <= x"7E";
		wait for 100 ns;

		-- SFD
		i_PKT_SEND <= '1';
		wait until i_TX_RDY = '1';

		-- SRC_MAC
		i_TX_DATA <= x"8E";
		wait until i_TX_RDY = '1';

		-- DEST_MAC
		i_TX_DATA <= x"F5";
		wait until i_TX_RDY = '1';

		-- DATA_LENGTH
		i_TX_DATA <= x"00";
		wait until i_TX_RDY = '1';
		i_TX_DATA <= x"03";
		wait until i_TX_RDY = '1';

		-- DATA
		i_TX_DATA <= x"E8";
		wait until i_TX_RDY = '1';
		i_TX_DATA <= x"12";
		wait until i_TX_RDY = '1';
		i_TX_DATA <= x"9C";

		-- CRC
		wait until i_TX_RDY = '1';
		wait until i_TX_RDY = '1';
		wait until i_TX_RDY = '1';
		wait until i_TX_RDY = '1';
		i_TX_DATA <= x"00";

		wait for i_CLK_period*10;

		-- insert stimulus here 

      wait;
   end process;

END;
