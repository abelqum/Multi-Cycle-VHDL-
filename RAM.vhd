library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity RAM is
port(
    clk     : in  std_logic; 
    Adress  : in  std_logic_vector(7 downto 0);
    Data_in : in  std_logic_vector(23 downto 0);
    EnRAM   : in  std_logic; 
    RW      : in  std_logic; 
    Data_out: out std_logic_vector(23 downto 0)
);
end RAM;

architecture Behavioral of RAM is

   type RAM_MEMORY is array (0 to 255) of std_logic_vector(23 downto 0);

signal MEMORY: RAM_MEMORY := (
    -- PROGRAMA 1: 17x+25y-w/4 (CON BUCLE DE RETARDO DE 10 SEGUNDOS)
    -- W=27 (en 217), X=3 (en 218), Y=15 (en 219)
    0 => "00001011" & "00000000" & "11011000",  -- LW R0, [W] (Offset=216 -> 1+216=217)
    1 => "00001011" & "00000001" & "11011000",  -- LW R1, [X] (Offset=216 -> 2+216=218)
    2 => "00001011" & "00000010" & "11011000",  -- LW R2, [Y] (Offset=216 -> 3+216=219)
    
    -- Calcular 17X
    3 => "00011101" & "00000001" & "00010001",  -- MULI R1, 17 (R1 = 3 * 17 = 51)
    
    -- Calcular 25Y    
    4 => "00011101" & "00000010" & "00011001",  -- MULI R2, 25 (R2 = 15 * 25 = 375)
    
    -- Calcular W/4
    5 => "00011110" & "00000000" & "00000100",  -- DIVI R0, 4 (R0 = 27 / 4 = 6)
    
    -- Calcular 17X + 25Y
    6 => "00000000" & "00000001" & "00000010",  -- ADD R1, R2 (R1 = 51 + 375 = 426)
    
    -- Calcular (17X + 25Y) - W/4 
    7 => "00000001" & "00000001" & "00000000", -- SUB R1, R0 (R1 = 426 - 6 = 420)
    
    -- MOSTRAR RESULTADO (420)
    -- Tu instrucción DISP [Opcode 37] usa el registro en el campo 'A' (IR[15:8])
    8 => "00100101" & "00000001" & "00000000", -- DISP R1 (Muestra 420)

    -- === INICIO DEL BUCLE DE RETARDO (Aprox 10 segundos) ===
    -- R1 = i (contador externo, 10s) - REUTILIZAMOS R1
    -- R2 = j (contador medio, 37)
    -- R3 = k (contador interno, 65535)

    -- Cargar contador externo 'i' (10)
    9 => "00001011" & "00000001" & "11101100", -- (PC=9) LW R1, [I_VALUE] (Offset=236 -> 10+236=246)

    -- ETIQUETA_I (PC=10)
    -- Cargar contador medio 'j' (37)
    10 => "00001011" & "00000010" & "11101100", -- (PC=10) LW R2, [J_VALUE] (Offset=236 -> 11+236=247)

    -- ETIQUETA_J (PC=11)
    -- Cargar contador interno 'k' (65535)
    11 => "00001011" & "00000011" & "11101100", -- (PC=11) LW R3, [K_VALUE] (Offset=236 -> 12+236=248)

    -- ETIQUETA_K (PC=12)
    12 => "00011010" & "00000000" & "00000000", -- (PC=12) NOP (Opcode 26) <--- ¡AQUÍ ESTÁ EL NOP!
    13 => "00011100" & "00000011" & "00000001", -- (PC=13) SUBI R3, 1 (Opcode 28)
    14 => "00010010" & "00000000" & "11111101", -- (PC=14) BNZ ETIQUETA_K (a PC=12). Offset = 12-(14+1) = -3

    -- FIN BUCLE K
    15 => "00011100" & "00000010" & "00000001", -- (PC=15) SUBI R2, 1
    16 => "00010010" & "00000000" & "11111010", -- (PC=16) BNZ ETIQUETA_J (a PC=11). Offset = 11-(16+1) = -6

    -- FIN BUCLE J
    17 => "00011100" & "00000001" & "00000001", -- (PC=17) SUBI R1, 1
    18 => "00010010" & "00000000" & "11110111", -- (PC=18) BNZ ETIQUETA_I (a PC=10). Offset = 10-(18+1) = -9
    19 => "00000000" & "00000001" & "00000010",  -- ADD R1, R2 (R1 = 51 + 375 = 426)
    -- FIN BUCLE I
 20 => "00100101" & "00000001" & "00000000", -- DISP R1 (Muestra 420)
    21 => "00100100" & "00000000" & "00000000", -- HALT (Opcode 36)

    -- === FIN PROGRAMA 1 ===

    -- (El resto de la memoria está vacía (cero) o se usa para datos)
    

    -- =================================================================
    -- SECCIÓN DE DATOS
    -- =================================================================
    217 => "00000000" & "00000000" & "00011011",  -- W = 27 decimal
    218 => "00000000" & "00000000" & "00000011",  -- X = 3 decimal
    219 => "00000000" & "00000000" & "00001111",  -- Y = 15 decimal
    
    -- === CONSTANTES DEL BUCLE DE RETARDO ===
    246 => "00000000" & "00000000" & "00001010",  -- I_VALUE = 10
    247 => "00000000" & "00000000" & "00100101",  -- J_VALUE = 37 (NUEVO VALOR)
    248 => "00000000" & "11111111" & "11111111",  -- K_VALUE = 65535

    others => (others => '0')
);
  signal addr_int : integer range 0 to 255; 
--    
begin
 
    addr_int <= to_integer(unsigned(Adress));

    -- Escritura Síncrona
    process(clk)
    begin
        if rising_edge(clk) then
            if EnRAM = '1' and RW = '0' then 
                MEMORY(addr_int) <= Data_in; 
            end if;
        end if;
    end process;

    -- Lectura Asíncrona
    Data_out <= MEMORY(addr_int);

end Behavioral;  -- código el chido que ya hace el delay de 10 segundos, aplicar para programa de la practica 2
