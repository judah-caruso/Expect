# Expect

A compile-time testing module for the Jai language, allowing you to easily
write and run tests without them getting in the way. 

# Usage


```c++
#import "Expect";

add :: (x: int, y: int) -> int { return x + y; }
sub :: (x: int, y: int) -> int { return x - y; }

#run {
    test("Add", #code {
        x := add(10, 20);
        y := *x;
        z := *x;

        expect(y == z);
        expect(z != null && <<y == 30);
        expect(add(1, 2) == 3);
    });

    test("Sub", #code {
        expect(sub(1, 1) == 0);
        x := sub(20, 10);
        y := *x;

        expect(y == *x);
        expect(<<y == 10);
        expect(<<y == 20, expected_to_fail = true);
    });

    test("Other", #code {
        expect(1 == 1, "1 didn't equal 1");

        x := 10;
        y := 20;
        y -= x;

        expect(y > 10, "expected y to > 10, instead was %", y);
    }, halt_on_fail = true);
}

// Recommended usage
#if RUN_TESTS #run { // Provide this in your build file.
    // ...
}
```

Sample Output:

```
> Running tests

> Add :: some_program.jai 185:5
        [000] some_program.jai 190:09 pass
        [001] some_program.jai 191:09 pass
        [002] some_program.jai 192:09 pass
> 3/3 tests passed. Time: 0.00065 seconds

> Sub :: some_program.jai 195:5
        [000] some_program.jai 196:09 pass
        [001] some_program.jai 200:09 pass
        [002] some_program.jai 201:09 pass
        [003] some_program.jai 202:09 pass
> 4/4 tests passed. Time: 0.000788 seconds

> Other :: some_program.jai 205:5
        [000] some_program.jai 206:09 pass
        [001] some_program.jai 212:09 fail :: expected y to be > 10, instead was 10

In workspace #2 ("Target Program"):
some_program.jai:212,9: Error: Testing halted due to failed expectation!

    y -= x;
    expect(y > 10, "expected y to be > 10, instead was %", y);
```

See `tests/` for more examples.


# Notes

The original version of this module analyzed the expression passed to `expect`,
allowing it to provide information about the call (attempt to dereference a null
pointer, which kind of comparison was passed, etc.). The current version does
**not** do this as the utility/usefulness of the introspection wasn't clear in
practice. If I find a use for it, it will be re-added.


# License

MIT
