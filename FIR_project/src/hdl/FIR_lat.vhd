library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIR_lat is
    generic(
        AUDIO_DATA_WIDTH   : integer range 0 to 63 := 24;
        DATA_WIDTH         : integer range 0 to 63 := 32
    );
    port(
        clk : in std_logic;
        rst : in std_logic;

        -- axis slave
        s_axis_tdata  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;
        s_axis_tlast  : in  std_logic;

        -- axis master
        m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;
        m_axis_tlast  : out std_logic
    );
end entity FIR_lat;


architecture RTL of FIR_lat is

    constant zero_padding : std_logic_vector(DATA_WIDTH-AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

    type audio_reg_array is array (6 downto 0) of signed(AUDIO_DATA_WIDTH-1 downto 0);
    signal audio_data_shift_l : audio_reg_array := (others=>(others=>'0'));
    signal audio_data_shift_r : audio_reg_array := (others=>(others=>'0'));

    type coeff_array is array (6 downto 0) of integer range -32768 to 32767; --16 bits
    constant coeff : coeff_array := (1915, 5389, 8266, 9979, 8266, 5389, 1915);
    -- FIR filter, lpf fl-->4.8 kHz, att -30 db, 7 taps

    type res_mult_array is array (6 downto 0) of signed(AUDIO_DATA_WIDTH+16-1 downto 0);
    signal mult_reg_l : res_mult_array;
    signal mult_reg_r : res_mult_array;


    type data_array is array (0 to 1) of signed(AUDIO_DATA_WIDTH+16-1 downto 0);
    signal data : data_array;

    signal m_select     : integer range 0 to 1;
    signal m_new_word   : std_logic;
    signal m_new_packet : std_logic;

    signal s_select       : integer range 0 to 1;
    signal s_new_word     : std_logic;
    signal s_new_packet   : std_logic;
    signal s_new_packet_r : std_logic_vector(1 downto 0) := "00";

    signal m_axis_tvalid_r : std_logic;
    signal m_axis_tlast_r  : std_logic;

    signal s_axis_tready_r : std_logic := '1';


begin

    m_axis_tvalid <= m_axis_tvalid_r;
    m_axis_tlast  <= m_axis_tlast_r ;

    s_axis_tready <= s_axis_tready_r;

    process (m_axis_tlast_r, s_axis_tlast) is
    begin
        if (m_axis_tlast_r = '1') then
            m_select <= 1;
        else
            m_select <= 0;
        end if;
        if (s_axis_tlast = '1') then
            s_select <= 1;
        else
            s_select <= 0;
        end if;
    end process ;

    process (m_axis_tvalid_r, m_axis_tready)
    begin
        if (m_axis_tvalid_r = '1' and m_axis_tready = '1') then
            m_new_word <= '1';
        else
            m_new_word <= '0';
        end if;
    end process;

    process (m_new_word, m_axis_tlast_r)
    begin
        if (m_new_word = '1' and m_axis_tlast_r = '1') then
            m_new_packet <= '1';
        else
            m_new_packet <= '0';
        end if;
    end process;

    process (s_axis_tvalid, s_axis_tready_r)
    begin
        if (s_axis_tvalid = '1' and s_axis_tready_r = '1') then
            s_new_word <= '1';
        else
            s_new_word <= '0';
        end if;
    end process;

    process (s_new_word, s_axis_tlast)
    begin
        if (s_new_word = '1' and s_axis_tlast = '1') then
            s_new_packet <= '1';
        else
            s_new_packet <= '0';
        end if;
    end process;

    process (clk) is
    begin
        if rising_edge(clk) then
            s_new_packet_r(0) <= s_new_packet;
            s_new_packet_r(1) <= s_new_packet_r(0);
        end if;
    end process;

    shift_reg_p : process (clk) is
    begin
        if rising_edge(clk) then
            if (s_new_word = '1') then
                if (s_select = 1) then
                    audio_data_shift_r(0) <= signed(s_axis_tdata(AUDIO_DATA_WIDTH-1 downto 0));
                    audio_data_shift_r(1) <= audio_data_shift_r(0);
                    audio_data_shift_r(2) <= audio_data_shift_r(1);
                    audio_data_shift_r(3) <= audio_data_shift_r(2);
                    audio_data_shift_r(4) <= audio_data_shift_r(3);
                    audio_data_shift_r(5) <= audio_data_shift_r(4);
                    audio_data_shift_r(6) <= audio_data_shift_r(5);
                else
                    audio_data_shift_l(0) <= signed(s_axis_tdata(AUDIO_DATA_WIDTH-1 downto 0));
                    audio_data_shift_l(1) <= audio_data_shift_l(0);
                    audio_data_shift_l(2) <= audio_data_shift_l(1);
                    audio_data_shift_l(3) <= audio_data_shift_l(2);
                    audio_data_shift_l(4) <= audio_data_shift_l(3);
                    audio_data_shift_l(5) <= audio_data_shift_l(4);
                    audio_data_shift_l(6) <= audio_data_shift_l(5);
                end if;
            end if;
        end if;

    end process shift_reg_p;

    process (clk) is
    begin
        if rising_edge(clk) then
            if (s_new_packet_r(0) = '1') then

                mult_reg_l(0) <= audio_data_shift_l(0) * to_signed(coeff(0), 16);
                mult_reg_l(1) <= audio_data_shift_l(1) * to_signed(coeff(1), 16);
                mult_reg_l(2) <= audio_data_shift_l(2) * to_signed(coeff(2), 16);
                mult_reg_l(3) <= audio_data_shift_l(3) * to_signed(coeff(3), 16);
                mult_reg_l(4) <= audio_data_shift_l(4) * to_signed(coeff(4), 16);
                mult_reg_l(5) <= audio_data_shift_l(5) * to_signed(coeff(5), 16);
                mult_reg_l(6) <= audio_data_shift_l(6) * to_signed(coeff(6), 16);

                mult_reg_r(0) <= audio_data_shift_r(0) * to_signed(coeff(0), 16);
                mult_reg_r(1) <= audio_data_shift_r(1) * to_signed(coeff(1), 16);
                mult_reg_r(2) <= audio_data_shift_r(2) * to_signed(coeff(2), 16);
                mult_reg_r(3) <= audio_data_shift_r(3) * to_signed(coeff(3), 16);
                mult_reg_r(4) <= audio_data_shift_r(4) * to_signed(coeff(4), 16);
                mult_reg_r(5) <= audio_data_shift_r(5) * to_signed(coeff(5), 16);
                mult_reg_r(6) <= audio_data_shift_r(6) * to_signed(coeff(6), 16);

            elsif (s_new_packet_r(1) = '1') then

                data(0) <= mult_reg_l(0) + mult_reg_l(1) + mult_reg_l(2)
 + mult_reg_l(3) + mult_reg_l(4) + mult_reg_l(5) + mult_reg_l(6);
                data(1) <= mult_reg_r(0) + mult_reg_r(1) + mult_reg_r(2)
 + mult_reg_r(3) + mult_reg_r(4) + mult_reg_r(5) + mult_reg_r(6);

            end if;
        end if;
    end process;

    process (clk) is
    begin
        if rising_edge(clk) then
            if (s_new_packet_r(1) = '1') then
                m_axis_tvalid_r <= '1';
            elsif (m_new_packet = '1') then
                m_axis_tvalid_r <= '0';
            end if;
        end if;
    end process;

    process (clk) is
    begin
        if rising_edge(clk) then
            if (m_new_packet = '1') then
                m_axis_tlast_r <= '0';
            elsif (m_new_word = '1') then
                m_axis_tlast_r <= '1';
            end if;
        end if;
    end process;

    process (m_axis_tvalid_r, data, m_select) is
    begin
        if (m_axis_tvalid_r = '1') then
            m_axis_tdata <= zero_padding & std_logic_vector(data(m_select)(AUDIO_DATA_WIDTH+16-1 downto 16));
        else
            m_axis_tdata <= (others => '0');
        end if;
    end process;

    process (clk) is
    begin
        if rising_edge(clk) then
            if (s_new_packet = '1') then
                s_axis_tready_r <= '0';
            elsif (m_new_packet = '1') then
                s_axis_tready_r <= '1';
            end if;
        end if;
    end process;


end architecture RTL;