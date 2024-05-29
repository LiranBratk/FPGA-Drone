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

entity soc_system_onchip_memory2_1 is 
        generic (
                 INIT_FILE : STRING := "soc_system_onchip_memory2_1.hex"
                 );
        port (
              -- inputs:
                 signal address : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
                 signal byteenable : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
                 signal chipselect : IN STD_LOGIC;
                 signal clk : IN STD_LOGIC;
                 signal clken : IN STD_LOGIC;
                 signal freeze : IN STD_LOGIC;
                 signal reset : IN STD_LOGIC;
                 signal reset_req : IN STD_LOGIC;
                 signal write : IN STD_LOGIC;
                 signal writedata : IN STD_LOGIC_VECTOR (63 DOWNTO 0);

              -- outputs:
                 signal readdata : OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
              );
end entity soc_system_onchip_memory2_1;


architecture europa of soc_system_onchip_memory2_1 is
  component altsyncram is
GENERIC (
      byte_size : NATURAL;
        init_file : STRING;
        lpm_type : STRING;
        maximum_depth : NATURAL;
        numwords_a : NATURAL;
        operation_mode : STRING;
        outdata_reg_a : STRING;
        ram_block_type : STRING;
        read_during_write_mode_mixed_ports : STRING;
        read_during_write_mode_port_a : STRING;
        width_a : NATURAL;
        width_byteena_a : NATURAL;
        widthad_a : NATURAL
      );
    PORT (
    signal q_a : OUT STD_LOGIC_VECTOR (63 DOWNTO 0);
        signal wren_a : IN STD_LOGIC;
        signal byteena_a : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
        signal clock0 : IN STD_LOGIC;
        signal address_a : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
        signal clocken0 : IN STD_LOGIC;
        signal data_a : IN STD_LOGIC_VECTOR (63 DOWNTO 0)
      );
  end component altsyncram;
                signal clocken0 :  STD_LOGIC;
                signal internal_readdata :  STD_LOGIC_VECTOR (63 DOWNTO 0);
                signal wren :  STD_LOGIC;

begin

  wren <= chipselect AND write;
  clocken0 <= clken AND NOT reset_req;
  the_altsyncram : altsyncram
    generic map(
      byte_size => 8,
      init_file => INIT_FILE,
      lpm_type => "altsyncram",
      maximum_depth => 8192,
      numwords_a => 8192,
      operation_mode => "SINGLE_PORT",
      outdata_reg_a => "UNREGISTERED",
      ram_block_type => "AUTO",
      read_during_write_mode_mixed_ports => "DONT_CARE",
      read_during_write_mode_port_a => "DONT_CARE",
      width_a => 64,
      width_byteena_a => 8,
      widthad_a => 13
    )
    port map(
            address_a => address,
            byteena_a => byteenable,
            clock0 => clk,
            clocken0 => clocken0,
            data_a => writedata,
            q_a => internal_readdata,
            wren_a => wren
    );

  --s1, which is an e_avalon_slave
  --s2, which is an e_avalon_slave
  --vhdl renameroo for output signals
  readdata <= internal_readdata;

end europa;

