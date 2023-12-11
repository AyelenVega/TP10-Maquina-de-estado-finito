library IEEE;
use IEEE.std_logic_1164.all;

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
    signal det_tiempo_sal: std_logic_vector(5 downto 0);
    signal dato: std_logic;

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
        if 2 <= std_logic_vector(unsigned (det_tiempo_sal)) <= 4 then dato<='0';
        elsif 8 <= std_logic_vector(unsigned (det_tiempo_sal)) <= 10 then dato<='1';
        end if ;        

    end process;


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