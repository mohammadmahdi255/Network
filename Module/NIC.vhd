library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;
use work.NIC_Package.all;
use work.Memory_Package.all;


entity NIC is
	generic
	(
		g_U2X : std_logic                     := '1';
		g_UCD : std_logic_vector(15 downto 0) := x"1111"
	);
	port
	(
		i_EN       : in     std_logic;
		i_CLK      : in     std_logic;

		-- TX Circular Buffer
		i_TX_PUSH  : in     std_logic;
		o_TX_FULL  : out    std_logic;
		b_TX_EMPTY : buffer std_logic;
		

		-- Status Flags
		b_TX_RDY   : buffer    std_logic;  -- TX Ready
		b_RX_RDY   : buffer    std_logic;  -- RX Ready
		b_RX_FULL  : buffer    std_logic;  -- RX Receive Frame

		i_DQ  : in  std_logic_vector(15 downto 0);
--		o_DQ  : out  std_logic_vector(15 downto 0);

		o_TX_SDO   : out    std_logic;
		i_RX_SDI   : in     std_logic
	);
end NIC;

architecture RTL of NIC is

	-- TX Circular Buffer Signals
	signal r_TX_POP : std_logic;
	signal r_TX_DQ  : t_BYTE_VECTOR(0 to 1);

	signal r_TX_PR_ST     : t_NIC_STATE             := IDLE;
	signal r_RX_PR_ST     : t_NIC_STATE             := IDLE;

	signal r_TX_INDEX     : std_logic_vector(9 downto 0) := (others => '0');
	signal r_RX_INDEX     : std_logic_vector(9 downto 0) := (others => '0');

	signal r_TX_CRC       : std_logic_vector(31 downto 0);
	signal r_TX_CRC_RST   : std_logic := '0';
	signal r_TX_CRC_EN    : std_logic := '0';
--	
--	signal r_RX_CRC       : std_logic_vector(31 downto 0);
--	signal r_RX_CRC_RST   : std_logic := '0'; 
--	signal r_RX_CRC_EN    : std_logic := '0'; 

	signal r_TX_CPLT      : std_logic := '0';  -- TX Complete

	signal r_TX_UART_STR  : std_logic                    := '0';
	signal r_TX_UART_RDY  : std_logic                    := '0';
	signal r_RX_UART_CLR  : std_logic                    := '0';
	signal r_RX_UART_RDY  : std_logic                    := '0';

	signal r_TX_UART_DATA : std_logic_vector(7 downto 0) := (others => '0');
	signal r_RX_UART_DATA : std_logic_vector(7 downto 0) := (others => '0');

begin

	TX_BUFFER : entity Circular_Buffer
	generic map
	(
		DATA_WIDTH => 2,
		ADDR_WIDTH => 4
	)
	port map
	(
		i_EN    => i_EN,
		i_CLK   => i_CLK,
		i_PUSH  => i_TX_PUSH,
		i_POP   => r_TX_POP,
		o_FULL  => o_TX_FULL,
		b_EMPTY => b_TX_EMPTY,

		i_DATA  => to_byte_vector(i_DQ),
		o_DATA  => r_TX_DQ
	);
	
--	TX_CRC : entity Work.CRC
--		generic
--		map(
--		g_DATA_WIDTH => 16,
--		g_CRC_WIDTH  => 32,
--		g_POLY       => x"A833982B",
--		g_INIT       => x"FFFFFFFF",
--		g_XOROUT     => x"FFFFFFFF",
--		g_REFIN      => '1',
--		g_REFOUT     => '1'
--		)
--		port map
--		(
--			i_RST_N => r_TX_CRC_RST,
--			i_EN    => r_TX_CRC_EN,
--			i_CLK   => i_CLK,
--
--			i_DATA  => i_DQ,
--			o_CRC   => r_TX_CRC
--		);
--		
--	RX_CRC : entity Work.CRC
--		generic
--		map(
--		g_DATA_WIDTH => 8,
--		g_CRC_WIDTH  => 32,
--		g_POLY       => x"A833982B",
--		g_INIT       => x"FFFFFFFF",
--		g_XOROUT     => x"FFFFFFFF",
--		g_REFIN      => '1',
--		g_REFOUT     => '1'
--		)
--		port map
--		(
--			i_RST_N => r_RX_CRC_EN,
--			i_EN    => r_RX_CRC_EN,
--			i_CLK   => i_CLK,
--
--			i_DATA  => r_RX_UART_DATA,
--			o_CRC   => r_RX_CRC
--		);

	UART_uut : entity Work.UART
		generic
		map(WIDTH => 8)
		port
		map (
		i_EN        => i_EN,
		i_CLK       => i_CLK,

		i_U2X       => g_U2X,
		i_UCD       => g_UCD,
		i_PARITY_EN => '0',

		i_TX_STR    => r_TX_UART_STR,
		o_TX_RDY    => r_TX_UART_RDY,
		i_RX_CLR    => r_RX_UART_CLR,
		o_RX_RDY    => r_RX_UART_RDY,
		o_RX_DV     => open,

		i_TX_DATA   => r_TX_UART_DATA,
		o_RX_DATA   => r_RX_UART_DATA,

		o_TX_SDO    => o_TX_SDO,
		i_RX_SDI    => i_RX_SDI
		);	
	
	TX_FRAME : process (i_EN, i_CLK)
		variable v_INDEX : std_logic_vector(9 downto 0) := (others => '0');
	begin

		if i_EN = '0' then

			v_INDEX := (others => '0');
			r_TX_CPLT <= '0';
			r_TX_UART_STR <= '0';
			r_TX_PR_ST <= IDLE;
			
			-- TX CRC
			r_TX_CRC_RST <= '0';

		elsif rising_edge(i_CLK) then
		
			r_TX_CRC_EN <= '0';
			if r_TX_UART_RDY = '0' then
				r_TX_UART_STR <= '0';
			end if;

			if r_TX_UART_RDY = '1' and r_TX_UART_STR = '0' then
			
				r_TX_UART_STR <= '1';
				r_TX_POP <= v_INDEX(0);
				
				r_TX_CRC_RST <= '1';
				r_TX_CRC_EN <= '1';

				case r_TX_PR_ST is

					when IDLE =>
						r_TX_UART_STR <= '0';
						r_TX_CRC_RST <= '0';
						if b_TX_EMPTY = '0' then
							r_TX_UART_DATA <= x"7E";
							r_TX_INDEX <= to_slv(4, r_TX_INDEX'length);
							r_TX_PR_ST <= HEADER;
						end if;
						
					when HEADER => 
						r_TX_UART_DATA <= r_TX_DQ(to_int(v_INDEX(0)));
						v_INDEX := v_INDEX + 1;
						if v_INDEX = r_TX_INDEX then
							v_INDEX := (others => '0');
							r_TX_INDEX <= to_std_logic_vector(r_TX_DQ)(r_TX_INDEX'range);
							r_TX_PR_ST <= PAYLOAD;
						end if;
						
					when PAYLOAD =>
						r_TX_UART_DATA <= r_TX_DQ(to_int(v_INDEX(0)));
						v_INDEX := v_INDEX + 1;
						if v_INDEX = r_TX_INDEX then
							v_INDEX := (others => '0');
							r_TX_INDEX <= to_slv(4, r_TX_INDEX'length);
							r_TX_PR_ST <= CRC;
						end if;
						
					when CRC =>
						r_TX_CRC_EN <= '0';
						r_TX_UART_DATA <= to_byte_vector(r_TX_CRC)(to_int(v_INDEX));
						v_INDEX := v_INDEX + 1;
						if v_INDEX = r_TX_INDEX then
							v_INDEX := (others => '0');
							r_TX_PR_ST <= IDLE;
						end if;

				end case;

			end if;
		end if;

	end process;
	
--	RX_FRAME: process (i_EN, i_CLK)
--		variable v_INDEX : integer range 0 to 255 := 0;
--	begin
--
--		if i_EN = '0' then
--
--			v_INDEX := 0;
--			r_RX_LOCK <= '0';
--			r_RX_UART_CLR <= '0';
--			r_RX_PR_ST <= IDLE;
--			
--			-- RX CRC
--			r_RX_CRC_RST <= '0';
--			r_RX_CRC_EN <= '0';
--
--		elsif rising_edge(i_CLK) then
--		
--			if b_RX_RDY = '1' then
--				r_RX_LOCK <= '0';
--			end if;
--			
--			r_RX_CRC_RST <= '1';
--			r_RX_CRC_EN <= '0';
--		
--			r_RX_UART_CLR <= r_RX_UART_RDY;
--
--			if r_RX_UART_RDY = '1' and r_RX_UART_CLR = '0' then
--
--				case r_RX_PR_ST is
--
--					when IDLE =>
--						r_RX_CRC_RST <= '0';
--						if r_RX_LOCK = '0' and r_RX_UART_DATA  = x"7E" then
--							r_RX_INDEX <= 2;
--							r_RX_PR_ST <= HEADER;
--						end if;
--						
--					when HEADER =>
--						r_RX_CRC_EN <= '1';
--						r_RX_PKT.header(v_INDEX) <= r_RX_UART_DATA;
--						v_INDEX := v_INDEX + 1;
--						if v_INDEX = r_RX_INDEX then
--							v_INDEX := 0;
--							r_RX_INDEX <= to_int(r_RX_PKT.header(1));
--							r_RX_PR_ST <= PAYLOAD;
--						end if;
--						
--					when PAYLOAD =>
--						r_RX_CRC_EN <= '1';
--						r_RX_PKT.payload(v_INDEX) <= r_RX_UART_DATA;
--						v_INDEX := v_INDEX + 1;
--						if v_INDEX = r_RX_INDEX then
--							v_INDEX := 0;
--							r_RX_INDEX <= 4;
--							r_RX_PR_ST <= CRC;
--						end if;
--						
--					when CRC =>
--						r_RX_PKT.crc(v_INDEX) <= r_RX_UART_DATA;
--						v_INDEX := v_INDEX + 1;
--						if v_INDEX = r_RX_INDEX then
--							v_INDEX := 0;
--							r_RX_LOCK <= '1';
--							r_RX_PR_ST <= IDLE;
--						end if;
--
--				end case;
--
--			end if;
--		end if;
--
--	end process;
--
--	RX_Data_Operation : process (i_EN, i_CLK)
--		variable v_INDEX : integer range 0 to 127 := 0;
--		variable v_LENGTH : integer range 0 to 127 := 0;
--	begin
--
--		if i_EN = '0' then
--			
--			r_RX_BUFFER <= (others => (others => (others => '0')));
--			v_INDEX := 0;
--
--		elsif rising_edge(i_CLK) then
--	
--			if i_RD_BUF = '1' then
--			
--				o_DQ    <= to_std_logic_vector(r_RX_BUFFER(v_INDEX));
--				if v_INDEX = v_LENGTH then
--					v_INDEX := 0;
--					b_RX_FULL <= '0';
--				else
--					v_INDEX := v_INDEX + 1;
--				end if;
--				
--			end if;
--			
--			if r_RX_LOCK = '1' then
--				
--				b_RX_RDY <= not b_RX_FULL;
--				if b_RX_FULL = '0' and r_TX_PKT.crc = to_byte_vector(r_RX_CRC) then
--					r_RX_BUFFER <= convert_packet_to_memory(r_TX_PKT);
--					v_LENGTH := to_int(r_RX_PKT.header(1));
--					b_RX_FULL <= '1';
--					b_RX_RDY <= '1';
--				end if;
--				
--			end if;
--
--		end if;
--
--	end process;


end RTL;
