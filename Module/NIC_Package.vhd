library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;
use work.Memory_Package.all;

package NIC_Package is

	type t_NIC_STATE is (
		IDLE,
		HEADER,
		PAYLOAD,
		CRC
	);

	type t_TX_REQ is (IDLE, BUFFER_OP, COMPLETE);

	type t_MEMORY is array(0 to 127) of t_BYTE_VECTOR(0 to 1);
	type t_PACKET is record
		
		header  : t_BYTE_VECTOR(0 to 1);
		payload : t_BYTE_VECTOR(0 to 253);
		crc     : t_BYTE_VECTOR(0 to 3);
		
	end record;

	function to_slv(i : integer; l: integer) return std_logic_vector;
	
	function to_byte_vector(data : std_logic_vector) return t_BYTE_VECTOR;
	function to_std_logic_vector(input_vector : t_BYTE_VECTOR) return std_logic_vector;
		
	function convert_memory_to_packet(memory: t_MEMORY; crc: std_logic_vector) return t_PACKET;
	function convert_packet_to_memory(packet: t_PACKET) return t_MEMORY;
	
end NIC_Package;

package body NIC_Package is

	function to_slv(i : integer; l: integer) return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(i, l));
	end function;
	
	function to_byte_vector(data : std_logic_vector) return t_BYTE_VECTOR is
	  variable result : t_BYTE_VECTOR(0 to (data'length + 7) / 8 - 1);
	begin
	  for i in result'range loop
		result(i) := data(((i+1)*8-1 + data'right) downto (i*8 + data'right));
	  end loop;
	  return result;
	end function;
	
	function to_std_logic_vector(input_vector : t_BYTE_VECTOR) return std_logic_vector is
	  variable result_vector : std_logic_vector(input_vector'length * 8 - 1 downto 0);
	begin
	  -- Concatenate the elements of the input_vector
	  for i in input_vector'range loop
		result_vector(i * 8 + 7 downto i * 8) := input_vector(i);
	  end loop;
	  
	  return result_vector;
	end function;
	
	function convert_memory_to_packet(memory: t_MEMORY; crc: std_logic_vector) return t_PACKET is
		variable packet: t_PACKET;
	begin
		

		packet.header := memory(0);
		packet.crc := to_byte_vector(crc);
		
		for i in 1 to 127 loop
			packet.payload(2 * i - 2) := memory(i)(0);
			packet.payload(2 * i - 1) := memory(i)(1);
		end loop;
    
		return packet;
	end function;
	
	function convert_packet_to_memory(packet: t_PACKET) return t_MEMORY is
		variable memory: t_MEMORY;
	begin
		memory(0) := packet.header;
		
		for i in 1 to 127 loop
			memory(i)(0) := packet.payload(2 * i - 2);
			memory(i)(1) := packet.payload(2 * i - 1);
		end loop;
    
		return memory;
	end function;


end NIC_Package;
