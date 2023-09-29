library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;

package Memory_Package is

	subtype t_BYTE is std_logic_vector(7 downto 0);
	type t_BYTE_VECTOR is array(natural range <>) of t_BYTE;
	
	function to_int(b         : std_logic_vector) return integer;
	
	function to_byte_vector(data : std_logic_vector) return t_BYTE_VECTOR;

end Memory_Package;

package body Memory_Package is

	function to_int(b : std_logic_vector) return integer is
	begin
		return to_integer(unsigned(b));
	end function;
	
	-- to_byte_vector
	function to_byte_vector(data : std_logic_vector) return t_BYTE_VECTOR is
	  variable result : t_BYTE_VECTOR(0 to (data'length + 7) / 8 - 1);
	begin
	  for i in result'range loop
		result(i) := data(((i+1)*8-1 + data'right) downto (i*8 + data'right));
	  end loop;
	  return result;
	end function;

 
end Memory_Package;
