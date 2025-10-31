library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity RF is
port(
    clk     : in  std_logic; 
    A       : in  std_logic_vector(7 downto 0);
    B       : in  std_logic_vector(7 downto 0);
    Reset   : in  std_logic;
    Dest    : in  std_logic_vector(7 downto 0);
    Data_in : in  std_logic_vector(15 downto 0);
    EnRF    : in  std_logic; 
    A_out   : out std_logic_vector(15 downto 0);
    B_out   : out std_logic_vector(15 downto 0)
);
end RF;

architecture Behavioral of RF is

   type RegFile is array (0 to 3) of std_logic_vector(15 downto 0);
signal TablaReg : RegFile := (
    0 => "00000000" & "00000000",  -- R0 = 0
    1 => "00000000" & "00000000",  -- R1 = 0 (aquí se guardará PC+1)
    2 => "00000000" & "00000000",  -- R2 = 8 (dirección de salto)
    3 => "00000000" & "00000000"   -- R3 = 0
);

 signal addr_a, addr_b, addr_dest : integer range 0 to 3; 

begin
    addr_a    <= to_integer(unsigned(A(1 downto 0)));
    addr_b    <= to_integer(unsigned(B(1 downto 0)));
    addr_dest <= to_integer(unsigned(Dest(1 downto 0)));

 
    process(clk, Reset)
    begin
        if Reset = '0' then
            TablaReg(0) <= (others => '0');
            TablaReg(1) <= (others => '0');
            TablaReg(2) <= (others => '0');
            TablaReg(3) <= (others => '0');
            
        elsif rising_edge(clk) then -- Lógica de Escritura
            if EnRF = '1' then
                TablaReg(addr_dest) <= Data_in;
            end if;
        end if;
    end process;

    
    A_out <= TablaReg(addr_a);
    B_out <= TablaReg(addr_b);

end Behavioral;