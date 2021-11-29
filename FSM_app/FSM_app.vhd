library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FSM_app is
    Port ( a : in STD_LOGIC;
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           a_out : out STD_LOGIC);
end FSM_app;

architecture Behavioral of FSM_app is
-- States definitions as before
type state_type is (ST0, ST1, ST2, ST3, Det);
signal state : state_type;

begin
	sync_proc : process(clk)
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				state <= ST0;
				a_out <= '0'; -- pre-assign
			else
				case state is
				when ST0 => 
					a_out <= '0'; 
					if (a = '0') then state <= ST1;
					end if;
				when ST1 => 
					a_out <= '0';
					if (a = '1') then state <= ST2;
					end if;
				when ST2 => 
					a_out <= '0';
					if (a = '1') then state <= ST0;
					elsif (a = '0') then state <= ST3;
					end if;
				when ST3 =>
					a_out <= '0';
					if (a = '0') then state <= ST1;
					elsif (a = '1') then state <= Det;
					end if;
				when Det =>
					a_out <= '1';
					state <= ST0;
				when others =>
					a_out <= '0'; 
					state <= ST0; 
				end case;
			end if;
		end if;
	end process sync_proc;
end Behavioral;
