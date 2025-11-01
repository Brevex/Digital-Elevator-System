library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.elevator_pkg.all;

entity elevator_system_tb is
end elevator_system_tb;

architecture Behavioral of elevator_system_tb is
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    signal call_up   : floor_array := (others => '0');
    signal call_down : floor_array := (others => '0');

    signal internal_calls_0 : floor_array := (others => '0');
    signal internal_calls_1 : floor_array := (others => '0');
    signal internal_calls_2 : floor_array := (others => '0');

    signal move_up      : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal move_down    : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal motor_enable : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal brake        : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal door_open    : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal door_close   : std_logic_vector(NUM_ELEVATORS-1 downto 0);

    signal seg7_display_0_tens  : std_logic_vector(6 downto 0);
    signal seg7_display_0_units : std_logic_vector(6 downto 0);
    signal seg7_display_1_tens  : std_logic_vector(6 downto 0);
    signal seg7_display_1_units : std_logic_vector(6 downto 0);
    signal seg7_display_2_tens  : std_logic_vector(6 downto 0);
    signal seg7_display_2_units : std_logic_vector(6 downto 0);

    signal current_floor_0 : unsigned(FLOOR_BITS-1 downto 0);
    signal current_floor_1 : unsigned(FLOOR_BITS-1 downto 0);
    signal current_floor_2 : unsigned(FLOOR_BITS-1 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    signal sim_finished : boolean := false;

begin
    DUT : entity work.elevator_system
        port map (
            clk                  => clk,
            reset                => reset,
            call_up              => call_up,
            call_down            => call_down,
            internal_calls_0     => internal_calls_0,
            internal_calls_1     => internal_calls_1,
            internal_calls_2     => internal_calls_2,
            move_up              => move_up,
            move_down            => move_down,
            motor_enable         => motor_enable,
            brake                => brake,
            door_open            => door_open,
            door_close           => door_close,

            seg7_display_0_tens  => seg7_display_0_tens,
            seg7_display_0_units => seg7_display_0_units,
            seg7_display_1_tens  => seg7_display_1_tens,
            seg7_display_1_units => seg7_display_1_units,
            seg7_display_2_tens  => seg7_display_2_tens,
            seg7_display_2_units => seg7_display_2_units,

            current_floor_0      => current_floor_0,
            current_floor_1      => current_floor_1,
            current_floor_2      => current_floor_2
        );

    clk_process : process
    begin
        while not sim_finished loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_process : process
        procedure wait_cycles(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure clear_calls is
        begin
            call_up          <= (others => '0');
            call_down        <= (others => '0');
            internal_calls_0 <= (others => '0');
            internal_calls_1 <= (others => '0');
            internal_calls_2 <= (others => '0');
        end procedure;

    begin
        report "Inicio da Simulacao";

        reset <= '1';
        clear_calls;
        wait_cycles(10);
        reset <= '0';
        wait_cycles(10);

        report "Reset concluido. Todos elevadores no andar 0.";
        wait_cycles(200);

        report "CENARIO 1: Chamada externa simples";
        report "Chamada UP no andar 5";
        call_up(5) <= '1';
        wait_cycles(5);
        call_up(5) <= '0';
        wait_cycles(3000);
        report "CENARIO 1 concluido.";
        clear_calls;
        wait_cycles(100);

        report "CENARIO 2: Chamada interna";
        report "Elevador 0 vai para andar 10";
        internal_calls_0(10) <= '1';
        wait_cycles(5);
        internal_calls_0(10) <= '0';
        wait_cycles(3000);
        report "CENARIO 2 concluido.";
        clear_calls;
        wait_cycles(100);

        report "CENARIO 3: Multiplas chamadas concorrentes";
        report "Chamadas nos andares 3 (UP), 7 (UP) e 15 (DOWN)";
        call_up(3)   <= '1';
        call_up(7)   <= '1';
        call_down(15) <= '1';
        wait_cycles(10);
        clear_calls;
        wait_cycles(10000);
        report "CENARIO 3 concluido.";
        wait_cycles(100);

        report "CENARIO 4: Teste de abertura/fechamento de portas";
        report "Chamada no andar 2 (Estando no 10)";
        call_up(2) <= '1';
        wait_cycles(5);
        call_up(2) <= '0';
        wait_cycles(4000);
        report "CENARIO 4 concluido.";
        clear_calls;
        wait_cycles(100);

        report "CENARIO 5: Stress test - multiplas chamadas";
        report "Chamadas em varios andares simultaneamente";
        call_up(1)           <= '1';
        call_up(5)           <= '1';
        call_up(8)           <= '1';
        call_down(12)        <= '1';
        call_down(18)        <= '1';
        call_up(20)          <= '1';
        internal_calls_0(15) <= '1';
        internal_calls_1(25) <= '1';
        wait_cycles(10);
        clear_calls;
        wait_cycles(15000);
        report "CENARIO 5 concluido.";
        wait_cycles(100);

        report "Simulacao concluida com sucesso!";
        sim_finished <= true;
        wait;
    end process;

    monitor_process : process
        variable last_move_up     : std_logic_vector(NUM_ELEVATORS-1 downto 0) := (others => '0');
        variable last_move_down   : std_logic_vector(NUM_ELEVATORS-1 downto 0) := (others => '0');
        variable last_door_open   : std_logic_vector(NUM_ELEVATORS-1 downto 0) := (others => '0');
        variable current_floor_int : integer;
    begin
        wait until rising_edge(clk);

        if reset = '0' then
            for i in 0 to NUM_ELEVATORS-1 loop

                case i is
                    when 0      => current_floor_int := to_integer(current_floor_0);
                    when 1      => current_floor_int := to_integer(current_floor_1);
                    when 2      => current_floor_int := to_integer(current_floor_2);
                    when others => current_floor_int := -1;
                end case;

                if move_up(i) = '1' and last_move_up(i) = '0' then
                    report "LOG: Elevador " & integer'image(i) & " INICIOU SUBIDA (Andar " & integer'image(current_floor_int) & ")";
                end if;

                if move_down(i) = '1' and last_move_down(i) = '0' then
                    report "LOG: Elevador " & integer'image(i) & " INICIOU DESCIDA (Andar " & integer'image(current_floor_int) & ")";
                end if;

                if door_open(i) = '1' and last_door_open(i) = '0' then
                    report "LOG: Elevador " & integer'image(i) & " ABRIU PORTA (Andar " & integer'image(current_floor_int) & ")";
                end if;

            end loop;

            last_move_up   := move_up;
            last_move_down := move_down;
            last_door_open := door_open;

        else
            last_move_up   := (others => '0');
            last_move_down := (others => '0');
            last_door_open := (others => '0');
        end if;
    end process;

end Behavioral;