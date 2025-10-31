library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 


entity TopModule is
port( 
        clk_27,reset,pause_run: in std_logic;
        Sel_program: in std_logic_vector(1 downto 0);
        seg: out std_logic_vector(0 to 7);
        an: out std_logic_vector(3 downto 0);
        leds,ledsd: out std_logic_vector(3 downto 0);
        ZF,CF,SF,OvF: out std_logic
);
end TopModule;

architecture Behavioral of TopModule is


component binbcd16 is
    Port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        binario : in  STD_LOGIC_VECTOR (15 downto 0);
        bcd     : out STD_LOGIC_VECTOR (15 downto 0)
    );
end component;

component display is
    Port (
        Datos     : in  std_logic_vector(15 downto 0); -- Input: 4 BCD digits
        clk_27mhz : in  STD_LOGIC;                   -- Input: Clock (e.g., 27MHz)
        seg       : out STD_LOGIC_VECTOR(0 to 7);    -- Output: 7-segment lines (a-g, dp)
        an        : out STD_LOGIC_VECTOR(3 downto 0) -- Output: Anode selects (digit enable)
    );
end component;

component ALU16bits is
    port(
        A : in std_logic_vector(15 downto 0);
        B : in std_logic_vector(15 downto 0);
        sel : in std_logic_vector(3 downto 0);
        resultado : out std_logic_vector(15 downto 0);
        residuo : out std_logic_vector(7 downto 0);
        CF : out std_logic;
        ZF: out std_logic;
        SF: out std_logic;
        OvF: out std_logic;
        error_div : out std_logic
    );
end component;

component FlagReg is
port(
    OvF_in  : in  std_logic;
    ZF_in   : in  std_logic;
    SF_in   : in  std_logic;
    CF_in   : in  std_logic;
    clk     : in  std_logic;
    reset   : in  std_logic;
    EnFlags : in  std_logic;
    OvF_out : out std_logic;
    ZF_out  : out std_logic;
    SF_out  : out std_logic;
    CF_out  : out std_logic
);
end component;


component InstReg is
port( 
    EnIR: std_logic;
    clk: std_logic;
    Reset: std_logic;
    Data_in: in std_logic_vector(23 downto 0);
    Data_out: out std_logic_vector(23 downto 0)
);
end component;


component PC is
port(
    Clk   : in  std_logic;
    Reset : in  std_logic;
    D_in  : in  std_logic_vector(7 downto 0);
    EnPC  : in  std_logic;
    D_out : out std_logic_vector(7 downto 0)
);
end component;

component RAM is
port(
    clk     : in  std_logic;
    Adress  : in  std_logic_vector(7 downto 0);
    Data_in : in  std_logic_vector(23 downto 0);
    EnRAM   : in  std_logic;
    RW      : in  std_logic;
    Data_out: out std_logic_vector(23 downto 0)
);
end component;

component RF is
port(
    clk     : in  std_logic;
    A       : in  std_logic_vector(7 downto 0); -- Dirección lectura A
    B       : in  std_logic_vector(7 downto 0); -- Dirección lectura B
    Reset   : in  std_logic;
    Dest    : in  std_logic_vector(7 downto 0); -- Dirección escritura
    Data_in : in  std_logic_vector(15 downto 0); -- Dato escritura
    EnRF    : in  std_logic;
    A_out   : out std_logic_vector(15 downto 0); -- Dato leído A
    B_out   : out std_logic_vector(15 downto 0)  -- Dato leído B
);
end component;

component SignExtend is
port(
    Data_in  : in  std_logic_vector(7 downto 0);
    Data_out : out std_logic_vector(15 downto 0)
);
end component;

component UC is
    port(
        Instruction : in  std_logic_vector(23 downto 0);
        clk         : in  std_logic;
        reset       : in  std_logic;
        CF, ZF, SF, OvF : in  std_logic;
        EnPC, Mux_Addr, EnRAM, RW, EnIR, MUX_Dest, MUX_RData, EnRF, MUX_ALUA, EnFlags : out std_logic;
        MUX_ALUB, PC_sel : out std_logic_vector(1 downto 0);
        estados: out std_logic_vector(3 downto 0);
        ALU_Op    : out std_logic_vector(3 downto 0);
        Display_En : out std_logic 
    );

end component;
signal Mux_PC,Mux_alub: std_logic_vector(1 downto 0);
signal IR,RAM_out,dat_in: std_logic_vector(23 downto 0);
signal entrada_display,entrada_display1, Resultado_alu,Mux_ALUA_out,Mux_ALUB_out,SignExt_out,Mux_Data_out,RF_A_out,RF_B_out,mar16: std_logic_vector(15 downto 0);
signal Sel_op: std_logic_vector(3 downto 0);
signal Residuo,Mux_Dest_out,Mux_Addr_out,Mux_PC_out,MAR: std_logic_vector(7 downto 0):=(others=>'0');
signal Err_div,OvF_TEMP,SF_TEMP,ZF_TEMP,CF_TEMP,EnRegFile,EnRam,RW,EnIR,EnPC,EnFlags,OvF_out,SF_out,ZF_out,CF_out: std_logic:='0';
signal Mux_addr,Mux_rdata,Mux_dest,Mux_alua: std_logic:='0';
signal Display_En : std_logic;
constant MAX_COUNT_1SEC : natural := 27000000; -- 27 Millones de ciclos para 1 segundo a 27MHz 27000000
    signal contador_1hz : natural range 0 to MAX_COUNT_1SEC - 1 := 0;
    signal clk         : std_logic := '0';
begin
 Generador_Enable_1Hz: process(clk_27, reset) -- **Nombre de entrada cambiado a 'clk_27'**
   begin
        if reset = '0' then -- Asumiendo reset activo-bajo
            contador_1hz <= 0;
            clk          <= '0'; -- **Salida cambiada**
        elsif rising_edge(clk_27) then -- **Entrada cambiada**
            if contador_1hz = MAX_COUNT_1SEC - 1 then
                contador_1hz <= 0;
                clk          <= '1'; -- **Salida cambiada**
            else
                 contador_1hz <= contador_1hz + 1;
               clk          <= '0'; -- **Salida cambiada**
            end if;
         end if;
    end process Generador_Enable_1Hz;

Driver_Display: display port map (
    Datos     => entrada_display, 
    clk_27mhz => clk_27, 
    seg       => seg,
    an        => an
);

process(clk)
begin
    if rising_edge(clk) then
        if Display_En = '1' then
            entrada_display1 <= Resultado_alu;  -- Solo mostrar cuando está habilitado
        end if;
        -- Si Display_En = '0', mantiene el último valor mostrado
    end if;
end process;
Convertidor_BCD: binbcd16 port map (
    clk     => clk,
    reset   => reset,
    binario => mar16,  
    bcd     => entrada_display
);
mar16<="00000000"&MAR;
 with Mux_PC select Mux_PC_out <=
       Resultado_alu(7 downto 0) when "00", --PC+1
      IR(7 downto 0) when "01",    --JUMP
       RF_A_out(7 downto 0) when "10", --JALR
        (others => '0') when others;

Contador_Programa: PC port map (
    Clk   => clk,
    Reset => reset,
    D_in  => Mux_PC_out, -- Conectar al Mux de entrada del PC
    EnPC  => EnPC,
    D_out => MAR
);

 with Mux_addr select Mux_Addr_out <=
        MAR when '0',
        Resultado_alu(7 downto 0) when '1',
       (others => '0') when others;

dat_in<="00000000"&RF_B_out;
Memoria_Principal: RAM port map (
    clk      => clk,
    Adress   => Mux_Addr_out, -- Conectar a Mux_Addr
    Data_in  => dat_in, -- Conectar a RF B Out (para SW)
    EnRAM    => EnRam,
    RW       => RW,
    Data_out => RAM_out -- Va al IR y al Mux de datos del RF
);

Registro_Instruccion: InstReg port map (
    EnIR     => EnIR,
    clk      => clk,
    Reset    => reset,
    Data_in  => RAM_out, -- Dato viene de la RAM
    Data_out => IR
);

 with Mux_dest select Mux_Dest_out <=
        IR(15 downto 8) when '0', -- A
        IR(7 downto 0) when '1',  -- B
        (others => '0') when others;

 with Mux_rdata select Mux_Data_out <=
        RAM_out(15 downto 0) when '0', -- RAM_out
        Resultado_alu when '1',  -- ACUMULADOR ALU
        (others => '0') when others;

Banco_Registros: RF port map (
    clk     => clk,
    A       => IR(15 downto 8), -- Campo A de la instrucción
    B       => IR(7 downto 0),  -- Campo B de la instrucción
    Reset   => reset,
    Dest    => Mux_Dest_out, -- Conectar a Mux_Dest o IR
    Data_in => Mux_Data_out, -- Conectar a Mux_RData
    EnRF    => EnRegFile,
    A_out   => RF_A_out, -- Va a Mux_ALUA
    B_out   => RF_B_out  -- Va a Mux_ALUB y RAM Data In
);

 with Mux_alua select Mux_ALUA_out <=
        "00000000"&MAR when '0', -- PC
        RF_A_out when '1',  -- REG_A
        (others => '0')when others;

 with Mux_alub select Mux_ALUB_out <=
        RF_B_out when "00", 
       "0000000000000001" when "01",
       "0000000000000000" when "10",
        SignExt_out when "11",
        (others => '0') when others;


Extensor_Signo: SignExtend port map (
    Data_in  => IR(7 downto 0), -- Campo B (inmediato) de la instrucción
    Data_out => SignExt_out -- Va a Mux_ALUB
);


ALU_principal: ALU16bits port map (
    A         => Mux_ALUA_out,
    B         => Mux_ALUB_out,
    sel       => Sel_op,
    resultado => Resultado_alu,
    residuo   => Residuo,
    CF        => CF_TEMP,
    ZF        => ZF_TEMP,
    SF        => SF_TEMP,
    OvF       => OvF_TEMP,
    error_div => Err_div
);

Registro_Banderas: FlagReg port map (
    OvF_in  => OvF_TEMP,
    ZF_in   => ZF_TEMP,
    SF_in   => SF_TEMP,
    CF_in   => CF_TEMP,
    clk     => clk,
    reset   => reset,
    EnFlags => EnFlags,
    OvF_out => OvF_out,
    ZF_out  => ZF_out,
    SF_out  => SF_out,
    CF_out  => CF_out
);

Unidad_Control_inst: UC port map (
    Instruction => IR,         -- Input: Full instruction from InstReg
    clk         => clk,             -- Input: System clock
    reset       => reset,             -- Input: System reset
    CF          => CF_out,    -- Input: Carry flag from FlagReg
    ZF          => ZF_out,    -- Input: Zero flag from FlagReg
    SF          => SF_out,    -- Input: Sign flag from FlagReg
    OvF         => OvF_out,   -- Input: Overflow flag from FlagReg

    -- Control Signal Outputs: Connect to respective control inputs in datapath
    EnPC        => EnPC,
    Mux_Addr    => Mux_addr,
    EnRAM       => EnRam,
    RW          => RW,
    EnIR        => EnIR,
    MUX_Dest    => Mux_dest,
    MUX_RData   => Mux_rdata,
    EnRF        => EnRegFile,
    MUX_ALUA    => Mux_alua,
    EnFlags     => EnFlags,
    MUX_ALUB    => Mux_alub,
    PC_sel      => Mux_PC,
    estados     => leds,
    ALU_Op      => Sel_op,
    Display_En  => Display_En 
);
ledsd<=  CF_out&ZF_out&SF_out&OvF_out;
end Behavioral;




