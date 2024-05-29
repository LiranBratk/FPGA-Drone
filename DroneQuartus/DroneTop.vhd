library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DroneTop is
    Port (
        RXPin     : in  STD_LOGIC;   -- Serial receiver pin
        gclk      : in  STD_LOGIC;   -- Global clock
        rst       : in  STD_LOGIC;   -- Reset
        M1        : out STD_LOGIC;   -- Motor 1 output
        M2        : out STD_LOGIC;   -- Motor 2 output
        M3        : out STD_LOGIC;   -- Motor 3 output
        M4        : out STD_LOGIC    -- Motor 4 output
    );
end DroneTop;

architecture ARC_DroneTop of DroneTop is

    -- Signals for internal data handling
    signal s_Data          : std_logic_vector(7 downto 0);
    signal s_CounterRecieve: std_logic_vector(3 downto 0);
    signal s_Done          : std_logic;
    signal ResInt          : integer;
    signal DC1             : integer;
    signal DC2             : integer;
    signal DC3             : integer;
    signal DC4             : integer;
    signal CalcPrec        : integer;

    -- Component declaration for receiving logic
    component RecieveLogic is
        port (
            clk            : in  std_logic;
            rst            : in  std_logic;
            RXD            : in  std_logic; 
            REdata         : out std_logic_vector(7 downto 0);
            counterREcieve : out std_logic_vector(3 downto 0);
            done           : out std_logic
        );
    end component;

    -- Component declaration for PWM signal generation
    component PWM_sig is
        port (
            rst : in  std_logic;
            clk : in  std_logic;
            DC  : in  integer;
            pwm : out std_logic
        );
    end component;

begin

    -- Instantiation of the receiving logic component
    Inst : RecieveLogic
    port map (
        clk => gclk,
        rst => rst,
        RXD => RXPin,
        REdata => s_Data,
        counterREcieve => s_CounterRecieve,
        done => s_Done
    );

    -- Instantiation of the PWM signal generation components for each motor
    u1 : PWM_sig
    port map (
        clk => gclk,
        rst => rst,
        DC  => DC1,
        pwm => M1
    );
        
    u2 : PWM_sig
    port map (
        clk => gclk,
        rst => rst,
        DC  => DC2,
        pwm => M2
    );
        
    u3 : PWM_sig
    port map (
        clk => gclk,
        rst => rst,
        DC  => DC3,
        pwm => M3
    );
    
    u4 : PWM_sig
    port map (
        clk => gclk,
        rst => rst,
        DC  => DC4,
        pwm => M4
    );

	process(gclk, rst)
	begin
		 if rst = '0' then
			  -- If reset is active, set all duty cycles to 0
			  DC1 <= 0;
			  DC2 <= 0;
			  DC3 <= 0;
			  DC4 <= 0;
		 elsif gclk'event and gclk = '1' then
			  -- Convert the received 8-bit data to an integer
			  ResInt <= to_integer(unsigned(s_Data));
			  -- Calculate the precise duty cycle
			  CalcPrec <= (ResInt * 4095) / 255;
			  -- Assign the calculated duty cycle to all motors
			  DC1 <= CalcPrec;
			  DC2 <= CalcPrec;
			  DC3 <= CalcPrec;
			  DC4 <= CalcPrec;
		 end if;
	end process;
end architecture ARC_DroneTop;
