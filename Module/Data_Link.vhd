library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.PHYSICAL_LINK_PACKAGE.all;
use WORK.DATA_LINK_PACKAGE.all;
use WORK.MEMORY_PACKAGE.all;

entity Data_Link is
	port
	(
		i_EN      : in  std_logic;
		i_CLK     : in  std_logic;

		i_U2X     : in  std_logic;
		i_UCD     : in  std_logic_vector(15 downto 0);
		i_MAC     : in  t_BYTE;

		i_BUFFER  : in  t_BUFFER;
		o_PAYLOAD : out t_BYTE_VECTOR(0 to 15);

		i_TX_STR  : in  std_logic;
		o_TX_BUSY : out std_logic;

		i_RX_CLR  : in  std_logic;
		o_RX_RDY  : out std_logic;

		o_TX_SDO  : out std_logic;
		i_RX_SDI  : in  std_logic
	);
end Data_Link;

architecture RTL of Data_Link is

	-- Connection Controler Signals
	signal r_DL_ST     : t_DL_ST := ARP_REQUEST;
	signal r_DEST_MAC  : t_BYTE  := c_BROAD_CAST;

	-- CRC Signals
	signal r_TX_CRC    : t_CRC;
	signal r_RX_CRC    : t_CRC;

	-- TX Buffer signals
	signal r_TX_ST     : t_FR_ST := IDLE;
	signal r_TX_BUFFER : t_BUFFER;
	signal r_TX_MF_STR : std_logic := '0';
	alias r_TX_BF_RDY is r_TX_CRC.rst_n;

	-- TX frame handler signals
	signal r_TX_STR    : std_logic := '0';
	signal r_TX_RDY    : std_logic;
	signal r_TX_FRAME  : t_FRAME;

	-- RX frame handler signals
	signal r_RX_RDY    : std_logic;
	signal r_RX_CLR    : std_logic := '0';
	signal r_RX_FRAME  : t_FRAME;

	-- RX Buffer signals
	signal r_RX_ST     : t_FR_ST := IDLE;
	signal r_RX_BUFFER : t_FRAME;
	signal r_RX_BF_RDY : std_logic := '0';
	signal r_RX_BF_CLR : std_logic := '0';

begin

	Control_Unit : process (i_EN, i_CLK)

	begin

		if i_EN = '0' then

			r_DEST_MAC  <= c_BROAD_CAST;
			r_TX_MF_STR <= '0';
			o_TX_BUSY   <= '1';
			o_RX_RDY    <= '0';
			r_DL_ST     <= ARP_REQUEST;

		elsif rising_edge(i_CLK) then

			r_TX_MF_STR <= '0';

			if r_RX_BF_RDY = '0' then
				r_RX_BF_CLR <= '0';
			end if;

			if i_RX_CLR = '1' then
				o_RX_RDY <= '0';
			end if;

			if r_TX_BF_RDY = '0' then

				case r_DL_ST is

					when ARP_REQUEST =>
						r_DEST_MAC  <= c_BROAD_CAST;
						r_TX_BUFFER <= make_arp(c_ARP_REQUEST, i_MAC, c_BROAD_CAST);
						r_TX_MF_STR <= '1';
						r_DL_ST     <= ARP_REPLAY;

					when ARP_REPLAY  =>

					when ESTABLISHED =>
						if i_TX_STR = '1' then
							r_TX_BUFFER <= i_BUFFER;
							r_TX_MF_STR <= '1';
						end if;

				end case;

			end if;

			if r_RX_BF_RDY = '1' then

				case r_RX_BUFFER.payload(0) is

					when c_ARP =>

						if r_RX_BUFFER.payload(1) = c_ARP_REQUEST and r_TX_BF_RDY = '0' then
							r_TX_BUFFER <= make_arp(c_ARP_REPLY, i_MAC, r_RX_BUFFER.payload(2));
							r_TX_MF_STR <= '1';
							r_RX_BF_CLR <= '1';

						elsif r_RX_BUFFER.payload(1) = c_ARP_REPLY and r_RX_BUFFER.payload(3) = i_MAC then
							r_DEST_MAC  <= r_RX_BUFFER.payload(2);
							r_DL_ST     <= ESTABLISHED;
							r_RX_BF_CLR <= '1';
							o_TX_BUSY   <= '0';
						else
							r_DL_ST   <= ARP_REQUEST;
							o_TX_BUSY <= '1';
						end if;

					when others =>
						r_RX_BF_CLR <= '1';
						if r_DEST_MAC = r_RX_BUFFER.src_mac then
							o_PAYLOAD <= r_RX_BUFFER.payload;
							o_RX_RDY  <= '1';
						else
							r_DEST_MAC <= c_BROAD_CAST;
							r_DL_ST    <= ARP_REQUEST;
							o_TX_BUSY  <= '1';
						end if;

				end case;

			end if;

		end if;

	end process;

	TX_CRC : entity Work.CRC
		generic
		map(
		g_DATA_WIDTH => 1,
		g_CRC_WIDTH  => 4,
		g_POLY       => x"04C11DB7",
		g_INIT       => x"FFFFFFFF",
		g_XOROUT     => x"FFFFFFFF",
		g_REFIN      => '0',
		g_REFOUT     => '0'
		)
		port map
		(
			i_RST_N => r_TX_CRC.rst_n,
			i_EN    => r_TX_CRC.en,
			i_CLK   => i_CLK,

			i_DATA  => r_TX_CRC.data,
			o_CRC   => r_TX_CRC.crc
		);

	TX_Making_Frame : process (i_EN, i_CLK)
		variable v_INDEX : integer range 0 to 16 := 0;
	begin

		if i_EN = '0' then
			r_TX_CRC.rst_n <= '0';
			r_TX_CRC.en    <= '0';
			r_TX_CRC.data  <= (others => '0');

			v_INDEX := 0;
			r_TX_ST <= IDLE;
		elsif rising_edge(i_CLK) then

			case r_TX_ST is

				when IDLE =>
					r_TX_STR <= '0';
					if r_TX_MF_STR = '1' then
						r_TX_CRC.rst_n <= '1';
						r_TX_CRC.en    <= '1';
						r_TX_CRC.data  <= i_MAC;
						r_TX_ST        <= SRC_MAC;
					end if;

				when SRC_MAC =>
					r_TX_CRC.data <= r_DEST_MAC;
					r_TX_ST       <= DEST_MAC;

				when DEST_MAC =>
					r_TX_CRC.data <= r_TX_BUFFER.len;
					r_TX_ST       <= LEN;

				when LEN | PAYLOAD =>
					if v_INDEX = to_int(r_TX_BUFFER.len) then
						r_TX_CRC.data <= x"00";
						v_INDEX := 0;
						r_TX_ST <= FCS;
					else
						r_TX_CRC.data <= r_TX_BUFFER.payload(v_INDEX);
						v_INDEX := v_INDEX + 1;
						r_TX_ST <= PAYLOAD;
					end if;

				when FCS =>
					v_INDEX := v_INDEX + 1;
					if v_INDEX = r_TX_FRAME.fcs'length then
						r_TX_CRC.en <= '0';
						v_INDEX := 0;
						r_TX_ST <= FRAME_RDY;
					end if;

				when FRAME_RDY =>
					if r_TX_RDY = '1' then
						r_TX_FRAME.src_mac  <= i_MAC;
						r_TX_FRAME.dest_mac <= r_DEST_MAC;
						r_TX_FRAME.len      <= r_TX_BUFFER.len;
						r_TX_FRAME.payload  <= r_TX_BUFFER.payload;
						r_TX_FRAME.fcs      <= to_byte_vector(r_TX_CRC.crc);

						r_TX_STR            <= '1';
						r_TX_CRC.rst_n      <= '0';
						v_INDEX := 0;
						r_TX_ST <= IDLE;
					end if;

			end case;

		end if;

	end process;

	Frame_Handler : entity work.Physical_Link
		port
	map
	(
	i_EN     => i_EN,
	i_CLK    => i_CLK,

	i_U2X    => i_U2X,
	i_UCD    => i_UCD,

	i_TX_STR => r_TX_STR,
	o_TX_RDY => r_TX_RDY,
	i_RX_CLR => r_RX_CLR,
	o_RX_RDY => r_RX_RDY,

	i_FRAME  => r_TX_FRAME,
	b_FRAME  => r_RX_FRAME,

	o_TX_SDO => o_TX_SDO,
	i_RX_SDI => i_RX_SDI
	);

	RX_Checking_Frame : process (i_EN, i_CLK)
		variable v_INDEX : integer range 0 to 16 := 0;
	begin

		if i_EN = '0' then
			r_RX_BF_RDY    <= '0';
			r_RX_CLR       <= '0';
			r_RX_CRC.rst_n <= '0';
			r_RX_CRC.en    <= '0';
			r_RX_CRC.data  <= (others => '0');

			v_INDEX := 0;
			r_RX_ST <= IDLE;
		elsif rising_edge(i_CLK) then

			r_RX_CLR <= '0';

			case r_RX_ST is

				when IDLE =>

					if r_RX_RDY = '1' and r_RX_BF_RDY = '0' then
						r_RX_CLR <= '1';
						if r_RX_FRAME.dest_mac = i_MAC or r_RX_FRAME.dest_mac = c_BROAD_CAST then
							r_RX_CRC.rst_n <= '1';
							r_RX_CRC.en    <= '1';

							r_RX_BUFFER    <= r_RX_FRAME;
							r_RX_CRC.data  <= r_RX_FRAME.src_mac;
							r_RX_ST        <= SRC_MAC;
						end if;
					end if;

				when SRC_MAC =>
					r_RX_CRC.data <= r_RX_BUFFER.dest_mac;
					r_RX_ST       <= DEST_MAC;

				when DEST_MAC =>
					r_RX_CRC.data <= r_RX_BUFFER.len;
					r_RX_ST       <= LEN;

				when LEN | PAYLOAD =>
					if v_INDEX = to_int(r_RX_BUFFER.len) then
						r_RX_CRC.data <= r_RX_BUFFER.fcs(0);
						v_INDEX := 0;
						r_RX_ST <= FCS;
					else
						r_RX_CRC.data <= r_RX_BUFFER.payload(v_INDEX);
						v_INDEX := v_INDEX + 1;
						r_RX_ST <= PAYLOAD;
					end if;

				when FCS =>
					v_INDEX := v_INDEX + 1;
					if v_INDEX = r_RX_BUFFER.fcs'length then
						r_RX_CRC.rst_n <= '0';
						r_RX_CRC.en    <= '0';
						v_INDEX := 0;
						r_RX_ST <= IDLE;
						if r_RX_CRC.crc = x"00000000" then
							r_RX_BF_RDY <= '1';
							r_RX_ST     <= FRAME_RDY;
						end if;
					else
						r_RX_CRC.data <= r_RX_BUFFER.fcs(v_INDEX);
					end if;

				when FRAME_RDY =>
					if r_RX_BF_CLR = '1' then
						r_RX_BF_RDY <= '0';
						r_RX_ST     <= IDLE;
					end if;

			end case;

		end if;

	end process;

	RX_CRC : entity Work.CRC
		generic
		map(
		g_DATA_WIDTH => 1,
		g_CRC_WIDTH  => 4,
		g_POLY       => x"04C11DB7",
		g_INIT       => x"FFFFFFFF",
		g_XOROUT     => x"FFFFFFFF",
		g_REFIN      => '0',
		g_REFOUT     => '0'
		)
		port
		map
		(
		i_RST_N => r_RX_CRC.rst_n,
		i_EN    => r_RX_CRC.en,
		i_CLK   => i_CLK,

		i_DATA  => r_RX_CRC.data,
		o_CRC   => r_RX_CRC.crc
		);

end RTL;
