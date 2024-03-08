LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;


--  Entity Declaration

ENTITY PWM_sig IS
	-- {{ALTERA_IO_BEGIN}} DO NOT REMOVE THIS LINE!
	PORT
	(
		rst : IN STD_LOGIC;
		clk : IN STD_LOGIC;
		
		DC : IN STD_LOGIC_VECTOR(21 downto 0);
		pwm : OUT STD_LOGIC
	);
	-- {{ALTERA_IO_END}} DO NOT REMOVE THIS LINE!

END PWM_sig;


--  Architecture Body

ARCHITECTURE PWM_sig_architecture OF PWM_sig IS

signal cou : std_logic_vector(21 downto 0);
signal flag : std_logic;

begin

process(clk,rst)

begin

if rst = '1' then 
	cou<=(others=>'0');
	flag<= '1';
	pwm<='0';
	
elsif clk'event and clk = '1' then


	if flag = '1' then 
		if (cou<= 1000000) then
			cou<= cou+'1';
			pwm<= '0';
		else
			flag<='0'; 
			cou<=(others =>'0');
		end if; 
	else 
		if (cou<=1000000) then
			cou<=cou + '1';
				if cou<=DC then
					pwm<='1';
				else
					pwm<='0';
				end if;
		else 
			cou<=(others=>'0');
			flag<='0';
		end if;
end if;
end if;
end process;

END PWM_sig_architecture;