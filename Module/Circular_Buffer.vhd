library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Circular_Buffer is
	generic
	(
		DATA_WIDTH : integer := 8;
		ADDR_WIDTH : integer := 4
	);
	port
	(
		i_EN    : in std_logic;
		i_CLK   : in std_logic;
		i_WR_EN : in std_logic;
		i_RD_EN : in std_logic;
		o_FULL  : out std_logic;
		o_EMPTY : out std_logic;

		i_DATA  : in std_logic_vector (DATA_WIDTH - 1 downto 0);
		o_DATA  : out std_logic_vector (DATA_WIDTH - 1 downto 0)
	);
end Circular_Buffer;

architecture RTL of Circular_Buffer is

	type  t_MEM is array(0 to 2 ** ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1  downto 0); 

	signal r_FRONT : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal r_REAR  : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal w_FULL  : std_logic;
	signal w_EMPTY : std_logic;
	
	signal r_Buffer : t_MEM := (others => (others => '0'));

begin

	o_FULL <= w_FULL;
	o_EMPTY <= w_EMPTY;
	
	w_FULL <= '1' when r_FRONT = r_REAR + 1 else
		'0';
	w_EMPTY <= '1' when r_FRONT = r_REAR else
		'0';

	Control : process (i_EN, i_CLK)
	begin
		
		if i_EN = '0' then
			r_FRONT <= (others => '0');
			r_REAR  <= (others => '0');
			r_Buffer <= (others => (others => '0'));
		elsif falling_edge(i_CLK) then
			if i_RD_EN = '1' and w_EMPTY = '0' then
				r_FRONT <= r_FRONT + 1;
			end if;
			
			if i_WR_EN = '1' and w_FULL = '0' then
				r_Buffer(to_integer(r_REAR)) <= i_DATA;
				r_REAR <= r_REAR + 1;
			end if;
			
		end if;

	end process;
	
	o_DATA <= r_Buffer(to_integer(r_FRONT));

end RTL;
