library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;
use work.Memory_Package.all;

package Data_Link_Manager_Package is

	type t_CONC_ST is (IDLE, HANDSHAKE, DEST_ADDR, ESTABLISHED);
	type t_DL_ST is (
		IDLE,
		SFD,
		ADDRESS,
		P_TYPE,
		DATA,
		CRC
	);

	
	constant c_SFD : t_BYTE := x"7E";
	constant ACK : t_BYTE := x"AC";
	
	type t_PACKET is record
		
		src_mac  : std_logic_vector(3 downto 0);
		dest_mac : std_logic_vector(3 downto 0);
		p_type   : t_BYTE;
		data     : t_BYTE;
		crc      : t_BYTE;
		
	end record;

end Data_Link_Manager_Package;

package body Data_Link_Manager_Package is

 
end Data_Link_Manager_Package;
