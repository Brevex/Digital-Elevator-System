library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package elevator_pkg is
    constant NUM_ELEVATORS     : integer := 3;
    constant NUM_FLOORS        : integer := 32;
    constant FLOOR_BITS        : integer := 5;

    constant DOOR_OPEN_TIME    : integer := 50;
    constant DOOR_CLOSE_TIME   : integer := 50;
    constant DOOR_HOLD_TIME    : integer := 100;
    constant FLOOR_TRAVEL_TIME : integer := 200;

    type floor_array                is array (0 to NUM_FLOORS-1) of std_logic;
    type elevator_floor_array       is array (0 to NUM_ELEVATORS-1) of unsigned(FLOOR_BITS-1 downto 0);
    type elevator_request_array     is array (0 to NUM_ELEVATORS-1) of floor_array;

    type elevator_state_type is (
        IDLE,
        OPENING_DOOR,
        DOOR_OPENED,
        CLOSING_DOOR,
        MOVING_UP,
        MOVING_DOWN
    );

    type scheduler_state_type is (
        SCANNING,
        ALLOCATING,
        WAITING
    );

    type direction_type is (DIR_NONE, DIR_UP, DIR_DOWN);
    type direction_array is array (0 to NUM_ELEVATORS-1) of direction_type;

    type elevator_request is record
        target_floor : unsigned(FLOOR_BITS-1 downto 0);
        direction    : direction_type;
        valid        : std_logic;
    end record;

    type elevator_request_array_type is array (0 to NUM_ELEVATORS-1) of elevator_request;

    type elevator_status is record
        current_floor : unsigned(FLOOR_BITS-1 downto 0);
        direction     : direction_type;
        busy          : std_logic;
        door_open     : std_logic;
    end record;

    type elevator_status_array is array (0 to NUM_ELEVATORS-1) of elevator_status;

    function floor_to_7seg(floor_num : unsigned(FLOOR_BITS-1 downto 0)) return std_logic_vector;

    function floor_distance(floor1, floor2 : unsigned(FLOOR_BITS-1 downto 0)) return integer;

end package elevator_pkg;

package body elevator_pkg is
    function floor_to_7seg(floor_num : unsigned(FLOOR_BITS-1 downto 0)) return std_logic_vector is
        variable digit : integer;
        variable seg   : std_logic_vector(6 downto 0);
    begin
        digit := to_integer(floor_num mod 10);

        case digit is
            when 0     => seg := "0111111";
            when 1     => seg := "0000110";
            when 2     => seg := "1011011";
            when 3     => seg := "1001111";
            when 4     => seg := "1100110";
            when 5     => seg := "1101101";
            when 6     => seg := "1111101";
            when 7     => seg := "0000111";
            when 8     => seg := "1111111";
            when 9     => seg := "1101111";
            when others => seg := "0000000";
        end case;

        return seg;
    end function;

    function floor_distance(floor1, floor2 : unsigned(FLOOR_BITS-1 downto 0)) return integer is
        variable f1, f2 : integer;
    begin
        f1 := to_integer(floor1);
        f2 := to_integer(floor2);

        if f1 > f2 then
            return f1 - f2;
        else
            return f2 - f1;
        end if;
    end function;

end package body elevator_pkg;