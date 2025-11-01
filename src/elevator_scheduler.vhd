library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.elevator_pkg.all;

entity elevator_scheduler is
    Port (
        clk                 : in  std_logic;
        reset               : in  std_logic;

        call_up             : in  floor_array;
        call_down           : in  floor_array;

        elevator_floors     : in  elevator_floor_array;
        elevator_directions : in  direction_array;
        elevator_busy       : in  std_logic_vector(NUM_ELEVATORS-1 downto 0);
        elevator_door_open  : in  std_logic_vector(NUM_ELEVATORS-1 downto 0);

        request_floor       : out elevator_floor_array;
        request_direction   : out direction_array;
        request_valid       : out std_logic_vector(NUM_ELEVATORS-1 downto 0);
        request_ack         : in  std_logic_vector(NUM_ELEVATORS-1 downto 0)
    );
end elevator_scheduler;

architecture Behavioral of elevator_scheduler is
    type state_type is (IDLE, SCANNING, SELECTING, ALLOCATING);
    signal state : state_type := IDLE;

    signal pending_up   : floor_array := (others => '0');
    signal pending_down : floor_array := (others => '0');

    signal prev_call_up   : floor_array := (others => '0');
    signal prev_call_down : floor_array := (others => '0');

    signal selected_elevator  : integer range 0 to NUM_ELEVATORS-1 := 0;
    signal selected_floor     : unsigned(FLOOR_BITS-1 downto 0) := (others => '0');
    signal selected_direction : direction_type := DIR_NONE;
    signal allocation_done    : std_logic := '0';

    type allocated_flags is array (0 to NUM_ELEVATORS-1) of std_logic;
    signal elevator_allocated : allocated_flags := (others => '0');

    function calculate_cost(
        elev_floor   : unsigned(FLOOR_BITS-1 downto 0);
        elev_dir     : direction_type;
        elev_busy    : std_logic;
        call_floor   : unsigned(FLOOR_BITS-1 downto 0);
        call_dir     : direction_type;
        is_allocated : std_logic
    ) return integer is
        variable distance : integer;
        variable cost     : integer;
    begin
        if is_allocated = '1' then
            return 99999;
        end if;

        distance := floor_distance(elev_floor, call_floor);
        cost     := distance;

        if elev_busy = '1' then
            cost := cost + 50;
        end if;

        if elev_dir = call_dir and call_dir /= DIR_NONE then
            cost := cost - 10;
        end if;

        if elev_dir = DIR_NONE then
            cost := cost - 5;
        end if;

        return cost;
    end function;

begin

    process(clk, reset)
        variable best_cost     : integer;
        variable current_cost  : integer;
        variable best_elevator : integer;
        variable has_pending   : std_logic;
        variable scan_floor    : integer;
    begin
        if reset = '1' then
            state              <= IDLE;
            pending_up         <= (others => '0');
            pending_down       <= (others => '0');
            prev_call_up       <= (others => '0');
            prev_call_down     <= (others => '0');
            request_valid      <= (others => '0');
            selected_elevator  <= 0;
            allocation_done    <= '0';
            elevator_allocated <= (others => '0');

        elsif rising_edge(clk) then
            prev_call_up   <= call_up;
            prev_call_down <= call_down;

            for i in 0 to NUM_ELEVATORS-1 loop
                if request_ack(i) = '1' then
                    elevator_allocated(i) <= '0';
                end if;
            end loop;

            case state is

                when IDLE =>
                    for i in 0 to NUM_FLOORS-1 loop
                        if call_up(i) = '1' and prev_call_up(i) = '0' then
                            pending_up(i) <= '1';
                        end if;
                        if call_down(i) = '1' and prev_call_down(i) = '0' then
                            pending_down(i) <= '1';
                        end if;
                    end loop;

                    has_pending := '0';
                    for i in 0 to NUM_FLOORS-1 loop
                        if pending_up(i) = '1' or pending_down(i) = '1' then
                            has_pending := '1';
                            exit;
                        end if;
                    end loop;

                    if has_pending = '1' then
                        state <= SCANNING;
                    end if;

                when SCANNING =>
                    has_pending := '0';
                    for i in 0 to NUM_FLOORS-1 loop
                        if pending_up(i) = '1' then
                            selected_floor     <= to_unsigned(i, FLOOR_BITS);
                            selected_direction <= DIR_UP;
                            state              <= SELECTING;
                            has_pending        := '1';
                            exit;
                        elsif pending_down(i) = '1' then
                            selected_floor     <= to_unsigned(i, FLOOR_BITS);
                            selected_direction <= DIR_DOWN;
                            state              <= SELECTING;
                            has_pending        := '1';
                            exit;
                        end if;
                    end loop;

                    if has_pending = '0' then
                        state <= IDLE;
                    end if;

                when SELECTING =>
                    best_cost     := 99999;
                    best_elevator := 0;

                    for i in 0 to NUM_ELEVATORS-1 loop
                        current_cost := calculate_cost(
                            elevator_floors(i),
                            elevator_directions(i),
                            elevator_busy(i),
                            selected_floor,
                            selected_direction,
                            elevator_allocated(i)
                        );

                        if current_cost < best_cost then
                            best_cost     := current_cost;
                            best_elevator := i;
                        end if;
                    end loop;

                    selected_elevator <= best_elevator;
                    state             <= ALLOCATING;

                when ALLOCATING =>
                    if allocation_done = '0' then
                        request_floor(selected_elevator)     <= selected_floor;
                        request_direction(selected_elevator) <= selected_direction;
                        request_valid(selected_elevator)     <= '1';

                        elevator_allocated(selected_elevator) <= '1';

                        scan_floor := to_integer(selected_floor);
                        if selected_direction = DIR_UP then
                            pending_up(scan_floor) <= '0';
                        else
                            pending_down(scan_floor) <= '0';
                        end if;

                        allocation_done <= '1';
                    end if;

                    if request_ack(selected_elevator) = '1' then
                        request_valid(selected_elevator) <= '0';
                        allocation_done                  <= '0';
                        state                            <= IDLE;
                    end if;

            end case;

        end if;
    end process;

end Behavioral;