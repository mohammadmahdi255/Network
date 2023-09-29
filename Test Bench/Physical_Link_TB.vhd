library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.physical_link_package.all;

entity Physical_Link_TB is
end Physical_Link_TB;

architecture behavior of Physical_Link_TB is

	-- Component Declaration for the Unit Under Test (UUT)

	component Physical_Link
		generic
		(
			g_U2X : std_logic                     := '0';
			g_UCD : std_logic_vector(15 downto 0) := x"1111"
		);
		port
		(
			i_EN     : in     std_logic;
			i_CLK    : in     std_logic;

			i_TX_STR : in     std_logic;
			o_TX_RDY : out    std_logic;
			i_RX_CLR : in     std_logic;
			o_RX_RDY : out    std_logic;

			i_FRAME  : in     t_FRAME;
			b_FRAME  : buffer t_FRAME;

			o_TX_SDO : out    std_logic;
			i_RX_SDI : in     std_logic
		);
	end component;

	--Inputs
	signal i_EN     : std_logic := '0';
	signal i_CLK    : std_logic := '0';
	signal i_TX_STR : std_logic := '0';
	signal i_RX_CLR : std_logic := '0';
	signal i_FRAME  : t_FRAME;
	signal i_RX_SDI : std_logic := '0';

	--Outputs
	signal o_TX_RDY : std_logic;
	signal o_RX_RDY : std_logic;
	signal b_FRAME  : t_FRAME := (
		src_mac  => x"00",
		dest_mac => x"00",
		len      => x"00",
		payload  => (others => x"00"),
		fcs      => (others => x"00")
	);
	signal o_TX_SDO       : std_logic;

	-- Clock period definitions
	constant i_CLK_period : time := 10 ns;

begin

	-- Instantiate the Unit Under Test (UUT)
	uut : Physical_Link
	generic
	map
	(
	g_U2X => '1',
	g_UCD => x"0000"
	)
	port map
	(
		i_EN     => i_EN,
		i_CLK    => i_CLK,
		i_TX_STR => i_TX_STR,
		o_TX_RDY => o_TX_RDY,
		i_RX_CLR => i_RX_CLR,
		o_RX_RDY => o_RX_RDY,
		i_FRAME  => i_FRAME,
		b_FRAME  => b_FRAME,
		o_TX_SDO => o_TX_SDO,
		i_RX_SDI => i_RX_SDI
	);

	i_RX_SDI <= o_TX_SDO;

	-- Clock process definitions
	i_CLK_process : process
	begin
		i_CLK <= '0';
		wait for i_CLK_period/2;
		i_CLK <= '1';
		wait for i_CLK_period/2;
	end process;

	-- Stimulus process
	stim_proc : process
	begin
		-- hold reset state for 100 ns.
		i_EN     <= '0';
		i_TX_STR <= '1';
		i_FRAME  <= (
			src_mac  => x"AC",
			dest_mac => x"D8",
			len      => x"06",
			payload  => (x"13", x"8F", x"AB", x"4C", x"C3", x"44", others => x"00"),
			fcs      => (x"3E", x"5F", x"21", x"3F")
			);
		wait for 100 ns;
		i_EN <= '1';

		wait for 10 ns;
		wait until o_TX_RDY = '1';
		i_FRAME <= (
			src_mac  => x"AC",
			dest_mac => x"D8",
			len      => x"0A",
			payload  => (x"13", x"8F", x"AB", x"4C", x"C3", x"44", x"33", x"CE", x"FF", x"3F", others => x"00"),
			fcs      => (x"3E", x"5F", x"21", x"3F")
			);

		-- insert stimulus here 

		wait;
	end process;

end;
