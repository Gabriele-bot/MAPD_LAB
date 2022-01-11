library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;
use std.textio.all;

entity FIR_lat_tb is
end;

architecture bench of FIR_lat_tb is

    component FIR_lat
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

    signal ena : std_logic := '0';
    signal value1_std_logic_24_bit : std_logic_vector(23 downto 0) := ( others => '0');
    signal value2_std_logic_24_bit : std_logic_vector(23 downto 0) := ( others => '0');
    signal file_in_end : boolean := false;


    constant tolerance : signed(23 downto 0) := to_signed(2,24);
    signal enb : std_logic := '0';
    signal value1_std_logic_24_bit_out : std_logic_vector(23 downto 0) := ( others => '0');
    signal value1_up_out               : std_logic_vector(23 downto 0) := ( others => '0');
    signal value1_down_out             : std_logic_vector(23 downto 0) := ( others => '0');
    signal value2_std_logic_24_bit_out : std_logic_vector(23 downto 0) := ( others => '0');
    signal value2_up_out               : std_logic_vector(23 downto 0) := ( others => '0');
    signal value2_down_out             : std_logic_vector(23 downto 0) := ( others => '0');
    signal file_out_end : boolean := false;
    
    signal value1_fir_24_bit_out : std_logic_vector(23 downto 0) := ( others => '0');
    signal value2_fir_24_bit_out : std_logic_vector(23 downto 0) := ( others => '0');

    constant clock_period: time := 10 ns ;
    constant data_gap    : time := 4 * clock_period;
    signal stop_the_clock: boolean;

    signal err_cnt : unsigned(15 downto 0) := ( others => '0');

begin

    -- Insert values for generic parameters !!
    uut: FIR_lat generic map ( AUDIO_DATA_WIDTH => AUDIO_DATA_WIDTH,
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

    read_in_p : process (clk, rst) is
        ---------------------------------------------------------------------------------------------------------

        constant NUM_COL                : integer := 2;   -- number of column of file

        type t_integer_array       is array(integer range <> )  of integer;
        file test_vector                : text open read_mode is "input_file.txt";
        variable row                    : line;
        variable v_data_read            : t_integer_array(1 to NUM_COL);
        variable v_data_row_counter     : integer := 0;

        -----------------------------------------------------------------------------------------------------------
    begin
        if(rst='1') then
            v_data_row_counter     := 0;
            v_data_read            := (others=> -1);
        ------------------------------------
        elsif(rising_edge(clk)) then

            if (endfile(test_vector)) then
                file_in_end <= true;
            end if;

            if(ena = '1') then  -- external enable signal

                -- read from input file in "row" variable
                if(not endfile(test_vector)) then
                    v_data_row_counter := v_data_row_counter + 1;
                    readline(test_vector,row);
                end if;

                -- read integer number from "row" variable in integer array
                for kk in 1 to NUM_COL loop
                    read(row,v_data_read(kk));
                end loop;
                value1_std_logic_24_bit    <= std_logic_vector(to_signed(v_data_read(1),24));
                value2_std_logic_24_bit    <= std_logic_vector(to_signed(v_data_read(2),24));
            end if;

        end if;
    end process read_in_p;

    read_out_p : process (clk, rst) is
        ---------------------------------------------------------------------------------------------------------

        constant NUM_COL                : integer := 2;   -- number of column of file

        type t_integer_array       is array(integer range <> )  of integer;
        file test_vector                : text open read_mode is "output_file.txt";
        variable row                    : line;
        variable v_data_read            : t_integer_array(1 to NUM_COL);
        variable v_data_row_counter     : integer := 0;

        -----------------------------------------------------------------------------------------------------------
    begin
        if(rst='1') then
            v_data_row_counter     := 0;
            v_data_read            := (others=> -1);
        ------------------------------------
        elsif(rising_edge(clk)) then

            if(enb = '1') then  -- external enable signal

                -- read from input file in "row" variable
                if(not endfile(test_vector)) then
                    v_data_row_counter := v_data_row_counter + 1;
                    readline(test_vector,row);
                else
                    file_out_end <= true;
                end if;

                -- read integer number from "row" variable in integer array
                for kk in 1 to NUM_COL loop
                    read(row,v_data_read(kk));
                end loop;
                value1_std_logic_24_bit_out    <= std_logic_vector(to_signed(v_data_read(1),24));
                value2_std_logic_24_bit_out    <= std_logic_vector(to_signed(v_data_read(2),24));
            end if;

        end if;
    end process read_out_p;

    stimulus: process

    begin

        -- Put initialisation code here
        stop_the_clock <= false;
        rst <= '0';
        ena <= '0';
        enb <= '0';
        s_axis_tdata  <= ( others => '0') ;
        s_axis_tvalid <= '0';
        s_axis_tlast  <= '0';
        m_axis_tready <= '0';
        wait for 50 ns;

        -- Put test bench stimulus code here
        m_axis_tready <= '1';

        while (not file_in_end) loop
            ena <= '1';
            enb <= '1';
            wait for clock_period;
            ena <= '0';
            enb <= '0';

            s_axis_tdata  <= X"00" & value1_std_logic_24_bit ;
            s_axis_tvalid <= '1';
            s_axis_tlast  <= '0';
            wait for clock_period;
            s_axis_tdata  <= ( others => '0') ;
            s_axis_tvalid <= '0';
            s_axis_tlast  <= '0';
            wait for data_gap;
            s_axis_tdata  <= X"00" & value2_std_logic_24_bit ;
            s_axis_tvalid <= '1';
            s_axis_tlast  <= '1';
            wait for clock_period;
            s_axis_tdata  <= ( others => '0') ;
            s_axis_tvalid <= '0';
            s_axis_tlast  <= '0';

            exit when file_in_end;

            wait for data_gap;

        end loop;
        
        wait until (m_axis_tvalid = '1' and m_axis_tlast = '1');
        wait for 2*clock_period;

        report "Total errors found = " & integer'image(to_integer(err_cnt));

        if file_in_end then
            stop_the_clock <= true;
        end if;

        wait;
    end process;

    value1_up_out   <= std_logic_vector(signed(value1_std_logic_24_bit_out) + tolerance);
    value1_down_out <= std_logic_vector(signed(value1_std_logic_24_bit_out) - tolerance);
    value2_up_out   <= std_logic_vector(signed(value2_std_logic_24_bit_out) + tolerance);
    value2_down_out <= std_logic_vector(signed(value2_std_logic_24_bit_out) - tolerance);

    check_data_p : process (clk) is
        ---------------------------------------------------------------------------------------------------------

        file test_vector                : text open write_mode is "output_file_fir.txt";
        variable row                    : line;
        -----------------------------------------------------------------------------------------------------------
    begin

        if(rising_edge(clk)) then
            if (m_axis_tvalid = '1' and m_axis_tlast = '0') then
                value1_fir_24_bit_out <= m_axis_tdata(23 downto 0);
                if (signed(m_axis_tdata(23 downto 0)) < signed(value1_down_out))then
                    report "Left output does not match, expected " & integer'image(to_integer(signed(value1_std_logic_24_bit_out))) 
                    & " got " & integer'image(to_integer(signed(m_axis_tdata(23 downto 0)))) severity warning;
                    err_cnt <= err_cnt + X"0001";
                elsif (signed(m_axis_tdata(23 downto 0)) > signed(value1_up_out)) then
                    report "Left output does not match, expected " & integer'image(to_integer(signed(value1_std_logic_24_bit_out))) 
                    & " got " & integer'image(to_integer(signed(m_axis_tdata(23 downto 0)))) severity warning;
                    err_cnt <= err_cnt + X"0001";
                end if;
            elsif (m_axis_tvalid = '1' and m_axis_tlast = '1') then
                write(row, to_integer(signed(value1_fir_24_bit_out))    , right, 15);
                write(row, to_integer(signed(m_axis_tdata(23 downto 0))), right, 15);
                writeline(test_vector,row);
                value2_fir_24_bit_out <= m_axis_tdata(23 downto 0);
                if (signed(m_axis_tdata(23 downto 0)) < signed(value2_down_out))then
                    report "Right output does not match, expected " & integer'image(to_integer(signed(value2_std_logic_24_bit_out))) 
                    & " got " & integer'image(to_integer(signed(m_axis_tdata(23 downto 0)))) severity warning;
                    err_cnt <= err_cnt + X"0001";
                elsif (signed(m_axis_tdata(23 downto 0)) > signed(value2_up_out)) then
                    report "Right output does not match, expected " & integer'image(to_integer(signed(value2_std_logic_24_bit_out))) 
                    & " got " & integer'image(to_integer(signed(m_axis_tdata(23 downto 0)))) severity warning;
                    err_cnt <= err_cnt + X"0001";
                end if;
            end if;
        end if;

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
