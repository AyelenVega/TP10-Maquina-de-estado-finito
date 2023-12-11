library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package contador_pkg is
    component contador is
        generic (
        constant N:positive);
    port (
        rst   : in std_logic;
        D     : in std_logic_vector (N-1 downto 0);
        carga : in std_logic;
        hab   : in std_logic;
        clk   : in std_logic;
        Q     : out std_logic_vector (N-1 downto 0);
        Co    : out std_logic);
    end component;
end package;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity contador is
    generic (
        constant N:positive);
    port (
        rst   : in std_logic;
        D     : in std_logic_vector (N-1 downto 0);
        carga : in std_logic;
        hab   : in std_logic;
        clk   : in std_logic;
        Q     : out std_logic_vector (N-1 downto 0);
        Co    : out std_logic);
end contador;

architecture solucion of contador is
signal Q_actual, Q_sig : std_logic_vector(N-1 downto 0);
begin
    memoria : process (rst,clk)
    begin
        if rst = '1' then
            Q_actual <= (others => '0');
        elsif (hab = '1' and (clk'event and clk = '1')) then
            Q_actual <= Q_sig;
        end if;
    end process;

    intermedio: process (hab,Q_actual,carga)
    begin
        if hab = '0' then 
            Q_sig <= Q_actual;
        elsif carga = '1' then
            Q_sig <= D;
        else
            Q_sig <= std_logic_vector(unsigned(Q_actual) + 1);
        end if;
    end process;

    salida : process (Q_actual)
    begin
        Q <= Q_actual;
        
        if Q_actual = (N-1 downto 0 => '1') then
            Co <= '1';
        else
            Co <= '0';
        end if;
    end process;
end solucion;