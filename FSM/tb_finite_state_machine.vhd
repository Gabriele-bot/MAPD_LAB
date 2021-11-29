-- Testbench created online at:
--   https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos Ltd

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_finite_state_machine is
end;

architecture bench of tb_finite_state_machine is

  component finite_state_machine
      Port ( a : in STD_LOGIC;
             clk : in STD_LOGIC;
             rst : in STD_LOGIC;
             a_out : out STD_LOGIC);
  end component;

  signal a: STD_LOGIC;
  signal clk: STD_LOGIC;
  signal rst: STD_LOGIC;
  signal a_out: STD_LOGIC;

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  uut: finite_state_machine port map ( a     => a,
                                    clk   => clk,
                                    rst   => rst,
                                    a_out => a_out );

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
  
  resetting: process
  begin
       rst <= '0';
       wait for 33ns;
       rst <= '1';
       wait for 43ns;
       rst <= '0';
       wait;
  end process;

end;
