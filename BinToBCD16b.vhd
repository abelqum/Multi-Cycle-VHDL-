library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binbcd16 is -- Renamed entity for clarity
    Port (
        clk     : in  std_logic;
        reset   : in  std_logic; -- Assuming active-low ('0')
        binario : in  STD_LOGIC_VECTOR (15 downto 0); -- 16 bits (0-65535)
        bcd     : out STD_LOGIC_VECTOR (15 downto 0)  -- 4 BCD digits (16 bits)
    );
end binbcd16;

architecture Behavioral of binbcd16 is
begin
    process(clk, reset)
        -- Variable range 0-9999 is sufficient for 4 BCD digits
        -- but using 0-65535 still works if input exceeds 9999
        variable temp_int : integer range 0 to 65535;
    begin
        if reset = '0' then
            bcd <= (others => '0');
        elsif rising_edge(clk) then
            -- Limit input to 9999 if strictly 4 digits needed, otherwise use full value
            if to_integer(unsigned(binario)) > 9999 then
                 temp_int := 9999; -- Or handle overflow display differently
            else
                 temp_int := to_integer(unsigned(binario));
            end if;

            -- Extract 4 BCD digits
            bcd(15 downto 12) <= std_logic_vector(to_unsigned(temp_int / 1000, 4));         -- Mil
            bcd(11 downto 8)  <= std_logic_vector(to_unsigned((temp_int mod 1000) / 100, 4));  -- Cien
            bcd(7 downto 4)   <= std_logic_vector(to_unsigned((temp_int mod 100) / 10, 4));   -- Diez
            bcd(3 downto 0)   <= std_logic_vector(to_unsigned(temp_int mod 10, 4));          -- Uno
        end if;
    end process;
end Behavioral;