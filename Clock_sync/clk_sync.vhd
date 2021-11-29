-- library imports
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_sync is
    Port ( a : in STD_LOGIC;
           clk : in STD_LOGIC;
           sync_a : out STD_LOGIC);
end clk_sync;

architecture Behavioral of clk_sync is

-- intern signals definition
signal intern : STD_LOGIC := '0'; -- set its initial value to 0

begin

sync_ffp : process(clk)
begin 
if rising_edge (clk)  then 
   intern <= a;
   sync_a <= intern;
end if;
end process;

end Behavioral;
