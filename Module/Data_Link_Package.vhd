library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.PHYSICAL_LINK_PACKAGE.all;
use WORK.MEMORY_PACKAGE.all;

package Data_Link_Package is

	type t_DL_ST is (ARP_REQUEST, ARP_REPLAY, ESTABLISHED);

	type t_FR_ST is (
		IDLE,
		SRC_MAC,
		DEST_MAC,
		LEN,
		PAYLOAD,
		FCS,
		FRAME_RDY
	);

	-- Broad Cast
	constant c_BROAD_CAST  : t_BYTE := x"FF";

	-- ARP Protocol
	constant c_ARP         : t_BYTE := x"08";
	constant c_ARP_REQUEST : t_BYTE := x"01";
	constant c_ARP_REPLY   : t_BYTE := x"02";

	-- Flags
	constant c_ACK         : t_BYTE := x"80";
	constant c_SYN         : t_BYTE := x"40";

	type t_CRC is record
		rst_n : std_logic;
		en    : std_logic;
		crc   : std_logic_vector(31 downto 0);
		data  : t_BYTE;
	end record;

	type t_BUFFER is record
		len     : t_BYTE;
		payload : t_BYTE_VECTOR(0 to 15);
	end record;

	--	type t_TCP_PAYLOAD is record
	--
	--		protocol : t_BYTE;
	--		seq_num  : t_BYTE;
	--		ack_num  : t_BYTE;
	--		flag     : t_BYTE;
	--		data     : t_BYTE;
	--
	--	end record;

	--	function ftbv(frame : t_FRAME) return t_BYTE_VECTOR;
	--	function byte_vector_to_packet(data : t_BYTE_VECTOR) return t_PACKET;
	--	
	function make_arp(operation, src_mac, dest_mac : t_BYTE) return t_BUFFER;

end Data_Link_Package;

package body Data_Link_Package is

	-- frame_to_byte_vector
	--	function ftbv(frame : t_FRAME) return t_BYTE_VECTOR is
	--		variable result : t_BYTE_VECTOR(0 to 10);
	--	begin
	--		result(0) 		:= frame.src_mac;
	--		result(1) 		:= frame.dest_mac;
	--		result(2 to 6) 	:= frame.payload;
	--		result(7 to 10) := frame.fcs;
	--		return result;
	--	end function;
	--
	---- Function to convert t_BYTE_VECTOR to t_PACKET
	--function byte_vector_to_packet(data : t_BYTE_VECTOR) return t_PACKET is
	--    variable result : t_PACKET;
	--begin
	--    result.address  := data(0);
	--    result.protocol  := data(1);
	--    result.flag  := data(2);
	--    result.data     := data(3);
	--    result.crc      := data(4 to 5);
	--    return result;
	--end function;
	--

	------------------------------------------------------------------------------
	-- Table: ARP Fields Based on Real ARP Protocol
	-- Description: This table provides a description of the individual fields within the ARP payload, along with their byte sizes.
	--
	-- +--------------+----------------------------------+--------------+
	-- | Field        | Description                      | Byte Size    |
	-- +--------------+----------------------------------+--------------+
	-- | protocol     | Represents the protocol field    | 1 byte       |
	-- |              | of the ARP packet.               |              |
	-- +--------------+----------------------------------+--------------+
	-- | operation    | Represents the operation field   | 1 byte       |
	-- |              | of the ARP packet.               |              |
	-- +--------------+----------------------------------+--------------+
	-- | src_mac      | Represents the source MAC        | 1 byte       |
	-- |              | address field of the ARP packet. |              |
	-- +--------------+----------------------------------+--------------+
	-- | dest_mac     | Represents the destination MAC   | 1 byte       |
	-- |              | address field of the ARP packet. |              |
	-- +--------------+----------------------------------+--------------+
	------------------------------------------------------------------------------

	function make_arp(operation, src_mac, dest_mac : t_BYTE) return t_BUFFER is
		variable result                                : t_BUFFER;
	begin
		result.len        := x"04";
		result.payload(0) := c_ARP;
		result.payload(1) := operation;
		result.payload(2) := src_mac;
		result.payload(3) := dest_mac;
		return result;
	end function;

end Data_Link_Package;
