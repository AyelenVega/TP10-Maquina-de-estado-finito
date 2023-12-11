library IEEE;
use IEEE.std_logic_1164.all;
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
    --Control

    --Detector de tiempo
    signal MED: std_logic;
    signal ciclos: std_logic_vector(31 downto 0);

    --Contador
    signal cant_bit: std_logic_vector(31 downto 0);

    --Registro de desplazamiento 
    signal ent_sipo, hab_sipo: std_logic;
    signal sipo_actual, sipo_siguiente, sipo_sal: std_logic_vector(31 downto 0);

    signal mensaje_correcto: std_logic;

    --Memorias salida
    signal dir_salida, cmd_salida: std_logic_vector(7 downto 0);
    signal hab_mem: std_logic;

begin


    --Control
    control: process (all)
    begin
           
    end process;

    --Detector de tiempo
    det: det_tiempo generic map(N => 32) port map(
        rst => rst,
        pulso => not infrarrojo,
        hab => hab,
        clk => clk,
        med => MED,
        tiempo => ciclos
    );


    --Contador
    cont: contador generic map (N => 32) port map(
        rst => rst,
        D => sipo_actual,
        carga => '0',
        hab => hab,
        clk => clk,
        Q => cant_bit
    );
    

    --Registro de desplazamiento
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
    mensaje_correcto <= '1' when ((sipo_sal(7 downto 0) = not sipo_sal(15 downto 8)) and (sipo_sal(23 downto 16) = not sipo_sal(31 downto 24))) else '0';


    --Memoria Direccion salida
    memoria_dir: process (all)
    begin
        if (rst = '1') then
        dir_salida <= (others => '0');
        elsif (rising_edge(clk) and hab_mem='1') then
        dir_salida <= sipo_sal(7 downto 0); 
        end if;
        end process;

    --Memoria Comando salida
    memoria_cmd: process (all)
    begin
        if (rst = '1') then
        cmd_salida <= (others => '0');
        elsif (rising_edge(clk) and hab_mem='1') then
        cmd_salida <= sipo_sal(23 downto 16); 
        end if;
        end process;
    

    --Salida
    dir<=dir_salida;
    cmd<=cmd_salida;

end architecture;