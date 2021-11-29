library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity tb_FSM_app is
end;

architecture bench of tb_FSM_app is

  component FSM_app
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

  uut: FSM_app port map ( a     => a,
                                    clk   => clk,
                                    rst   => rst,
                                    a_out => a_out );

  stimulus: process
  begin
  
    for I in 1 to 10 loop
       -- send sequence '0101'
       a <= '0';
       wait for 4ns;
       a <= '1';
       wait for 10ns;
       a <= '0';
       wait for 10ns;
       a <= '1';
       wait for 10ns;
       -- different sequence
       a <= '0';
       wait for 10ns;
       a <= '0';
       wait for 4ns;
       a <= '1';
       wait for 10ns;
       a <= '0';
       wait for 10ns;
       a <= '1';
       wait for 10ns;
       a <= '0';
       wait for 10ns;
       -- different sequence
       a <= '0';
       wait for 10ns;
       a <= '1';
       wait for 4ns;
       a <= '1';
       wait for 10ns;
       a <= '0';
       wait for 10ns;
       a <= '1';
       wait for 10ns;
       a <= '0';
       wait for 10ns;

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
