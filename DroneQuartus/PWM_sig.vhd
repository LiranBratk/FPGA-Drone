LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

-- Entity Declaration
ENTITY PWM_sig IS
    PORT
    (
        rst : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        DC : IN INTEGER;      -- Duty cycle input
        pwm : OUT STD_LOGIC   -- PWM output
    );
END PWM_sig;

-- Architecture Body
ARCHITECTURE PWM_sig_architecture OF PWM_sig IS
    SIGNAL cou : INTEGER := 0;           -- Counter
    SIGNAL flag : STD_LOGIC;             -- Flag for state control
    SIGNAL FixedDC : INTEGER;            -- Fixed duty cycle
BEGIN
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN 
            -- Reset condition
            cou <= 0;
            flag <= '1';
            pwm <= '0';
        ELSIF clk'EVENT AND clk = '1' THEN
            -- Calculate fixed duty cycle (1..2ms range)
            FixedDC <= ((5 * (10 ** 4)) + ((5 * (10 ** 4) * DC) / 4095));

            IF flag = '1' THEN 
                -- Off-period state
                IF cou < 1000000 THEN
                    cou <= cou + 1;
                    pwm <= '0';
                ELSE
                    flag <= '0'; 
                    cou <= 0;
                END IF; 
            ELSE 
                -- On-period state
                IF cou < 1000000 THEN
                    cou <= cou + 1;
                    IF cou <= FixedDC THEN
                        pwm <= '1';
                    ELSE
                        pwm <= '0';
                    END IF;
                ELSE 
                    cou <= 0;
                    flag <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;
END PWM_sig_architecture;
