library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.uart_package.all;
use work.STD_PACKAGE.all;

entity Circular_Buffer is
	generic
	(
		DATA_WIDTH : integer := 2;
		ADDR_WIDTH : integer := 4
	);
	port
	(
		i_EN    : in     std_logic;
		i_CLK   : in     std_logic;
		i_PUSH  : in     std_logic;
		i_POP   : in     std_logic;
		o_FULL  : out    std_logic;
		b_EMPTY : buffer std_logic;

		i_DATA  : in     t_BYTE_VECTOR (0 to DATA_WIDTH - 1);
		o_DATA  : out    t_BYTE_VECTOR (0 to DATA_WIDTH - 1)
	);
end Circular_Buffer;

architecture RTL of Circular_Buffer is

	constant c_SIZE : integer := 2 ** ADDR_WIDTH;
	type t_MEM is array(0 to c_SIZE - 1) of t_BYTE_VECTOR (0 to DATA_WIDTH - 1);

	signal r_FRONT  : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal r_REAR   : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
	signal r_SIZE   : integer range 0 to c_SIZE         := 0;
	signal w_FULL   : std_logic;

	signal r_BUFFER : t_MEM := (others => (others => (others => '0')));

begin

	o_FULL <= w_FULL;

	w_FULL <= '1' when r_SIZE = c_SIZE else
		'0';
	b_EMPTY <= '1' when r_SIZE = 0 else
		'0';

	Control : process (i_EN, i_CLK)
	begin

		if i_EN = '0' then
			r_FRONT <= (others => '0');
			r_REAR  <= (others => '0');
			r_SIZE  <= 0;

		elsif falling_edge(i_CLK) then

			if i_POP = '1' and b_EMPTY = '0' then
				r_FRONT <= r_FRONT + 1;
			end if;

			if i_PUSH = '1' and w_FULL = '0' then
				r_BUFFER(to_integer(r_REAR)) <= i_DATA;
				r_REAR                       <= r_REAR + 1;
			end if;

			r_SIZE <= r_SIZE + to_int(i_PUSH and not w_FULL) - to_int(i_POP and not b_EMPTY);

		end if;

	end process;

	o_DATA <= r_BUFFER(to_integer(r_FRONT));

end RTL;
