library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FIR_MAC is
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
end entity FIR_MAC;


architecture RTL of FIR_MAC is

    type audio_reg_array is array (6 downto 0) of signed(AUDIO_DATA_WIDTH-1 downto 0);
    signal audio_data_shift_l : audio_reg_array := (others=>(others=>'0'));
    signal audio_data_shift_r : audio_reg_array := (others=>(others=>'0'));

    type coeff_array is array (6 downto 0) of integer range -32768 to 32767; --16 bits
    constant coeff : coeff_array := (1915, 5389, 8266, 9979, 8266, 5389, 1915);
    -- FIR filter, lpf fl-->4.8 kHz, att -30 db, 7 taps


    type state_type is (idle, mult_0, mult_1, mult_2, mult_3, mult_4, mult_5, mult_6, send_data);
    signal state : state_type := idle;

    signal res_l, res_r : signed(AUDIO_DATA_WIDTH+16-1 downto 0) := (others => '0');

    signal sel : std_logic;

    constant  zero_padding : std_logic_vector(DATA_WIDTH-AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');
    signal m_axis_tvalid_r : std_logic;
    signal m_axis_tlast_r  : std_logic;

    signal s_axis_tready_r : std_logic := '1';


begin

    m_axis_tvalid <= m_axis_tvalid_r;
    m_axis_tlast  <= m_axis_tlast_r ;

    s_axis_tready <= s_axis_tready_r;

    shift_reg_p : process (clk) is
    begin
        if rising_edge(clk) then
            if (s_axis_tvalid = '1' and s_axis_tready_r = '1') then
                if (s_axis_tlast = '1') then
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

    MAC_p : process (clk, rst) is
    begin
        if (rst = '1') then
            state <= idle;
            s_axis_tready_r <= '0';
            m_axis_tvalid_r <= '0';
            res_l   <=  (others => '0') ;
            res_r   <=  (others => '0') ;
            sel     <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    s_axis_tready_r <= '1';
                    m_axis_tvalid_r <= '0';
                    res_l   <=  (others => '0') ;
                    res_r   <=  (others => '0') ;
                    if (s_axis_tvalid = '1') then
                        sel <= s_axis_tlast;
                        state <= mult_0;
                    end if;
                when mult_0 =>
                    s_axis_tready_r <= '0';
                    m_axis_tvalid_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(0) * to_signed(coeff(0), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(0) * to_signed(coeff(0), 16));
                    end if;
                    state <= mult_1;
                when mult_1 =>
                    s_axis_tready_r <= '0';
                    m_axis_tvalid_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(1) * to_signed(coeff(1), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(1) * to_signed(coeff(1), 16));
                    end if;
                    state <= mult_2;
                when mult_2 =>
                    s_axis_tready_r <= '0';
                    m_axis_tvalid_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(2) * to_signed(coeff(2), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(2) * to_signed(coeff(2), 16));
                    end if;
                    state <= mult_3;
                when mult_3 =>
                    s_axis_tready_r <= '0';
                    m_axis_tvalid_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(3) * to_signed(coeff(3), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(3) * to_signed(coeff(3), 16));
                    end if;
                    state <= mult_4;
                when mult_4 =>
                    s_axis_tready_r <= '0';
                    m_axis_tvalid_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(4) * to_signed(coeff(4), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(4) * to_signed(coeff(4), 16));
                    end if;
                    state <= mult_5;
                when mult_5 =>
                    s_axis_tready_r <= '0';
                    m_axis_tvalid_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(5) * to_signed(coeff(5), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(5) * to_signed(coeff(5), 16));
                    end if;
                    state <= mult_6;
                when mult_6 =>
                    s_axis_tready_r <= '0';
                    if (sel = '1') then
                        res_r <= res_r + (audio_data_shift_r(6) * to_signed(coeff(6), 16));
                    else
                        res_l <= res_l + (audio_data_shift_l(6) * to_signed(coeff(6), 16));
                    end if;
                    if (m_axis_tready = '1') then
                        m_axis_tvalid_r <= '1';
                        state <= idle;
                    else
                        m_axis_tvalid_r <= '0';
                        state <= send_data;
                    end if;
                    state <= idle;
                when send_data =>
                    s_axis_tready_r <= '0';
                    if (m_axis_tready = '1') then
                        m_axis_tvalid_r <= '1';
                        state <= idle;
                    else
                        m_axis_tvalid_r <= '0';
                        state <= send_data;
                    end if;
            end case;
        end if;

    end process MAC_p;

    result_p : process (res_l, res_r, sel) is
    begin
        if (sel = '1') then
            m_axis_tdata <= zero_padding & std_logic_vector(res_r(AUDIO_DATA_WIDTH+16-1 downto 16));
        else
            m_axis_tdata <= zero_padding & std_logic_vector(res_l(AUDIO_DATA_WIDTH+16-1 downto 16));
        end if;
    end process result_p;

    m_axis_tlast_r <= sel and m_axis_tvalid_r;

end architecture RTL;

