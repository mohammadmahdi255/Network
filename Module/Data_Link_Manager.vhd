library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;
use work.Data_Link_Manager_Package.all;
use work.Memory_Package.all;

entity Data_Link_Manager is
	generic
	(
		g_U2X : std_logic                     := '1';
		g_UCD : std_logic_vector(15 downto 0) := x"1111"
	);
	port
	(
		i_EN       : in     std_logic;
		i_CLK      : in     std_logic;
		
		i_ADDR     : in     t_BYTE;

		o_TX_SDO   : out    std_logic;
		i_RX_SDI   : in     std_logic
	);
end Data_Link_Manager;

architecture RTL of Data_Link_Manager is
	
	-- UART Signals
	signal r_TX_UART_STR  : std_logic                    := '0';
	signal r_TX_UART_RDY  : std_logic                    := '0';
	signal r_RX_UART_CLR  : std_logic                    := '0';
	signal r_RX_UART_RDY  : std_logic                    := '0';
	signal r_RX_UART_IDLE : std_logic                    := '0';

	signal r_TX_UART_DATA : std_logic_vector(7 downto 0) := (others => '0');
	signal r_RX_UART_DATA : std_logic_vector(7 downto 0) := (others => '0');
	
	-- Connection Controler Signals
	signal r_CONC_ST : t_CONC_ST := IDLE;
	
	signal r_TX_ST   : t_DL_ST   := IDLE;
	signal r_TX_TRF  : std_logic := '0';

begin

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
		o_RX_IDLE   => r_RX_UART_IDLE,

		i_TX_DATA   => r_TX_UART_DATA,
		o_RX_DATA   => r_RX_UART_DATA,

		o_TX_SDO    => o_TX_SDO,
		i_RX_SDI    => i_RX_SDI
		);
		
--	Connection_Control : process(i_EN, i_CLK)
--	begin
--		
--		if i_EN = '0' then
--			r_CONC_ST <= IDLE;
--			
--		elsif rising_edge(i_CLK) then
--		
--			case r_CONC_ST is
--			
--				when IDLE =>
--					if i_RX_SDI = '1' then
--						r_TX_UART_STR <= '1';
--						r_TX_UART_DATA <= SFD;
--					end if;
--					
--					if r_TX_UART_RDY = '0' then
--						r_TX_UART_STR <= '0';
--						r_CONC_ST <= HANDSHAKE;
--					end if;
--					
--				when HANDSHAKE =>
--					if r_RX_UART_RDY = '1' then
--						r_RX_UART_CLR <= '1';
--						if r_RX_UART_DATA = x"7E" then
--							r_CONC_ST <= i_ADDR;
--						end if;
--					end if;
--			
--			end case;
--			
--			if i_RX_SDI = '0' and r_RX_UART_IDLE = '1' then
--				r_CONC_ST <= IDLE;
--			end if;
--		
--		end if;
--	
--	end process;
	
	TX_FRAME : process (i_EN, i_CLK)
		variable v_INDEX : std_logic_vector(9 downto 0) := (others => '0');
	begin

		if i_EN = '0' then

			v_INDEX := (others => '0');
			r_TX_CPLT <= '0';
			r_TX_UART_STR <= '0';
			r_TX_ST <= IDLE;
			
			-- TX CRC
			r_TX_CRC_RST <= '0';

		elsif rising_edge(i_CLK) then
		
			r_TX_CRC_EN <= '0';
			if r_TX_UART_RDY = '0' then
				r_TX_UART_STR <= '0';
			end if;

			if r_TX_UART_RDY = '1' and r_TX_UART_STR = '0' then
			
				r_TX_UART_STR <= '1';

--				r_TX_CRC_RST <= '1';
--				r_TX_CRC_EN <= '1';

				case r_TX_ST is

					when IDLE =>
						r_TX_UART_STR <= r_TX_TRF;
						if r_TX_TRF = '1' then
							r_TX_UART_DATA <= c_SFD;
							r_TX_ST <= SFD;
						end if;
						
					when SFD => 
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


end RTL;

