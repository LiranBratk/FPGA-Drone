library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity a is
    Port (
        Q         : out STD_LOGIC;  -- PWM outputs - 1bit
        TestA     : out STD_LOGIC;
        TestB     : out STD_LOGIC;
        TestC     : out STD_LOGIC;
        TestD     : out STD_LOGIC;
        TestE     : out STD_LOGIC;
        TestF     : out STD_LOGIC;
        TestG     : out STD_LOGIC;
        TestH     : out STD_LOGIC;
        TestI     : out STD_LOGIC;
        TestJ     : out STD_LOGIC;
        TestK     : out STD_LOGIC;
        
        outclk_2  : out std_logic;  -- outclk2.clk
        locked    : out std_logic;  -- locked.export
		  
        gclk      : in STD_LOGIC;   
        rst       : in STD_LOGIC;
        
        ADC_CONVST : out STD_LOGIC; -- Required ADC communication serial
        ADC_SCK    : out STD_LOGIC;
        ADC_SDI    : out STD_LOGIC;
        ADC_SDO    : in STD_LOGIC;
        
        M1        : OUT STD_LOGIC;  -- Motors output
        M2        : OUT STD_LOGIC;
        M3        : OUT STD_LOGIC;
        M4        : OUT STD_LOGIC
    );
end a;

architecture aa of a IS
    -- Any signals
    signal Sdc          : std_logic_vector(10 downto 0);
    signal data         : std_logic_vector(11 downto 0);
    signal done         : std_logic;
    signal outclk_0     : std_logic; 
    signal outclk_1     : std_logic;
    signal measure_ch   : std_logic_VECTOR(2 DOWNTO 0);
    signal measure_start: std_logic;
    signal DC1          : std_logic_vector(21 downto 0);
    signal DC2          : std_logic_vector(21 downto 0);
    signal DC3          : std_logic_vector(21 downto 0);
    signal DC4          : std_logic_vector(21 downto 0);
    signal CalcPrec     : integer;

    component Active_reset IS
        Port (
            clk10m      : IN STD_LOGIC;
            reset_n_OUT : out STD_LOGIC
        );
    end component;

    component PLL is
        Port (
            refclk   : in  std_logic ; 
            rst      : in  std_logic ; 
            outclk_0 : out std_logic;        
            outclk_1 : out std_logic;        
            outclk_2 : out std_logic;        
            locked   : out std_logic         
        );
    end component PLL;

    component adc_ltc2308 is
        Port (
            clk              : in STD_LOGIC;
            ADC_CONVST       : out STD_LOGIC; 
            ADC_SCK          : out STD_LOGIC; 
            ADC_SDI          : out STD_LOGIC; 
            ADC_SDO          : in STD_LOGIC;
            measure_ch       : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            measure_dataread : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
            measure_done     : OUT STD_LOGIC;
            measure_start    : IN STD_LOGIC
        );
    end component adc_ltc2308;

    component PWM_sig is
        port (
            rst : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            DC  : IN STD_LOGIC_VECTOR(21 downto 0);
            pwm : OUT STD_LOGIC
        );
    end component;

    function DCeq (signal m : integer)
        return integer is 
            variable sol : integer;
        begin 
            sol := 25*m+50000;
            return sol;
    end DCeq;
    
begin
    -- PPL
    pll_inst : PLL
    port map (
        refclk   => gclk, 
        rst      => '0',      
        outclk_0 => outclk_0, 
        outclk_1 => outclk_1, 
        outclk_2 => outclk_2, 
        locked   => locked    
    );    
    
    -- Active Reset 
    ActiveReset_inst : Active_reset
    port map (
        clk10m      => outclk_0,
        reset_n_OUT => measure_start
    );

    -- Instantiate the ADC component
    ADC_instt: adc_ltc2308
    port map (
        ADC_CONVST       => ADC_CONVST,
        ADC_SCK          => ADC_SCK,
        ADC_SDI          => ADC_SDI,
        ADC_SDO          => ADC_SDO,
        clk              => outclk_1,
        measure_ch       => "000",
        measure_dataread => data,
        measure_done     => done,
        measure_start    => measure_start
    );

    u1 : PWM_sig
    port map (
        clk => Gclk,
        rst => rst,
        DC  => Dc1,
        pwm => M1
    );
        
    u2 : PWM_sig
    port map (
        clk => Gclk,
        rst => rst,
        DC  => DC2,
        pwm => M2
    );
        
    u3 : PWM_sig
    port map (
        clk => Gclk,
        rst => rst,
        DC  => DC3,
        pwm => M3
    );
    
    u4 : PWM_sig
    port map (
        clk => Gclk,
        rst => rst,
        DC  => DC4,
        pwm => M4
    );

    process(gclk)
    begin
        if gclk'event and gclk = '1' then
            if done = '1' then
                Sdc <= data(11 downto 1);
                TestA <= Sdc(0);
                TestB <= Sdc(1);
                TestC <= Sdc(2);
                TestD <= Sdc(3);
                TestE <= Sdc(4);
                TestF <= Sdc(5);
                TestG <= Sdc(6);
                TestH <= Sdc(7);
                TestI <= Sdc(8);
                TestJ <= Sdc(9);
                TestK <= Sdc(10);
            end if;
            CalcPrec <= ((conv_integer(Sdc) * 4096) / 255);
            -- DC1<=CONV_STD_LOGIC_VECTOR(DCeq((conv_integer(Sdc) * 1023) / 100), 22);
            -- CONV_STD_LOGIC_VECTOR(DCeq(conv_integer(Sdc)), 22);
            DC1 <= CONV_STD_LOGIC_VECTOR((CalcPrec), 22);
            DC2 <= CONV_STD_LOGIC_VECTOR(DCeq(CalcPrec), 22);
            DC3 <= CONV_STD_LOGIC_VECTOR(DCeq(CalcPrec), 22);
            DC4 <= CONV_STD_LOGIC_VECTOR(DCeq(CalcPrec), 22);
        end if;
    end process;
end architecture aa;
