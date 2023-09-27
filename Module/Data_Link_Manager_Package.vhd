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
	
	function packet_to_byte_vector(packet : t_PACKET) return t_BYTE_VECTOR;
	function byte_vector_to_packet(data : t_BYTE_VECTOR) return t_PACKET;

end Data_Link_Manager_Package;

package body Data_Link_Manager_Package is

function packet_to_byte_vector(packet : t_PACKET) return t_BYTE_VECTOR is
    variable result : t_BYTE_VECTOR(0 to 3);
begin
    result(0) := packet.src_mac & packet.dest_mac;
    result(1) := packet.p_type;
    result(2) := packet.data;
    result(3) := packet.crc;
    return result;
end function;

-- Function to convert t_BYTE_VECTOR to t_PACKET
function byte_vector_to_packet(data : t_BYTE_VECTOR) return t_PACKET is
    variable result : t_PACKET;
begin
    result.src_mac  := data(0)(7 downto 4);
    result.dest_mac := data(0)(3 downto 0);
    result.p_type   := data(1);
    result.data     := data(2);
    result.crc      := data(3);
    return result;
end function;
 
end Data_Link_Manager_Package;
