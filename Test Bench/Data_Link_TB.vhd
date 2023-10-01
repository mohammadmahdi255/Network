-- TestBench Template 

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.PHYSICAL_LINK_PACKAGE.all;
use WORK.DATA_LINK_PACKAGE.all;
use WORK.MEMORY_PACKAGE.all;

entity Data_Link_TB is
end Data_Link_TB;

architecture behavior of Data_Link_TB is

	-- Component Declaration
	component Data_Link
		generic
		(
			g_U2X     : std_logic                     := '0';
			g_UCD     : std_logic_vector(15 downto 0) := x"1111";
			g_SRC_MAC : t_BYTE                        := x"FF"
		);
		port
		(
			i_EN      : in  std_logic;
			i_CLK     : in  std_logic;

			i_BUFFER  : in  t_BUFFER;
			o_PAYLOAD : out t_BYTE_VECTOR(0 to 15);

			i_TX_STR  : in  std_logic;
			o_TX_BUSY : out std_logic;

			i_RX_CLR  : in  std_logic;
			o_RX_RDY  : out std_logic;

			o_TX_SDO  : out std_logic;
			i_RX_SDI  : in  std_logic
		);
	end component;
	
	constant c_U2X : std_logic := '1';
	constant c_UCD : std_logic_vector(15 downto 0) := x"0000";
	
	signal i_EN      : std_logic_vector(1 downto 0) := "00";
	signal i_CLK     : std_logic;
	
	type t_BUF_ARR is array(0 to 1) of t_BUFFER; 
	type t_PAY_ARR is array(0 to 1) of t_BYTE_VECTOR(0 to 15); 

	signal i_BUFFER  : t_BUF_ARR;
	signal o_PAYLOAD : t_PAY_ARR;

	signal i_TX_STR  : std_logic_vector(1 downto 0) := "00";
	signal o_TX_BUSY : std_logic_vector(1 downto 0) := "00";

	signal i_RX_CLR  : std_logic_vector(1 downto 0) := "00";
	signal o_RX_RDY  : std_logic_vector(1 downto 0) := "00";

	signal o_TX_SDO  : std_logic;
	signal i_RX_SDI  : std_logic;

	-- Clock period definitions
	constant i_CLK_period : time := 10 ns;

begin

	-- Component Instantiation
	Ethernet_0 : Data_Link
	generic map
	(
		g_U2X => c_U2X,
		g_UCD => c_UCD,
		g_SRC_MAC => x"3D"
	)
	port map
	(
		i_EN => i_EN(0),
		i_CLK => i_CLK,
		
		i_BUFFER => i_BUFFER(0),
		o_PAYLOAD => o_PAYLOAD(0),
		
		i_TX_STR => i_TX_STR(0),
		o_TX_BUSY => o_TX_BUSY(0),
		i_RX_CLR => i_RX_CLR(0),
		o_RX_RDY => o_RX_RDY(0),
		
		o_TX_SDO => o_TX_SDO,
		i_RX_SDI => i_RX_SDI
	);
	
	Ethernet_1 : Data_Link
	generic map
	(
		g_U2X => c_U2X,
		g_UCD => c_UCD,
		g_SRC_MAC => x"F8"
	)
	port map
	(
		i_EN => i_EN(1),
		i_CLK => i_CLK,
		
		i_BUFFER => i_BUFFER(1),
		o_PAYLOAD => o_PAYLOAD(1),
		
		i_TX_STR => i_TX_STR(1),
		o_TX_BUSY => o_TX_BUSY(1),
		i_RX_CLR => i_RX_CLR(1),
		o_RX_RDY => o_RX_RDY(1),
		
		o_TX_SDO => i_RX_SDI,
		i_RX_SDI => o_TX_SDO
	);
	
	-- Clock process definitions
	i_CLK_process : process
	begin
		i_CLK <= '0';
		wait for i_CLK_period/2;
		i_CLK <= '1';
		wait for i_CLK_period/2;
	end process;


	--  Test Bench Statements
	tb : process
	begin
		
		wait for 100 ns; -- wait until global set/reset completes
		
		i_EN <= "11";
		
		
		wait until o_TX_BUSY = "00"; -- wait until ETHERNET ESTABlished
		i_TX_STR(0) <= '1';
		i_BUFFER(0) <= (
			len => x"0A",
			payload => (x"13", x"8F", x"AB", x"4C", x"C3", x"44", x"33", x"CE", x"FF", x"3F", others => x"00")
		);
		
		i_TX_STR(1) <= '1';
		i_BUFFER(1) <= (
			len      => x"06",
			payload  => (x"13", x"8F", x"AB", x"4C", x"C3", x"44", others => x"00")
		);
		-- Add user defined stimulus here
		
		wait for 100 ns;
		i_TX_STR <= "00";

		wait;            -- will wait forever
	end process tb;
	--  End Test Bench 

end;
