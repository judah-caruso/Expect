# Expect

Compile-time testing module for the Jai language.

# Usage

```c++
#import "Expect";

#run {
    set("Some group of tests", #code {
        expect(1 == 1, "One did not equal one!");
        expect(1 == 2, should_fail = true); // Allow intentionally failing tests
        expect(call_to_thing(), "Call to thing failed!");
    });

    // You can choose to run all tests (regardless of if previous fail or not)
    set("Some tests may fail", exit_on_first_fail = false, #code {
        expect(-1 == 2);
        expect(some_variable == -1, "Some variable was supposed to be -1");
        expect(-4 < 1, should_fail = true);
    });
}

// Alternate usage
#placeholder RUN_TESTS; // Provide this via build
#if RUN_TESTS #run {
    // ...
}
```

See `test.jai` for more examples.

# Note

This was originally written using a very old version of Jai. Only the necessary steps to get it compiling
on the latest version have been taken. I will work to clean this up and improve it soon.
