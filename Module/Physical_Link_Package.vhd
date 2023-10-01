library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.MEMORY_PACKAGE.all;

package Physical_Link_Package is

	type t_PHY_ST is (
		IDLE,
		SFD,
		SRC_MAC,
		DEST_MAC,
		LEN,
		PAYLOAD,
		FCS
	);

	-- Start Frame Delimiter
	constant c_SFD         : t_BYTE := x"7E";

	------------------------------------------------------------------------------
	-- Table: Frame Fields based on IEEE 802.3 Ethernet Frame
	-- Description: This table provides a description of the individual fields within the t_FRAME record, along with their byte sizes.
	--
	-- +--------------+---------------------------------------+--------------+
	-- | Field        | Description                           | Byte Size    |
	-- +--------------+---------------------------------------+--------------+
	-- | SFD          | Start Frame Delimiter  field of the   | 1 byte       |
	-- |              | frame.                                |              |
	-- +--------------+---------------------------------------+--------------+
	-- | src_mac      | Represents the source MAC address     | 1 byte       |
	-- |              | field of the frame.                   |              |
	-- +--------------+---------------------------------------+--------------+
	-- | dest_mac     | Represents the destination MAC        | 1 byte       |
	-- |              | address field of the frame.           |              |
	-- +--------------+---------------------------------------+--------------+
	-- | len          | Represents the length field of the    | 1 byte       |
	-- |              | frame.                                |              |
	-- +--------------+---------------------------------------+--------------+
	-- | payload      | Represents the payload of the frame   | 4 bytes      |
	-- |              | (t_BYTE_VECTOR with indices 0 to 15). | (variable)   |
	-- +--------------+---------------------------------------+--------------+
	-- | fcs          | Represents the Frame Check Sequence   | 4 bytes      |
	-- |              | (FCS) of the frame.                   |              |
	-- +--------------+---------------------------------------+--------------+
	------------------------------------------------------------------------------
	
	type t_FRAME is record

		src_mac  : t_BYTE;
		dest_mac : t_BYTE;
		len      : t_BYTE;
		payload  : t_BYTE_VECTOR(0 to 15);
		fcs      : t_BYTE_VECTOR(0 to 3);

	end record;
	
	
	------------------------------------------------------------------------------
	-- Table: Field Description for t_UART Record
	-- Description: This table provides a description of the individual fields within the t_UART record, along with their data types.
	--
	-- +----------+-------------------------------------+------------+
	-- | Field    | Description                         | Data Type  |
	-- +----------+-------------------------------------+------------+
	-- | tx_str   | Transmission Start Signal           | std_logic  |
	-- +----------+-------------------------------------+------------+
	-- | tx_rdy   | Transmission Ready Signal           | std_logic  |
	-- +----------+-------------------------------------+------------+
	-- | tx_data  | Transmission Data                   | t_BYTE     |
	-- +----------+-------------------------------------+------------+
	-- | rx_clr   | Receive Clear Signal                | std_logic  |
	-- +----------+-------------------------------------+------------+
	-- | rx_rdy   | Receive Ready Signal                | std_logic  |
	-- +----------+-------------------------------------+------------+
	-- | rx_idle  | Receive Idle Signal                 | std_logic  |
	-- +----------+-------------------------------------+------------+
	-- | rx_data  | Received Data                       | t_BYTE     |
	-- +----------+-------------------------------------+------------+
	------------------------------------------------------------------------------
	
	type t_UART is record

		tx_str   : std_logic;
		tx_rdy   : std_logic;
		tx_data  : t_BYTE;
		
		rx_clr   : std_logic;
		rx_rdy   : std_logic;
		rx_dv    : std_logic;
		rx_data  : t_BYTE;

	end record;
	
end Physical_Link_Package;

package body Physical_Link_Package is


end Physical_Link_Package;
