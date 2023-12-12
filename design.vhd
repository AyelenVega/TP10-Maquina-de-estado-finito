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
    subtype t_ciclos_det is std_logic_vector(5 downto 0);

    --Controlador
    signal uno              : std_logic;
    signal cero             : std_logic;
    signal inicio           : std_logic;
    signal repeticion       : std_logic;
    signal mensaje_correcto : std_logic;
    signal desplazar        : std_logic;

    constant CERO_MIN         : t_ciclos_det := std_logic_vector(to_unsigned(2,  t_ciclos_det'length));
    constant CERO_MED         : t_ciclos_det := std_logic_vector(to_unsigned(3,  t_ciclos_det'length));
    constant CERO_MAX         : t_ciclos_det := std_logic_vector(to_unsigned(4,  t_ciclos_det'length));
    constant UNO_MIN          : t_ciclos_det := std_logic_vector(to_unsigned(8,  t_ciclos_det'length));
    constant UNO_MED          : t_ciclos_det := std_logic_vector(to_unsigned(9,  t_ciclos_det'length));
    constant UNO_MAX          : t_ciclos_det := std_logic_vector(to_unsigned(10, t_ciclos_det'length));
    constant REPETICION_MIN   : t_ciclos_det := std_logic_vector(to_unsigned(11, t_ciclos_det'length));
    constant REPETICION_MED   : t_ciclos_det := std_logic_vector(to_unsigned(12, t_ciclos_det'length));
    constant REPETICION_MAX   : t_ciclos_det := std_logic_vector(to_unsigned(13, t_ciclos_det'length));
    constant INICIO_MIN       : t_ciclos_det := std_logic_vector(to_unsigned(23, t_ciclos_det'length));
    constant INICIO_MED       : t_ciclos_det := std_logic_vector(to_unsigned(24, t_ciclos_det'length));
    constant INICIO_MAX       : t_ciclos_det := std_logic_vector(to_unsigned(25, t_ciclos_det'length));

    --Detector de tiempo
    signal med    : std_logic;
    signal ciclos : t_ciclos_det;

    --Contador
    signal hab_contador     : std_logic;
    signal mensaje_completo : std_logic;
    signal Co               : std_logic;

    constant D : std_logic_vector(4 downto 0) := (others => '1');


    --Registro de desplazamiento 
    signal ent_sipo       : std_logic; 
    signal hab_sipo       : std_logic;
    signal sipo_actual    : std_logic_vector(31 downto 0);
    signal sipo_siguiente : std_logic_vector(31 downto 0);
    signal sipo_sal       : std_logic_vector(31 downto 0);

    subtype SIPO_DIR  is natural range 7  downto 0;
    subtype SIPO_NDIR is natural range 15 downto 8;
    subtype SIPO_CMD  is natural range 23 downto 16;
    subtype SIPO_NCMD is natural range 31 downto 24;

    --Memorias salida
    signal dir_salida : std_logic_vector(7 downto 0);
    signal cmd_salida : std_logic_vector(7 downto 0);
    signal hab_mem    : std_logic;

    --Memoria Valido
    signal hab_val       : std_logic;
    signal valido_salida : std_logic;
    signal valido_sig    : std_logic;

begin

    --Detector de tiempo
    det: det_tiempo generic map(N => 6) port map(
        rst    => rst,
        pulso  => not infrarrojo,
        hab    => hab,
        clk    => clk,
        med    => med,
        tiempo => ciclos
    );

    --Deteccion de incio, repeticion, cero o uno
    inicio     <= med when ciclos = INICIO_MIN     or ciclos = INICIO_MED     or ciclos = INICIO_MAX     else '0';    
    cero       <= med when ciclos = CERO_MIN       or ciclos = CERO_MED       or ciclos = CERO_MAX       else '0';
    uno        <= med when ciclos = UNO_MIN        or ciclos = UNO_MED        or ciclos = UNO_MAX        else '0';
    repeticion <= med when ciclos = REPETICION_MIN or ciclos = REPETICION_MED or ciclos = REPETICION_MAX else '0';

    --Definicion de habilitaciones para SIPO y contador
    hab_contador <= uno or cero or inicio;
    desplazar    <= uno or cero;

    --Contador
    cont: contador generic map (N => 5) port map(
        rst   => rst,
        D     => D,
        carga => inicio,
        hab   => hab_contador,
        clk   => clk,
        Co    => Co
    );
       

    --Registro de desplazamiento SIPO
    ent_sipo <= '0' when cero='1' else '1';
    hab_sipo <= desplazar;

    memoria_sipo: process(rst,clk)
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
    mensaje_completo <= Co and not inicio;
    mensaje_correcto <= mensaje_completo when (sipo_sal(SIPO_DIR) = not sipo_sal(SIPO_NDIR)) and (sipo_sal(SIPO_CMD) = not sipo_sal(SIPO_NCMD))  
                        else '0';
    

    --Memorias de salida

    hab_mem    <= mensaje_correcto;
    hab_val    <= mensaje_completo;
    valido_sig <= mensaje_correcto and mensaje_completo;


    memoria_dir: process (all)
    begin
        if (rst = '1') then
            dir_salida <= (others => '0');
        elsif (rising_edge(clk) and hab_mem='1') then
            dir_salida <= sipo_sal(SIPO_DIR); 
        end if;
    end process;

    memoria_cmd: process (all)
    begin
        if (rst = '1') then
            cmd_salida <= (others => '0');
        elsif (rising_edge(clk) and hab_mem='1') then
            cmd_salida <= sipo_sal(SIPO_CMD); 
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
    dir    <= dir_salida;
    cmd    <= cmd_salida;
    valido <= valido_salida and not repeticion;

end architecture;