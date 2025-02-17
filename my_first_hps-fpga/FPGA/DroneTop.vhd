	 library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DroneTop is
    Port (
		outclk_2 	: out std_logic;        -- outclk2.clk
		locked   	: out std_logic;         --  locked.export
		
	 -- Global variables
		gclk : in STD_LOGIC;
		rst: in STD_LOGIC;
	
	 -- Required ADC communication serial
		ADC_CONVST : out STD_LOGIC;
		ADC_SCK : out STD_LOGIC;
		ADC_SDI : out STD_LOGIC;
		ADC_SDO : in STD_LOGIC;
		
	 -- Motors output
		M1 : OUT STD_LOGIC;
		M2 : OUT STD_LOGIC;
		M3 : OUT STD_LOGIC;
		M4 : OUT STD_LOGIC
    );
end DroneTop;


--	Goals for whole application:
--		1. Communicate with ADC, get value from potentiometer -> translate it to DutyCycle for PWM
--		2. Do PWM with ADC value
--		3. Be able to get commands from ESP using GPIO (includes coding esp and web application <EZ>)


architecture ARC_DroneTop of DroneTop IS
	-- Any signals
	signal Sdc : std_logic_vector(10 downto 0);
	signal data : std_logic_vector(11 downto 0);
	signal done : std_logic;

	signal outclk_0 :  std_logic; 
	signal outclk_1 : std_logic;
	signal measure_ch : std_logic_VECTOR(2 DOWNTO 0);
	signal measure_start : std_logic;

	signal DC1 : std_logic_vector(21 downto 0);
	signal DC2 : std_logic_vector(21 downto 0);
	signal DC3 : std_logic_vector(21 downto 0);
	signal DC4 : std_logic_vector(21 downto 0);
	
	-- Declare Active reset as a component
	component Active_reset IS
		Port (
			clk10m : IN STD_LOGIC;
			reset_n_OUT : out STD_LOGIC
		);
	end component;

	-- Declare PLL as a component
	component soc_system_pll_0 is
		Port (
			refclk   : in  std_logic ; -- clk
			rst      : in  std_logic ; -- reset
			outclk_0 : out std_logic;        -- clk
			outclk_1 : out std_logic;        -- clk
			outclk_2 : out std_logic;        -- clk
			locked   : out std_logic         -- export
		);
	end component soc_system_pll_0;

	-- Declare ltc2308 as a component
	component adc_ltc2308 is
		Port (
		-- Global variables
			clk : in STD_LOGIC;
--			clock_out: out std_LOGIC;
--			DataOut : out std_LOGIC_vector(11 downto 0);
		
		-- Required ADC communication serial
			ADC_CONVST : out STD_LOGIC; -- ADC Conversion Start
			ADC_SCK : out STD_LOGIC; -- ADC CLOCK
			ADC_SDI : out STD_LOGIC; -- FPGA to ADC
			ADC_SDO : in STD_LOGIC; -- ADC to FPGA
			
		-- Detail bits about spi communication
			measure_ch : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			measure_dataread : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
			measure_done : OUT STD_LOGIC;
			measure_start : IN STD_LOGIC
		
		);
	end component;

	
	component PWM_sig is
	port (
		rst : IN STD_LOGIC;
		clk : IN STD_LOGIC;
		DC : IN STD_LOGIC_VECTOR(21 downto 0);
		pwm : OUT STD_LOGIC
		);
	end component;
	
	function DCeq (signal m : integer)
		return integer is variable sol : integer;
			begin 
				sol := 25*m+50000;
				return sol;
	end DCeq;
	
	begin
	-- Any Process
	
	-- PPL
	pll_inst : soc_system_pll_0
	port map (
		refclk   => gclk, --  refclk.clk
		rst      => '0',      --   reset.reset
		outclk_0 => outclk_0, -- outclk0.clk
		outclk_1 => outclk_1, -- outclk1.clk -40mhz
		outclk_2 => outclk_2, -- outclk2.clk
		locked   => locked    --  locked.export
	);	
	
	-- Active Reset 
	ActiveReset_inst : Active_reset
	port map (
		clk10m => outclk_0,
		reset_n_OUT => measure_start
	);

	-- Instantiate the ADC component
	ADC_instt: adc_ltc2308
	port map (
-- Serial SDI communication with LTC2308
	ADC_CONVST => ADC_CONVST,
	ADC_SCK => ADC_SCK,
	ADC_SDI => ADC_SDI,
	ADC_SDO => ADC_SDO,

-- Clock
	clk => outclk_1,

-- Serial details for SPI
	measure_ch => "000", -- Channel selection
	measure_dataread => data, -- Data !!!!
	measure_done => done, -- Conversion done
	measure_start => measure_start -- Conversion start
	
   );

	
	u1 : PWM_sig
		port map
		(
			clk=>Gclk,
			rst=>rst,
			DC=>Dc1,
			pwm=>M1
			
		);
			
	u2 : PWM_sig
		port map
		(
			clk=>Gclk,
			rst=>rst,
			DC=>DC2,
			pwm=>M2
			
		);
			
	u3 : PWM_sig
		port map
		(
			clk=>Gclk,
			rst=>rst,
			DC=>DC3,
			pwm=>M3
			
			
		);
		
	u4 : PWM_sig
		port map
		(
			clk=>Gclk,
			rst=>rst,
			DC=>DC4,
			pwm=>M4
			
		);

	process(gclk)
		begin
			if gclk'event and gclk = '1' then
				if done = '1' then
					Sdc<= data(11 downto 1);
				end if;
				DC1<=CONV_STD_LOGIC_VECTOR(DCeq(conv_integer(Sdc)), 22);
				DC2<=CONV_STD_LOGIC_VECTOR(DCeq(conv_integer(Sdc)), 22);
				DC3<=CONV_STD_LOGIC_VECTOR(DCeq(conv_integer(Sdc)), 22);
				DC4<=CONV_STD_LOGIC_VECTOR(DCeq(conv_integer(Sdc)), 22);
			end if;
	end process;
	
end architecture ARC_DroneTop;