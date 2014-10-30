library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity video_ram is
    port
        ( clk  : in  std_logic
        ; we   : in  std_logic
        ; a    : in  std_logic_vector(15 downto 0)
        ; d    : in  std_logic_vector(15 downto 0)
        ; dpra : in  std_logic_vector(15 downto 0)
        ; dpo  : out std_logic_vector(15 downto 0)
        );
end video_ram;

architecture Behavioral of video_ram is

    subtype ram_cell_t is std_logic_vector(15 downto 0);
    type ram_t is array (16383 downto 0) of ram_cell_t;
    
    signal ram : ram_t;

begin

    process (clk, we, d) begin
        if rising_edge(clk) then
            if we = '0' then
                ram(to_integer(unsigned(a))) <= d;
            end if;
        end if;
    end process;
    
    process (clk, dpra) begin
        if rising_edge(clk) then
            dpo <= ram(to_integer(unsigned(dpra)));
        end if;
    end process;

end Behavioral;

