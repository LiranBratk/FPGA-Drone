-- unnamed.vhd

-- Generated using ACDS version 18.1 625

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity unnamed is
	port (
		probe  : in  std_logic_vector(0 downto 0) := (others => '0'); --  probes.probe
		source : out std_logic_vector(0 downto 0)                     -- sources.source
	);
end entity unnamed;

architecture rtl of unnamed is
	component altsource_probe_top is
		generic (
			sld_auto_instance_index : string  := "YES";
			sld_instance_index      : integer := 0;
			instance_id             : string  := "NONE";
			probe_width             : integer := 1;
			source_width            : integer := 1;
			source_initial_value    : string  := "0";
			enable_metastability    : string  := "NO"
		);
		port (
			source     : out std_logic_vector(0 downto 0);                    -- source
			probe      : in  std_logic_vector(0 downto 0) := (others => 'X'); -- probe
			source_ena : in  std_logic                    := 'X'              -- source_ena
		);
	end component altsource_probe_top;

begin

	in_system_sources_probes_0 : component altsource_probe_top
		generic map (
			sld_auto_instance_index => "YES",
			sld_instance_index      => 0,
			instance_id             => "NONE",
			probe_width             => 1,
			source_width            => 1,
			source_initial_value    => "0",
			enable_metastability    => "NO"
		)
		port map (
			source     => source, -- sources.source
			probe      => probe,  --  probes.probe
			source_ena => '1'     -- (terminated)
		);

end architecture rtl; -- of unnamed
