# Expect

Compile-time testing module for the Jai language.

# Usage

```c++
#import "Expect";

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

// Alternate usage
#placeholder RUN_TESTS; // Provide this via build
#if RUN_TESTS #run {
    // ...
}
```

Output:

```
> Running sets

> Test :: Add tests
        [001] expect/test.jai 9:9 :: equality check OK
        [002] expect/test.jai 13:9 :: equality check OK
        [003] expect/test.jai 14:9 :: logical and check OK
> 3/3 test(s) passed! Set took 0.001705 seconds

> Test :: Sub tests
        [001] expect/test.jai 18:9 :: equality check OK
        [002] expect/test.jai 21:9 :: equality check OK
        [003] expect/test.jai 22:9 :: equality check OK
        [004] expect/test.jai 24:9 :: equality check FAIL (expected failure)
> 4/4 test(s) passed! Set took 0.002176 seconds

> Test :: Some tests
        [001] expect/test.jai 28:9 :: equality check OK
        [002] expect/test.jai 33:9 :: equality check OK
> 2/2 test(s) passed! Set took 0.001112 seconds
```

See `test.jai` for more examples.

# Note

This was originally written using a very old version of Jai. Only the necessary steps to get it compiling
on the latest version have been taken. I will work to clean this up and improve it soon.

# License

MIT
