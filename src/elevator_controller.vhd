library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.elevator_pkg.all;

entity elevator_controller is
    Port (
        clk                 : in  std_logic;
        reset               : in  std_logic;

        request_floor       : in  unsigned(FLOOR_BITS-1 downto 0);
        request_direction   : in  direction_type;
        request_valid       : in  std_logic;
        request_ack         : out std_logic;

        internal_calls      : in  floor_array;

        current_floor       : out unsigned(FLOOR_BITS-1 downto 0);
        current_direction   : out direction_type;
        busy                : out std_logic;
        door_is_open        : out std_logic;

        move_up             : out std_logic;
        move_down           : out std_logic;
        motor_enable        : out std_logic;
        brake               : out std_logic;

        door_open           : out std_logic;
        door_close          : out std_logic;

        seg7_display_tens   : out std_logic_vector(6 downto 0);
        seg7_display_units  : out std_logic_vector(6 downto 0)
    );
end elevator_controller;

architecture Behavioral of elevator_controller is
    signal state      : elevator_state_type := IDLE;
    signal next_state : elevator_state_type;

    signal floor_reg          : unsigned(FLOOR_BITS-1 downto 0) := (others => '0');
    signal direction_reg      : direction_type := DIR_NONE;
    signal next_direction     : direction_type;
    signal target_floor_reg : unsigned(FLOOR_BITS-1 downto 0) := (others => '0');

    signal destinations : floor_array := (others => '0');

    signal timer       : integer := 0;
    signal timer_limit : integer := 0;

    signal has_destination  : std_logic := '0';
    signal arrived_at_floor : std_logic := '0';

begin

    process(clk, reset)
    begin
        if reset = '1' then
            destinations <= (others => '0');
        elsif rising_edge(clk) then
            for i in 0 to NUM_FLOORS-1 loop
                if internal_calls(i) = '1' then
                    destinations(i) <= '1';
                end if;

                if (state = OPENING_DOOR and timer = 1) and i = to_integer(floor_reg) then
                    destinations(i) <= '0';
                end if;
            end loop;

            if request_valid = '1' and state = IDLE then
                destinations(to_integer(request_floor)) <= '1';
                target_floor_reg                      <= request_floor;
            end if;
        end if;
    end process;

    has_destination <= '1' when unsigned(destinations) /= 0 else '0';

    process(clk, reset)
    begin
        if reset = '1' then
            state            <= IDLE;
            floor_reg        <= (others => '0');
            direction_reg    <= DIR_NONE;
            timer            <= 0;
            arrived_at_floor <= '0';
        elsif rising_edge(clk) then
            state         <= next_state;
            direction_reg <= next_direction;

            if timer_limit > 0 and timer = 0 then
                timer <= timer_limit;
            elsif timer > 0 then
                timer <= timer - 1;
            end if;

            if state = MOVING_UP and timer = 0 and arrived_at_floor = '0' then
                floor_reg <= floor_reg + 1;

                if destinations(to_integer(floor_reg + 1)) = '1' then
                    arrived_at_floor <= '1';
                else
                    arrived_at_floor <= '0';
                end if;
            elsif state = MOVING_DOWN and timer = 0 and arrived_at_floor = '0' then
                floor_reg <= floor_reg - 1;

                if destinations(to_integer(floor_reg - 1)) = '1' then
                    arrived_at_floor <= '1';
                else
                    arrived_at_floor <= '0';
                end if;
            elsif (state /= MOVING_UP and state /= MOVING_DOWN) then
                arrived_at_floor <= '0';
            end if;

        end if;
    end process;

    process(state, timer, has_destination, destinations, floor_reg,
            request_valid, arrived_at_floor, direction_reg)
    begin
        next_state   <= state;
        next_direction <= direction_reg;
        move_up      <= '0';
        move_down    <= '0';
        motor_enable <= '0';
        brake        <= '1';
        door_open    <= '0';
        door_close   <= '0';
        busy         <= '1';
        request_ack  <= '0';
        timer_limit  <= 0;

        case state is

            when IDLE =>
                busy  <= '0';
                brake <= '1';

                if request_valid = '1' then
                    request_ack <= '1';
                end if;

                if has_destination = '1' then
                    for i in NUM_FLOORS-1 downto 0 loop
                        if destinations(i) = '1' then
                            if i > to_integer(floor_reg) then
                                next_direction <= DIR_UP;
                                next_state     <= CLOSING_DOOR;
                                timer_limit    <= DOOR_CLOSE_TIME;
                            elsif i < to_integer(floor_reg) then
                                next_direction <= DIR_DOWN;
                                next_state     <= CLOSING_DOOR;
                                timer_limit    <= DOOR_CLOSE_TIME;
                            else
                                next_direction <= DIR_NONE;
                                next_state     <= OPENING_DOOR;
                                timer_limit    <= DOOR_OPEN_TIME;
                            end if;
                            exit;
                        end if;
                    end loop;
                end if;

            when OPENING_DOOR =>
                door_open <= '1';
                busy      <= '1';

                if timer = 0 then
                    next_state  <= DOOR_OPENED;
                    timer_limit <= DOOR_HOLD_TIME;
                end if;

            when DOOR_OPENED =>
                door_open <= '1';
                busy      <= '1';

                if timer = 0 then
                    next_state  <= CLOSING_DOOR;
                    timer_limit <= DOOR_CLOSE_TIME;
                end if;

            when CLOSING_DOOR =>
                door_close <= '1';
                busy       <= '1';

                if timer = 0 then
                    if has_destination = '0' then
                        next_state     <= IDLE;
                        next_direction <= DIR_NONE;
                    elsif direction_reg = DIR_UP then
                        next_state  <= MOVING_UP;
                        timer_limit <= FLOOR_TRAVEL_TIME;
                    elsif direction_reg = DIR_DOWN then
                        next_state  <= MOVING_DOWN;
                        timer_limit <= FLOOR_TRAVEL_TIME;
                    else
                        next_state <= IDLE;
                    end if;
                end if;

            when MOVING_UP =>
                motor_enable <= '1';
                move_up      <= '1';
                brake        <= '0';
                busy         <= '1';

                if arrived_at_floor = '1' then
                    next_state     <= OPENING_DOOR;
                    timer_limit    <= DOOR_OPEN_TIME;
                    next_direction <= DIR_NONE;
                elsif floor_reg = NUM_FLOORS-1 then
                    next_state     <= IDLE;
                    next_direction <= DIR_NONE;
                elsif timer = 0 then
                    timer_limit <= FLOOR_TRAVEL_TIME;
                end if;

            when MOVING_DOWN =>
                motor_enable <= '1';
                move_down    <= '1';
                brake        <= '0';
                busy         <= '1';

                if arrived_at_floor = '1' then
                    next_state     <= OPENING_DOOR;
                    timer_limit    <= DOOR_OPEN_TIME;
                    next_direction <= DIR_NONE;
                elsif floor_reg = 0 then
                    next_state     <= IDLE;
                    next_direction <= DIR_NONE;
                elsif timer = 0 then
                    timer_limit <= FLOOR_TRAVEL_TIME;
                end if;

        end case;
    end process;

    current_floor     <= floor_reg;
    current_direction <= direction_reg;
    door_is_open      <= '1' when (state = DOOR_OPENED or state = OPENING_DOOR) else '0';

    seg7_display_tens  <= floor_to_7seg(to_unsigned(to_integer(floor_reg) / 10, FLOOR_BITS));
    seg7_display_units <= floor_to_7seg(to_unsigned(to_integer(floor_reg) mod 10, FLOOR_BITS));

end Behavioral;