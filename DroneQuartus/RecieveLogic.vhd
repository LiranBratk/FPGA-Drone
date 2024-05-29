library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use ieee.numeric_std.all;

entity RecieveLogic is
   port (clk            : in  std_logic;
         rst            : in  std_logic;
         RXD            : in  std_logic; -- Serial Reciever Pin AE25
         REdata         : out std_logic_vector(7 downto 0);
         counterREcieve : out std_logic_vector(3 downto 0);
         done           : out std_logic
         );
end entity RecieveLogic;

architecture Behavioral of RecieveLogic is
   type   state_vector is (wait_for_start_bit, start_bit_skip, wait_for_middle_point, counts_for_8_bit);
   signal state                       : state_vector;
   signal bit_counter                 : std_logic_vector(3 downto 0);
   signal Sdata                       : std_logic_vector(7 downto 0);
   signal sample_cnt                  : std_logic_vector(7 downto 0);
   signal cnt                         : std_logic_vector(4 downto 0);
   signal q1, rxd_fall, sample_cnt_en : std_logic;
   signal shift_en                    : std_logic;
   signal eq_27                       : std_logic;
	signal done_s                      : std_logic;
begin
   rxd_fall <= (not rxd) and q1;
   eq_27    <= '1' when (cnt = 27) else '0';
   process(clk, rst)is
   begin
      if (rst = '1') then
         Sdata         <= (others => '0');
         state         <= wait_for_start_bit;
         bit_counter   <= (others => '0');
         cnt           <= (others => '0');
         sample_cnt    <= (others => '0');
         shift_en      <= '0';
         sample_cnt_en <= '0';
         q1            <= '1';
         done_s        <= '0';
			REdata        <= (others => '0');
      elsif clk'event and clk = '0' then
         shift_en <= '0';
			done_s   <= bit_counter(3) and shift_en;
			if (done_s='1') then
				REdata <= Sdata;
			end if;	
         if (shift_en = '1') then
            Sdata <= RXD & Sdata(7 downto 1);
         end if;
         if (eq_27 = '1') then
            q1  <= rxd;
            cnt <= (others => '0');
            if (sample_cnt_en = '1') then
               sample_cnt <= sample_cnt+1;
            else
               sample_cnt <= (others => '0');
            end if;
            case state is
					when wait_for_start_bit =>
						sample_cnt_en <= '0';
						if (rxd_fall = '1') then
							state <= start_bit_skip;
						end if;
						when start_bit_skip =>
                  sample_cnt_en <= '1';
                  if sample_cnt(3 downto 0) = x"f" then
                     state <= wait_for_middle_point;
                  end if;
               when wait_for_middle_point =>		
                  sample_cnt_en <= '1';			
                  if sample_cnt(1 downto 0) = "11" then
                     state         <= counts_for_8_bit;
                     sample_cnt_en <= '0';
                  end if;
               when counts_for_8_bit =>	
                  sample_cnt_en <= '1'; 
                  if (sample_cnt(3 downto 0) = x"0") then
                     if (bit_counter <= 7) then
                        shift_en    <= '1';
                        bit_counter <= bit_counter+'1';
                     else
                        bit_counter   <= (others => '0');
                        sample_cnt_en <= '0';
                        state         <= wait_for_start_bit;
                     end if;
                  end if;
               when others =>
                  state <= wait_for_start_bit;
            end case;
         else
            cnt <= cnt+1;
         end if;
      end if;
   end process;
   counterREcieve <= bit_counter;
   done<=done_s;
end architecture Behavioral;