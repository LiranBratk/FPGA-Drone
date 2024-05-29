-----------------------------------------------------------------------------
-- Title           : Title
-----------------------------------------------------------------------------
-- Author          : Daniel Pelikan
-- Date Created    : 01-07-2016
-----------------------------------------------------------------------------
-- Description     : Description
--							
--
-----------------------------------------------------------------------------
-- Copyright 2016. All rights reserved
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;


entity SimpleAdd is
--  generic (
--    g_Variable : integer := 10    
--    );
	port 
	(
		reg1		: in std_logic_vector(7 downto 0);
		reg2		: in std_logic_vector(7 downto 0);
		reg3		: out std_logic_vector(7 downto 0)
		
	);

end entity;

architecture rtl of SimpleAdd is

--	signal tmp : std_logic := 0 ;
--	constant const    : std_logic_vector(3 downto 0) := "1000";

begin

	reg3 <= std_logic_vector(unsigned(reg1) + unsigned(reg2));
	
end rtl;
