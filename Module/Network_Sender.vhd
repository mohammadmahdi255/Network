library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Data_Link is
	port
	(
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
end Data_Link;

architecture RTL of Data_Link is

	type t_FSM is (
		IDLE,
		SFD,
		DEST_MAC,
		SRC_MAC,
		DATA_LENGTH,
		DATA,
		CRC
	);
	
	signal r_TX_PR_ST   : t_FSM     := IDLE;	
	signal r_RX_PR_ST   : t_FSM     := IDLE;
	
	signal r_TX_STR         : std_logic := '0';
	signal r_TX_DATA_LENGTH : unsigned(15 downto 0) := (others => '0');
	
	signal r_RX_CLR         : std_logic := '0';
	signal r_RX_DATA_LENGTH : unsigned(15 downto 0) := (others => '0');
	
begin

	o_TX_STR <= r_TX_STR;
	o_RX_CLR <= r_RX_CLR;
	
	TX_FRAME : process (i_EN, i_CLK)
		variable v_COUNTER   : unsigned(15 downto 0) := (others => '0');
	begin

		if i_EN = '0' then
			r_TX_PR_ST <= IDLE;
			v_COUNTER := (others => '0');
			o_TX_DATA <= (others => '0');
			r_TX_DATA_LENGTH <= (others => '0');
			r_TX_STR <= '0';
			o_TX_RD_EN <= '0';
			
		elsif rising_edge(i_CLK) then
		
			o_TX_RD_EN <= '0';
			if i_TX_RDY = '0' then
				r_TX_STR <= '0';
			end if;
			
			if i_TX_RDY = '1' and r_TX_STR = '0' and i_TX_EMPTY = '0' then
			
				o_TX_DATA <= i_TX_DATA;
				o_TX_RD_EN  <= not i_TX_EMPTY;
				r_TX_STR <= not i_TX_EMPTY;
				
				case r_TX_PR_ST is
					when IDLE =>
						if i_TX_DATA = x"7E" then
							r_TX_PR_ST <= SFD;
						else
							r_TX_STR <= '0';
						end if;
					when SFD =>
						r_TX_PR_ST <= DEST_MAC;
					when DEST_MAC =>
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
								r_TX_PR_ST <= CRC;
							else
								r_TX_PR_ST <= DATA;
							end if;
						end if;
						
					when DATA => 
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = r_TX_DATA_LENGTH then
							v_COUNTER := (others => '0');
							r_TX_PR_ST   <= CRC;
						end if;
						
					when CRC =>
						v_COUNTER := v_COUNTER + 1;
						
				end case;
				
			end if;
			
			if r_TX_PR_ST = CRC and v_COUNTER = x"0004" then
				v_COUNTER := (others => '0');
				if i_TX_EMPTY = '0' and i_TX_DATA = x"7E" then
					r_TX_PR_ST <= SFD;
				else 
					r_TX_PR_ST <= IDLE;
				end if;
			end if;
			
		end if;

	end process TX_FRAME;
	
	
	RX_FRAME : process (i_EN, i_CLK)
		variable v_COUNTER   : unsigned(15 downto 0) := (others => '0');
	begin

		if i_EN = '0' then
			r_RX_PR_ST <= IDLE;
			v_COUNTER := (others => '0');
			o_RX_DATA <= (others => '0');
			r_RX_DATA_LENGTH <= (others => '0');
			r_RX_CLR <= '0';
			o_RX_WR_EN <= '0';
			
		elsif rising_edge(i_CLK) then
		
			o_RX_WR_EN <= '0';
			r_RX_CLR <= i_RX_RDY;
			
			if i_RX_RDY = '1' and r_RX_CLR = '0' and i_RX_FULL = '0' then
			
				o_RX_DATA <= i_RX_DATA;
				o_RX_WR_EN  <= not i_RX_FULL;
				
				case r_RX_PR_ST is
					when IDLE =>
						if i_RX_DATA = x"7E" then
							r_RX_PR_ST <= SFD;
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
								r_RX_PR_ST <= CRC;
							else
								r_RX_PR_ST <= DATA;
							end if;
						end if;
						
					when DATA => 
						v_COUNTER := v_COUNTER + 1;
						if v_COUNTER = r_RX_DATA_LENGTH then
							v_COUNTER := (others => '0');
							r_RX_PR_ST   <= CRC;						
						end if;
						
					when CRC =>
						v_COUNTER := v_COUNTER + 1;
						
				end case;
				
			end if;
			
			if r_RX_PR_ST = CRC and v_COUNTER = x"0004" then
				v_COUNTER := (others => '0');
				if i_RX_FULL = '0' and i_RX_DATA = x"7E" then
					r_RX_PR_ST <= SFD;
				else 
					r_RX_PR_ST <= IDLE;
				end if;
			end if;
			
		end if;

	end process RX_FRAME;

end RTL;
