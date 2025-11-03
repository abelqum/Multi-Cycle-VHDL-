library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity binbcd16 is
    Port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        binario : in  STD_LOGIC_VECTOR (15 downto 0);
        signo   : in  std_logic;
        bcd     : out STD_LOGIC_VECTOR (15 downto 0)
    );
end binbcd16;



architecture Behavioral of binbcd16 is
begin
    process(clk, reset)
        variable temp_int : integer range -32768 to 32767;
        variable abs_value : integer range 0 to 32768;
        variable is_negative : boolean;
    begin
        if reset = '0' then
            bcd <= (others => '0');
        elsif rising_edge(clk) then
            -- Convertir a entero con signo
            temp_int := to_integer(signed(binario));
            
            -- Determinar si es negativo y tomar valor absoluto
            if temp_int < 0 then
                is_negative := true;
                abs_value := -temp_int;  -- Valor absoluto
            else
                is_negative := false;
                abs_value := temp_int;
            end if;
            
         
            -- Extraer 4 dígitos BCD del valor absoluto
            bcd(15 downto 12) <= std_logic_vector(to_unsigned(abs_value / 1000, 4));         -- Miles
            bcd(11 downto 8)  <= std_logic_vector(to_unsigned((abs_value mod 1000) / 100, 4));  -- Centenas
            bcd(7 downto 4)   <= std_logic_vector(to_unsigned((abs_value mod 100) / 10, 4));   -- Decenas
            bcd(3 downto 0)   <= std_logic_vector(to_unsigned(abs_value mod 10, 4));          -- Unidades
            
            
        end if;
    end process;
end Behavioral;
