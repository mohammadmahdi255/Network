LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY Circular_Buffer_TB IS
END Circular_Buffer_TB;
 
ARCHITECTURE behavior OF Circular_Buffer_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Circular_Buffer
    PORT(
         i_EN : IN  std_logic;
         i_CLK : IN  std_logic;
         i_WR_EN : IN  std_logic;
         i_RD_EN : IN  std_logic;
         o_FULL : OUT  std_logic;
         o_EMPTY : OUT  std_logic;
         i_DATA : IN  std_logic_vector(7 downto 0);
         o_DATA : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_EN : std_logic := '0';
   signal i_CLK : std_logic := '0';
   signal i_WR_EN : std_logic := '0';
   signal i_RD_EN : std_logic := '0';
   signal i_DATA : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal o_FULL : std_logic;
   signal o_EMPTY : std_logic;
   signal o_DATA : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant i_CLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Circular_Buffer PORT MAP (
          i_EN => i_EN,
          i_CLK => i_CLK,
          i_WR_EN => i_WR_EN,
          i_RD_EN => i_RD_EN,
          o_FULL => o_FULL,
          o_EMPTY => o_EMPTY,
          i_DATA => i_DATA,
          o_DATA => o_DATA
        );

   -- Clock process definitions
   i_CLK_process :process
   begin
		i_CLK <= '0';
		wait for i_CLK_period/2;
		i_CLK <= '1';
		wait for i_CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
	  i_EN <= '1';
	  wait for i_CLK_period * 3;
	  
	  i_WR_EN <= '1';
	  
	  for i in 10 to 40 loop
		i_DATA <= std_logic_vector(to_unsigned(i, 8));
		wait for i_CLK_period;
	  end loop;
	  
	  i_WR_EN <= '0';
      wait for 500 ns;
	  i_RD_EN <= '1';

      wait for i_CLK_period;

      -- insert stimulus here 

      wait;
   end process;

END;
