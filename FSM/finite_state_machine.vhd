library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity finite_state_machine is
    Port ( a : in STD_LOGIC;
           clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           a_out : out STD_LOGIC);
end finite_state_machine;

architecture Behavioral of finite_state_machine is
-- new type definition
type state_type is (ST0, ST1);
-- signal definitions
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
				-- Set the outputs accordingly to the state
				a_out <= '0';
  				-- Change state if needed
				if (a = '1') then state <= ST1;
				end if;
			when ST1 =>
				-- Set the outputs accordingly to the state
				a_out <= '1';
				-- Change state if needed
				if (a = '1') then state <= ST0;
				end if;
			when others => -- the catch-all condition
				a_out <= '0'; -- arbitrary; it should never
				state <= ST0; -- make it to these two statements
			end case;
		end if;
	end if;
	end process sync_proc;
end Behavioral;
