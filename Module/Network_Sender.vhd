library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Data_Link is
	port
	(
		i_EN      : in  std_logic;
		i_CLK     : in  std_logic;
		
		-- Data Link Config
		i_MAC_ADDR : in std_logic_vector (7 downto 0);
		
		-- Data Link Control Pins
		i_PKT_SEND : in std_logic;
		
		-- Data Link Status Pins
		b_TX_RDY  : buffer  std_logic;
		o_RX_RECV : out  std_logic;
		o_ERR_SIG : out  std_logic;
		
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
end Data_Link;

architecture RTL of Data_Link is

	type t_FSM is (
		IDLE,
		SFD,
		DEST_MAC,
		SRC_MAC,
		DATA_LENGTH,
		DATA,
		PADDING,
		CRC
	);
	
	signal r_TX_PR_ST   : t_FSM     := IDLE;	
	signal r_RX_PR_ST   : t_FSM     := IDLE;
	
	signal r_TX_STR         : std_logic := '0';
	signal r_TX_DATA_LENGTH : unsigned(15 downto 0) := (others => '0');
	
	signal r_RX_CLR         : std_logic := '0';
	signal r_RX_DATA_LENGTH : unsigned(15 downto 0) := (others => '0');
	
	constant c_ZERO : std_logic_vector(31 downto 0) := (others => '0');
--	attribute keep : string;
--	attribute keep of c_ZERO : signal is "true";

	signal r_TX_CRC : std_logic_vector(31 downto 0) := (others => '0');
	signal r_RX_CRC : std_logic_vector(31 downto 0) := (others => '0');
	signal r_TX_DATA : std_logic_vector(7 downto 0) := (others => '0');
	signal r_TX_CRC_EN  : std_logic;
	signal r_RX_CRC_EN  : std_logic;
	signal r_TX_CRC_RST_N  : std_logic := '0';
	signal r_RX_CRC_RST_N  : std_logic := '0';
begin

	o_TX_STR <= r_TX_STR;
	o_RX_CLR <= r_RX_CLR;
	o_TX_DATA <= r_TX_DATA;
	
	TX_CRC : entity Work.CRC 
		generic map(	
			g_DATA_WIDTH => 8,
			g_CRC_WIDTH  => 32
		)
		port map (
			i_RST_N => r_TX_CRC_RST_N,
			i_EN => r_TX_CRC_EN, 
			i_CLK  => i_CLK,

			i_POLY   => x"814141AB",
			i_INIT   => c_ZERO,
			i_XOROUT => c_ZERO,
			i_REFIN  => '0',
			i_REFOUT => '0',

			i_DATA   => r_TX_DATA,
			o_CRC    => r_TX_CRC
		);
	
	TX_FRAME : process (i_EN, i_CLK)
		variable v_COUNTER   : unsigned(15 downto 0) := (others => '0');
	begin

		if i_EN = '0' then
			r_TX_PR_ST <= IDLE;
			v_COUNTER := (others => '0');
			r_TX_DATA <= (others => '0');
			r_TX_DATA_LENGTH <= (others => '0');
			r_TX_CRC_EN <= '0';
			b_TX_RDY <= '1';
			r_TX_STR <= '0';
			o_TX_RD_EN <= '0';
			
		elsif rising_edge(i_CLK) then
			
			r_TX_CRC_RST_N <= '1';
			r_TX_CRC_EN <= '0';
			o_TX_RD_EN <= '0';
			if i_TX_RDY = '0' then
				r_TX_STR <= '0';
			end if;
			
			if i_TX_RDY = '1' and r_TX_STR = '0' then
			
				r_TX_CRC_EN <= '1';
				r_TX_STR <= '1';
				r_TX_DATA <= i_TX_DATA;
				o_TX_RD_EN <= '1';
				
				case r_TX_PR_ST is
					when IDLE =>
						o_TX_RD_EN <= '0';
						if i_PKT_SEND = '1' then
							r_TX_DATA <= x"7E";
							b_TX_RDY <= '0';
							r_TX_PR_ST <= SFD;
						else
							r_TX_CRC_RST_N <= '0';
							r_TX_STR <= '0';
							r_TX_CRC_EN <= '0';
						end if;
						
					when SFD =>
						r_TX_PR_ST <= DEST_MAC;
						
					when DEST_MAC =>
						o_TX_RD_EN <= '0';
						r_TX_DATA <= i_MAC_ADDR;
						r_TX_PR_ST <= SRC_MAC;
						
					when SRC_MAC =>
						r_TX_DATA_LENGTH(15 downto 8) <= unsigned(i_TX_DATA);
						r_TX_PR_ST <= DATA_LENGTH;
						
					when DATA_LENGTH =>
						if v_COUNTER = x"0000" then
							r_TX_DATA_LENGTH(7 downto 0) <= unsigned(i_TX_DATA);
							v_COUNTER := v_COUNTER + 1;
						else
							v_COUNTER := (others => '0');
							if r_TX_DATA_LENGTH = x"0000" then
								r_TX_DATA <= (others => '0');
								r_TX_PR_ST <= PADDING;
							else
								r_TX_PR_ST <= DATA;
							end if;
						end if;
						
					when DATA => 
						r_TX_CRC_EN <= '1';
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = r_TX_DATA_LENGTH then
							v_COUNTER := (others => '0');
							r_TX_DATA <= (others => '0');
							r_TX_PR_ST   <= PADDING;
						end if;
					
					when PADDING =>
						r_TX_DATA <= (others => '0');
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = x"0004" then
							v_COUNTER := (others => '0');
							r_TX_CRC_EN <= '0';
							r_TX_DATA <= r_TX_CRC(31 downto 24);
							r_TX_PR_ST <= CRC;
						end if;
						
					when CRC =>
						v_COUNTER := v_COUNTER + 1;
						r_TX_CRC_EN <= '0';
						if v_COUNTER = x"0004" then
							v_COUNTER := (others => '0');
							b_TX_RDY <= '1';
							r_TX_STR <= '0';
							r_TX_PR_ST <= IDLE;
						else
							r_TX_DATA <= r_TX_CRC(31-8*to_integer(v_COUNTER) downto 24-8*to_integer(v_COUNTER));
						end if;
				end case;
				
			end if;	
			
		end if;

	end process TX_FRAME;
	
	RX_CRC : entity Work.CRC 
		generic map(	
			g_DATA_WIDTH => 8,
			g_CRC_WIDTH  => 32
		)
		port map (
			i_RST_N => r_RX_CRC_RST_N,
			i_EN => r_RX_CRC_EN, 
			i_CLK  => i_CLK,

			i_POLY   => x"814141AB",
			i_INIT   => c_ZERO,
			i_XOROUT => c_ZERO,
			i_REFIN  => '0',
			i_REFOUT => '0',

			i_DATA   => i_RX_DATA,
			o_CRC    => r_RX_CRC
		);
	
	RX_FRAME : process (i_EN, i_CLK)
		variable v_COUNTER   : unsigned(15 downto 0) := (others => '0');
	begin

		if i_EN = '0' then
			r_RX_PR_ST <= IDLE;
			v_COUNTER := (others => '0');
			o_RX_DATA <= (others => '0');
			r_RX_DATA_LENGTH <= (others => '0');
			r_RX_CRC_EN <= '0';
			o_RX_RECV <= '0';
			r_RX_CLR <= '0';
			o_RX_WR_EN <= '0';
			
		elsif rising_edge(i_CLK) then
		
			r_RX_CRC_RST_N <= '1';
			r_RX_CRC_EN <= '0';
			o_RX_WR_EN <= '0';
			r_RX_CLR <= i_RX_RDY;
			
			if i_RX_RDY = '1' and r_RX_CLR = '0' then
			
				o_RX_DATA <= i_RX_DATA;
				o_RX_WR_EN  <= not i_RX_FULL;
				o_ERR_SIG <= '0';
				r_RX_CRC_EN <= '1';
				
				case r_RX_PR_ST is
					when IDLE =>
						if i_RX_DATA = x"7E" then
							r_RX_PR_ST <= SFD;
							o_RX_RECV <= '0';
						else
							r_RX_CRC_EN <= '0';
							r_RX_CRC_RST_N <= '0';
						end if;
					when SFD =>
						r_RX_PR_ST <= DEST_MAC;
					when DEST_MAC =>
						r_RX_PR_ST <= SRC_MAC;
					when SRC_MAC =>
						r_RX_DATA_LENGTH(15 downto 8) <= unsigned(i_RX_DATA);
						r_RX_PR_ST <= DATA_LENGTH;
					when DATA_LENGTH =>
						if v_COUNTER = x"0000" then
							r_RX_DATA_LENGTH(7 downto 0) <= unsigned(i_RX_DATA);
							v_COUNTER := v_COUNTER + 1;
						else
							v_COUNTER := (others => '0');
							if r_RX_DATA_LENGTH = x"0000" then
								r_RX_PR_ST <= PADDING;
							else
								r_RX_PR_ST <= DATA;
							end if;
						end if;
						
					when DATA => 
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = r_RX_DATA_LENGTH then
							v_COUNTER := (others => '0');
							r_RX_CRC_EN <= '0';
							r_RX_PR_ST   <= PADDING;						
						end if;
						
					when PADDING =>
						r_RX_CRC_EN <= '0';
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = x"0004" then
							v_COUNTER := (others => '0');
							r_RX_CRC_EN <= '1';
							r_RX_PR_ST <= CRC;
						end if;
						
					when CRC =>
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = x"0003" then
							v_COUNTER := (others => '0');
							o_RX_RECV <= '1';
							
							if r_RX_CRC = x"00000000" then
								o_ERR_SIG <= '0';
							else
								o_ERR_SIG <= '1';
							end if;
										
							r_RX_PR_ST <= IDLE;
						end if;		
						
				end case;
				
			end if;
			
			
			
		end if;

	end process RX_FRAME;

end RTL;
