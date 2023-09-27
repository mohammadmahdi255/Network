library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity UART_Network is
    Port ( 
		i_EN  : in  STD_LOGIC;
        i_CLK : in  STD_LOGIC
		 );
end UART_Network;

architecture RTL of UART_Network is

	type t_FSM is (IDLE, REQUEST, WAIT_ACK);
	signal r_PR_ST : t_FSM := IDLE;
	
begin

	SEND_DATA :process (i_EN, i_CLK)
	begin
	
		if i_EN = '0' then
			
		elsif rising_edge(i_CLK) then
			
		end if;
	
	end process SEND_DATA;


end RTL;

