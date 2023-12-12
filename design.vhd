library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.contador_pkg.all;
use work.det_tiempo_pkg.all;

entity receptor_ir is
    port (
        rst        : in std_logic;
        infrarrojo : in std_logic;
        hab        : in std_logic;
        clk        : in std_logic;
        valido     : out std_logic;
        dir        : out std_logic_vector (7 downto 0);
        cmd        : out std_logic_vector (7 downto 0));
end receptor_ir;

architecture arch of receptor_ir is
    --Controlador
    signal uno,cero,inicio, repeticion, desplazar: std_logic;
    signal mensaje_correcto, desplazar_2, co_act: std_logic;

    --Detector de tiempo
    signal MED: std_logic;
    signal ciclos: std_logic_vector(5 downto 0);

    --Contador
    signal cant_bit: std_logic_vector(4 downto 0);
    signal hab_contador, mensaje_completo, Co: std_logic;
    constant D : std_logic_vector(4 downto 0) := (others => '0');


    --Registro de desplazamiento 
    signal ent_sipo, hab_sipo: std_logic;
    signal sipo_actual, sipo_siguiente, sipo_sal: std_logic_vector(31 downto 0);


    --Memorias salida
    signal dir_salida, cmd_salida: std_logic_vector(7 downto 0);
    signal hab_mem: std_logic;

    --Memoria Valido
    signal hab_val, valido_salida, valido_sig: std_logic;

begin

    --Detector de tiempo
    det: det_tiempo generic map(N => 6) port map(
        rst => rst,
        pulso => not infrarrojo,
        hab => hab,
        clk => clk,
        med => MED,
        tiempo => ciclos
    );

    --Controlador
    inicio<='1' when MED='1' and (to_integer(unsigned(ciclos))=23 or to_integer(unsigned(ciclos))=24 or to_integer(unsigned(ciclos))=25) else '0';
    cero<= '1' when MED='1' and (to_integer(unsigned(ciclos))=2 or to_integer(unsigned(ciclos))=3 or to_integer(unsigned(ciclos))=4) else '0';
    uno<= '1' when MED='1' and (to_integer(unsigned(ciclos))=8 or to_integer(unsigned(ciclos))=9 or to_integer(unsigned(ciclos))=10) else '0';
    repeticion<='1' when MED='1' and (to_integer(unsigned(ciclos))=11 or to_integer(unsigned(ciclos))=12 or to_integer(unsigned(ciclos))=13) else '0';


    desplazar<=uno or cero or inicio;
    desplazar_2<=uno or cero;
    valido_sig<=mensaje_correcto and mensaje_completo;


  


    --Contador
    cont: contador generic map (N => 5) port map(
        rst => rst,
        D => D,
        carga => inicio,
        hab => desplazar,
        clk => clk,
        Q => cant_bit,
        Co => Co
    );
    
    ff_co: process(all)
    begin
        if rst='1' then
            co_act<='0';
        elsif rising_edge(clk) then
            co_act<=Co; 
        end if ;

    end process;
    mensaje_completo<=co_act;
    

    --Registro de desplazamiento
    ent_sipo<= '0' when cero='1' else '1';
    hab_sipo<=desplazar_2;

    memoria_sipo: process(all)
    begin
        if rst = '1' then 
            sipo_actual <= (others => '0');
        elsif rising_edge(clk) then 
            sipo_actual <= sipo_siguiente;
        end if;
    end process;

    LES_sipo: process(all)
    begin
        if hab_sipo = '1' then
            sipo_siguiente <= ent_sipo & sipo_actual(31 downto 1);
        else
            sipo_siguiente <= sipo_actual;
        end if;
    end process;

    sipo_sal <= sipo_actual;


    --Comparacion 
    mensaje_correcto <= '1' when (mensaje_completo='1' and (sipo_sal(7 downto 0) = not sipo_sal(15 downto 8)) and (sipo_sal(23 downto 16) = not sipo_sal(31 downto 24)))  else '0';
    

    --Memorias de salida
    hab_mem<=mensaje_correcto;
    hab_val<=mensaje_completo;

    memoria_dir: process (all)
    begin
        if (rst = '1') then
        dir_salida <= (others => '0');
        elsif (rising_edge(clk) and hab_mem='1') then
        dir_salida <= sipo_sal(7 downto 0); 
        end if;
        end process;

    memoria_cmd: process (all)
    begin
        if (rst = '1') then
        cmd_salida <= (others => '0');
        elsif (rising_edge(clk) and hab_mem='1') then
        cmd_salida <= sipo_sal(23 downto 16); 
        end if;
        end process;
    

    memoria_valido: process (all)
    begin
        if (rst = '1') then
        valido_salida <= '0';
        elsif (rising_edge(clk) and hab_val='1') then
        valido_salida <= valido_sig; 
        end if;
        end process;  
        
        
    --Salida
    dir<=dir_salida;
    cmd<=cmd_salida;
    valido<=valido_salida;

end architecture;