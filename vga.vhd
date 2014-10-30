----------------------------------------------------------------------------------
-- Engineer:       Mike Field <hamster@snap.net.nz>
-- Module Name:    ColourTest - Behavioral 
-- Description:    Generates an 640x480 VGA showing all colours
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity vga is
   generic (
      hRez       : natural := 640;	
      hStartSync : natural := 656;
      hEndSync   : natural := 752;
      hMaxCount  : natural := 800;
      hsyncActive : std_logic := '0';
		
      vRez       : natural := 480;
      vStartSync : natural := 490;
      vEndSync   : natural := 492;
      vMaxCount  : natural := 525;
      vsyncActive : std_logic := '1'
   );

    Port ( pixelClock : in  STD_LOGIC;
           Red        : out STD_LOGIC_VECTOR (7 downto 0);
           Green      : out STD_LOGIC_VECTOR (7 downto 0);
           Blue       : out STD_LOGIC_VECTOR (7 downto 0);
           hSync      : out STD_LOGIC;
           vSync      : out STD_LOGIC;
           blank      : out STD_LOGIC;
           read_addr : out std_logic_vector(15 downto 0);
           read_data : in std_logic_vector(15 downto 0)
           );
end vga;

architecture Behavioral of vga is
   type reg is record
      hCounter : std_logic_vector(11 downto 0);
      vCounter : std_logic_vector(11 downto 0);

      red      : std_logic_vector(7 downto 0);
      green    : std_logic_vector(7 downto 0);
      blue     : std_logic_vector(7 downto 0);

      hSync    : std_logic;
      vSync    : std_logic;
      blank    : std_logic;		
   end record;

   signal r : reg := ((others=>'0'), (others=>'0'),
                      (others=>'0'), (others=>'0'), (others=>'0'), 
                      '0', '0', '0');
   signal n : reg;   
begin
   -- Assign the outputs
   hSync <= r.hSync;
   vSync <= r.vSync;
   Red   <= r.red;
   Green <= r.green;
   Blue  <= r.blue;
   blank <= r.blank;
   
   read_addr <= std_logic_vector(resize(
                        unsigned(n.vCounter) * to_unsigned(128, 16) + unsigned(n.hCounter)
                        ,16));
   
   process(r,n,read_data)
   begin
      n <= r;
      n.hSync <= not hSyncActive;      
      n.vSync <= not vSyncActive;      

      -- Count the lines and rows      
      if r.hCounter = hMaxCount-1 then
         n.hCounter <= (others => '0');
         if r.vCounter = vMaxCount-1 then
            n.vCounter <= (others => '0');
         else
            n.vCounter <= r.vCounter+1;
         end if;
      else
         n.hCounter <= r.hCounter+1;
      end if;

      if r.hCounter  < hRez and r.vCounter  < vRez then
        if r.hCounter  < 128 and r.vCounter  < 128 then
         n.red   <= read_data(15 downto 11) & "000";
         n.green <= read_data(10 downto 5) & "00";
         n.blue  <= read_data(4 downto 0) & "000";
        else
         n.red   <= (others => '1');
         n.green <= (others => '1');
         n.blue  <= (others => '1');
        end if;
         n.blank <= '0';
         
      else
         n.red   <= (others => '0');
         n.green <= (others => '0');
         n.blue  <= (others => '0');
         n.blank <= '1';
      end if;
      
      -- Are we in the hSync pulse?
      if r.hCounter >= hStartSync and r.hCounter < hEndSync then
         n.hSync <= hSyncActive;
      end if;

      -- Are we in the vSync pulse?
      if r.vCounter >= vStartSync and r.vCounter < vEndSync then
         n.vSync <= vSyncActive; 
      end if;
   end process;

   process(pixelClock,n)
   begin
      if rising_edge(pixelClock)
      then
         r <= n;
      end if;
   end process;
end Behavioral;
