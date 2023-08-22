
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
		
		-- FIFO TX buffer pins
		i_TX_EMPTY   : in  std_logic;
		i_TX_DATA    : in  std_logic_vector (7 downto 0);
		o_TX_RD_EN   : out std_logic;
		
		-- FIFO RX buffer pins
		i_RX_FULL    : in  std_logic;
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
   signal i_TX_EMPTY : std_logic := '0';
   signal i_TX_DATA : std_logic_vector(7 downto 0) := (others => '0');
   signal i_RX_FULL : std_logic := '0';
   signal i_TX_RDY : std_logic := '0';
   signal i_RX_RDY : std_logic := '0';
   signal i_RX_DATA : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal o_TX_RD_EN : std_logic;
   signal o_RX_DATA : std_logic_vector(7 downto 0);
   signal o_RX_WR_EN : std_logic;
   signal o_TX_STR : std_logic;
   signal o_TX_DATA : std_logic_vector(7 downto 0);
   signal o_RX_CLR : std_logic;
   
   
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
		  
          i_TX_EMPTY => i_TX_EMPTY,
          i_TX_DATA => i_TX_DATA,
          o_TX_RD_EN => o_TX_RD_EN,
		  
          i_RX_FULL => i_RX_FULL,
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
	  i_RX_FULL <= '0';
	  i_TX_EMPTY <= '0';
	  i_U2X <= '1';
	  i_UCD <= x"0000";
	  i_TX_DATA <= x"8E";
      wait for 100 ns;
	  i_TX_DATA <= x"7E";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"F5";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"4E";
	  
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"00";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"03";
	  
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"E8";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"12";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"9C";
	  
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"A8";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"AA";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"CC";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"EE";
	  wait until i_TX_RDY = '1';
	  i_TX_DATA <= x"00";

      wait for i_CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
