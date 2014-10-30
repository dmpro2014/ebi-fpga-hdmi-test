----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: dvid_test 
--  Top level design for testing my DVI-D interface
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity dvid_test is
    Port ( clk_50  : in  STD_LOGIC;
           tmds    : out  STD_LOGIC_VECTOR(3 downto 0);
           tmdsb   : out  STD_LOGIC_VECTOR(3 downto 0);
      write_enable : in std_logic;
      write_addr : in std_logic_vector(15 downto 0);
      write_data : in std_logic_vector(15 downto 0);
      
      led_1 : out std_logic;
      led_2 : out std_logic;
      led_3 : out std_logic;
      led_4 : out std_logic);

end dvid_test;

architecture Behavioral of dvid_test is
   component clocking
   port (
      -- Clock in ports
      CLK_IN1           : in     std_logic;
      -- Clock out ports
      CLK_OUT1          : out    std_logic;
      CLK_OUT2         : out    std_logic;
      CLK_OUT3          : out    std_logic   );
   end component;

   COMPONENT dvid
   PORT(
      clk      : IN std_logic;
      clk_n    : IN std_logic;
      clk_pixel: IN std_logic;
      red_p   : IN std_logic_vector(7 downto 0);
      green_p : IN std_logic_vector(7 downto 0);
      blue_p  : IN std_logic_vector(7 downto 0);
      blank   : IN std_logic;
      hsync   : IN std_logic;
      vsync   : IN std_logic;          
      red_s   : OUT std_logic;
      green_s : OUT std_logic;
      blue_s  : OUT std_logic;
      clock_s : OUT std_logic
      );
   END COMPONENT;

   signal clk_dvi  : std_logic := '0';
   signal clk_dvin : std_logic := '0';
   signal clk_vga  : std_logic := '0';

   signal red     : std_logic_vector(7 downto 0) := (others => '0');
   signal green   : std_logic_vector(7 downto 0) := (others => '0');
   signal blue    : std_logic_vector(7 downto 0) := (others => '0');
   signal hsync   : std_logic := '0';
   signal vsync   : std_logic := '0';
   signal blank   : std_logic := '0';
   signal red_s   : std_logic;
   signal green_s : std_logic;
   signal blue_s  : std_logic;
   signal clock_s : std_logic;
   
   signal blit_state : std_logic;
   signal blit_choice : std_logic;

   signal write_enable1 : std_logic;
   signal read_data1 : std_logic_vector(15 downto 0);

   signal write_enable2 : std_logic;
   signal read_data2 : std_logic_vector(15 downto 0);

   signal read_addr : std_logic_vector(15 downto 0);
   signal read_data : std_logic_vector(15 downto 0);
   
   signal clk_ebi : std_logic;
begin
   
   led_1 <= '0';
   led_2 <= '0';
   led_3 <= write_enable;
   led_4 <= blit_state;
   
   clk_ebi <= clk_dvi;
   
   
clocking_inst : clocking port map (
      CLK_IN1  => clk_50,
      -- Clock out ports
      CLK_OUT1 => clk_dvi,  -- for 640x480@60Hz : 125MHZ
      CLK_OUT2 => clk_dvin, -- for 640x480@60Hz : 125MHZ, 180 degree phase shift
      CLK_OUT3 => clk_vga   -- for 640x480@60Hz : 25MHZ 
    );

Inst_dvid: dvid PORT MAP(
      clk       => clk_dvi,
      clk_n     => clk_dvin, 
      clk_pixel => clk_vga,
      red_p     => red,
      green_p   => green,
      blue_p    => blue,
      blank     => blank,
      hsync     => hsync,
      vsync     => vsync,
      -- outputs to TMDS drivers
      red_s     => red_s,
      green_s   => green_s,
      blue_s    => blue_s,
      clock_s   => clock_s
   );
   
OBUFDS_blue  : OBUFDS port map ( O  => TMDS(0), OB => TMDSB(0), I  => blue_s  );
OBUFDS_red   : OBUFDS port map ( O  => TMDS(1), OB => TMDSB(1), I  => green_s );
OBUFDS_green : OBUFDS port map ( O  => TMDS(2), OB => TMDSB(2), I  => red_s   );
OBUFDS_clock : OBUFDS port map ( O  => TMDS(3), OB => TMDSB(3), I  => clock_s );
    -- generic map ( IOSTANDARD => "DEFAULT")    
   
Inst_vga: entity work.vga GENERIC MAP (
      hRez       => 640, hStartSync => 656, hEndSync   => 752, hMaxCount  => 800, hsyncActive => '0',
      vRez       => 480, vStartSync => 490, vEndSync   => 492, vMaxCount  => 525, vsyncActive => '1'
   ) PORT MAP(
      pixelClock => clk_vga,
      Red        => red,
      Green      => green,
      Blue       => blue,
      hSync      => hSync,
      vSync      => vSync,
      blank      => blank,
      
      read_addr  => read_addr,
      read_data  => read_data
   );
   
process (clk_ebi, write_addr, write_data, write_enable) begin
    if rising_edge(clk_ebi) then
        if write_addr = X"ffff" and write_enable = '0' then
            blit_state <= write_data(0);
        end if;
    end if;
end process;

process (clk_ebi, blit_state, vSync) begin
    if rising_edge(clk_ebi) then
        if vSync = '1' then
            blit_choice <= blit_state;
        end if;
    end if;
end process;

process (blit_state, write_enable, write_addr) begin
    if blit_state = '0' then
        write_enable1 <= write_enable;
        write_enable2 <= '1';
    else
        write_enable1 <= '1';
        write_enable2 <= write_enable;
    end if;
    
    if write_addr = X"ffff" then
        write_enable1 <= '1';
        write_enable2 <= '1';
    end if;
end process;

process (blit_choice, read_data2, read_data1) begin
    if blit_choice = '0' then
        read_data <= read_data2;
    else
        read_data <= read_data1;
    end if;
end process;

video_ram_inst1:
    entity work.video_ram
        port map
            ( clk => clk_ebi
            , we => write_enable1
            , a => write_addr
            , d => write_data
            
            , dpra => read_addr
            , dpo => read_data1
            );

video_ram_inst2:
    entity work.video_ram
        port map
            ( clk => clk_ebi
            , we => write_enable2
            , a => write_addr
            , d => write_data
            
            , dpra => read_addr
            , dpo => read_data2
            );

end Behavioral;
