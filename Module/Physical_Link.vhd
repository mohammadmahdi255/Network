library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.MEMORY_PACKAGE.all;
use WORK.PHYSICAL_LINK_PACKAGE.all;

entity Physical_Link is
	port
	(
		i_EN     : in     std_logic;
		i_CLK    : in     std_logic;
		
		i_U2X    : in std_logic;
		i_UCD    : in std_logic_vector(15 downto 0);

		i_TX_STR : in     std_logic;
		o_TX_RDY : out    std_logic;
		i_RX_CLR : in     std_logic;
		o_RX_RDY : out    std_logic;

		i_FRAME  : in     t_FRAME;
		b_FRAME  : buffer t_FRAME;

		o_TX_SDO : out    std_logic;
		i_RX_SDI : in     std_logic
	);
end Physical_Link;

architecture RTL of Physical_Link is

	-- UART Signals
	signal r_UART  : t_UART;

	-- TX Transmiter signals
	signal r_TX_ST : t_PHY_ST := IDLE;

	-- RX Receiver signals
	signal r_RX_ST : t_PHY_ST := IDLE;

begin

	UART : entity Work.UART
		generic
		map(WIDTH => 8)
		port map
		(
			i_EN        => i_EN,
			i_CLK       => i_CLK,

			i_U2X       => i_U2X,
			i_UCD       => i_UCD,
			i_PARITY_EN => '0',

			i_TX_STR    => r_UART.tx_str,
			o_TX_RDY    => r_UART.tx_rdy,
			i_RX_CLR    => r_UART.rx_clr,
			o_RX_RDY    => r_UART.rx_rdy,
			o_RX_DV     => r_UART.rx_dv,

			i_TX_DATA   => r_UART.tx_data,
			o_RX_DATA   => r_UART.rx_data,

			o_TX_SDO    => o_TX_SDO,
			i_RX_SDI    => i_RX_SDI
		);

	TX_FRAME : process (i_EN, i_CLK)
		variable v_INDEX : integer range 0 to 15 := 0;
	begin

		if i_EN = '0' then

			o_TX_RDY       <= '1';
			r_UART.tx_str  <= '0';
			r_UART.tx_data <= x"00";
			v_INDEX := 0;
			r_TX_ST <= IDLE;

		elsif rising_edge(i_CLK) then

			if r_UART.tx_rdy = '0' then
				r_UART.tx_str <= '0';
			end if;

			if r_UART.tx_rdy = '1' and r_UART.tx_str = '0' then

				r_UART.tx_str <= '1';

				case r_TX_ST is

					when IDLE =>
						if i_TX_STR = '1' then
							o_TX_RDY       <= '0';
							r_UART.tx_data <= c_SFD;
							r_TX_ST        <= SFD;
						else
							r_UART.tx_str <= '0';
						end if;

					when SFD =>

						r_UART.tx_data <= i_FRAME.src_mac;
						r_TX_ST        <= SRC_MAC;

					when SRC_MAC =>
						r_UART.tx_data <= i_FRAME.dest_mac;
						r_TX_ST        <= DEST_MAC;

					when DEST_MAC =>
						r_UART.tx_data <= i_FRAME.len;
						r_TX_ST        <= LEN;

					when LEN | PAYLOAD =>
						if v_INDEX = to_int(i_FRAME.len) then
							r_UART.tx_data <= i_FRAME.fcs(0);
							v_INDEX := 0;
							r_TX_ST <= FCS;
						else
							r_UART.tx_data <= i_FRAME.payload(v_INDEX);
							v_INDEX := v_INDEX + 1;
							r_TX_ST <= PAYLOAD;
						end if;

					when FCS =>
						v_INDEX := v_INDEX + 1;
						if v_INDEX = i_FRAME.fcs'length then
							o_TX_RDY       <= '1';
							r_UART.tx_str  <= '0';
							r_UART.tx_data <= x"00";
							v_INDEX := 0;
							r_TX_ST <= IDLE;
						else
							r_UART.tx_data <= i_FRAME.fcs(v_INDEX);
						end if;

				end case;

			end if;

		end if;

	end process;

	RX_FRAME : process (i_EN, i_CLK)
		variable v_INDEX : integer range 0 to 15 := 0;
	begin

		if i_EN = '0' then

			b_FRAME <= (
				src_mac  => x"00",
				dest_mac => x"00",
				len      => x"00",
				payload  => (others => x"00"),
				fcs      => (others => x"00")
				);

			o_RX_RDY      <= '0';
			r_UART.rx_clr <= '0';
			r_RX_ST       <= IDLE;

		elsif rising_edge(i_CLK) then

			r_UART.rx_clr <= r_UART.rx_rdy;

			if i_RX_CLR = '1' then
				o_RX_RDY <= '0';
			end if;

			if (r_UART.rx_rdy or r_UART.rx_dv) = '1' and r_UART.rx_clr = '0' then

				case r_RX_ST is

					when IDLE =>
						if r_UART.rx_data = c_SFD then
							r_RX_ST <= SFD;
						end if;

					when SFD =>
						o_RX_RDY <= '0';
						b_FRAME.src_mac <= r_UART.rx_data;
						r_RX_ST         <= SRC_MAC;

					when SRC_MAC =>
						b_FRAME.dest_mac <= r_UART.rx_data;
						r_RX_ST          <= DEST_MAC;

					when DEST_MAC =>
						b_FRAME.len <= r_UART.rx_data;
						r_RX_ST     <= LEN;

					when LEN | PAYLOAD =>
						if v_INDEX = to_int(b_FRAME.len) then
							b_FRAME.fcs(0) <= r_UART.rx_data;
							v_INDEX := 0;
							r_RX_ST <= FCS;
						else
							b_FRAME.payload(v_INDEX) <= r_UART.rx_data;
							v_INDEX := v_INDEX + 1;
							r_RX_ST <= PAYLOAD;
						end if;

					when FCS =>
						v_INDEX := v_INDEX + 1;
						b_FRAME.fcs(v_INDEX) <= r_UART.rx_data;
						if v_INDEX = b_FRAME.fcs'length - 1 then
							o_RX_RDY <= '1';
							v_INDEX := 0;
							r_RX_ST <= IDLE;
--							if r_UART.rx_data = c_SFD then
--								r_RX_ST <= SFD;
--							end if;
						end if;

				end case;

			end if;

		end if;

	end process;

end RTL;
