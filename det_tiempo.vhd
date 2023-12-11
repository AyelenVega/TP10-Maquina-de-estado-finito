library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package det_tiempo_pkg is
    component det_tiempo is
        generic( constant N: positive);
    port ( 
        rst : in std_logic;
        pulso : in std_logic;
        hab : in std_logic;
        clk : in std_logic;
        med : out std_logic;
        tiempo : out std_logic_vector (N-1 downto 0));
    end component;
end package;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.contador_pkg.all;

entity det_tiempo is
    generic (
        constant N : natural := 4);
    port(
        rst : in std_logic;
        pulso : in std_logic;
        hab : in std_logic;
        clk : in std_logic;
        med : out std_logic;
        tiempo : out std_logic_vector (N-1 downto 0));
end det_tiempo;

architecture solucion of det_tiempo is
constant uno : std_logic_vector(N-1 downto 0) := (0 => '1', others => '0');
signal Q2, salida : std_logic_vector(N-1 downto 0);
signal fl_asc, fl_dsc, hab_cont, flanco, med_act, Q1 : std_logic;
begin
    memoria : process(all)
    begin
        if rst = '1' then
            Q1 <= '1';
        elsif rising_edge(clk) then
            Q1 <= pulso;
        end if;
    end process;

    fl_dsc <= not pulso and Q1;
    fl_asc <= pulso and not Q1;

    U1 : contador generic map (N => N) port map (
        rst => rst,
        D => uno,
        carga => fl_dsc,
        hab => hab_cont,
        clk => clk,
        Q => Q2);

    hab_cont <= hab when to_integer(unsigned(Q2)) /= 0 else fl_dsc and hab;

    salida <= Q2 when fl_asc else tiempo;

    process(all)
    begin
        if rst = '1' then 
            tiempo <= (others => '0');
        elsif rising_edge(clk) then
            tiempo <= salida;
        end if;
    end process;

    flanco <= fl_asc or fl_dsc;
    med_act <= fl_asc when flanco else med;

    medicion : process(all)
    begin
        if rst = '1' then
            med <= '0';
        elsif rising_edge(clk) then
            med <= med_act;
        end if;
    end process;
            
end solucion;