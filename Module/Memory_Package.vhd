library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;

package Memory_Package is

	subtype t_BYTE is std_logic_vector(7 downto 0);
	type t_BYTE_VECTOR is array(natural range <>) of t_BYTE;
	
	function to_int(b         : std_logic_vector) return integer;

end Memory_Package;

package body Memory_Package is

	function to_int(b : std_logic_vector) return integer is
	begin
		return to_integer(unsigned(b));
	end function;

 
end Memory_Package;
