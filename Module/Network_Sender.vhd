library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Network_Sender is
	generic
	(
		WIDTH : integer := 8
	);
	port
	(
		i_EN     : in  std_logic;
		i_CLK    : in  std_logic;
		i_U2X    : in  std_logic;
		i_UCD    : in  std_logic_vector (15 downto 0);
		i_STR    : in  std_logic;
		i_DATA   : in  std_logic_vector (WIDTH - 1 downto 0);
		o_READY  : out std_logic;

		o_TX_SDO : out std_logic;
		i_RX_SDI : in  std_logic
	);
end Network_Sender;

architecture RTL of Network_Sender is

	type t_FSM is (IDLE, REQUEST, WAIT_ACK);
	signal r_PR_ST   : t_FSM     := IDLE;

	signal r_TX_STR  : std_logic := '0';
	signal r_TX_RDY  : std_logic := '0';
	signal r_RX_CLR  : std_logic := '0';
	signal r_RX_RDY  : std_logic := '0';
	signal r_RX_DV   : std_logic := '0';
	signal r_TX_DATA : std_logic_vector (WIDTH - 1 downto 0);
	signal r_RX_DATA : std_logic_vector (WIDTH - 1 downto 0);

begin

	UART : entity WORK.UART
		generic
		map
		(
		WIDTH => WIDTH
		)
		port map
		(
			i_EN        => i_EN,
			i_CLK       => i_CLK,

			i_U2X       => i_U2X,
			i_UCD       => i_UCD,
			i_PARITY_EN => '1',

			i_TX_STR    => r_TX_STR,
			o_TX_RDY    => r_TX_RDY,
			i_RX_CLR    => r_RX_CLR,
			o_RX_RDY    => r_RX_RDY,
			o_RX_DV     => r_RX_DV,

			i_TX_DATA   => r_TX_DATA,
			o_RX_DATA   => r_RX_DATA,

			o_TX_SDO    => o_TX_SDO,
			i_RX_SDI    => i_RX_SDI
		);

	SEND_DATA : process (i_EN, i_CLK)
	begin

		if i_EN = '0' then
			r_PR_ST   <= IDLE;
			o_NX_DATA <= '1';
		elsif rising_edge(i_CLK) then

			case r_PR_ST is

				when IDLE =>
					if i_STR = '1' then
						r_TX_DATA <= i_DATA;
						r_TX_STR  <= '1';
					end if;

					if r_TX_RDY = '0' then
						r_TX_STR  <= '0';
						o_NX_DATA <= '0';
						r_PR_ST   <= REQUEST;
					end if;

				when REQUEST =>
					if r_TX_RDY = '0' then
						r_TX_STR  <= '0';
						o_NX_DATA <= '0';
						r_PR_ST   <= REQUEST;
					end if;

				when WAIT_ACK =>
					o_TX_STR <= '0';
					if true then
					end if;
			end case;

			end if;

		end process SEND_DATA;

	end RTL;
