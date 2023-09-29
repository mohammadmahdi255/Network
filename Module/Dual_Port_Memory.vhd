library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;
use work.Memory_Package.all;

entity Dual_Port_Memory is
	port
	(
		i_EN    : in  std_logic;
		i_CLK   : in  std_logic;
		
		i_RE    : in  std_logic;
		i_RADDR : in  std_logic_vector(9 downto 0);
		o_RDATA : out t_BYTE;
		
		i_WE    : in  std_logic;
		i_WADDR : in  std_logic_vector(9 downto 0);
		i_WDATA : in  t_BYTE
	);
end Dual_Port_Memory;

architecture RTL of Dual_Port_Memory is
	
	signal r_MEMORY : t_BYTE_VECTOR(0 to 540);

begin

	process (i_EN, i_CLK)
	begin
	
		if i_EN = '0' then
			r_MEMORY <= (others => (others => '0'));
			o_RDATA <= (others => '0');
		elsif rising_edge(i_CLK) then
			
			if i_RE = '1' then
				o_RDATA <= r_MEMORY(to_int(i_RADDR));
			end if;
			
			if i_WE = '1' then
				r_MEMORY(to_int(i_WADDR)) <= i_WDATA;
			end if;
			
		end if;
	
	end process;

end RTL;
