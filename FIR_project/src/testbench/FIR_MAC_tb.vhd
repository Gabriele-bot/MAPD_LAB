library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity FIR_MAC_tb is
end;

architecture bench of FIR_MAC_tb is

    component FIR_MAC
        generic(
            AUDIO_DATA_WIDTH   : integer range 0 to 63 := 24;
            DATA_WIDTH         : integer range 0 to 63 := 32
        );
        port(
            clk : in std_logic;
            rst : in std_logic;
            s_axis_tdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            s_axis_tvalid : in  std_logic;
            s_axis_tready : out std_logic;
            s_axis_tlast  : in  std_logic;
            m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            m_axis_tvalid : out std_logic;
            m_axis_tready : in  std_logic;
            m_axis_tlast  : out std_logic
        );
    end component;

    constant AUDIO_DATA_WIDTH   : integer range 0 to 63 := 24;
    constant DATA_WIDTH         : integer range 0 to 63 := 32;

    signal clk: std_logic;
    signal rst: std_logic;
    signal s_axis_tdata: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal s_axis_tvalid: std_logic;
    signal s_axis_tready: std_logic;
    signal s_axis_tlast: std_logic;
    signal m_axis_tdata: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal m_axis_tvalid: std_logic;
    signal m_axis_tready: std_logic;
    signal m_axis_tlast: std_logic ;

    constant clock_period: time := 10 ns ;
    constant data_gap    : time := 150 ns;
    signal stop_the_clock: boolean;

begin

    -- Insert values for generic parameters !!
    uut: FIR_MAC generic map ( AUDIO_DATA_WIDTH => AUDIO_DATA_WIDTH,
                    DATA_WIDTH       => DATA_WIDTH )
        port map ( clk              => clk,
                 rst              => rst,
                 s_axis_tdata     => s_axis_tdata,
                 s_axis_tvalid    => s_axis_tvalid,
                 s_axis_tready    => s_axis_tready,
                 s_axis_tlast     => s_axis_tlast,
                 m_axis_tdata     => m_axis_tdata,
                 m_axis_tvalid    => m_axis_tvalid,
                 m_axis_tready    => m_axis_tready,
                 m_axis_tlast     => m_axis_tlast );

    stimulus: process
    begin

        -- Put initialisation code here
        stop_the_clock <= false;
        rst <= '0';
        s_axis_tdata  <= ( others => '0') ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        m_axis_tready <= '0';
        wait for 50 ns;

        -- Put test bench stimulus code here
        m_axis_tready <= '1';

        s_axis_tdata  <= ( others => '0') ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '0';
        wait for 10 ns;
        s_axis_tdata  <= ( others => '0') ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;
        s_axis_tdata  <= ( others => '0') ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '1';
        wait for 10 ns;
        s_axis_tdata  <= ( others => '0') ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;

        s_axis_tdata  <=  x"00004000" ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '0';
        wait for 10 ns;
        s_axis_tdata  <=  x"00004000"  ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;
        s_axis_tdata  <=  x"00004000" ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '1';
        wait for 10 ns;
        s_axis_tdata  <=  x"00004000"  ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;

        s_axis_tdata  <=  x"00008000"  ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '0';
        wait for 10 ns;
        s_axis_tdata  <=  x"00008000"  ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;
        s_axis_tdata  <=  x"00008000" ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '1';
        wait for 10 ns;
        s_axis_tdata  <=  x"00008000"  ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;

        s_axis_tdata  <=  x"0000f000"  ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '0';
        wait for 10 ns;
        s_axis_tdata  <=  x"0000f000"  ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;
        s_axis_tdata  <=  x"0000f000" ;
        s_axis_tvalid <= '1';
        s_axis_tlast  <= '1';
        wait for 10 ns;
        s_axis_tdata  <=  x"0000f000"  ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        wait for data_gap;

        for i in 0 to 100 loop
            s_axis_tdata  <=  x"0000f000"  ;
            s_axis_tvalid <= '1';
            s_axis_tlast  <= '0';
            wait for 10 ns;
            s_axis_tdata  <=  x"0000f000"  ;
            s_axis_tvalid <= '0';
            s_axis_tlast  <= '0';
            wait for data_gap;
            s_axis_tdata  <=  x"0000f000" ;
            s_axis_tvalid <= '1';
            s_axis_tlast  <= '1';
            wait for 10 ns;
            s_axis_tdata  <=  x"0000f000"  ;
            s_axis_tvalid <= '0';
            s_axis_tlast  <= '0';
            wait for data_gap;
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

end bench;