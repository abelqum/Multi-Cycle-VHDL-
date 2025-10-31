library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity display is
    Port (
        Datos: in std_logic_vector(15 downto 0);     -- Entrada BCD de 16 bits (4 dígitos)
        clk_27mhz : in  STD_LOGIC;                   -- Reloj de 27 MHz        
        seg       : out STD_LOGIC_VECTOR(0 to 7);    -- Salida de segmentos (a-g)
        an        : out STD_LOGIC_VECTOR(3 downto 0) -- Ánodos (selección de display)
    );
end display;

architecture Behavioral of display is
 
    -- Señales para el divisor de frecuencia
    signal contador : integer := 0;
    signal clk_10khz : STD_LOGIC := '0';

    -- Señales del multiplexor
    signal display_sel : INTEGER := 0;
    signal bcd_actual : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    
    -- Señales para los dígitos BCD
    signal unidades, decenas, centenas, millares: std_logic_vector(3 downto 0);  

begin

    -- Extraer los 4 dígitos BCD del vector de entrada de 16 bits
    unidades <= Datos(3 downto 0);    -- Dígito unidades (bits 3-0)
    decenas  <= Datos(7 downto 4);    -- Dígito decenas (bits 7-4)
    centenas <= Datos(11 downto 8);   -- Dígito centenas (bits 11-8)
    millares <= Datos(15 downto 12);  -- Dígito millares (bits 15-12)

    -- Divisor de frecuencia: de 27MHz a 10kHz
    process(clk_27mhz)
    begin
        if rising_edge(clk_27mhz) then
            if contador = 1349 then  -- 27MHz / 10kHz = 2700, medio ciclo = 1350-1
                contador <= 0;
                clk_10khz <= not clk_10khz;  -- Genera reloj de 10kHz
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;

    -- Multiplexor de displays (funciona a 10kHz)
    process(clk_10khz)
    begin
        if rising_edge(clk_10khz) then
            display_sel <= (display_sel + 1) mod 4;  -- Cicla entre 0,1,2,3
        end if;
    end process;

    -- Selección del dígito actual para mostrar
    process(display_sel, unidades, decenas, centenas, millares)
    begin
        case display_sel is
            when 0 =>
                bcd_actual <= unidades;  -- Muestra unidades
                an <= "1110";           -- Habilita primer display
            when 1 =>
                bcd_actual <= decenas;   -- Muestra decenas
                an <= "1101";           -- Habilita segundo display
            when 2 =>
                bcd_actual <= centenas;  -- Muestra centenas
                an <= "1011";           -- Habilita tercer display
            when 3 =>
                bcd_actual <= millares;  -- Muestra millares
                an <= "0111";           -- Habilita cuarto display
            when others =>
                bcd_actual <= "0000";    -- Apagado
                an <= "1111";           -- Todos los displays apagados
        end case;
    end process;

    -- Conversor BCD a 7 segmentos (cátodo común)
    process(bcd_actual)
    begin
        case bcd_actual is
            when "0000" => seg <= "11111100"; -- 0
            when "0001" => seg <= "01100000"; -- 1
            when "0010" => seg <= "11011010"; -- 2
            when "0011" => seg <= "11110010"; -- 3
            when "0100" => seg <= "01100110"; -- 4
            when "0101" => seg <= "10110110"; -- 5
            when "0110" => seg <= "10111110"; -- 6
            when "0111" => seg <= "11100000"; -- 7
            when "1000" => seg <= "11111110"; -- 8
            when "1001" => seg <= "11110110"; -- 9
            when others => seg <= "00000000"; -- Apagado (para valores no BCD)
        end case;
    end process;

end Behavioral;