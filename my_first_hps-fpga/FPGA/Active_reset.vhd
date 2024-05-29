
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;


--  Entity Declaration

ENTITY Active_reset IS
PORT
(
clk10m : IN STD_LOGIC;

reset_n_OUT : out STD_LOGIC

);


END Active_reset;




ARCHITECTURE Active_reset_architecture OF Active_reset IS
signal srset_n:std_logic:='0';
signal cou:integer:= 0;


BEGIN
process(clk10m)
begin

if clk10m'event and clk10m='1' then 


		if cou <= 12 then  
			cou<= cou +1;			
			
		else
			cou<=0;
			srset_n<= not srset_n;
		end if;
end if;
END PROCESS;	
reset_n_OUT<=srset_n;

END Active_reset_architecture;
