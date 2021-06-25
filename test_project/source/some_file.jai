Some_Struct :: struct {
    x: int;
    y: int;
    something: float64;
}

operator== :: (lhs: Some_Struct, rhs: Some_Struct) -> bool {
    return (
        lhs.x == rhs.x &&
        lhs.y == rhs.y &&
        lhs.something == rhs.something
    );
}

