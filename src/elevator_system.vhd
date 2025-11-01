library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.elevator_pkg.all;

entity elevator_system is
    Port (
        clk                  : in  std_logic;
        reset                : in  std_logic;

        call_up              : in  floor_array;
        call_down            : in  floor_array;

        internal_calls_0     : in  floor_array;
        internal_calls_1     : in  floor_array;
        internal_calls_2     : in  floor_array;

        move_up              : out std_logic_vector(NUM_ELEVATORS-1 downto 0);
        move_down            : out std_logic_vector(NUM_ELEVATORS-1 downto 0);
        motor_enable         : out std_logic_vector(NUM_ELEVATORS-1 downto 0);
        brake                : out std_logic_vector(NUM_ELEVATORS-1 downto 0);

        door_open            : out std_logic_vector(NUM_ELEVATORS-1 downto 0);
        door_close           : out std_logic_vector(NUM_ELEVATORS-1 downto 0);

        seg7_display_0_tens  : out std_logic_vector(6 downto 0);
        seg7_display_0_units : out std_logic_vector(6 downto 0);
        seg7_display_1_tens  : out std_logic_vector(6 downto 0);
        seg7_display_1_units : out std_logic_vector(6 downto 0);
        seg7_display_2_tens  : out std_logic_vector(6 downto 0);
        seg7_display_2_units : out std_logic_vector(6 downto 0);

        current_floor_0      : out unsigned(FLOOR_BITS-1 downto 0);
        current_floor_1      : out unsigned(FLOOR_BITS-1 downto 0);
        current_floor_2      : out unsigned(FLOOR_BITS-1 downto 0)
    );
end elevator_system;

architecture Structural of elevator_system is
    signal req_floor     : elevator_floor_array;
    signal req_direction : direction_array;
    signal req_valid     : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal req_ack       : std_logic_vector(NUM_ELEVATORS-1 downto 0);

    signal elev_floors     : elevator_floor_array;
    signal elev_directions : direction_array;
    signal elev_busy       : std_logic_vector(NUM_ELEVATORS-1 downto 0);
    signal elev_door_open  : std_logic_vector(NUM_ELEVATORS-1 downto 0);

    type internal_calls_array is array (0 to NUM_ELEVATORS-1) of floor_array;
    signal internal_calls : internal_calls_array;

    type seg7_array is array (0 to NUM_ELEVATORS-1) of std_logic_vector(6 downto 0);
    signal all_seg7_tens  : seg7_array;
    signal all_seg7_units : seg7_array;

begin
    internal_calls(0) <= internal_calls_0;
    internal_calls(1) <= internal_calls_1;
    internal_calls(2) <= internal_calls_2;

    scheduler_inst : entity work.elevator_scheduler
        port map (
            clk                 => clk,
            reset               => reset,
            call_up             => call_up,
            call_down           => call_down,
            elevator_floors     => elev_floors,
            elevator_directions => elev_directions,
            elevator_busy       => elev_busy,
            elevator_door_open  => elev_door_open,
            request_floor       => req_floor,
            request_direction   => req_direction,
            request_valid       => req_valid,
            request_ack         => req_ack
        );

    gen_elevators : for i in 0 to NUM_ELEVATORS-1 generate
        controller_inst : entity work.elevator_controller
            port map (
                clk                  => clk,
                reset                => reset,

                request_floor        => req_floor(i),
                request_direction    => req_direction(i),
                request_valid        => req_valid(i),
                request_ack          => req_ack(i),

                internal_calls       => internal_calls(i),

                current_floor        => elev_floors(i),
                current_direction    => elev_directions(i),
                busy                 => elev_busy(i),
                door_is_open         => elev_door_open(i),

                move_up              => move_up(i),
                move_down            => move_down(i),
                motor_enable         => motor_enable(i),
                brake                => brake(i),

                door_open            => door_open(i),
                door_close           => door_close(i),

                seg7_display_tens    => all_seg7_tens(i),
                seg7_display_units   => all_seg7_units(i)
            );
    end generate;

    seg7_display_0_tens  <= all_seg7_tens(0);
    seg7_display_0_units <= all_seg7_units(0);
    seg7_display_1_tens  <= all_seg7_tens(1);
    seg7_display_1_units <= all_seg7_units(1);
    seg7_display_2_tens  <= all_seg7_tens(2);
    seg7_display_2_units <= all_seg7_units(2);

    current_floor_0 <= elev_floors(0);
    current_floor_1 <= elev_floors(1);
    current_floor_2 <= elev_floors(2);

end Structural;