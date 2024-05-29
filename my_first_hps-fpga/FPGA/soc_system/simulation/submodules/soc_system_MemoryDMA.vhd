--Legal Notice: (C)2024 Altera Corporation. All rights reserved.  Your
--use of Altera Corporation's design tools, logic functions and other
--software and tools, and its AMPP partner logic functions, and any
--output files any of the foregoing (including device programming or
--simulation files), and any associated documentation or information are
--expressly subject to the terms and conditions of the Altera Program
--License Subscription Agreement or other applicable license agreement,
--including, without limitation, that your use is for the sole purpose
--of programming logic devices manufactured by Altera and sold by Altera
--or its authorized distributors.  Please refer to the applicable
--agreement for further details.


-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity control_status_slave_which_resides_within_soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal atlantic_error : IN STD_LOGIC;
                 signal chain_run : IN STD_LOGIC;
                 signal clk : IN STD_LOGIC;
                 signal command_fifo_empty : IN STD_LOGIC;
                 signal csr_address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal csr_chipselect : IN STD_LOGIC;
                 signal csr_read : IN STD_LOGIC;
                 signal csr_write : IN STD_LOGIC;
                 signal csr_writedata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal desc_address_fifo_empty : IN STD_LOGIC;
                 signal descriptor_read_address : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_read : IN STD_LOGIC;
                 signal descriptor_write_busy : IN STD_LOGIC;
                 signal descriptor_write_write : IN STD_LOGIC;
                 signal owned_by_hw : IN STD_LOGIC;
                 signal read_go : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal status_token_fifo_empty : IN STD_LOGIC;
                 signal status_token_fifo_rdreq : IN STD_LOGIC;
                 signal write_go : IN STD_LOGIC;

              -- outputs:
                 signal csr_irq : OUT STD_LOGIC;
                 signal csr_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_pointer_lower_reg_out : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_pointer_upper_reg_out : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal park : OUT STD_LOGIC;
                 signal pollen_clear_run : OUT STD_LOGIC;
                 signal run : OUT STD_LOGIC;
                 signal sw_reset : OUT STD_LOGIC
              );
end entity control_status_slave_which_resides_within_soc_system_MemoryDMA;


architecture europa of control_status_slave_which_resides_within_soc_system_MemoryDMA is
                signal busy :  STD_LOGIC;
                signal can_have_new_chain_complete :  STD_LOGIC;
                signal chain_completed :  STD_LOGIC;
                signal chain_completed_int :  STD_LOGIC;
                signal chain_completed_int_rise :  STD_LOGIC;
                signal clear_chain_completed :  STD_LOGIC;
                signal clear_descriptor_completed :  STD_LOGIC;
                signal clear_error :  STD_LOGIC;
                signal clear_interrupt :  STD_LOGIC;
                signal clear_run :  STD_LOGIC;
                signal control_reg :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal control_reg_en :  STD_LOGIC;
                signal csr_control :  STD_LOGIC;
                signal csr_status :  STD_LOGIC;
                signal delayed_chain_completed_int :  STD_LOGIC;
                signal delayed_csr_write :  STD_LOGIC;
                signal delayed_descriptor_counter :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal delayed_descriptor_write_write :  STD_LOGIC;
                signal delayed_eop_encountered :  STD_LOGIC;
                signal delayed_max_desc_processed :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal delayed_run :  STD_LOGIC;
                signal descriptor_completed :  STD_LOGIC;
                signal descriptor_counter :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal descriptor_pointer_data :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal descriptor_pointer_lower_reg :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal descriptor_pointer_lower_reg_en :  STD_LOGIC;
                signal descriptor_pointer_upper_reg :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal descriptor_pointer_upper_reg_en :  STD_LOGIC;
                signal descriptor_read_read_r :  STD_LOGIC;
                signal descriptor_read_read_rising :  STD_LOGIC;
                signal descriptor_write_write_fall :  STD_LOGIC;
                signal do_restart :  STD_LOGIC;
                signal do_restart_compare :  STD_LOGIC;
                signal eop_encountered :  STD_LOGIC;
                signal eop_encountered_rise :  STD_LOGIC;
                signal error :  STD_LOGIC;
                signal hw_version :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal ie_chain_completed :  STD_LOGIC;
                signal ie_descriptor_completed :  STD_LOGIC;
                signal ie_eop_encountered :  STD_LOGIC;
                signal ie_error :  STD_LOGIC;
                signal ie_global :  STD_LOGIC;
                signal ie_max_desc_processed :  STD_LOGIC;
                signal internal_csr_irq2 :  STD_LOGIC;
                signal internal_run :  STD_LOGIC;
                signal max_desc_processed :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal poll_en :  STD_LOGIC;
                signal status_reg :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal stop_dma_error :  STD_LOGIC;
                signal timeout_counter :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal timeout_reg :  STD_LOGIC_VECTOR (10 DOWNTO 0);
                signal version_reg :  STD_LOGIC;

begin

  --csr, which is an e_avalon_slave
  --Control Status Register (Readdata)
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      csr_readdata <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(csr_read) = '1' then 
        case csr_address is -- synthesis parallel_case
            when std_logic_vector'("0000") => 
                csr_readdata <= status_reg;
            -- when std_logic_vector'("0000") 
        
            when std_logic_vector'("0001") => 
                csr_readdata <= std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(version_reg));
            -- when std_logic_vector'("0001") 
        
            when std_logic_vector'("0100") => 
                csr_readdata <= control_reg;
            -- when std_logic_vector'("0100") 
        
            when std_logic_vector'("1000") => 
                csr_readdata <= descriptor_pointer_lower_reg;
            -- when std_logic_vector'("1000") 
        
            when std_logic_vector'("1100") => 
                csr_readdata <= descriptor_pointer_upper_reg;
            -- when std_logic_vector'("1100") 
        
            when others => 
                csr_readdata <= std_logic_vector'("00000000000000000000000000000000");
            -- when others 
        
        end case; -- csr_address
      end if;
    end if;

  end process;

  --register outs
  descriptor_pointer_upper_reg_out <= descriptor_pointer_upper_reg;
  descriptor_pointer_lower_reg_out <= descriptor_pointer_lower_reg;
  --control register bits
  ie_error <= control_reg(0);
  ie_eop_encountered <= control_reg(1);
  ie_descriptor_completed <= control_reg(2);
  ie_chain_completed <= control_reg(3);
  ie_global <= control_reg(4);
  internal_run <= control_reg(5) AND ((NOT(((stop_dma_error AND error))) AND (((NOT(chain_completed_int)) OR (((do_restart AND poll_en) AND chain_completed_int))))));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_run <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_run <= internal_run;
    end if;

  end process;

  stop_dma_error <= control_reg(6);
  ie_max_desc_processed <= control_reg(7);
  max_desc_processed <= control_reg(15 DOWNTO 8);
  sw_reset <= control_reg(16);
  park <= control_reg(17);
  poll_en <= control_reg(18);
  timeout_reg <= control_reg(30 DOWNTO 20);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      timeout_counter <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(((((control_reg(5) AND NOT(busy)) AND poll_en)) OR do_restart)) = '1' then 
        timeout_counter <= A_EXT (A_WE_StdLogicVector((std_logic'(do_restart) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("000000000000000") & ((((std_logic_vector'("0") & (timeout_counter)) + (std_logic_vector'("0000000000000000") & (A_TOSTDLOGICVECTOR(std_logic'('1'))))))))), 16);
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      do_restart_compare <= std_logic'('0');
    elsif clk'event and clk = '1' then
      do_restart_compare <= to_std_logic((timeout_counter = (timeout_reg & std_logic_vector'("11111"))));
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      do_restart <= std_logic'('0');
    elsif clk'event and clk = '1' then
      do_restart <= poll_en AND do_restart_compare;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      clear_interrupt <= std_logic'('0');
    elsif clk'event and clk = '1' then
      clear_interrupt <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(control_reg_en) = '1'), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(csr_writedata(31)))), std_logic_vector'("00000000000000000000000000000000")));
    end if;

  end process;

  --control register
  control_reg_en <= (to_std_logic(((csr_address = std_logic_vector'("0100")))) AND csr_write) AND csr_chipselect;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      control_reg <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(control_reg_en) = '1' then 
        control_reg <= Std_Logic_Vector'(A_ToStdLogicVector(std_logic'('0')) & csr_writedata(30 DOWNTO 0));
      end if;
    end if;

  end process;

  --descriptor_pointer_upper_reg
  descriptor_pointer_upper_reg_en <= (to_std_logic(((csr_address = std_logic_vector'("1100")))) AND csr_write) AND csr_chipselect;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_pointer_upper_reg <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(descriptor_pointer_upper_reg_en) = '1' then 
        descriptor_pointer_upper_reg <= csr_writedata;
      end if;
    end if;

  end process;

  --section to update the descriptor pointer
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_read_read_r <= std_logic'('0');
    elsif clk'event and clk = '1' then
      descriptor_read_read_r <= descriptor_read_read;
    end if;

  end process;

  descriptor_read_read_rising <= descriptor_read_read AND NOT(descriptor_read_read_r);
  descriptor_pointer_data <= A_WE_StdLogicVector((std_logic'(descriptor_read_read_rising) = '1'), descriptor_read_address, csr_writedata);
  --descriptor_pointer_lower_reg
  descriptor_pointer_lower_reg_en <= (((to_std_logic(((csr_address = std_logic_vector'("1000")))) AND csr_write) AND csr_chipselect)) OR ((poll_en AND descriptor_read_read_rising));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_pointer_lower_reg <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(descriptor_pointer_lower_reg_en) = '1' then 
        descriptor_pointer_lower_reg <= descriptor_pointer_data;
      end if;
    end if;

  end process;

  --Hardware Version Register
  hw_version <= std_logic_vector'("0001");
  version_reg <= Vector_To_Std_Logic(Std_Logic_Vector'(std_logic_vector'("000000000000000000000000") & hw_version));
  --status register
  status_reg <= Std_Logic_Vector'(std_logic_vector'("000000000000000000000000000") & A_ToStdLogicVector(busy) & A_ToStdLogicVector(chain_completed) & A_ToStdLogicVector(descriptor_completed) & A_ToStdLogicVector(eop_encountered) & A_ToStdLogicVector(error));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      busy <= std_logic'('0');
    elsif clk'event and clk = '1' then
      busy <= (((((((NOT command_fifo_empty OR NOT status_token_fifo_empty) OR NOT desc_address_fifo_empty) OR chain_run) OR descriptor_write_busy) OR delayed_csr_write) OR owned_by_hw) OR write_go) OR read_go;
    end if;

  end process;

  --Chain Completed Status Register
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      chain_completed <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((((((internal_run AND NOT owned_by_hw) AND NOT busy)) OR clear_chain_completed) OR do_restart)) = '1' then 
        chain_completed <= A_WE_StdLogic((std_logic'(((clear_chain_completed OR do_restart))) = '1'), std_logic'('0'), NOT delayed_csr_write);
      end if;
    end if;

  end process;

  --chain_completed_int is the internal chain completed state for SGDMA.
  --Will not be affected with clearing of chain_completed Status Register,to prevent SGDMA being restarted when the status bit is cleared
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      chain_completed_int <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((((((internal_run AND NOT owned_by_hw) AND NOT busy)) OR clear_run) OR do_restart)) = '1' then 
        chain_completed_int <= A_WE_StdLogic((std_logic'(((clear_run OR do_restart))) = '1'), std_logic'('0'), NOT delayed_csr_write);
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_csr_write <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_csr_write <= csr_write;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_completed <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((descriptor_write_write_fall OR clear_descriptor_completed)) = '1' then 
        descriptor_completed <= NOT clear_descriptor_completed;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      error <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((atlantic_error OR clear_error)) = '1' then 
        error <= NOT clear_error;
      end if;
    end if;

  end process;

  csr_status <= (csr_write AND csr_chipselect) AND to_std_logic(((csr_address = std_logic_vector'("0000"))));
  clear_chain_completed <= csr_writedata(3) AND csr_status;
  clear_descriptor_completed <= csr_writedata(2) AND csr_status;
  clear_error <= csr_writedata(0) AND csr_status;
  csr_control <= (csr_write AND csr_chipselect) AND to_std_logic(((csr_address = std_logic_vector'("0100"))));
  clear_run <= NOT(csr_writedata(5)) AND csr_control;
  pollen_clear_run <= poll_en AND clear_run;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_eop_encountered <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_eop_encountered <= eop_encountered;
    end if;

  end process;

  eop_encountered_rise <= NOT delayed_eop_encountered AND eop_encountered;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_descriptor_write_write <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_descriptor_write_write <= descriptor_write_write;
    end if;

  end process;

  descriptor_write_write_fall <= delayed_descriptor_write_write AND NOT descriptor_write_write;
  eop_encountered <= std_logic'('0');
  --chain_completed rising edge detector
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_chain_completed_int <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_chain_completed_int <= chain_completed_int;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      can_have_new_chain_complete <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((descriptor_write_write OR ((NOT delayed_chain_completed_int AND chain_completed_int)))) = '1' then 
        can_have_new_chain_complete <= descriptor_write_write;
      end if;
    end if;

  end process;

  chain_completed_int_rise <= (NOT delayed_chain_completed_int AND chain_completed_int) AND can_have_new_chain_complete;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_counter <= std_logic_vector'("00000000");
    elsif clk'event and clk = '1' then
      if std_logic'(status_token_fifo_rdreq) = '1' then 
        descriptor_counter <= A_EXT (((std_logic_vector'("0") & (descriptor_counter)) + (std_logic_vector'("00000000") & (A_TOSTDLOGICVECTOR(std_logic'('1'))))), 8);
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_descriptor_counter <= std_logic_vector'("00000000");
    elsif clk'event and clk = '1' then
      delayed_descriptor_counter <= descriptor_counter;
    end if;

  end process;

  delayed_max_desc_processed <= A_EXT (((std_logic_vector'("0000000000000000000000000") & (max_desc_processed)) - std_logic_vector'("000000000000000000000000000000001")), 8);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_csr_irq2 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      internal_csr_irq2 <= A_WE_StdLogic((std_logic'(internal_csr_irq2) = '1'), NOT clear_interrupt, (((delayed_run AND ie_global) AND (((((((ie_error AND error)) OR ((ie_eop_encountered AND eop_encountered_rise))) OR ((ie_descriptor_completed AND descriptor_write_write_fall))) OR ((ie_chain_completed AND chain_completed_int_rise))) OR (((ie_max_desc_processed AND to_std_logic(((descriptor_counter = max_desc_processed)))) AND to_std_logic(((delayed_descriptor_counter = delayed_max_desc_processed))))))))));
    end if;

  end process;

  --vhdl renameroo for output signals
  csr_irq <= internal_csr_irq2;
  --vhdl renameroo for output signals
  run <= internal_run;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.all;

entity descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal controlbitsfifo_data : IN STD_LOGIC_VECTOR (6 DOWNTO 0);
                 signal controlbitsfifo_rdreq : IN STD_LOGIC;
                 signal controlbitsfifo_wrreq : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;

              -- outputs:
                 signal controlbitsfifo_empty : OUT STD_LOGIC;
                 signal controlbitsfifo_full : OUT STD_LOGIC;
                 signal controlbitsfifo_q : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
              );
end entity descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo;


architecture europa of descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo is
  component scfifo is
GENERIC (
      add_ram_output_register : STRING;
        intended_device_family : STRING;
        lpm_numwords : NATURAL;
        lpm_showahead : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL;
        lpm_widthu : NATURAL;
        overflow_checking : STRING;
        underflow_checking : STRING;
        use_eab : STRING
      );
    PORT (
    signal q : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        signal empty : OUT STD_LOGIC;
        signal full : OUT STD_LOGIC;
        signal aclr : IN STD_LOGIC;
        signal rdreq : IN STD_LOGIC;
        signal clock : IN STD_LOGIC;
        signal wrreq : IN STD_LOGIC;
        signal data : IN STD_LOGIC_VECTOR (6 DOWNTO 0)
      );
  end component scfifo;
                signal internal_controlbitsfifo_empty :  STD_LOGIC;
                signal internal_controlbitsfifo_full :  STD_LOGIC;
                signal internal_controlbitsfifo_q1 :  STD_LOGIC_VECTOR (6 DOWNTO 0);

begin

  descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo_controlbitsfifo : scfifo
    generic map(
      add_ram_output_register => "ON",
      intended_device_family => "CYCLONEV",
      lpm_numwords => 2,
      lpm_showahead => "OFF",
      lpm_type => "scfifo",
      lpm_width => 7,
      lpm_widthu => 1,
      overflow_checking => "ON",
      underflow_checking => "ON",
      use_eab => "OFF"
    )
    port map(
            aclr => reset,
            clock => clk,
            data => controlbitsfifo_data,
            empty => internal_controlbitsfifo_empty,
            full => internal_controlbitsfifo_full,
            q => internal_controlbitsfifo_q1,
            rdreq => controlbitsfifo_rdreq,
            wrreq => controlbitsfifo_wrreq
    );

  --vhdl renameroo for output signals
  controlbitsfifo_empty <= internal_controlbitsfifo_empty;
  --vhdl renameroo for output signals
  controlbitsfifo_full <= internal_controlbitsfifo_full;
  --vhdl renameroo for output signals
  controlbitsfifo_q <= internal_controlbitsfifo_q1;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity descriptor_read_which_resides_within_soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal command_fifo_full : IN STD_LOGIC;
                 signal controlbitsfifo_rdreq : IN STD_LOGIC;
                 signal desc_address_fifo_full : IN STD_LOGIC;
                 signal descriptor_pointer_lower_reg_out : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_pointer_upper_reg_out : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_readdatavalid : IN STD_LOGIC;
                 signal descriptor_read_waitrequest : IN STD_LOGIC;
                 signal pollen_clear_run : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal run : IN STD_LOGIC;

              -- outputs:
                 signal atlantic_channel : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal chain_run : OUT STD_LOGIC;
                 signal command_fifo_data : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
                 signal command_fifo_wrreq : OUT STD_LOGIC;
                 signal control : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                 signal controlbitsfifo_q : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
                 signal desc_address_fifo_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal desc_address_fifo_wrreq : OUT STD_LOGIC;
                 signal descriptor_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_read : OUT STD_LOGIC;
                 signal generate_eop : OUT STD_LOGIC;
                 signal next_desc : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal owned_by_hw : OUT STD_LOGIC;
                 signal read_fixed_address : OUT STD_LOGIC;
                 signal write_fixed_address : OUT STD_LOGIC
              );
end entity descriptor_read_which_resides_within_soc_system_MemoryDMA;


architecture europa of descriptor_read_which_resides_within_soc_system_MemoryDMA is
component descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal controlbitsfifo_data : IN STD_LOGIC_VECTOR (6 DOWNTO 0);
                    signal controlbitsfifo_rdreq : IN STD_LOGIC;
                    signal controlbitsfifo_wrreq : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;

                 -- outputs:
                    signal controlbitsfifo_empty : OUT STD_LOGIC;
                    signal controlbitsfifo_full : OUT STD_LOGIC;
                    signal controlbitsfifo_q : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)
                 );
end component descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo;

                signal bytes_to_transfer :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal command_fifo_wrreq_in :  STD_LOGIC;
                signal controlbitsfifo_data :  STD_LOGIC_VECTOR (6 DOWNTO 0);
                signal controlbitsfifo_empty :  STD_LOGIC;
                signal controlbitsfifo_full :  STD_LOGIC;
                signal controlbitsfifo_wrreq :  STD_LOGIC;
                signal delayed_desc_reg_en :  STD_LOGIC;
                signal delayed_run :  STD_LOGIC;
                signal desc_assembler :  STD_LOGIC_VECTOR (255 DOWNTO 0);
                signal desc_read_start :  STD_LOGIC;
                signal desc_reg :  STD_LOGIC_VECTOR (255 DOWNTO 0);
                signal desc_reg_en :  STD_LOGIC;
                signal descriptor_read_completed :  STD_LOGIC;
                signal descriptor_read_completed_in :  STD_LOGIC;
                signal fifos_not_full :  STD_LOGIC;
                signal got_one_descriptor :  STD_LOGIC;
                signal init_descriptor :  STD_LOGIC_VECTOR (255 DOWNTO 0);
                signal internal_chain_run :  STD_LOGIC;
                signal internal_command_fifo_wrreq1 :  STD_LOGIC;
                signal internal_control :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal internal_controlbitsfifo_q :  STD_LOGIC_VECTOR (6 DOWNTO 0);
                signal internal_descriptor_read_address2 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_descriptor_read_read2 :  STD_LOGIC;
                signal internal_next_desc :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_owned_by_hw :  STD_LOGIC;
                signal pollen_clear_run_desc :  STD_LOGIC_VECTOR (255 DOWNTO 0);
                signal posted_desc_counter :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal posted_read_queued :  STD_LOGIC;
                signal read_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal read_burst :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal received_desc_counter :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal run_rising_edge :  STD_LOGIC;
                signal run_rising_edge_in :  STD_LOGIC;
                signal started :  STD_LOGIC;
                signal started_in :  STD_LOGIC;
                signal write_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal write_burst :  STD_LOGIC_VECTOR (7 DOWNTO 0);

begin

  --descriptor_read, which is an e_avalon_master
  --Control assignments
  command_fifo_wrreq_in <= ((internal_chain_run AND fifos_not_full) AND delayed_desc_reg_en) AND internal_owned_by_hw;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_command_fifo_wrreq1 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      internal_command_fifo_wrreq1 <= command_fifo_wrreq_in;
    end if;

  end process;

  desc_address_fifo_wrreq <= internal_command_fifo_wrreq1;
  fifos_not_full <= NOT command_fifo_full AND NOT desc_address_fifo_full;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_desc_reg_en <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_desc_reg_en <= desc_reg_en;
    end if;

  end process;

  read_address <= desc_reg(31 DOWNTO 0);
  write_address <= desc_reg(95 DOWNTO 64);
  internal_next_desc <= desc_reg(159 DOWNTO 128);
  bytes_to_transfer <= desc_reg(207 DOWNTO 192);
  read_burst <= desc_reg(215 DOWNTO 208);
  write_burst <= desc_reg(223 DOWNTO 216);
  internal_control <= desc_reg(255 DOWNTO 248);
  command_fifo_data <= internal_control & write_burst & read_burst & bytes_to_transfer & write_address & read_address;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      desc_address_fifo_data <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(desc_reg_en) = '1' then 
        desc_address_fifo_data <= internal_next_desc;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      received_desc_counter <= std_logic_vector'("0000");
    elsif clk'event and clk = '1' then
      received_desc_counter <= A_EXT (A_WE_StdLogicVector((((std_logic_vector'("0000000000000000000000000000") & (received_desc_counter)) = std_logic_vector'("00000000000000000000000000001000"))), std_logic_vector'("000000000000000000000000000000000"), (A_WE_StdLogicVector((std_logic'(descriptor_read_readdatavalid) = '1'), (((std_logic_vector'("00000000000000000000000000000") & (received_desc_counter)) + std_logic_vector'("000000000000000000000000000000001"))), (std_logic_vector'("00000000000000000000000000000") & (received_desc_counter))))), 4);
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      posted_desc_counter <= std_logic_vector'("0000");
    elsif clk'event and clk = '1' then
      posted_desc_counter <= A_EXT (A_WE_StdLogicVector((std_logic'((((desc_read_start AND internal_owned_by_hw) AND to_std_logic((((std_logic_vector'("0000000000000000000000000000") & (posted_desc_counter)) /= std_logic_vector'("00000000000000000000000000001000"))))))) = '1'), std_logic_vector'("000000000000000000000000000001000"), (A_WE_StdLogicVector((std_logic'((((or_reduce(posted_desc_counter) AND NOT descriptor_read_waitrequest) AND fifos_not_full))) = '1'), (((std_logic_vector'("00000000000000000000000000000") & (posted_desc_counter)) - std_logic_vector'("000000000000000000000000000000001"))), (std_logic_vector'("00000000000000000000000000000") & (posted_desc_counter))))), 4);
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      desc_read_start <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_read_waitrequest) = '1' then 
        desc_read_start <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(desc_read_start) = '1'), std_logic_vector'("00000000000000000000000000000000"), (A_WE_StdLogicVector((std_logic'((NOT ((((desc_reg_en OR delayed_desc_reg_en) OR internal_command_fifo_wrreq1) OR or_reduce(received_desc_counter))))) = '1'), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(((((internal_chain_run AND fifos_not_full) AND nor_reduce(posted_desc_counter)) AND NOT posted_read_queued))))), std_logic_vector'("00000000000000000000000000000000")))));
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_chain_run <= std_logic'('0');
    elsif clk'event and clk = '1' then
      internal_chain_run <= ((run AND (((internal_owned_by_hw OR ((delayed_desc_reg_en OR desc_reg_en))) OR or_reduce(posted_desc_counter)) OR or_reduce(received_desc_counter)))) OR run_rising_edge_in;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_descriptor_read_read2 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_read_waitrequest) = '1' then 
        internal_descriptor_read_read2 <= or_reduce(posted_desc_counter) AND fifos_not_full;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_descriptor_read_address2 <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_read_waitrequest) = '1' then 
        internal_descriptor_read_address2 <= A_EXT (A_WE_StdLogicVector((std_logic'((internal_descriptor_read_read2)) = '1'), (((std_logic_vector'("0") & (internal_descriptor_read_address2)) + std_logic_vector'("000000000000000000000000000000100"))), (std_logic_vector'("0") & (internal_next_desc))), 32);
      end if;
    end if;

  end process;

  descriptor_read_completed_in <= A_WE_StdLogic((std_logic'(started) = '1'), (((run AND NOT internal_owned_by_hw) AND nor_reduce(posted_desc_counter))), descriptor_read_completed);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      posted_read_queued <= std_logic'('0');
    elsif clk'event and clk = '1' then
      posted_read_queued <= A_WE_StdLogic((std_logic'(posted_read_queued) = '1'), NOT (got_one_descriptor), (internal_descriptor_read_read2));
    end if;

  end process;

  --control bits
  generate_eop <= internal_control(0);
  read_fixed_address <= internal_control(1);
  write_fixed_address <= internal_control(2);
  atlantic_channel <= internal_control(6 DOWNTO 3);
  internal_owned_by_hw <= internal_control(7);
  got_one_descriptor <= to_std_logic(((std_logic_vector'("0000000000000000000000000000") & (received_desc_counter)) = std_logic_vector'("00000000000000000000000000001000")));
  --read descriptor
  desc_reg_en <= internal_chain_run AND got_one_descriptor;
  init_descriptor <= Std_Logic_Vector'(A_ToStdLogicVector(std_logic'('1')) & std_logic_vector'("0000000000000000000000000000000") & std_logic_vector'("00000000000000000000000000000000") & descriptor_pointer_upper_reg_out & descriptor_pointer_lower_reg_out & std_logic_vector'("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"));
  --Clear owned_by_hw bit when run is clear in Descriptor Polling Mode
  pollen_clear_run_desc <= Std_Logic_Vector'(A_ToStdLogicVector(std_logic'('0')) & std_logic_vector'("0000000000000000000000000000000") & std_logic_vector'("00000000000000000000000000000000") & descriptor_pointer_upper_reg_out & descriptor_pointer_lower_reg_out & std_logic_vector'("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      desc_reg <= std_logic_vector'("0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(((desc_reg_en OR run_rising_edge_in) OR pollen_clear_run)) = '1' then 
        desc_reg <= A_WE_StdLogicVector((std_logic'(run_rising_edge_in) = '1'), init_descriptor, A_WE_StdLogicVector((std_logic'(pollen_clear_run) = '1'), pollen_clear_run_desc, desc_assembler));
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      desc_assembler <= std_logic_vector'("0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(descriptor_read_readdatavalid) = '1' then 
        desc_assembler <= A_SRL(desc_assembler,std_logic_vector'("00000000000000000000000000100000")) OR (descriptor_read_readdata & std_logic_vector'("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"));
      end if;
    end if;

  end process;

  --descriptor_read_completed register
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_read_completed <= std_logic'('0');
    elsif clk'event and clk = '1' then
      descriptor_read_completed <= descriptor_read_completed_in;
    end if;

  end process;

  --started register
  started_in <= A_WE_StdLogic((std_logic'(((run_rising_edge OR run_rising_edge_in))) = '1'), std_logic'('1'), (A_WE_StdLogic((std_logic'(descriptor_read_completed) = '1'), std_logic'('0'), started)));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      started <= std_logic'('0');
    elsif clk'event and clk = '1' then
      started <= started_in;
    end if;

  end process;

  --delayed_run signal for the rising edge detector
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_run <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_run <= run;
    end if;

  end process;

  --Run rising edge detector
  run_rising_edge_in <= run AND NOT delayed_run;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      run_rising_edge <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((run_rising_edge_in OR desc_reg_en)) = '1' then 
        run_rising_edge <= run_rising_edge_in;
      end if;
    end if;

  end process;

  --the_descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo, which is an e_instance
  the_descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo : descriptor_read_which_resides_within_soc_system_MemoryDMA_control_bits_fifo
    port map(
      controlbitsfifo_empty => controlbitsfifo_empty,
      controlbitsfifo_full => controlbitsfifo_full,
      controlbitsfifo_q => internal_controlbitsfifo_q,
      clk => clk,
      controlbitsfifo_data => controlbitsfifo_data,
      controlbitsfifo_rdreq => controlbitsfifo_rdreq,
      controlbitsfifo_wrreq => controlbitsfifo_wrreq,
      reset => reset
    );


  controlbitsfifo_data <= internal_control(6 DOWNTO 0);
  controlbitsfifo_wrreq <= internal_command_fifo_wrreq1;
  --vhdl renameroo for output signals
  chain_run <= internal_chain_run;
  --vhdl renameroo for output signals
  command_fifo_wrreq <= internal_command_fifo_wrreq1;
  --vhdl renameroo for output signals
  control <= internal_control;
  --vhdl renameroo for output signals
  controlbitsfifo_q <= internal_controlbitsfifo_q;
  --vhdl renameroo for output signals
  descriptor_read_address <= internal_descriptor_read_address2;
  --vhdl renameroo for output signals
  descriptor_read_read <= internal_descriptor_read_read2;
  --vhdl renameroo for output signals
  next_desc <= internal_next_desc;
  --vhdl renameroo for output signals
  owned_by_hw <= internal_owned_by_hw;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity descriptor_write_which_resides_within_soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal controlbitsfifo_q : IN STD_LOGIC_VECTOR (6 DOWNTO 0);
                 signal desc_address_fifo_empty : IN STD_LOGIC;
                 signal desc_address_fifo_q : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_write_waitrequest : IN STD_LOGIC;
                 signal park : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal status_token_fifo_data : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                 signal status_token_fifo_empty : IN STD_LOGIC;
                 signal status_token_fifo_q : IN STD_LOGIC_VECTOR (23 DOWNTO 0);

              -- outputs:
                 signal atlantic_error : OUT STD_LOGIC;
                 signal controlbitsfifo_rdreq : OUT STD_LOGIC;
                 signal desc_address_fifo_rdreq : OUT STD_LOGIC;
                 signal descriptor_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_write_busy : OUT STD_LOGIC;
                 signal descriptor_write_write : OUT STD_LOGIC;
                 signal descriptor_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal status_token_fifo_rdreq : OUT STD_LOGIC;
                 signal t_eop : OUT STD_LOGIC
              );
end entity descriptor_write_which_resides_within_soc_system_MemoryDMA;


architecture europa of descriptor_write_which_resides_within_soc_system_MemoryDMA is
                signal can_write :  STD_LOGIC;
                signal descriptor_write_write0 :  STD_LOGIC;
                signal fifos_not_empty :  STD_LOGIC;
                signal internal_descriptor_write_write2 :  STD_LOGIC;
                signal internal_status_token_fifo_rdreq1 :  STD_LOGIC;
                signal status_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal status_token_fifo_rdreq_in :  STD_LOGIC;

begin

  --descriptor_write, which is an e_avalon_master
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_write_writedata <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_write_waitrequest) = '1' then 
        descriptor_write_writedata <= Std_Logic_Vector'(A_ToStdLogicVector(park) & controlbitsfifo_q & status_token_fifo_q);
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_write_address <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_write_waitrequest) = '1' then 
        descriptor_write_address <= A_EXT (((std_logic_vector'("0") & (desc_address_fifo_q)) + std_logic_vector'("000000000000000000000000000011100")), 32);
      end if;
    end if;

  end process;

  fifos_not_empty <= NOT status_token_fifo_empty AND NOT desc_address_fifo_empty;
  can_write <= NOT descriptor_write_waitrequest AND fifos_not_empty;
  --write register
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      descriptor_write_write0 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_write_waitrequest) = '1' then 
        descriptor_write_write0 <= internal_status_token_fifo_rdreq1;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_descriptor_write_write2 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT descriptor_write_waitrequest) = '1' then 
        internal_descriptor_write_write2 <= descriptor_write_write0;
      end if;
    end if;

  end process;

  --status_token_fifo_rdreq register
  status_token_fifo_rdreq_in <= A_WE_StdLogic((std_logic'(internal_status_token_fifo_rdreq1) = '1'), std_logic'('0'), can_write);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_status_token_fifo_rdreq1 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      internal_status_token_fifo_rdreq1 <= status_token_fifo_rdreq_in;
    end if;

  end process;

  desc_address_fifo_rdreq <= internal_status_token_fifo_rdreq1;
  descriptor_write_busy <= descriptor_write_write0 OR internal_descriptor_write_write2;
  status_reg <= status_token_fifo_data(23 DOWNTO 16);
  t_eop <= status_reg(7);
  atlantic_error <= (((((status_reg(6) OR status_reg(5)) OR status_reg(4)) OR status_reg(3)) OR status_reg(2)) OR status_reg(1)) OR status_reg(0);
  controlbitsfifo_rdreq <= internal_status_token_fifo_rdreq1;
  --vhdl renameroo for output signals
  descriptor_write_write <= internal_descriptor_write_write2;
  --vhdl renameroo for output signals
  status_token_fifo_rdreq <= internal_status_token_fifo_rdreq1;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity soc_system_MemoryDMA_chain is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal command_fifo_empty : IN STD_LOGIC;
                 signal command_fifo_full : IN STD_LOGIC;
                 signal csr_address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal csr_chipselect : IN STD_LOGIC;
                 signal csr_read : IN STD_LOGIC;
                 signal csr_write : IN STD_LOGIC;
                 signal csr_writedata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal desc_address_fifo_empty : IN STD_LOGIC;
                 signal desc_address_fifo_full : IN STD_LOGIC;
                 signal desc_address_fifo_q : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_readdatavalid : IN STD_LOGIC;
                 signal descriptor_read_waitrequest : IN STD_LOGIC;
                 signal descriptor_write_waitrequest : IN STD_LOGIC;
                 signal read_go : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal status_token_fifo_data : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                 signal status_token_fifo_empty : IN STD_LOGIC;
                 signal status_token_fifo_q : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                 signal write_go : IN STD_LOGIC;

              -- outputs:
                 signal command_fifo_data : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
                 signal command_fifo_wrreq : OUT STD_LOGIC;
                 signal csr_irq : OUT STD_LOGIC;
                 signal csr_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal desc_address_fifo_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal desc_address_fifo_rdreq : OUT STD_LOGIC;
                 signal desc_address_fifo_wrreq : OUT STD_LOGIC;
                 signal descriptor_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_read : OUT STD_LOGIC;
                 signal descriptor_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_write_write : OUT STD_LOGIC;
                 signal descriptor_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal status_token_fifo_rdreq : OUT STD_LOGIC;
                 signal sw_reset : OUT STD_LOGIC
              );
end entity soc_system_MemoryDMA_chain;


architecture europa of soc_system_MemoryDMA_chain is
component control_status_slave_which_resides_within_soc_system_MemoryDMA is 
           port (
                 -- inputs:
                    signal atlantic_error : IN STD_LOGIC;
                    signal chain_run : IN STD_LOGIC;
                    signal clk : IN STD_LOGIC;
                    signal command_fifo_empty : IN STD_LOGIC;
                    signal csr_address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal csr_chipselect : IN STD_LOGIC;
                    signal csr_read : IN STD_LOGIC;
                    signal csr_write : IN STD_LOGIC;
                    signal csr_writedata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal desc_address_fifo_empty : IN STD_LOGIC;
                    signal descriptor_read_address : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_read : IN STD_LOGIC;
                    signal descriptor_write_busy : IN STD_LOGIC;
                    signal descriptor_write_write : IN STD_LOGIC;
                    signal owned_by_hw : IN STD_LOGIC;
                    signal read_go : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal status_token_fifo_empty : IN STD_LOGIC;
                    signal status_token_fifo_rdreq : IN STD_LOGIC;
                    signal write_go : IN STD_LOGIC;

                 -- outputs:
                    signal csr_irq : OUT STD_LOGIC;
                    signal csr_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_pointer_lower_reg_out : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_pointer_upper_reg_out : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal park : OUT STD_LOGIC;
                    signal pollen_clear_run : OUT STD_LOGIC;
                    signal run : OUT STD_LOGIC;
                    signal sw_reset : OUT STD_LOGIC
                 );
end component control_status_slave_which_resides_within_soc_system_MemoryDMA;

component descriptor_read_which_resides_within_soc_system_MemoryDMA is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal command_fifo_full : IN STD_LOGIC;
                    signal controlbitsfifo_rdreq : IN STD_LOGIC;
                    signal desc_address_fifo_full : IN STD_LOGIC;
                    signal descriptor_pointer_lower_reg_out : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_pointer_upper_reg_out : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_readdatavalid : IN STD_LOGIC;
                    signal descriptor_read_waitrequest : IN STD_LOGIC;
                    signal pollen_clear_run : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal run : IN STD_LOGIC;

                 -- outputs:
                    signal atlantic_channel : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal chain_run : OUT STD_LOGIC;
                    signal command_fifo_data : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
                    signal command_fifo_wrreq : OUT STD_LOGIC;
                    signal control : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
                    signal controlbitsfifo_q : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
                    signal desc_address_fifo_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal desc_address_fifo_wrreq : OUT STD_LOGIC;
                    signal descriptor_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_read : OUT STD_LOGIC;
                    signal generate_eop : OUT STD_LOGIC;
                    signal next_desc : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal owned_by_hw : OUT STD_LOGIC;
                    signal read_fixed_address : OUT STD_LOGIC;
                    signal write_fixed_address : OUT STD_LOGIC
                 );
end component descriptor_read_which_resides_within_soc_system_MemoryDMA;

component descriptor_write_which_resides_within_soc_system_MemoryDMA is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal controlbitsfifo_q : IN STD_LOGIC_VECTOR (6 DOWNTO 0);
                    signal desc_address_fifo_empty : IN STD_LOGIC;
                    signal desc_address_fifo_q : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_write_waitrequest : IN STD_LOGIC;
                    signal park : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal status_token_fifo_data : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                    signal status_token_fifo_empty : IN STD_LOGIC;
                    signal status_token_fifo_q : IN STD_LOGIC_VECTOR (23 DOWNTO 0);

                 -- outputs:
                    signal atlantic_error : OUT STD_LOGIC;
                    signal controlbitsfifo_rdreq : OUT STD_LOGIC;
                    signal desc_address_fifo_rdreq : OUT STD_LOGIC;
                    signal descriptor_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_write_busy : OUT STD_LOGIC;
                    signal descriptor_write_write : OUT STD_LOGIC;
                    signal descriptor_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal status_token_fifo_rdreq : OUT STD_LOGIC;
                    signal t_eop : OUT STD_LOGIC
                 );
end component descriptor_write_which_resides_within_soc_system_MemoryDMA;

                signal atlantic_channel :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal atlantic_error :  STD_LOGIC;
                signal chain_run :  STD_LOGIC;
                signal control :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal controlbitsfifo_q :  STD_LOGIC_VECTOR (6 DOWNTO 0);
                signal controlbitsfifo_rdreq :  STD_LOGIC;
                signal descriptor_pointer_lower_reg_out :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal descriptor_pointer_upper_reg_out :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal descriptor_write_busy :  STD_LOGIC;
                signal generate_eop :  STD_LOGIC;
                signal internal_command_fifo_data :  STD_LOGIC_VECTOR (103 DOWNTO 0);
                signal internal_command_fifo_wrreq :  STD_LOGIC;
                signal internal_csr_irq1 :  STD_LOGIC;
                signal internal_csr_readdata1 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_desc_address_fifo_data :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_desc_address_fifo_rdreq :  STD_LOGIC;
                signal internal_desc_address_fifo_wrreq :  STD_LOGIC;
                signal internal_descriptor_read_address1 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_descriptor_read_read1 :  STD_LOGIC;
                signal internal_descriptor_write_address1 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_descriptor_write_write1 :  STD_LOGIC;
                signal internal_descriptor_write_writedata1 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_status_token_fifo_rdreq :  STD_LOGIC;
                signal internal_sw_reset :  STD_LOGIC;
                signal next_desc :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal owned_by_hw :  STD_LOGIC;
                signal park :  STD_LOGIC;
                signal pollen_clear_run :  STD_LOGIC;
                signal read_fixed_address :  STD_LOGIC;
                signal run :  STD_LOGIC;
                signal t_eop :  STD_LOGIC;
                signal write_fixed_address :  STD_LOGIC;

begin

  --the_control_status_slave_which_resides_within_soc_system_MemoryDMA, which is an e_instance
  the_control_status_slave_which_resides_within_soc_system_MemoryDMA : control_status_slave_which_resides_within_soc_system_MemoryDMA
    port map(
      csr_irq => internal_csr_irq1,
      csr_readdata => internal_csr_readdata1,
      descriptor_pointer_lower_reg_out => descriptor_pointer_lower_reg_out,
      descriptor_pointer_upper_reg_out => descriptor_pointer_upper_reg_out,
      park => park,
      pollen_clear_run => pollen_clear_run,
      run => run,
      sw_reset => internal_sw_reset,
      atlantic_error => atlantic_error,
      chain_run => chain_run,
      clk => clk,
      command_fifo_empty => command_fifo_empty,
      csr_address => csr_address,
      csr_chipselect => csr_chipselect,
      csr_read => csr_read,
      csr_write => csr_write,
      csr_writedata => csr_writedata,
      desc_address_fifo_empty => desc_address_fifo_empty,
      descriptor_read_address => internal_descriptor_read_address1,
      descriptor_read_read => internal_descriptor_read_read1,
      descriptor_write_busy => descriptor_write_busy,
      descriptor_write_write => internal_descriptor_write_write1,
      owned_by_hw => owned_by_hw,
      read_go => read_go,
      reset_n => reset_n,
      status_token_fifo_empty => status_token_fifo_empty,
      status_token_fifo_rdreq => internal_status_token_fifo_rdreq,
      write_go => write_go
    );


  --the_descriptor_read_which_resides_within_soc_system_MemoryDMA, which is an e_instance
  the_descriptor_read_which_resides_within_soc_system_MemoryDMA : descriptor_read_which_resides_within_soc_system_MemoryDMA
    port map(
      atlantic_channel => atlantic_channel,
      chain_run => chain_run,
      command_fifo_data => internal_command_fifo_data,
      command_fifo_wrreq => internal_command_fifo_wrreq,
      control => control,
      controlbitsfifo_q => controlbitsfifo_q,
      desc_address_fifo_data => internal_desc_address_fifo_data,
      desc_address_fifo_wrreq => internal_desc_address_fifo_wrreq,
      descriptor_read_address => internal_descriptor_read_address1,
      descriptor_read_read => internal_descriptor_read_read1,
      generate_eop => generate_eop,
      next_desc => next_desc,
      owned_by_hw => owned_by_hw,
      read_fixed_address => read_fixed_address,
      write_fixed_address => write_fixed_address,
      clk => clk,
      command_fifo_full => command_fifo_full,
      controlbitsfifo_rdreq => controlbitsfifo_rdreq,
      desc_address_fifo_full => desc_address_fifo_full,
      descriptor_pointer_lower_reg_out => descriptor_pointer_lower_reg_out,
      descriptor_pointer_upper_reg_out => descriptor_pointer_upper_reg_out,
      descriptor_read_readdata => descriptor_read_readdata,
      descriptor_read_readdatavalid => descriptor_read_readdatavalid,
      descriptor_read_waitrequest => descriptor_read_waitrequest,
      pollen_clear_run => pollen_clear_run,
      reset => reset,
      reset_n => reset_n,
      run => run
    );


  --the_descriptor_write_which_resides_within_soc_system_MemoryDMA, which is an e_instance
  the_descriptor_write_which_resides_within_soc_system_MemoryDMA : descriptor_write_which_resides_within_soc_system_MemoryDMA
    port map(
      atlantic_error => atlantic_error,
      controlbitsfifo_rdreq => controlbitsfifo_rdreq,
      desc_address_fifo_rdreq => internal_desc_address_fifo_rdreq,
      descriptor_write_address => internal_descriptor_write_address1,
      descriptor_write_busy => descriptor_write_busy,
      descriptor_write_write => internal_descriptor_write_write1,
      descriptor_write_writedata => internal_descriptor_write_writedata1,
      status_token_fifo_rdreq => internal_status_token_fifo_rdreq,
      t_eop => t_eop,
      clk => clk,
      controlbitsfifo_q => controlbitsfifo_q,
      desc_address_fifo_empty => desc_address_fifo_empty,
      desc_address_fifo_q => desc_address_fifo_q,
      descriptor_write_waitrequest => descriptor_write_waitrequest,
      park => park,
      reset_n => reset_n,
      status_token_fifo_data => status_token_fifo_data,
      status_token_fifo_empty => status_token_fifo_empty,
      status_token_fifo_q => status_token_fifo_q
    );


  --vhdl renameroo for output signals
  command_fifo_data <= internal_command_fifo_data;
  --vhdl renameroo for output signals
  command_fifo_wrreq <= internal_command_fifo_wrreq;
  --vhdl renameroo for output signals
  csr_irq <= internal_csr_irq1;
  --vhdl renameroo for output signals
  csr_readdata <= internal_csr_readdata1;
  --vhdl renameroo for output signals
  desc_address_fifo_data <= internal_desc_address_fifo_data;
  --vhdl renameroo for output signals
  desc_address_fifo_rdreq <= internal_desc_address_fifo_rdreq;
  --vhdl renameroo for output signals
  desc_address_fifo_wrreq <= internal_desc_address_fifo_wrreq;
  --vhdl renameroo for output signals
  descriptor_read_address <= internal_descriptor_read_address1;
  --vhdl renameroo for output signals
  descriptor_read_read <= internal_descriptor_read_read1;
  --vhdl renameroo for output signals
  descriptor_write_address <= internal_descriptor_write_address1;
  --vhdl renameroo for output signals
  descriptor_write_write <= internal_descriptor_write_write1;
  --vhdl renameroo for output signals
  descriptor_write_writedata <= internal_descriptor_write_writedata1;
  --vhdl renameroo for output signals
  status_token_fifo_rdreq <= internal_status_token_fifo_rdreq;
  --vhdl renameroo for output signals
  sw_reset <= internal_sw_reset;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity soc_system_MemoryDMA_command_grabber is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal command_fifo_empty : IN STD_LOGIC;
                 signal command_fifo_q : IN STD_LOGIC_VECTOR (103 DOWNTO 0);
                 signal m_read_waitrequest : IN STD_LOGIC;
                 signal m_write_waitrequest : IN STD_LOGIC;
                 signal read_go : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal write_go : IN STD_LOGIC;

              -- outputs:
                 signal command_fifo_rdreq : OUT STD_LOGIC;
                 signal read_command_data : OUT STD_LOGIC_VECTOR (58 DOWNTO 0);
                 signal read_command_valid : OUT STD_LOGIC;
                 signal write_command_data : OUT STD_LOGIC_VECTOR (56 DOWNTO 0);
                 signal write_command_valid : OUT STD_LOGIC
              );
end entity soc_system_MemoryDMA_command_grabber;


architecture europa of soc_system_MemoryDMA_command_grabber is
                signal atlantic_channel :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal bytes_to_transfer :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal command_fifo_rdreq_in :  STD_LOGIC;
                signal command_fifo_rdreq_reg :  STD_LOGIC;
                signal command_valid :  STD_LOGIC;
                signal control :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal delay1_command_valid :  STD_LOGIC;
                signal generate_eop :  STD_LOGIC;
                signal read_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal read_burst :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal read_fixed_address :  STD_LOGIC;
                signal write_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal write_burst :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal write_fixed_address :  STD_LOGIC;

begin

  --Descriptor components
  read_address <= command_fifo_q(31 DOWNTO 0);
  write_address <= command_fifo_q(63 DOWNTO 32);
  bytes_to_transfer <= command_fifo_q(79 DOWNTO 64);
  read_burst <= command_fifo_q(87 DOWNTO 80);
  write_burst <= command_fifo_q(95 DOWNTO 88);
  control <= command_fifo_q(103 DOWNTO 96);
  --control bits
  generate_eop <= control(0);
  read_fixed_address <= control(1);
  write_fixed_address <= control(2);
  atlantic_channel <= control(6 DOWNTO 3);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      read_command_data <= std_logic_vector'("00000000000000000000000000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      read_command_data <= Std_Logic_Vector'(A_ToStdLogicVector(write_fixed_address) & A_ToStdLogicVector(generate_eop) & A_ToStdLogicVector(NOT read_fixed_address) & read_burst & bytes_to_transfer & read_address);
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      write_command_data <= std_logic_vector'("000000000000000000000000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      write_command_data <= Std_Logic_Vector'(A_ToStdLogicVector(NOT write_fixed_address) & write_burst & bytes_to_transfer & write_address);
    end if;

  end process;

  read_command_valid <= command_valid;
  write_command_valid <= command_valid;
  --command_fifo_rdreq register
  command_fifo_rdreq_in <= A_WE_StdLogic((std_logic'(((command_fifo_rdreq_reg OR command_valid))) = '1'), std_logic'('0'), ((((NOT read_go AND NOT write_go) AND NOT m_read_waitrequest) AND NOT m_write_waitrequest)));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      command_fifo_rdreq_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT command_fifo_empty) = '1' then 
        command_fifo_rdreq_reg <= command_fifo_rdreq_in;
      end if;
    end if;

  end process;

  command_fifo_rdreq <= command_fifo_rdreq_reg;
  --command_valid register
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delay1_command_valid <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delay1_command_valid <= command_fifo_rdreq_reg;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      command_valid <= std_logic'('0');
    elsif clk'event and clk = '1' then
      command_valid <= delay1_command_valid;
    end if;

  end process;


end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity soc_system_MemoryDMA_m_read is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal m_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_read_readdatavalid : IN STD_LOGIC;
                 signal m_read_waitrequest : IN STD_LOGIC;
                 signal read_command_data : IN STD_LOGIC_VECTOR (58 DOWNTO 0);
                 signal read_command_valid : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal source_stream_ready : IN STD_LOGIC;

              -- outputs:
                 signal m_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_read_read : OUT STD_LOGIC;
                 signal read_go : OUT STD_LOGIC;
                 signal source_stream_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal source_stream_empty : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal source_stream_endofpacket : OUT STD_LOGIC;
                 signal source_stream_startofpacket : OUT STD_LOGIC;
                 signal source_stream_valid : OUT STD_LOGIC
              );
end entity soc_system_MemoryDMA_m_read;


architecture europa of soc_system_MemoryDMA_m_read is
                signal burst_size :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal burst_size_right_shifted :  STD_LOGIC_VECTOR (5 DOWNTO 0);
                signal burst_value :  STD_LOGIC;
                signal bytes_to_transfer :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal empty_operand :  STD_LOGIC_VECTOR (2 DOWNTO 0);
                signal empty_value :  STD_LOGIC_VECTOR (2 DOWNTO 0);
                signal endofpacket :  STD_LOGIC;
                signal generate_eop :  STD_LOGIC;
                signal generate_sop :  STD_LOGIC;
                signal has_transactions_to_post :  STD_LOGIC;
                signal increment_address :  STD_LOGIC;
                signal internal_m_read_address1 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_m_read_read1 :  STD_LOGIC;
                signal internal_read_go :  STD_LOGIC;
                signal internal_source_stream_empty :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal internal_source_stream_endofpacket :  STD_LOGIC;
                signal internal_source_stream_startofpacket :  STD_LOGIC;
                signal internal_source_stream_valid :  STD_LOGIC;
                signal m_read_address_inc :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal m_read_state :  STD_LOGIC_VECTOR (6 DOWNTO 0);
                signal maximum_transactions_in_queue :  STD_LOGIC;
                signal read_command_data_reg :  STD_LOGIC_VECTOR (58 DOWNTO 0);
                signal read_posted :  STD_LOGIC;
                signal received_data_counter :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal received_enough_data :  STD_LOGIC;
                signal remaining_transactions :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal single_transfer :  STD_LOGIC;
                signal start_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal still_got_full_burst :  STD_LOGIC;
                signal transactions_in_queue :  STD_LOGIC_VECTOR (6 DOWNTO 0);
                signal transactions_left_to_post :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal tx_shift :  STD_LOGIC;

begin

  --m_read, which is an e_avalon_master
  --read_command_data_reg
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      read_command_data_reg <= std_logic_vector'("00000000000000000000000000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(read_command_valid) = '1' then 
        read_command_data_reg <= read_command_data;
      end if;
    end if;

  end process;

  --command input
  start_address <= read_command_data_reg(31 DOWNTO 0);
  bytes_to_transfer <= read_command_data_reg(47 DOWNTO 32);
  increment_address <= read_command_data_reg(56);
  generate_eop <= read_command_data_reg(57);
  generate_sop <= read_command_data_reg(58);
  burst_size <= std_logic_vector'("0001");
  burst_size_right_shifted <= burst_size & std_logic_vector'("00");
  --Request Path
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      transactions_left_to_post <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      if m_read_state = std_logic_vector'("0000100") then 
        transactions_left_to_post <= A_EXT (((std_logic_vector'("0") & ((A_SRL(bytes_to_transfer,std_logic_vector'("00000000000000000000000000000010"))))) + (std_logic_vector'("0000000000000000") & (A_TOSTDLOGICVECTOR(or_reduce(bytes_to_transfer(1 DOWNTO 0)))))), 16);
      elsif std_logic'(NOT m_read_waitrequest) = '1' then 
        if m_read_state = std_logic_vector'("0001000") then 
          transactions_left_to_post <= A_EXT (((std_logic_vector'("0") & (transactions_left_to_post)) - (std_logic_vector'("0000000000000000") & (A_TOSTDLOGICVECTOR(burst_value)))), 16);
        end if;
      elsif m_read_state = std_logic_vector'("1000000") then 
        transactions_left_to_post <= std_logic_vector'("0000000000000000");
      end if;
    end if;

  end process;

  still_got_full_burst <= to_std_logic((transactions_left_to_post>=(std_logic_vector'("000000000000") & (burst_size))));
  burst_value <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(still_got_full_burst) = '1'), (std_logic_vector'("000000000000") & (burst_size)), transactions_left_to_post));
  has_transactions_to_post <= or_reduce(transactions_left_to_post);
  read_posted <= internal_m_read_read1 AND NOT m_read_waitrequest;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      transactions_in_queue <= std_logic_vector'("0000000");
    elsif clk'event and clk = '1' then
      transactions_in_queue <= A_EXT (A_WE_StdLogicVector((std_logic'(((read_posted AND NOT m_read_readdatavalid))) = '1'), (((std_logic_vector'("00000000000000000000000000") & (transactions_in_queue)) + std_logic_vector'("000000000000000000000000000000001"))), (A_WE_StdLogicVector((std_logic'(((NOT read_posted AND m_read_readdatavalid))) = '1'), (((std_logic_vector'("00000000000000000000000000") & (transactions_in_queue)) - std_logic_vector'("000000000000000000000000000000001"))), (std_logic_vector'("00000000000000000000000000") & (transactions_in_queue))))), 7);
    end if;

  end process;

  maximum_transactions_in_queue <= to_std_logic(((std_logic_vector'("00000000000000000000000000") & (transactions_in_queue))>=((std_logic_vector'("000000000000000000000000000011111") - std_logic_vector'("000000000000000000000000000000001")))));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_m_read_read1 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_read_waitrequest) = '1' then 
        internal_m_read_read1 <= (internal_read_go AND to_std_logic(((m_read_state = std_logic_vector'("0001000"))))) AND has_transactions_to_post;
      end if;
    end if;

  end process;

  m_read_address_inc <= A_EXT (A_WE_StdLogicVector((std_logic'(increment_address) = '1'), (((std_logic_vector'("0") & (internal_m_read_address1)) + (std_logic_vector'("000000000000000000000000000") & (burst_size_right_shifted)))), (std_logic_vector'("0") & (internal_m_read_address1))), 32);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_m_read_address1 <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if m_read_state = std_logic_vector'("0000100") then 
        internal_m_read_address1 <= Std_Logic_Vector'(start_address(31 DOWNTO 2) & std_logic_vector'("00"));
      elsif std_logic'(NOT m_read_waitrequest) = '1' then 
        if std_logic'((internal_read_go AND internal_m_read_read1)) = '1' then 
          internal_m_read_address1 <= m_read_address_inc;
        end if;
      end if;
    end if;

  end process;

  --Unaligned transfer not supported, tx_shift is always 0.
  tx_shift <= std_logic'('0');
  --Response Path
  single_transfer <= internal_source_stream_startofpacket AND internal_source_stream_endofpacket;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      received_data_counter <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(m_read_readdatavalid) = '1' then 
        if std_logic'(single_transfer) = '1' then 
          received_data_counter <= A_EXT (((std_logic_vector'("0") & (((std_logic_vector'("0") & (((std_logic_vector'("00000000000000000") & (received_data_counter)) + std_logic_vector'("000000000000000000000000000000100")))) - (std_logic_vector'("000000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(tx_shift)))))) - (std_logic_vector'("000000000000000000000000000000000") & (internal_source_stream_empty))), 16);
        elsif std_logic'(endofpacket) = '1' then 
          received_data_counter <= A_EXT (((std_logic_vector'("00000000000000000") & (received_data_counter)) + (std_logic_vector'("0") & ((A_WE_StdLogicVector((std_logic'(or_reduce(bytes_to_transfer(1 DOWNTO 0))) = '1'), (std_logic_vector'("000000000000000000000000000000") & (bytes_to_transfer(1 DOWNTO 0))), std_logic_vector'("00000000000000000000000000000100")))))), 16);
        elsif std_logic'(NOT or_reduce(received_data_counter)) = '1' then 
          received_data_counter <= A_EXT (((std_logic_vector'("0") & (((std_logic_vector'("00000000000000000") & (received_data_counter)) + std_logic_vector'("000000000000000000000000000000100")))) - (std_logic_vector'("000000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(tx_shift)))), 16);
        else
          received_data_counter <= A_EXT (((std_logic_vector'("00000000000000000") & (received_data_counter)) + std_logic_vector'("000000000000000000000000000000100")), 16);
        end if;
      elsif m_read_state = std_logic_vector'("0000010") then 
        received_data_counter <= std_logic_vector'("0000000000000000");
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      remaining_transactions <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      if m_read_state = std_logic_vector'("0000100") then 
        remaining_transactions <= A_EXT (((std_logic_vector'("0") & ((A_SRL(bytes_to_transfer,std_logic_vector'("00000000000000000000000000000010"))))) + (std_logic_vector'("0000000000000000") & (A_TOSTDLOGICVECTOR(or_reduce(bytes_to_transfer(1 DOWNTO 0)))))), 16);
      elsif std_logic'((internal_read_go AND m_read_readdatavalid)) = '1' then 
        remaining_transactions <= A_EXT (((std_logic_vector'("00000000000000000") & (remaining_transactions)) - std_logic_vector'("000000000000000000000000000000001")), 16);
      end if;
    end if;

  end process;

  endofpacket <= to_std_logic(((std_logic_vector'("0000000000000000") & (remaining_transactions)) = std_logic_vector'("00000000000000000000000000000001")));
  --FSM
  received_enough_data <= to_std_logic((received_data_counter>=bytes_to_transfer));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_read_state <= std_logic_vector'("0000001");
    elsif clk'event and clk = '1' then
      if (std_logic_vector'("00000000000000000000000000000001")) /= std_logic_vector'("00000000000000000000000000000000") then 
        case m_read_state is -- synthesis parallel_case
            when std_logic_vector'("0000001") => 
                if std_logic'(read_command_valid) = '1' then 
                  m_read_state <= std_logic_vector'("0000010");
                end if;
            -- when std_logic_vector'("0000001") 
        
            when std_logic_vector'("0000010") => 
                m_read_state <= std_logic_vector'("0000100");
            -- when std_logic_vector'("0000010") 
        
            when std_logic_vector'("0000100") => 
                if std_logic'(NOT source_stream_ready) = '1' then 
                  m_read_state <= std_logic_vector'("0010000");
                else
                  m_read_state <= std_logic_vector'("0001000");
                end if;
            -- when std_logic_vector'("0000100") 
        
            when std_logic_vector'("0001000") => 
                if std_logic'((NOT source_stream_ready OR maximum_transactions_in_queue)) = '1' then 
                  m_read_state <= std_logic_vector'("0010000");
                elsif std_logic'(NOT has_transactions_to_post) = '1' then 
                  m_read_state <= std_logic_vector'("0100000");
                elsif std_logic'(received_enough_data) = '1' then 
                  m_read_state <= std_logic_vector'("1000000");
                end if;
            -- when std_logic_vector'("0001000") 
        
            when std_logic_vector'("0010000") => 
                if std_logic'(received_enough_data) = '1' then 
                  m_read_state <= std_logic_vector'("1000000");
                elsif std_logic'(NOT has_transactions_to_post) = '1' then 
                  m_read_state <= std_logic_vector'("0100000");
                elsif std_logic'(((source_stream_ready AND NOT m_read_waitrequest) AND NOT maximum_transactions_in_queue)) = '1' then 
                  m_read_state <= std_logic_vector'("0001000");
                end if;
            -- when std_logic_vector'("0010000") 
        
            when std_logic_vector'("0100000") => 
                if std_logic'(received_enough_data) = '1' then 
                  m_read_state <= std_logic_vector'("1000000");
                end if;
            -- when std_logic_vector'("0100000") 
        
            when std_logic_vector'("1000000") => 
                m_read_state <= std_logic_vector'("0000001");
            -- when std_logic_vector'("1000000") 
        
            when others => 
                m_read_state <= std_logic_vector'("0000001");
            -- when others 
        
        end case; -- m_read_state
      end if;
    end if;

  end process;

  internal_read_go <= or_reduce(((m_read_state AND ((((std_logic_vector'("0001000") OR std_logic_vector'("0010000")) OR std_logic_vector'("0100000")) OR std_logic_vector'("1000000"))))));
  --Output on the Av-ST Source
  source_stream_data <= m_read_readdata;
  internal_source_stream_valid <= internal_read_go AND m_read_readdatavalid;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_source_stream_startofpacket <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT internal_source_stream_startofpacket) = '1' then 
        internal_source_stream_startofpacket <= to_std_logic((m_read_state = std_logic_vector'("0000100")));
      elsif std_logic'(internal_source_stream_valid) = '1' then 
        internal_source_stream_startofpacket <= NOT source_stream_ready;
      end if;
    end if;

  end process;

  internal_source_stream_endofpacket <= (internal_read_go AND endofpacket) AND m_read_readdatavalid;
  internal_source_stream_empty <= A_EXT (A_WE_StdLogicVector((std_logic'(((endofpacket AND internal_source_stream_valid))) = '1'), (std_logic_vector'("00000000000000000000000000000") & (empty_value)), std_logic_vector'("00000000000000000000000000000000")), 2);
  empty_operand <= std_logic_vector'("100");
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      empty_value <= std_logic_vector'("000");
    elsif clk'event and clk = '1' then
      empty_value <= A_EXT (((std_logic_vector'("0") & (empty_operand)) - (std_logic_vector'("00") & (bytes_to_transfer(1 DOWNTO 0)))), 3);
    end if;

  end process;

  --vhdl renameroo for output signals
  m_read_address <= internal_m_read_address1;
  --vhdl renameroo for output signals
  m_read_read <= internal_m_read_read1;
  --vhdl renameroo for output signals
  read_go <= internal_read_go;
  --vhdl renameroo for output signals
  source_stream_empty <= internal_source_stream_empty;
  --vhdl renameroo for output signals
  source_stream_endofpacket <= internal_source_stream_endofpacket;
  --vhdl renameroo for output signals
  source_stream_startofpacket <= internal_source_stream_startofpacket;
  --vhdl renameroo for output signals
  source_stream_valid <= internal_source_stream_valid;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.all;

entity soc_system_MemoryDMA_m_readfifo_m_readfifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal m_readfifo_data : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
                 signal m_readfifo_rdreq : IN STD_LOGIC;
                 signal m_readfifo_wrreq : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;

              -- outputs:
                 signal m_readfifo_empty : OUT STD_LOGIC;
                 signal m_readfifo_full : OUT STD_LOGIC;
                 signal m_readfifo_q : OUT STD_LOGIC_VECTOR (35 DOWNTO 0);
                 signal m_readfifo_usedw : OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
              );
end entity soc_system_MemoryDMA_m_readfifo_m_readfifo;


architecture europa of soc_system_MemoryDMA_m_readfifo_m_readfifo is
  component scfifo is
GENERIC (
      add_ram_output_register : STRING;
        intended_device_family : STRING;
        lpm_numwords : NATURAL;
        lpm_showahead : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL;
        lpm_widthu : NATURAL;
        overflow_checking : STRING;
        underflow_checking : STRING;
        use_eab : STRING
      );
    PORT (
    signal full : OUT STD_LOGIC;
        signal q : OUT STD_LOGIC_VECTOR (35 DOWNTO 0);
        signal usedw : OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
        signal empty : OUT STD_LOGIC;
        signal aclr : IN STD_LOGIC;
        signal rdreq : IN STD_LOGIC;
        signal data : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
        signal clock : IN STD_LOGIC;
        signal wrreq : IN STD_LOGIC
      );
  end component scfifo;
                signal internal_m_readfifo_empty :  STD_LOGIC;
                signal internal_m_readfifo_full :  STD_LOGIC;
                signal internal_m_readfifo_q :  STD_LOGIC_VECTOR (35 DOWNTO 0);
                signal internal_m_readfifo_usedw :  STD_LOGIC_VECTOR (5 DOWNTO 0);

begin

  soc_system_MemoryDMA_m_readfifo_m_readfifo_m_readfifo : scfifo
    generic map(
      add_ram_output_register => "ON",
      intended_device_family => "CYCLONEV",
      lpm_numwords => 64,
      lpm_showahead => "OFF",
      lpm_type => "scfifo",
      lpm_width => 36,
      lpm_widthu => 6,
      overflow_checking => "ON",
      underflow_checking => "ON",
      use_eab => "ON"
    )
    port map(
            aclr => reset,
            clock => clk,
            data => m_readfifo_data,
            empty => internal_m_readfifo_empty,
            full => internal_m_readfifo_full,
            q => internal_m_readfifo_q,
            rdreq => m_readfifo_rdreq,
            usedw => internal_m_readfifo_usedw,
            wrreq => m_readfifo_wrreq
    );

  --vhdl renameroo for output signals
  m_readfifo_empty <= internal_m_readfifo_empty;
  --vhdl renameroo for output signals
  m_readfifo_full <= internal_m_readfifo_full;
  --vhdl renameroo for output signals
  m_readfifo_q <= internal_m_readfifo_q;
  --vhdl renameroo for output signals
  m_readfifo_usedw <= internal_m_readfifo_usedw;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity soc_system_MemoryDMA_m_readfifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal sink_stream_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal sink_stream_empty : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal sink_stream_endofpacket : IN STD_LOGIC;
                 signal sink_stream_startofpacket : IN STD_LOGIC;
                 signal sink_stream_valid : IN STD_LOGIC;
                 signal source_stream_ready : IN STD_LOGIC;

              -- outputs:
                 signal sink_stream_ready : OUT STD_LOGIC;
                 signal source_stream_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal source_stream_empty : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal source_stream_endofpacket : OUT STD_LOGIC;
                 signal source_stream_startofpacket : OUT STD_LOGIC;
                 signal source_stream_valid : OUT STD_LOGIC
              );
end entity soc_system_MemoryDMA_m_readfifo;


architecture europa of soc_system_MemoryDMA_m_readfifo is
component soc_system_MemoryDMA_m_readfifo_m_readfifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal m_readfifo_data : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
                    signal m_readfifo_rdreq : IN STD_LOGIC;
                    signal m_readfifo_wrreq : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;

                 -- outputs:
                    signal m_readfifo_empty : OUT STD_LOGIC;
                    signal m_readfifo_full : OUT STD_LOGIC;
                    signal m_readfifo_q : OUT STD_LOGIC_VECTOR (35 DOWNTO 0);
                    signal m_readfifo_usedw : OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
                 );
end component soc_system_MemoryDMA_m_readfifo_m_readfifo;

                signal delayed_m_readfifo_empty :  STD_LOGIC;
                signal hold_condition :  STD_LOGIC;
                signal internal_source_stream_endofpacket1 :  STD_LOGIC;
                signal internal_source_stream_valid1 :  STD_LOGIC;
                signal m_readfifo_data :  STD_LOGIC_VECTOR (35 DOWNTO 0);
                signal m_readfifo_empty :  STD_LOGIC;
                signal m_readfifo_empty_fall :  STD_LOGIC;
                signal m_readfifo_full :  STD_LOGIC;
                signal m_readfifo_q :  STD_LOGIC_VECTOR (35 DOWNTO 0);
                signal m_readfifo_rdreq :  STD_LOGIC;
                signal m_readfifo_rdreq_delay :  STD_LOGIC;
                signal m_readfifo_usedw :  STD_LOGIC_VECTOR (5 DOWNTO 0);
                signal m_readfifo_wrreq :  STD_LOGIC;
                signal source_stream_empty_hold :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal source_stream_empty_sig :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal source_stream_endofpacket_from_fifo :  STD_LOGIC;
                signal source_stream_endofpacket_hold :  STD_LOGIC;
                signal source_stream_endofpacket_sig :  STD_LOGIC;
                signal source_stream_valid_reg :  STD_LOGIC;
                signal transmitted_eop :  STD_LOGIC;

begin

  --the_soc_system_MemoryDMA_m_readfifo_m_readfifo, which is an e_instance
  the_soc_system_MemoryDMA_m_readfifo_m_readfifo : soc_system_MemoryDMA_m_readfifo_m_readfifo
    port map(
      m_readfifo_empty => m_readfifo_empty,
      m_readfifo_full => m_readfifo_full,
      m_readfifo_q => m_readfifo_q,
      m_readfifo_usedw => m_readfifo_usedw,
      clk => clk,
      m_readfifo_data => m_readfifo_data,
      m_readfifo_rdreq => m_readfifo_rdreq,
      m_readfifo_wrreq => m_readfifo_wrreq,
      reset => reset
    );


  sink_stream_ready <= NOT m_readfifo_usedw(5) AND NOT m_readfifo_full;
  m_readfifo_rdreq <= (NOT m_readfifo_empty AND source_stream_ready) OR (m_readfifo_empty_fall AND NOT hold_condition);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_m_readfifo_empty <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_m_readfifo_empty <= m_readfifo_empty;
    end if;

  end process;

  m_readfifo_empty_fall <= NOT m_readfifo_empty AND delayed_m_readfifo_empty;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      source_stream_valid_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((source_stream_ready OR m_readfifo_rdreq)) = '1' then 
        source_stream_valid_reg <= m_readfifo_rdreq;
      end if;
    end if;

  end process;

  internal_source_stream_valid1 <= source_stream_valid_reg;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_readfifo_wrreq <= std_logic'('0');
    elsif clk'event and clk = '1' then
      m_readfifo_wrreq <= sink_stream_valid;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_readfifo_rdreq_delay <= std_logic'('0');
    elsif clk'event and clk = '1' then
      m_readfifo_rdreq_delay <= m_readfifo_rdreq;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      transmitted_eop <= std_logic'('0');
    elsif clk'event and clk = '1' then
      transmitted_eop <= A_WE_StdLogic((std_logic'(transmitted_eop) = '1'), NOT m_readfifo_rdreq, ((internal_source_stream_endofpacket1 AND source_stream_ready) AND internal_source_stream_valid1));
    end if;

  end process;

  source_stream_endofpacket_sig <= A_WE_StdLogic((std_logic'(m_readfifo_rdreq_delay) = '1'), (source_stream_endofpacket_from_fifo OR source_stream_endofpacket_hold), (((source_stream_endofpacket_from_fifo AND NOT transmitted_eop)) OR source_stream_endofpacket_hold));
  internal_source_stream_endofpacket1 <= source_stream_endofpacket_sig;
  hold_condition <= internal_source_stream_valid1 AND NOT source_stream_ready;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      source_stream_endofpacket_hold <= std_logic'('0');
    elsif clk'event and clk = '1' then
      source_stream_endofpacket_hold <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(hold_condition) = '1'), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(source_stream_endofpacket_sig))), (A_WE_StdLogicVector((std_logic'(source_stream_ready) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(source_stream_endofpacket_hold)))))));
    end if;

  end process;

  source_stream_empty_sig <= m_readfifo_q(33 DOWNTO 32);
  source_stream_empty <= source_stream_empty_sig OR source_stream_empty_hold;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      source_stream_empty_hold <= std_logic_vector'("00");
    elsif clk'event and clk = '1' then
      source_stream_empty_hold <= A_EXT (A_WE_StdLogicVector((std_logic'(hold_condition) = '1'), (std_logic_vector'("000000000000000000000000000000") & (source_stream_empty_sig)), (A_WE_StdLogicVector((std_logic'(source_stream_ready) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("000000000000000000000000000000") & (source_stream_empty_hold))))), 2);
    end if;

  end process;

  source_stream_data <= m_readfifo_q(31 DOWNTO 0);
  source_stream_endofpacket_from_fifo <= m_readfifo_q(34);
  source_stream_startofpacket <= m_readfifo_q(35);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_readfifo_data <= std_logic_vector'("000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      m_readfifo_data <= Std_Logic_Vector'(A_ToStdLogicVector(sink_stream_startofpacket) & A_ToStdLogicVector(sink_stream_endofpacket) & sink_stream_empty & sink_stream_data);
    end if;

  end process;

  --vhdl renameroo for output signals
  source_stream_endofpacket <= internal_source_stream_endofpacket1;
  --vhdl renameroo for output signals
  source_stream_valid <= internal_source_stream_valid1;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal byteenable_in : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal clk : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal waitrequest_in : IN STD_LOGIC;
                 signal write_in : IN STD_LOGIC;

              -- outputs:
                 signal byteenable_out : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal waitrequest_out : OUT STD_LOGIC
              );
end entity sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA;


architecture europa of sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA is

begin

  byteenable_out <= byteenable_in AND A_REP(write_in, 2);
  waitrequest_out <= waitrequest_in OR to_std_logic((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(waitrequest_in))) = std_logic_vector'("00000000000000000000000000000001"))))));

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity thirty_two_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal byteenable_in : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal clk : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal waitrequest_in : IN STD_LOGIC;
                 signal write_in : IN STD_LOGIC;

              -- outputs:
                 signal byteenable_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal waitrequest_out : OUT STD_LOGIC
              );
end entity thirty_two_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA;


architecture europa of thirty_two_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA is
component sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA is 
           port (
                 -- inputs:
                    signal byteenable_in : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                    signal clk : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal waitrequest_in : IN STD_LOGIC;
                    signal write_in : IN STD_LOGIC;

                 -- outputs:
                    signal byteenable_out : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                    signal waitrequest_out : OUT STD_LOGIC
                 );
end component sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA;

                signal advance_to_next_state :  STD_LOGIC;
                signal full_lower_half_transfer :  STD_LOGIC;
                signal full_upper_half_transfer :  STD_LOGIC;
                signal full_word_transfer :  STD_LOGIC;
                signal internal_byteenable_out1 :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal lower_enable :  STD_LOGIC;
                signal lower_stall :  STD_LOGIC;
                signal module_input5 :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal module_input6 :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal partial_lower_half_transfer :  STD_LOGIC;
                signal partial_upper_half_transfer :  STD_LOGIC;
                signal state_bit :  STD_LOGIC;
                signal transfer_done :  STD_LOGIC;
                signal two_stage_transfer :  STD_LOGIC;
                signal upper_enable :  STD_LOGIC;
                signal upper_stall :  STD_LOGIC;

begin

  partial_lower_half_transfer <= to_std_logic(((std_logic_vector'("000000000000000000000000000000") & (byteenable_in(1 DOWNTO 0))) /= std_logic_vector'("00000000000000000000000000000000")));
  full_lower_half_transfer <= to_std_logic((byteenable_in(1 DOWNTO 0) = A_REP(std_logic'('1'), 2)));
  partial_upper_half_transfer <= to_std_logic(((std_logic_vector'("000000000000000000000000000000") & (byteenable_in(3 DOWNTO 2))) /= std_logic_vector'("00000000000000000000000000000000")));
  full_upper_half_transfer <= to_std_logic((byteenable_in(3 DOWNTO 2) = A_REP(std_logic'('1'), 2)));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      state_bit <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(transfer_done))) = std_logic_vector'("00000000000000000000000000000001") then 
        state_bit <= std_logic'('0');
      elsif (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(advance_to_next_state))) = std_logic_vector'("00000000000000000000000000000001") then 
        state_bit <= std_logic'('1');
      end if;
    end if;

  end process;

  full_word_transfer <= to_std_logic(((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(full_lower_half_transfer))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(full_upper_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))));
  two_stage_transfer <= to_std_logic((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(full_word_transfer))) = std_logic_vector'("00000000000000000000000000000000"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(partial_lower_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(partial_upper_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))));
  advance_to_next_state <= to_std_logic((((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(lower_stall))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(state_bit))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(waitrequest_in))) = std_logic_vector'("00000000000000000000000000000000")))));
  transfer_done <= to_std_logic(((((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(full_word_transfer))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(waitrequest_in))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))))) OR ((((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000000"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(lower_stall))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(upper_stall))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(waitrequest_in))) = std_logic_vector'("00000000000000000000000000000000")))))) OR ((((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(state_bit))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(upper_stall))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(waitrequest_in))) = std_logic_vector'("00000000000000000000000000000000")))))));
  lower_enable <= to_std_logic((((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(full_word_transfer))) = std_logic_vector'("00000000000000000000000000000001"))))) OR ((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(partial_lower_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))))) OR (((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(partial_lower_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(state_bit))) = std_logic_vector'("00000000000000000000000000000000")))))));
  upper_enable <= to_std_logic((((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(full_word_transfer))) = std_logic_vector'("00000000000000000000000000000001"))))) OR ((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000000")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(partial_upper_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))))) OR (((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(two_stage_transfer))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(partial_upper_half_transfer))) = std_logic_vector'("00000000000000000000000000000001")))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(state_bit))) = std_logic_vector'("00000000000000000000000000000001")))))));
  --lower_sixteen_bit_byteenable_FSM, which is an e_instance
  lower_sixteen_bit_byteenable_FSM : sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA
    port map(
      byteenable_out => internal_byteenable_out1(1 DOWNTO 0),
      waitrequest_out => lower_stall,
      byteenable_in => module_input5,
      clk => clk,
      reset_n => reset_n,
      waitrequest_in => waitrequest_in,
      write_in => lower_enable
    );

  module_input5 <= byteenable_in(1 DOWNTO 0);

  --upper_sixteen_bit_byteenable_FSM, which is an e_instance
  upper_sixteen_bit_byteenable_FSM : sixteen_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA
    port map(
      byteenable_out => internal_byteenable_out1(3 DOWNTO 2),
      waitrequest_out => upper_stall,
      byteenable_in => module_input6,
      clk => clk,
      reset_n => reset_n,
      waitrequest_in => waitrequest_in,
      write_in => upper_enable
    );

  module_input6 <= byteenable_in(3 DOWNTO 2);

  waitrequest_out <= waitrequest_in OR to_std_logic((((((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(transfer_done))) = std_logic_vector'("00000000000000000000000000000000"))) AND (((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(write_in))) = std_logic_vector'("00000000000000000000000000000001"))))));
  --vhdl renameroo for output signals
  byteenable_out <= internal_byteenable_out1;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity byteenable_gen_which_resides_within_soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal byteenable_in : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal clk : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal waitrequest_in : IN STD_LOGIC;
                 signal write_in : IN STD_LOGIC;

              -- outputs:
                 signal byteenable_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal waitrequest_out : OUT STD_LOGIC
              );
end entity byteenable_gen_which_resides_within_soc_system_MemoryDMA;


architecture europa of byteenable_gen_which_resides_within_soc_system_MemoryDMA is
component thirty_two_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA is 
           port (
                 -- inputs:
                    signal byteenable_in : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal clk : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal waitrequest_in : IN STD_LOGIC;
                    signal write_in : IN STD_LOGIC;

                 -- outputs:
                    signal byteenable_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal waitrequest_out : OUT STD_LOGIC
                 );
end component thirty_two_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA;

                signal internal_byteenable_out :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal internal_waitrequest_out :  STD_LOGIC;

begin

  --the_thirty_two_bit_byteenable_FSM, which is an e_instance
  the_thirty_two_bit_byteenable_FSM : thirty_two_bit_byteenable_FSM_which_resides_within_soc_system_MemoryDMA
    port map(
      byteenable_out => internal_byteenable_out,
      waitrequest_out => internal_waitrequest_out,
      byteenable_in => byteenable_in,
      clk => clk,
      reset_n => reset_n,
      waitrequest_in => waitrequest_in,
      write_in => write_in
    );


  --vhdl renameroo for output signals
  byteenable_out <= internal_byteenable_out;
  --vhdl renameroo for output signals
  waitrequest_out <= internal_waitrequest_out;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity soc_system_MemoryDMA_m_write is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal e_00 : IN STD_LOGIC;
                 signal e_01 : IN STD_LOGIC;
                 signal e_02 : IN STD_LOGIC;
                 signal e_03 : IN STD_LOGIC;
                 signal e_04 : IN STD_LOGIC;
                 signal e_05 : IN STD_LOGIC;
                 signal e_06 : IN STD_LOGIC;
                 signal enough_data : IN STD_LOGIC;
                 signal eop_found : IN STD_LOGIC;
                 signal m_write_waitrequest : IN STD_LOGIC;
                 signal reset_n : IN STD_LOGIC;
                 signal sink_stream_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal sink_stream_empty : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                 signal sink_stream_endofpacket : IN STD_LOGIC;
                 signal sink_stream_startofpacket : IN STD_LOGIC;
                 signal sink_stream_valid : IN STD_LOGIC;
                 signal status_token_fifo_full : IN STD_LOGIC;
                 signal write_command_data : IN STD_LOGIC_VECTOR (56 DOWNTO 0);
                 signal write_command_valid : IN STD_LOGIC;

              -- outputs:
                 signal m_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_write_byteenable : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal m_write_write : OUT STD_LOGIC;
                 signal m_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal sink_stream_ready : OUT STD_LOGIC;
                 signal status_token_fifo_data : OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
                 signal status_token_fifo_wrreq : OUT STD_LOGIC;
                 signal write_go : OUT STD_LOGIC
              );
end entity soc_system_MemoryDMA_m_write;


architecture europa of soc_system_MemoryDMA_m_write is
component byteenable_gen_which_resides_within_soc_system_MemoryDMA is 
           port (
                 -- inputs:
                    signal byteenable_in : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal clk : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal waitrequest_in : IN STD_LOGIC;
                    signal write_in : IN STD_LOGIC;

                 -- outputs:
                    signal byteenable_out : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal waitrequest_out : OUT STD_LOGIC
                 );
end component byteenable_gen_which_resides_within_soc_system_MemoryDMA;

                signal actual_bytes_transferred :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal all_one :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal burst_counter :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal burst_counter_decrement :  STD_LOGIC;
                signal burst_counter_next :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal burst_counter_reg :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal burst_size :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal byteenable_enable :  STD_LOGIC;
                signal bytes_to_transfer :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal counter :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal counter_in :  STD_LOGIC_VECTOR (15 DOWNTO 0);
                signal delayed_write_command_valid :  STD_LOGIC;
                signal delayed_write_go :  STD_LOGIC;
                signal eop_found_hold :  STD_LOGIC;
                signal eop_reg :  STD_LOGIC;
                signal increment :  STD_LOGIC;
                signal increment_address :  STD_LOGIC;
                signal internal_m_write_address1 :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_m_write_byteenable1 :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal internal_m_write_write1 :  STD_LOGIC;
                signal internal_sink_stream_ready :  STD_LOGIC;
                signal m_write_byteenable_in :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal m_write_byteenable_reg :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal m_write_waitrequest_out :  STD_LOGIC;
                signal m_write_write_sig :  STD_LOGIC;
                signal m_write_writedata_reg :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal m_writefifo_fill :  STD_LOGIC;
                signal shift0 :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal shift1 :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal shift2 :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal shift3 :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal single_transfer :  STD_LOGIC;
                signal sink_stream_empty_shift :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal sink_stream_really_valid :  STD_LOGIC;
                signal start_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal status_reg :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal status_reg_in :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal status_word :  STD_LOGIC_VECTOR (7 DOWNTO 0);
                signal t_eop :  STD_LOGIC;
                signal write_command_data_reg :  STD_LOGIC_VECTOR (56 DOWNTO 0);
                signal write_go_fall_reg :  STD_LOGIC;
                signal write_go_fall_reg_in :  STD_LOGIC;
                signal write_go_reg :  STD_LOGIC;
                signal write_go_reg_in :  STD_LOGIC;
                signal write_go_reg_in_teop :  STD_LOGIC;

begin

  --m_write, which is an e_avalon_master
  burst_size <= std_logic_vector'("0001");
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_m_write_write1 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        internal_m_write_write1 <= write_go_reg AND ((sink_stream_really_valid OR m_write_write_sig));
      end if;
    end if;

  end process;

  m_writefifo_fill <= std_logic'('1');
  --command input
  start_address <= write_command_data_reg(31 DOWNTO 0);
  bytes_to_transfer <= write_command_data_reg(47 DOWNTO 32);
  increment_address <= write_command_data_reg(56);
  --increment or keep constant, the m_write_address depending on the command bit
  m_write_writedata <= m_write_writedata_reg;
  increment <= write_go_reg AND sink_stream_really_valid;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_write_writedata_reg <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        m_write_writedata_reg <= sink_stream_data;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_write_write_sig <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(m_write_waitrequest_out) = '1' then 
        m_write_write_sig <= sink_stream_really_valid AND NOT internal_m_write_write1;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      internal_m_write_address1 <= std_logic_vector'("00000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        internal_m_write_address1 <= A_EXT (A_WE_StdLogicVector((std_logic'(delayed_write_command_valid) = '1'), (std_logic_vector'("0") & (start_address)), (A_WE_StdLogicVector((std_logic'(increment_address) = '1'), (A_WE_StdLogicVector((std_logic'(internal_m_write_write1) = '1'), (((std_logic_vector'("0") & (internal_m_write_address1)) + std_logic_vector'("000000000000000000000000000000100"))), (std_logic_vector'("0") & (internal_m_write_address1)))), (std_logic_vector'("0") & (start_address))))), 32);
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      eop_found_hold <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(write_go_reg) = '1' then 
        eop_found_hold <= A_WE_StdLogic((std_logic'(eop_found_hold) = '1'), NOT ((sink_stream_endofpacket AND sink_stream_really_valid)), eop_found);
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      burst_counter_reg <= std_logic_vector'("0000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        burst_counter_reg <= burst_counter;
      end if;
    end if;

  end process;

  burst_counter_decrement <= (or_reduce(burst_counter) AND write_go_reg) AND sink_stream_really_valid;
  burst_counter_next <= A_EXT (((std_logic_vector'("00000000000000000000000000000") & (burst_counter)) - std_logic_vector'("000000000000000000000000000000001")), 4);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      burst_counter <= std_logic_vector'("0000");
    elsif clk'event and clk = '1' then
      if std_logic'(((NOT or_reduce(burst_counter) AND nor_reduce(burst_counter_reg)) AND write_go_reg)) = '1' then 
        if std_logic'(enough_data) = '1' then 
          burst_counter <= burst_size;
        elsif std_logic'(eop_found_hold) = '1' then 
          burst_counter <= std_logic_vector'("000") & (A_TOSTDLOGICVECTOR(m_writefifo_fill));
        end if;
      elsif std_logic'(NOT m_write_waitrequest_out) = '1' then 
        if std_logic'(burst_counter_decrement) = '1' then 
          burst_counter <= burst_counter_next;
        end if;
      end if;
    end if;

  end process;

  shift3 <= Std_Logic_Vector'(std_logic_vector'("000") & A_ToStdLogicVector(all_one(0)));
  shift2 <= Std_Logic_Vector'(std_logic_vector'("00") & all_one(1 DOWNTO 0));
  shift1 <= Std_Logic_Vector'(A_ToStdLogicVector(std_logic'('0')) & all_one(2 DOWNTO 0));
  shift0 <= all_one;
  sink_stream_empty_shift <= A_EXT (((((A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000011"))), (std_logic_vector'("0000000000000000000000000000") & (shift3)), std_logic_vector'("00000000000000000000000000000000"))) OR (A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000010"))), (std_logic_vector'("0000000000000000000000000000") & (shift2)), std_logic_vector'("00000000000000000000000000000000")))) OR (A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000001"))), (std_logic_vector'("0000000000000000000000000000") & (shift1)), std_logic_vector'("00000000000000000000000000000000")))) OR (A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000000"))), (std_logic_vector'("0000000000000000000000000000") & (shift0)), std_logic_vector'("00000000000000000000000000000000")))), 4);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      m_write_byteenable_reg <= std_logic_vector'("0000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        m_write_byteenable_reg <= A_EXT (((((A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000011"))), (std_logic_vector'("0000000000000000000000000000") & (shift3)), std_logic_vector'("00000000000000000000000000000000"))) OR (A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000010"))), (std_logic_vector'("0000000000000000000000000000") & (shift2)), std_logic_vector'("00000000000000000000000000000000")))) OR (A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000001"))), (std_logic_vector'("0000000000000000000000000000") & (shift1)), std_logic_vector'("00000000000000000000000000000000")))) OR (A_WE_StdLogicVector((((std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)) = std_logic_vector'("00000000000000000000000000000000"))), (std_logic_vector'("0000000000000000000000000000") & (shift0)), std_logic_vector'("00000000000000000000000000000000")))), 4);
      end if;
    end if;

  end process;

  all_one <= std_logic_vector'("1111");
  m_write_byteenable_in <= A_WE_StdLogicVector((std_logic'(byteenable_enable) = '1'), m_write_byteenable_reg, all_one);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      byteenable_enable <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        byteenable_enable <= sink_stream_endofpacket;
      end if;
    end if;

  end process;

  internal_sink_stream_ready <= Vector_To_Std_Logic(((std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(((write_go_reg AND NOT m_write_waitrequest_out) AND NOT eop_reg)))) AND (A_WE_StdLogicVector((std_logic'(or_reduce(bytes_to_transfer)) = '1'), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(to_std_logic(NOT ((counter>=bytes_to_transfer)))))), std_logic_vector'("00000000000000000000000000000001")))));
  --sink_stream_ready_sig
  --sink_stream_valid is only really valid when we're ready
  sink_stream_really_valid <= sink_stream_valid AND internal_sink_stream_ready;
  --write_command_data_reg
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      write_command_data_reg <= std_logic_vector'("000000000000000000000000000000000000000000000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(write_command_valid) = '1' then 
        write_command_data_reg <= write_command_data;
      end if;
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_write_command_valid <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_write_command_valid <= write_command_valid;
    end if;

  end process;

  --8-bits up-counter
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      counter <= std_logic_vector'("0000000000000000");
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        counter <= counter_in;
      end if;
    end if;

  end process;

  --write_go bit for all of this operation until count is up
  write_go_reg_in <= A_WE_StdLogic((std_logic'((delayed_write_command_valid)) = '1'), std_logic'('1'), A_WE_StdLogic(((counter>=bytes_to_transfer)), std_logic'('0'), write_go_reg));
  write_go_reg_in_teop <= A_WE_StdLogic((std_logic'(eop_reg) = '1'), NOT ((internal_m_write_write1 AND NOT m_write_waitrequest_out)), std_logic'('1'));
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      eop_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      eop_reg <= A_WE_StdLogic((std_logic'(eop_reg) = '1'), NOT ((internal_m_write_write1 AND NOT m_write_waitrequest_out)), (sink_stream_endofpacket AND sink_stream_really_valid));
    end if;

  end process;

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      write_go_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'(NOT m_write_waitrequest_out) = '1' then 
        write_go_reg <= A_WE_StdLogic((std_logic'(((write_go_reg AND to_std_logic((((std_logic_vector'("0000000000000000") & (bytes_to_transfer)) = std_logic_vector'("00000000000000000000000000000000"))))))) = '1'), write_go_reg_in_teop, write_go_reg_in);
      end if;
    end if;

  end process;

  write_go <= write_go_reg;
  t_eop <= ((sink_stream_endofpacket AND sink_stream_really_valid)) AND to_std_logic((((std_logic_vector'("0000000000000000") & (bytes_to_transfer)) = std_logic_vector'("00000000000000000000000000000000"))));
  single_transfer <= sink_stream_startofpacket AND sink_stream_endofpacket;
  counter_in <= A_EXT (A_WE_StdLogicVector((std_logic'((delayed_write_command_valid)) = '1'), std_logic_vector'("0000000000000000000000000000000000"), (A_WE_StdLogicVector((std_logic'(increment) = '1'), (((std_logic_vector'("0") & (((std_logic_vector'("00000000000000000") & (counter)) + std_logic_vector'("000000000000000000000000000000100")))) - (std_logic_vector'("00") & ((A_WE_StdLogicVector((std_logic'(sink_stream_endofpacket) = '1'), (std_logic_vector'("000000000000000000000000000000") & (sink_stream_empty)), std_logic_vector'("00000000000000000000000000000000"))))))), (std_logic_vector'("000000000000000000") & (counter))))), 16);
  --status register
  status_reg_in <= A_EXT (A_WE_StdLogicVector((std_logic'(write_go_fall_reg) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("000000000000000000000000") & (((status_word OR status_reg))))), 8);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      status_reg <= std_logic_vector'("00000000");
    elsif clk'event and clk = '1' then
      status_reg <= status_reg_in;
    end if;

  end process;

  --actual_bytes_transferred register
  actual_bytes_transferred <= counter;
  --status_token consists of the status signals and actual_bytes_transferred
  status_token_fifo_data <= status_reg & actual_bytes_transferred;
  status_word <= Std_Logic_Vector'(A_ToStdLogicVector(t_eop) & std_logic_vector'("0000000"));
  --delayed write go register
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      delayed_write_go <= std_logic'('0');
    elsif clk'event and clk = '1' then
      delayed_write_go <= write_go_reg;
    end if;

  end process;

  --write_go falling edge detector
  write_go_fall_reg_in <= delayed_write_go AND NOT write_go_reg;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      write_go_fall_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      write_go_fall_reg <= write_go_fall_reg_in;
    end if;

  end process;

  status_token_fifo_wrreq <= write_go_fall_reg AND NOT status_token_fifo_full;
  --the_byteenable_gen_which_resides_within_soc_system_MemoryDMA, which is an e_instance
  the_byteenable_gen_which_resides_within_soc_system_MemoryDMA : byteenable_gen_which_resides_within_soc_system_MemoryDMA
    port map(
      byteenable_out => internal_m_write_byteenable1,
      waitrequest_out => m_write_waitrequest_out,
      byteenable_in => m_write_byteenable_in,
      clk => clk,
      reset_n => reset_n,
      waitrequest_in => m_write_waitrequest,
      write_in => internal_m_write_write1
    );


  --vhdl renameroo for output signals
  m_write_address <= internal_m_write_address1;
  --vhdl renameroo for output signals
  m_write_byteenable <= internal_m_write_byteenable1;
  --vhdl renameroo for output signals
  m_write_write <= internal_m_write_write1;
  --vhdl renameroo for output signals
  sink_stream_ready <= internal_sink_stream_ready;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.all;

entity soc_system_MemoryDMA_command_fifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal command_fifo_data : IN STD_LOGIC_VECTOR (103 DOWNTO 0);
                 signal command_fifo_rdreq : IN STD_LOGIC;
                 signal command_fifo_wrreq : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;

              -- outputs:
                 signal command_fifo_empty : OUT STD_LOGIC;
                 signal command_fifo_full : OUT STD_LOGIC;
                 signal command_fifo_q : OUT STD_LOGIC_VECTOR (103 DOWNTO 0)
              );
end entity soc_system_MemoryDMA_command_fifo;


architecture europa of soc_system_MemoryDMA_command_fifo is
  component scfifo is
GENERIC (
      add_ram_output_register : STRING;
        intended_device_family : STRING;
        lpm_numwords : NATURAL;
        lpm_showahead : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL;
        lpm_widthu : NATURAL;
        overflow_checking : STRING;
        underflow_checking : STRING;
        use_eab : STRING
      );
    PORT (
    signal q : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
        signal empty : OUT STD_LOGIC;
        signal full : OUT STD_LOGIC;
        signal aclr : IN STD_LOGIC;
        signal rdreq : IN STD_LOGIC;
        signal clock : IN STD_LOGIC;
        signal wrreq : IN STD_LOGIC;
        signal data : IN STD_LOGIC_VECTOR (103 DOWNTO 0)
      );
  end component scfifo;
                signal internal_command_fifo_empty :  STD_LOGIC;
                signal internal_command_fifo_full :  STD_LOGIC;
                signal internal_command_fifo_q :  STD_LOGIC_VECTOR (103 DOWNTO 0);

begin

  soc_system_MemoryDMA_command_fifo_command_fifo : scfifo
    generic map(
      add_ram_output_register => "ON",
      intended_device_family => "CYCLONEV",
      lpm_numwords => 2,
      lpm_showahead => "OFF",
      lpm_type => "scfifo",
      lpm_width => 104,
      lpm_widthu => 1,
      overflow_checking => "ON",
      underflow_checking => "ON",
      use_eab => "ON"
    )
    port map(
            aclr => reset,
            clock => clk,
            data => command_fifo_data,
            empty => internal_command_fifo_empty,
            full => internal_command_fifo_full,
            q => internal_command_fifo_q,
            rdreq => command_fifo_rdreq,
            wrreq => command_fifo_wrreq
    );

  --vhdl renameroo for output signals
  command_fifo_empty <= internal_command_fifo_empty;
  --vhdl renameroo for output signals
  command_fifo_full <= internal_command_fifo_full;
  --vhdl renameroo for output signals
  command_fifo_q <= internal_command_fifo_q;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.all;

entity soc_system_MemoryDMA_desc_address_fifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal desc_address_fifo_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal desc_address_fifo_rdreq : IN STD_LOGIC;
                 signal desc_address_fifo_wrreq : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;

              -- outputs:
                 signal desc_address_fifo_empty : OUT STD_LOGIC;
                 signal desc_address_fifo_full : OUT STD_LOGIC;
                 signal desc_address_fifo_q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
              );
end entity soc_system_MemoryDMA_desc_address_fifo;


architecture europa of soc_system_MemoryDMA_desc_address_fifo is
  component scfifo is
GENERIC (
      add_ram_output_register : STRING;
        intended_device_family : STRING;
        lpm_numwords : NATURAL;
        lpm_showahead : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL;
        lpm_widthu : NATURAL;
        overflow_checking : STRING;
        underflow_checking : STRING;
        use_eab : STRING
      );
    PORT (
    signal q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
        signal empty : OUT STD_LOGIC;
        signal full : OUT STD_LOGIC;
        signal aclr : IN STD_LOGIC;
        signal rdreq : IN STD_LOGIC;
        signal clock : IN STD_LOGIC;
        signal wrreq : IN STD_LOGIC;
        signal data : IN STD_LOGIC_VECTOR (31 DOWNTO 0)
      );
  end component scfifo;
                signal internal_desc_address_fifo_empty :  STD_LOGIC;
                signal internal_desc_address_fifo_full :  STD_LOGIC;
                signal internal_desc_address_fifo_q :  STD_LOGIC_VECTOR (31 DOWNTO 0);

begin

  soc_system_MemoryDMA_desc_address_fifo_desc_address_fifo : scfifo
    generic map(
      add_ram_output_register => "ON",
      intended_device_family => "CYCLONEV",
      lpm_numwords => 2,
      lpm_showahead => "OFF",
      lpm_type => "scfifo",
      lpm_width => 32,
      lpm_widthu => 1,
      overflow_checking => "ON",
      underflow_checking => "ON",
      use_eab => "OFF"
    )
    port map(
            aclr => reset,
            clock => clk,
            data => desc_address_fifo_data,
            empty => internal_desc_address_fifo_empty,
            full => internal_desc_address_fifo_full,
            q => internal_desc_address_fifo_q,
            rdreq => desc_address_fifo_rdreq,
            wrreq => desc_address_fifo_wrreq
    );

  --vhdl renameroo for output signals
  desc_address_fifo_empty <= internal_desc_address_fifo_empty;
  --vhdl renameroo for output signals
  desc_address_fifo_full <= internal_desc_address_fifo_full;
  --vhdl renameroo for output signals
  desc_address_fifo_q <= internal_desc_address_fifo_q;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.all;

entity soc_system_MemoryDMA_status_token_fifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;
                 signal status_token_fifo_data : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                 signal status_token_fifo_rdreq : IN STD_LOGIC;
                 signal status_token_fifo_wrreq : IN STD_LOGIC;

              -- outputs:
                 signal status_token_fifo_empty : OUT STD_LOGIC;
                 signal status_token_fifo_full : OUT STD_LOGIC;
                 signal status_token_fifo_q : OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
              );
end entity soc_system_MemoryDMA_status_token_fifo;


architecture europa of soc_system_MemoryDMA_status_token_fifo is
  component scfifo is
GENERIC (
      add_ram_output_register : STRING;
        intended_device_family : STRING;
        lpm_numwords : NATURAL;
        lpm_showahead : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL;
        lpm_widthu : NATURAL;
        overflow_checking : STRING;
        underflow_checking : STRING;
        use_eab : STRING
      );
    PORT (
    signal q : OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
        signal empty : OUT STD_LOGIC;
        signal full : OUT STD_LOGIC;
        signal aclr : IN STD_LOGIC;
        signal rdreq : IN STD_LOGIC;
        signal clock : IN STD_LOGIC;
        signal wrreq : IN STD_LOGIC;
        signal data : IN STD_LOGIC_VECTOR (23 DOWNTO 0)
      );
  end component scfifo;
                signal internal_status_token_fifo_empty :  STD_LOGIC;
                signal internal_status_token_fifo_full :  STD_LOGIC;
                signal internal_status_token_fifo_q :  STD_LOGIC_VECTOR (23 DOWNTO 0);

begin

  soc_system_MemoryDMA_status_token_fifo_status_token_fifo : scfifo
    generic map(
      add_ram_output_register => "ON",
      intended_device_family => "CYCLONEV",
      lpm_numwords => 2,
      lpm_showahead => "OFF",
      lpm_type => "scfifo",
      lpm_width => 24,
      lpm_widthu => 1,
      overflow_checking => "ON",
      underflow_checking => "ON",
      use_eab => "ON"
    )
    port map(
            aclr => reset,
            clock => clk,
            data => status_token_fifo_data,
            empty => internal_status_token_fifo_empty,
            full => internal_status_token_fifo_full,
            q => internal_status_token_fifo_q,
            rdreq => status_token_fifo_rdreq,
            wrreq => status_token_fifo_wrreq
    );

  --vhdl renameroo for output signals
  status_token_fifo_empty <= internal_status_token_fifo_empty;
  --vhdl renameroo for output signals
  status_token_fifo_full <= internal_status_token_fifo_full;
  --vhdl renameroo for output signals
  status_token_fifo_q <= internal_status_token_fifo_q;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library lpm;
use lpm.all;

entity soc_system_MemoryDMA_stream_fifo is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;
                 signal stream_fifo_data : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
                 signal stream_fifo_rdreq : IN STD_LOGIC;
                 signal stream_fifo_wrreq : IN STD_LOGIC;

              -- outputs:
                 signal stream_fifo_empty : OUT STD_LOGIC;
                 signal stream_fifo_full : OUT STD_LOGIC;
                 signal stream_fifo_q : OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
              );
end entity soc_system_MemoryDMA_stream_fifo;


architecture europa of soc_system_MemoryDMA_stream_fifo is
  component scfifo is
GENERIC (
      add_ram_output_register : STRING;
        intended_device_family : STRING;
        lpm_numwords : NATURAL;
        lpm_showahead : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL;
        lpm_widthu : NATURAL;
        overflow_checking : STRING;
        underflow_checking : STRING;
        use_eab : STRING
      );
    PORT (
    signal q : OUT STD_LOGIC_VECTOR (35 DOWNTO 0);
        signal empty : OUT STD_LOGIC;
        signal full : OUT STD_LOGIC;
        signal aclr : IN STD_LOGIC;
        signal rdreq : IN STD_LOGIC;
        signal clock : IN STD_LOGIC;
        signal wrreq : IN STD_LOGIC;
        signal data : IN STD_LOGIC_VECTOR (35 DOWNTO 0)
      );
  end component scfifo;
                signal internal_stream_fifo_empty :  STD_LOGIC;
                signal internal_stream_fifo_full :  STD_LOGIC;
                signal internal_stream_fifo_q :  STD_LOGIC_VECTOR (35 DOWNTO 0);

begin

  soc_system_MemoryDMA_stream_fifo_stream_fifo : scfifo
    generic map(
      add_ram_output_register => "ON",
      intended_device_family => "CYCLONEV",
      lpm_numwords => 4,
      lpm_showahead => "OFF",
      lpm_type => "scfifo",
      lpm_width => 36,
      lpm_widthu => 2,
      overflow_checking => "ON",
      underflow_checking => "ON",
      use_eab => "ON"
    )
    port map(
            aclr => reset,
            clock => clk,
            data => stream_fifo_data,
            empty => internal_stream_fifo_empty,
            full => internal_stream_fifo_full,
            q => internal_stream_fifo_q,
            rdreq => stream_fifo_rdreq,
            wrreq => stream_fifo_wrreq
    );

  --vhdl renameroo for output signals
  stream_fifo_empty <= internal_stream_fifo_empty;
  --vhdl renameroo for output signals
  stream_fifo_full <= internal_stream_fifo_full;
  --vhdl renameroo for output signals
  stream_fifo_q <= internal_stream_fifo_q;

end europa;



-- turn off superfluous VHDL processor warnings 
-- altera message_level Level1 
-- altera message_off 10034 10035 10036 10037 10230 10240 10030 

library altera;
use altera.altera_europa_support_lib.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity soc_system_MemoryDMA is 
        port (
              -- inputs:
                 signal clk : IN STD_LOGIC;
                 signal csr_address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal csr_chipselect : IN STD_LOGIC;
                 signal csr_read : IN STD_LOGIC;
                 signal csr_write : IN STD_LOGIC;
                 signal csr_writedata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_readdatavalid : IN STD_LOGIC;
                 signal descriptor_read_waitrequest : IN STD_LOGIC;
                 signal descriptor_write_waitrequest : IN STD_LOGIC;
                 signal m_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_read_readdatavalid : IN STD_LOGIC;
                 signal m_read_waitrequest : IN STD_LOGIC;
                 signal m_write_waitrequest : IN STD_LOGIC;
                 signal system_reset_n : IN STD_LOGIC;

              -- outputs:
                 signal csr_irq : OUT STD_LOGIC;
                 signal csr_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_read_read : OUT STD_LOGIC;
                 signal descriptor_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal descriptor_write_write : OUT STD_LOGIC;
                 signal descriptor_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_read_read : OUT STD_LOGIC;
                 signal m_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                 signal m_write_byteenable : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                 signal m_write_write : OUT STD_LOGIC;
                 signal m_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
              );
end entity soc_system_MemoryDMA;


architecture europa of soc_system_MemoryDMA is
component soc_system_MemoryDMA_chain is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal command_fifo_empty : IN STD_LOGIC;
                    signal command_fifo_full : IN STD_LOGIC;
                    signal csr_address : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal csr_chipselect : IN STD_LOGIC;
                    signal csr_read : IN STD_LOGIC;
                    signal csr_write : IN STD_LOGIC;
                    signal csr_writedata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal desc_address_fifo_empty : IN STD_LOGIC;
                    signal desc_address_fifo_full : IN STD_LOGIC;
                    signal desc_address_fifo_q : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_readdatavalid : IN STD_LOGIC;
                    signal descriptor_read_waitrequest : IN STD_LOGIC;
                    signal descriptor_write_waitrequest : IN STD_LOGIC;
                    signal read_go : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal status_token_fifo_data : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                    signal status_token_fifo_empty : IN STD_LOGIC;
                    signal status_token_fifo_q : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                    signal write_go : IN STD_LOGIC;

                 -- outputs:
                    signal command_fifo_data : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
                    signal command_fifo_wrreq : OUT STD_LOGIC;
                    signal csr_irq : OUT STD_LOGIC;
                    signal csr_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal desc_address_fifo_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal desc_address_fifo_rdreq : OUT STD_LOGIC;
                    signal desc_address_fifo_wrreq : OUT STD_LOGIC;
                    signal descriptor_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_read_read : OUT STD_LOGIC;
                    signal descriptor_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal descriptor_write_write : OUT STD_LOGIC;
                    signal descriptor_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal status_token_fifo_rdreq : OUT STD_LOGIC;
                    signal sw_reset : OUT STD_LOGIC
                 );
end component soc_system_MemoryDMA_chain;

component soc_system_MemoryDMA_command_grabber is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal command_fifo_empty : IN STD_LOGIC;
                    signal command_fifo_q : IN STD_LOGIC_VECTOR (103 DOWNTO 0);
                    signal m_read_waitrequest : IN STD_LOGIC;
                    signal m_write_waitrequest : IN STD_LOGIC;
                    signal read_go : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal write_go : IN STD_LOGIC;

                 -- outputs:
                    signal command_fifo_rdreq : OUT STD_LOGIC;
                    signal read_command_data : OUT STD_LOGIC_VECTOR (58 DOWNTO 0);
                    signal read_command_valid : OUT STD_LOGIC;
                    signal write_command_data : OUT STD_LOGIC_VECTOR (56 DOWNTO 0);
                    signal write_command_valid : OUT STD_LOGIC
                 );
end component soc_system_MemoryDMA_command_grabber;

component soc_system_MemoryDMA_m_read is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal m_read_readdata : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal m_read_readdatavalid : IN STD_LOGIC;
                    signal m_read_waitrequest : IN STD_LOGIC;
                    signal read_command_data : IN STD_LOGIC_VECTOR (58 DOWNTO 0);
                    signal read_command_valid : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal source_stream_ready : IN STD_LOGIC;

                 -- outputs:
                    signal m_read_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal m_read_read : OUT STD_LOGIC;
                    signal read_go : OUT STD_LOGIC;
                    signal source_stream_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal source_stream_empty : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                    signal source_stream_endofpacket : OUT STD_LOGIC;
                    signal source_stream_startofpacket : OUT STD_LOGIC;
                    signal source_stream_valid : OUT STD_LOGIC
                 );
end component soc_system_MemoryDMA_m_read;

component soc_system_MemoryDMA_m_readfifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal sink_stream_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal sink_stream_empty : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                    signal sink_stream_endofpacket : IN STD_LOGIC;
                    signal sink_stream_startofpacket : IN STD_LOGIC;
                    signal sink_stream_valid : IN STD_LOGIC;
                    signal source_stream_ready : IN STD_LOGIC;

                 -- outputs:
                    signal sink_stream_ready : OUT STD_LOGIC;
                    signal source_stream_data : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal source_stream_empty : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
                    signal source_stream_endofpacket : OUT STD_LOGIC;
                    signal source_stream_startofpacket : OUT STD_LOGIC;
                    signal source_stream_valid : OUT STD_LOGIC
                 );
end component soc_system_MemoryDMA_m_readfifo;

component soc_system_MemoryDMA_m_write is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal e_00 : IN STD_LOGIC;
                    signal e_01 : IN STD_LOGIC;
                    signal e_02 : IN STD_LOGIC;
                    signal e_03 : IN STD_LOGIC;
                    signal e_04 : IN STD_LOGIC;
                    signal e_05 : IN STD_LOGIC;
                    signal e_06 : IN STD_LOGIC;
                    signal enough_data : IN STD_LOGIC;
                    signal eop_found : IN STD_LOGIC;
                    signal m_write_waitrequest : IN STD_LOGIC;
                    signal reset_n : IN STD_LOGIC;
                    signal sink_stream_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal sink_stream_empty : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
                    signal sink_stream_endofpacket : IN STD_LOGIC;
                    signal sink_stream_startofpacket : IN STD_LOGIC;
                    signal sink_stream_valid : IN STD_LOGIC;
                    signal status_token_fifo_full : IN STD_LOGIC;
                    signal write_command_data : IN STD_LOGIC_VECTOR (56 DOWNTO 0);
                    signal write_command_valid : IN STD_LOGIC;

                 -- outputs:
                    signal m_write_address : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal m_write_byteenable : OUT STD_LOGIC_VECTOR (3 DOWNTO 0);
                    signal m_write_write : OUT STD_LOGIC;
                    signal m_write_writedata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal sink_stream_ready : OUT STD_LOGIC;
                    signal status_token_fifo_data : OUT STD_LOGIC_VECTOR (23 DOWNTO 0);
                    signal status_token_fifo_wrreq : OUT STD_LOGIC;
                    signal write_go : OUT STD_LOGIC
                 );
end component soc_system_MemoryDMA_m_write;

component soc_system_MemoryDMA_command_fifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal command_fifo_data : IN STD_LOGIC_VECTOR (103 DOWNTO 0);
                    signal command_fifo_rdreq : IN STD_LOGIC;
                    signal command_fifo_wrreq : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;

                 -- outputs:
                    signal command_fifo_empty : OUT STD_LOGIC;
                    signal command_fifo_full : OUT STD_LOGIC;
                    signal command_fifo_q : OUT STD_LOGIC_VECTOR (103 DOWNTO 0)
                 );
end component soc_system_MemoryDMA_command_fifo;

component soc_system_MemoryDMA_desc_address_fifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal desc_address_fifo_data : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                    signal desc_address_fifo_rdreq : IN STD_LOGIC;
                    signal desc_address_fifo_wrreq : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;

                 -- outputs:
                    signal desc_address_fifo_empty : OUT STD_LOGIC;
                    signal desc_address_fifo_full : OUT STD_LOGIC;
                    signal desc_address_fifo_q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
                 );
end component soc_system_MemoryDMA_desc_address_fifo;

component soc_system_MemoryDMA_status_token_fifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;
                    signal status_token_fifo_data : IN STD_LOGIC_VECTOR (23 DOWNTO 0);
                    signal status_token_fifo_rdreq : IN STD_LOGIC;
                    signal status_token_fifo_wrreq : IN STD_LOGIC;

                 -- outputs:
                    signal status_token_fifo_empty : OUT STD_LOGIC;
                    signal status_token_fifo_full : OUT STD_LOGIC;
                    signal status_token_fifo_q : OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
                 );
end component soc_system_MemoryDMA_status_token_fifo;

component soc_system_MemoryDMA_stream_fifo is 
           port (
                 -- inputs:
                    signal clk : IN STD_LOGIC;
                    signal reset : IN STD_LOGIC;
                    signal stream_fifo_data : IN STD_LOGIC_VECTOR (35 DOWNTO 0);
                    signal stream_fifo_rdreq : IN STD_LOGIC;
                    signal stream_fifo_wrreq : IN STD_LOGIC;

                 -- outputs:
                    signal stream_fifo_empty : OUT STD_LOGIC;
                    signal stream_fifo_full : OUT STD_LOGIC;
                    signal stream_fifo_q : OUT STD_LOGIC_VECTOR (35 DOWNTO 0)
                 );
end component soc_system_MemoryDMA_stream_fifo;

                signal command_fifo_data :  STD_LOGIC_VECTOR (103 DOWNTO 0);
                signal command_fifo_empty :  STD_LOGIC;
                signal command_fifo_full :  STD_LOGIC;
                signal command_fifo_q :  STD_LOGIC_VECTOR (103 DOWNTO 0);
                signal command_fifo_rdreq :  STD_LOGIC;
                signal command_fifo_wrreq :  STD_LOGIC;
                signal data_to_fifo :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal desc_address_fifo_data :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal desc_address_fifo_empty :  STD_LOGIC;
                signal desc_address_fifo_full :  STD_LOGIC;
                signal desc_address_fifo_q :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal desc_address_fifo_rdreq :  STD_LOGIC;
                signal desc_address_fifo_wrreq :  STD_LOGIC;
                signal e_00 :  STD_LOGIC;
                signal e_01 :  STD_LOGIC;
                signal e_02 :  STD_LOGIC;
                signal e_03 :  STD_LOGIC;
                signal e_04 :  STD_LOGIC;
                signal e_05 :  STD_LOGIC;
                signal e_06 :  STD_LOGIC;
                signal empty_to_fifo :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal eop_to_fifo :  STD_LOGIC;
                signal internal_csr_irq :  STD_LOGIC;
                signal internal_csr_readdata :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_descriptor_read_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_descriptor_read_read :  STD_LOGIC;
                signal internal_descriptor_write_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_descriptor_write_write :  STD_LOGIC;
                signal internal_descriptor_write_writedata :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_m_read_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_m_read_read :  STD_LOGIC;
                signal internal_m_write_address :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal internal_m_write_byteenable :  STD_LOGIC_VECTOR (3 DOWNTO 0);
                signal internal_m_write_write :  STD_LOGIC;
                signal internal_m_write_writedata :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal module_input :  STD_LOGIC;
                signal module_input1 :  STD_LOGIC;
                signal module_input2 :  STD_LOGIC;
                signal module_input3 :  STD_LOGIC;
                signal module_input4 :  STD_LOGIC;
                signal module_input7 :  STD_LOGIC;
                signal module_input8 :  STD_LOGIC;
                signal module_input9 :  STD_LOGIC;
                signal read_command_data :  STD_LOGIC_VECTOR (58 DOWNTO 0);
                signal read_command_valid :  STD_LOGIC;
                signal read_go :  STD_LOGIC;
                signal ready_from_fifo :  STD_LOGIC;
                signal reset :  STD_LOGIC;
                signal reset_n :  STD_LOGIC;
                signal sink_stream_data :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal sink_stream_empty :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal sink_stream_endofpacket :  STD_LOGIC;
                signal sink_stream_endofpacket_from_fifo :  STD_LOGIC;
                signal sink_stream_endofpacket_hold :  STD_LOGIC;
                signal sink_stream_endofpacket_sig :  STD_LOGIC;
                signal sink_stream_ready :  STD_LOGIC;
                signal sink_stream_startofpacket :  STD_LOGIC;
                signal sink_stream_valid :  STD_LOGIC;
                signal sink_stream_valid_hold :  STD_LOGIC;
                signal sink_stream_valid_out :  STD_LOGIC;
                signal sink_stream_valid_reg :  STD_LOGIC;
                signal sop_to_fifo :  STD_LOGIC;
                signal source_stream_data :  STD_LOGIC_VECTOR (31 DOWNTO 0);
                signal source_stream_empty :  STD_LOGIC_VECTOR (1 DOWNTO 0);
                signal source_stream_endofpacket :  STD_LOGIC;
                signal source_stream_ready :  STD_LOGIC;
                signal source_stream_startofpacket :  STD_LOGIC;
                signal source_stream_valid :  STD_LOGIC;
                signal status_token_fifo_data :  STD_LOGIC_VECTOR (23 DOWNTO 0);
                signal status_token_fifo_empty :  STD_LOGIC;
                signal status_token_fifo_full :  STD_LOGIC;
                signal status_token_fifo_q :  STD_LOGIC_VECTOR (23 DOWNTO 0);
                signal status_token_fifo_rdreq :  STD_LOGIC;
                signal status_token_fifo_wrreq :  STD_LOGIC;
                signal stream_fifo_data :  STD_LOGIC_VECTOR (35 DOWNTO 0);
                signal stream_fifo_empty :  STD_LOGIC;
                signal stream_fifo_full :  STD_LOGIC;
                signal stream_fifo_q :  STD_LOGIC_VECTOR (35 DOWNTO 0);
                signal stream_fifo_rdreq :  STD_LOGIC;
                signal stream_fifo_wrreq :  STD_LOGIC;
                signal sw_reset :  STD_LOGIC;
                signal sw_reset_d1 :  STD_LOGIC;
                signal sw_reset_request :  STD_LOGIC;
                signal valid_to_fifo :  STD_LOGIC;
                signal write_command_data :  STD_LOGIC_VECTOR (56 DOWNTO 0);
                signal write_command_valid :  STD_LOGIC;
                signal write_go :  STD_LOGIC;

begin

  process (clk, system_reset_n)
  begin
    if system_reset_n = '0' then
      reset_n <= std_logic'('0');
    elsif clk'event and clk = '1' then
      reset_n <= NOT ((NOT system_reset_n OR sw_reset_request));
    end if;

  end process;

  process (clk, system_reset_n)
  begin
    if system_reset_n = '0' then
      sw_reset_d1 <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((sw_reset OR sw_reset_request)) = '1' then 
        sw_reset_d1 <= sw_reset AND NOT sw_reset_request;
      end if;
    end if;

  end process;

  process (clk, system_reset_n)
  begin
    if system_reset_n = '0' then
      sw_reset_request <= std_logic'('0');
    elsif clk'event and clk = '1' then
      if std_logic'((sw_reset OR sw_reset_request)) = '1' then 
        sw_reset_request <= sw_reset_d1 AND NOT sw_reset_request;
      end if;
    end if;

  end process;

  reset <= NOT reset_n;
  --the_soc_system_MemoryDMA_chain, which is an e_instance
  the_soc_system_MemoryDMA_chain : soc_system_MemoryDMA_chain
    port map(
      command_fifo_data => command_fifo_data,
      command_fifo_wrreq => command_fifo_wrreq,
      csr_irq => internal_csr_irq,
      csr_readdata => internal_csr_readdata,
      desc_address_fifo_data => desc_address_fifo_data,
      desc_address_fifo_rdreq => desc_address_fifo_rdreq,
      desc_address_fifo_wrreq => desc_address_fifo_wrreq,
      descriptor_read_address => internal_descriptor_read_address,
      descriptor_read_read => internal_descriptor_read_read,
      descriptor_write_address => internal_descriptor_write_address,
      descriptor_write_write => internal_descriptor_write_write,
      descriptor_write_writedata => internal_descriptor_write_writedata,
      status_token_fifo_rdreq => status_token_fifo_rdreq,
      sw_reset => sw_reset,
      clk => clk,
      command_fifo_empty => command_fifo_empty,
      command_fifo_full => command_fifo_full,
      csr_address => csr_address,
      csr_chipselect => csr_chipselect,
      csr_read => csr_read,
      csr_write => csr_write,
      csr_writedata => csr_writedata,
      desc_address_fifo_empty => desc_address_fifo_empty,
      desc_address_fifo_full => desc_address_fifo_full,
      desc_address_fifo_q => desc_address_fifo_q,
      descriptor_read_readdata => descriptor_read_readdata,
      descriptor_read_readdatavalid => descriptor_read_readdatavalid,
      descriptor_read_waitrequest => module_input,
      descriptor_write_waitrequest => module_input1,
      read_go => read_go,
      reset => reset,
      reset_n => reset_n,
      status_token_fifo_data => status_token_fifo_data,
      status_token_fifo_empty => status_token_fifo_empty,
      status_token_fifo_q => status_token_fifo_q,
      write_go => write_go
    );

  module_input <= descriptor_read_waitrequest AND internal_descriptor_read_read;
  module_input1 <= descriptor_write_waitrequest AND internal_descriptor_write_write;

  --the_soc_system_MemoryDMA_command_grabber, which is an e_instance
  the_soc_system_MemoryDMA_command_grabber : soc_system_MemoryDMA_command_grabber
    port map(
      command_fifo_rdreq => command_fifo_rdreq,
      read_command_data => read_command_data,
      read_command_valid => read_command_valid,
      write_command_data => write_command_data,
      write_command_valid => write_command_valid,
      clk => clk,
      command_fifo_empty => command_fifo_empty,
      command_fifo_q => command_fifo_q,
      m_read_waitrequest => module_input2,
      m_write_waitrequest => module_input3,
      read_go => read_go,
      reset_n => reset_n,
      write_go => write_go
    );

  module_input2 <= m_read_waitrequest AND internal_m_read_read;
  module_input3 <= m_write_waitrequest AND internal_m_write_write;

  --the_soc_system_MemoryDMA_m_read, which is an e_instance
  the_soc_system_MemoryDMA_m_read : soc_system_MemoryDMA_m_read
    port map(
      m_read_address => internal_m_read_address,
      m_read_read => internal_m_read_read,
      read_go => read_go,
      source_stream_data => data_to_fifo,
      source_stream_empty => empty_to_fifo,
      source_stream_endofpacket => eop_to_fifo,
      source_stream_startofpacket => sop_to_fifo,
      source_stream_valid => valid_to_fifo,
      clk => clk,
      m_read_readdata => m_read_readdata,
      m_read_readdatavalid => m_read_readdatavalid,
      m_read_waitrequest => module_input4,
      read_command_data => read_command_data,
      read_command_valid => read_command_valid,
      reset_n => reset_n,
      source_stream_ready => ready_from_fifo
    );

  module_input4 <= m_read_waitrequest AND internal_m_read_read;

  --the_soc_system_MemoryDMA_m_readfifo, which is an e_instance
  the_soc_system_MemoryDMA_m_readfifo : soc_system_MemoryDMA_m_readfifo
    port map(
      sink_stream_ready => ready_from_fifo,
      source_stream_data => source_stream_data,
      source_stream_empty => source_stream_empty,
      source_stream_endofpacket => source_stream_endofpacket,
      source_stream_startofpacket => source_stream_startofpacket,
      source_stream_valid => source_stream_valid,
      clk => clk,
      reset => reset,
      reset_n => reset_n,
      sink_stream_data => data_to_fifo,
      sink_stream_empty => empty_to_fifo,
      sink_stream_endofpacket => eop_to_fifo,
      sink_stream_startofpacket => sop_to_fifo,
      sink_stream_valid => valid_to_fifo,
      source_stream_ready => source_stream_ready
    );


  --the_soc_system_MemoryDMA_m_write, which is an e_instance
  the_soc_system_MemoryDMA_m_write : soc_system_MemoryDMA_m_write
    port map(
      m_write_address => internal_m_write_address,
      m_write_byteenable => internal_m_write_byteenable,
      m_write_write => internal_m_write_write,
      m_write_writedata => internal_m_write_writedata,
      sink_stream_ready => sink_stream_ready,
      status_token_fifo_data => status_token_fifo_data,
      status_token_fifo_wrreq => status_token_fifo_wrreq,
      write_go => write_go,
      clk => clk,
      e_00 => e_00,
      e_01 => e_01,
      e_02 => e_02,
      e_03 => e_03,
      e_04 => e_04,
      e_05 => e_05,
      e_06 => e_06,
      enough_data => module_input7,
      eop_found => module_input8,
      m_write_waitrequest => module_input9,
      reset_n => reset_n,
      sink_stream_data => sink_stream_data,
      sink_stream_empty => sink_stream_empty,
      sink_stream_endofpacket => sink_stream_endofpacket,
      sink_stream_startofpacket => sink_stream_startofpacket,
      sink_stream_valid => sink_stream_valid,
      status_token_fifo_full => status_token_fifo_full,
      write_command_data => write_command_data,
      write_command_valid => write_command_valid
    );

  module_input7 <= std_logic'('1');
  module_input8 <= std_logic'('0');
  module_input9 <= m_write_waitrequest AND internal_m_write_write;

  --the_soc_system_MemoryDMA_command_fifo, which is an e_instance
  the_soc_system_MemoryDMA_command_fifo : soc_system_MemoryDMA_command_fifo
    port map(
      command_fifo_empty => command_fifo_empty,
      command_fifo_full => command_fifo_full,
      command_fifo_q => command_fifo_q,
      clk => clk,
      command_fifo_data => command_fifo_data,
      command_fifo_rdreq => command_fifo_rdreq,
      command_fifo_wrreq => command_fifo_wrreq,
      reset => reset
    );


  --the_soc_system_MemoryDMA_desc_address_fifo, which is an e_instance
  the_soc_system_MemoryDMA_desc_address_fifo : soc_system_MemoryDMA_desc_address_fifo
    port map(
      desc_address_fifo_empty => desc_address_fifo_empty,
      desc_address_fifo_full => desc_address_fifo_full,
      desc_address_fifo_q => desc_address_fifo_q,
      clk => clk,
      desc_address_fifo_data => desc_address_fifo_data,
      desc_address_fifo_rdreq => desc_address_fifo_rdreq,
      desc_address_fifo_wrreq => desc_address_fifo_wrreq,
      reset => reset
    );


  --the_soc_system_MemoryDMA_status_token_fifo, which is an e_instance
  the_soc_system_MemoryDMA_status_token_fifo : soc_system_MemoryDMA_status_token_fifo
    port map(
      status_token_fifo_empty => status_token_fifo_empty,
      status_token_fifo_full => status_token_fifo_full,
      status_token_fifo_q => status_token_fifo_q,
      clk => clk,
      reset => reset,
      status_token_fifo_data => status_token_fifo_data,
      status_token_fifo_rdreq => status_token_fifo_rdreq,
      status_token_fifo_wrreq => status_token_fifo_wrreq
    );


  --descriptor_read, which is an e_avalon_master
  --descriptor_write, which is an e_avalon_master
  --csr, which is an e_avalon_slave
  --m_read, which is an e_avalon_master
  --m_write, which is an e_avalon_master
  --the_soc_system_MemoryDMA_stream_fifo, which is an e_instance
  the_soc_system_MemoryDMA_stream_fifo : soc_system_MemoryDMA_stream_fifo
    port map(
      stream_fifo_empty => stream_fifo_empty,
      stream_fifo_full => stream_fifo_full,
      stream_fifo_q => stream_fifo_q,
      clk => clk,
      reset => reset,
      stream_fifo_data => stream_fifo_data,
      stream_fifo_rdreq => stream_fifo_rdreq,
      stream_fifo_wrreq => stream_fifo_wrreq
    );


  --connect up the source to the stream_fifo
  source_stream_ready <= NOT stream_fifo_full;
  stream_fifo_data <= Std_Logic_Vector'(A_ToStdLogicVector(source_stream_startofpacket) & A_ToStdLogicVector(source_stream_endofpacket) & source_stream_empty & source_stream_data);
  stream_fifo_wrreq <= source_stream_valid AND source_stream_ready;
  --connect up the sink to the stream_fifo
  stream_fifo_rdreq <= NOT stream_fifo_empty AND sink_stream_ready;
  sink_stream_startofpacket <= stream_fifo_q(35);
  sink_stream_endofpacket_from_fifo <= stream_fifo_q(34);
  sink_stream_endofpacket_sig <= ((sink_stream_endofpacket_from_fifo AND sink_stream_valid)) OR sink_stream_endofpacket_hold;
  sink_stream_endofpacket <= sink_stream_endofpacket_sig;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      sink_stream_endofpacket_hold <= std_logic'('0');
    elsif clk'event and clk = '1' then
      sink_stream_endofpacket_hold <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(((sink_stream_endofpacket_sig AND NOT sink_stream_ready))) = '1'), std_logic_vector'("00000000000000000000000000000001"), (A_WE_StdLogicVector((std_logic'(sink_stream_ready) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(sink_stream_endofpacket_hold)))))));
    end if;

  end process;

  sink_stream_data <= stream_fifo_q(31 DOWNTO 0);
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      sink_stream_valid_reg <= std_logic'('0');
    elsif clk'event and clk = '1' then
      sink_stream_valid_reg <= stream_fifo_rdreq;
    end if;

  end process;

  sink_stream_valid_out <= sink_stream_valid_reg OR sink_stream_valid_hold;
  sink_stream_valid <= sink_stream_valid_out;
  process (clk, reset_n)
  begin
    if reset_n = '0' then
      sink_stream_valid_hold <= std_logic'('0');
    elsif clk'event and clk = '1' then
      sink_stream_valid_hold <= Vector_To_Std_Logic(A_WE_StdLogicVector((std_logic'(((sink_stream_valid_out AND NOT sink_stream_ready))) = '1'), std_logic_vector'("00000000000000000000000000000001"), (A_WE_StdLogicVector((std_logic'(sink_stream_ready) = '1'), std_logic_vector'("00000000000000000000000000000000"), (std_logic_vector'("0000000000000000000000000000000") & (A_TOSTDLOGICVECTOR(sink_stream_valid_hold)))))));
    end if;

  end process;

  sink_stream_empty <= stream_fifo_q(33 DOWNTO 32);
  --vhdl renameroo for output signals
  csr_irq <= internal_csr_irq;
  --vhdl renameroo for output signals
  csr_readdata <= internal_csr_readdata;
  --vhdl renameroo for output signals
  descriptor_read_address <= internal_descriptor_read_address;
  --vhdl renameroo for output signals
  descriptor_read_read <= internal_descriptor_read_read;
  --vhdl renameroo for output signals
  descriptor_write_address <= internal_descriptor_write_address;
  --vhdl renameroo for output signals
  descriptor_write_write <= internal_descriptor_write_write;
  --vhdl renameroo for output signals
  descriptor_write_writedata <= internal_descriptor_write_writedata;
  --vhdl renameroo for output signals
  m_read_address <= internal_m_read_address;
  --vhdl renameroo for output signals
  m_read_read <= internal_m_read_read;
  --vhdl renameroo for output signals
  m_write_address <= internal_m_write_address;
  --vhdl renameroo for output signals
  m_write_byteenable <= internal_m_write_byteenable;
  --vhdl renameroo for output signals
  m_write_write <= internal_m_write_write;
  --vhdl renameroo for output signals
  m_write_writedata <= internal_m_write_writedata;

end europa;

