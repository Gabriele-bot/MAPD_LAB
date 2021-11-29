-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_clk_sync is
end;

architecture bench of tb_clk_sync is

  component clk_sync
      Port ( a : in STD_LOGIC;
             clk : in STD_LOGIC;
             sync_a : out STD_LOGIC);
  end component;

  signal a: STD_LOGIC;
  signal clk: STD_LOGIC;
  signal sync_a: STD_LOGIC;

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  uut: clk_sync port map ( a      => a,
                                   clk    => clk,
                                   sync_a => sync_a );

  stimulus: process
  begin
  
    for I in 1 to 10 loop
       a <= '0';
       wait for 33ns;
       a <= '1';
       wait for 33ns;
    end loop;

    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;
