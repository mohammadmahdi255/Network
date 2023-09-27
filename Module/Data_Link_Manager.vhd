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
	
	-- TX Transmiter signals
	signal r_TX_ST     : t_DL_ST   := IDLE;
	signal r_TX_TRF    : std_logic := '0';
	signal r_TX_BUSY   : std_logic := '0';
	signal r_TX_PKT    : t_PACKET;
	signal r_TX_BUFFER : t_QUEUE;
	
	-- RX Receiver signals
	signal r_RX_ST     : t_DL_ST   := IDLE;
	signal r_RX_VALID  : std_logic := '0';
	signal r_RX_PKT    : t_PACKET;
	signal r_RX_BUFFER : t_QUEUE;

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
		
	TX_Queue : entity Circular_Buffer
	generic map
	(
		DATA_WIDTH => 4;
		ADDR_WIDTH => 3
	);
	port
	(
		i_EN    => i_EN,
		i_CLK   => i_CLK,
		i_PUSH  => r_TX_PUSH,
		i_POP   => r_TX_POP,
		o_FULL  => r_TX_FULL,
		b_EMPTY => r_TX_EMPTY,

		i_DATA  : in  t_BYTE_VECTOR (0 to DATA_WIDTH - 1);
		o_DATA  : out t_BYTE_VECTOR (0 to DATA_WIDTH - 1)
	);
end Circular_Buffer;
		
	Control_Unit : process(i_EN, i_CLK)
		variable v_TX_FRONT : integer range 0 to 7 := 0;
		variable v_TX_REAR  : integer range 0 to 7 := 0;
		variable v_TX_SIZE  : integer range 0 to 8 := 0;
	begin
		
		if i_EN = '0' then
			r_CONC_ST <= IDLE;
			
		elsif rising_edge(i_CLK) then
			
			if r_TX_BUSY = '1' then
				r_TX_TRF <= '0';
				
			elsif to_int(v_TX_SIZE) /= 0 then
				-- POP from TX Queue
				r_TX_PKT <= r_TX_BUFFER.queue(v_TX_FRONT);
				v_TX_FRONT <= v_TX_FRONT + 1;
				v_TX_SIZE := v_TX_SIZE - 1;
				r_TX_TRF <= '1';
			end if;
			
			if to_int(v_TX_SIZE) /= 8 then
				r_TX_BUFFER.queue(v_TX_FRONT + v_TX_SIZE) <= 
				v_TX_SIZE := v_TX_SIZE + 1;
			end if;
			
			
			
		end if;
	
	end process;
	
	TX_FRAME : process (i_EN, i_CLK)
		variable v_NX_ST : t_DL_ST := IDLE;
	begin

		if i_EN = '0' then

			r_TX_BUSY <= '0';
			r_TX_UART_STR <= '0';
			r_TX_UART_DATA <= x"00";
			v_NX_ST := IDLE;
			r_TX_ST <= IDLE;

		elsif rising_edge(i_CLK) then
		
			if r_TX_UART_RDY = '0' or r_TX_UART_STR = '0' then
				r_TX_ST <= v_NX_ST;
			end if;

			if r_TX_UART_RDY = '1' then

				case r_TX_ST is

					when IDLE =>
						if r_TX_TRF = '1' then
							r_TX_BUSY <= '1';
							r_TX_UART_STR <= '1';
							r_TX_UART_DATA <= c_SFD;
							v_NX_ST := SFD;
						end if;
						
					when SFD => 
						r_TX_UART_DATA <= r_TX_PKT.src_mac & r_TX_PKT.dest_mac;
						v_NX_ST := ADDRESS;
						
					when ADDRESS =>
						r_TX_UART_DATA <= r_TX_PKT.p_type;
						v_NX_ST := P_TYPE;
						
					when P_TYPE => 
						r_TX_UART_DATA <= r_TX_PKT.data;
						v_NX_ST := DATA;
						
					when DATA =>
						r_TX_UART_DATA <= r_TX_PKT.crc;
						v_NX_ST := CRC;
						
					when CRC =>
						r_TX_BUSY <= '0';
						r_TX_UART_STR <= '0';
						r_TX_UART_DATA <= x"00";
						v_NX_ST := IDLE;

				end case;

			end if;
			
		end if;

	end process;
	
	RX_FRAME : process (i_EN, i_CLK)
		variable v_NX_ST : t_DL_ST := IDLE;
	begin

		if i_EN = '0' then

			r_RX_VALID <= '0';
			r_RX_UART_CLR <= '0';
			v_NX_ST := IDLE;
			r_RX_ST <= IDLE;

		elsif rising_edge(i_CLK) then
			
			r_RX_UART_CLR <= r_RX_UART_RDY;

			case r_TX_ST is

				when IDLE =>
					r_RX_VALID <= '0';
					if r_RX_UART_IDLE = '0' then
						r_RX_ST <= SFD;
					end if;
					
				when SFD => 
					if r_RX_UART_DATA = c_SFD then
						v_NX_ST := ADDRESS;
					else
						v_NX_ST := IDLE;
					end if;
					
				when ADDRESS =>
					r_RX_PKT.src_mac <= r_RX_UART_DATA(7 downto 4);
					r_RX_PKT.dest_mac <= r_RX_UART_DATA(3 downto 0);
					v_NX_ST := ADDRESS;
					
				when P_TYPE =>
					r_RX_PKT.p_type <= r_RX_UART_DATA;
					v_NX_ST := P_TYPE;
					
				when DATA => 
					r_RX_PKT.data <= r_RX_UART_DATA;
					v_NX_ST := DATA;
					
				when CRC =>
					r_RX_PKT.crc <= r_RX_UART_DATA;
					v_NX_ST := IDLE;
					r_RX_VALID <= r_RX_UART_RDY;

			end case;
			
			if r_RX_UART_RDY = '1' then
				r_RX_ST <= v_NX_ST;
			end if;
			
		end if;

	end process;


end RTL;

