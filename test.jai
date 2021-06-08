#load "module.jai";

main :: () {}
add :: (x: int, y: int) -> int { return x + y; }
sub :: (x: int, y: int) -> int { return x - y; }

#run {
    set("Add tests", #code {
        x := add(10, 20);
        y := *x;
        z := *x;

        expect(y == z);
        expect(z != null && <<y == 30);
        expect(add(1, 2) == 3);
    });

    set("Sub tests", #code {
        expect(sub(1, 1) == 0);
        x := sub(20, 10);
        y := *x;

        expect(y == *x);
        expect(<<y == 10);
        expect(<<y == 20, should_fail = true);
    });

    set("Some tests", #code {
        expect(1 == 1, "1 didn't equal 1");

        x := 10;
        y := 20;
        y -= x;

        expect(y == 10);
    });
}
