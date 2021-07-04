add :: (x: int, y: int) -> int { return x + y; }
sub :: (x: int, y: int) -> int { return x - y; }

Pair :: struct {
    lhs: int;
    rhs: int;
}

main :: () {
    operations: [..]Pair;

    print(":: Addition\n");
    for 1..50 {
        pair := array_add(*operations);
        pair.lhs = 2 * it >> 1 + 1;
        pair.rhs = pair.lhs * it << 2 - 1;

        lhs := pair.lhs;
        rhs := pair.rhs;
        print("\t% + % is %\n", lhs, rhs, add(lhs, rhs));
    }

    print("\n:: Subtraction\n");
    for operations {
        lhs := it.lhs;
        rhs := it.rhs;
        print("\t% - % is %\n", rhs, lhs, sub(rhs, lhs));
    }
}

// true could be replaced with a variable created by your build file:
// #if RUN_TESTS #run { ...
#if true #run {
    // Basic 'test suites' for add and sub.
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

    bad_request_values: [..]int;
    defer array_free(bad_request_values);

    // You may want to allow tests to fail (if they involve networking, etc.).
    // This is a simple way to do that:
    test("Loops (expected to fail)", #code {
        timeouts := 0;
        timeout_period := 250; // our 'TTL'

        for 1..100 {
            x := it;
            x2 := it * 2;

            value := add(x, x2); // Pretend this is a network request.

            if it % 19 == 0 {
                sleep_milliseconds(xx timeout_period); // Pretend this is the request timing out.
                array_add(*bad_request_values, value);
                value = 0;
            }

            pass := expect(value > 0, "Request timed out after %ms!", timeout_period);
            if !pass timeouts += 1;

            if timeouts >= 5 {
                // To completely halt all subsequent tests after 5 failures:
                // compiler_report(tprint("Test halted after % request timeouts!", timeouts));
                break;
            }
        }
    });

    // Tests can rely on previous tests
    test("Check request values (expected to fail)", #code {
        for bad_request_values {
            expect(it <= 0, "Request with value % unexpectedly failed in previous test!", it);
        }
    });

    // Because all output is routed through the context logger, you can control
    // where the output goes.
    Test_Data :: struct {
        pass_file: File;
        fail_file: File;
    }

    // A simple logger that splits passing and failing tests into separate files.
    log_to_file :: (message: string, data: *void, info: Log_Info) {
        test := cast(*Test_Data)data;
        if !test || message.count <= 1 || info.common_flags & .VERBOSE_ONLY return;

        str := trim(message);
        handle: *File = ---;
        if info.common_flags & .ERROR {
            handle = *test.fail_file;
        }
        else {
            handle = *test.pass_file;
        }

        file_write(handle, tprint("%\n", str));
    }

    data: Test_Data;
    {
        file, ok := file_open("passing.text", true);
        if !ok return;
        data.pass_file = file;
    }

    {
        file, ok := file_open("failing.text", true);
        if !ok return;
        data.fail_file = file;
    }

    // Backup the previous logger (optional)
    previous_logger := context.logger;
    previous_data   := context.logger_data;

    // Use our custom logger
    context.logger = log_to_file;
    context.logger_data = *data;

    test("Writing things to file", #code {        
        for 0..100 {
            value := add(it, 1);
            expect(value == it + 1, "Value % was invalid!", value);
        }

        expect(true != true);
        expect(true || false && true);
        expect(true != true);
        expect(true || false && true);
    });

    test("More tests", #code {
        for 0..100 {
            if it % 19 == 0 {
                expect(false, "This failed!");
            }
            else {
                expect(true);
            }
        }
    });

    file_close(*data.pass_file);
    file_close(*data.fail_file);

    // Switch back to the previous logger
    context.logger = previous_logger;
    context.logger_data = previous_data;

    // A 'suite' that checks if we had more passing or failing tests based on
    // the files that were created by our custom logger.
    test("Test comparison", #code {
        passing, p_ok := read_entire_file("passing.text");
        expect(p_ok, "Unable to open passing test output file!");

        failing, f_ok := read_entire_file("failing.text"); 
        expect(f_ok, "Unable to open failing test output file!");

        pass_lines := split(passing, "\n").count;
        fail_lines := split(failing, "\n").count;

        // This is expected to fail, that's why it's the last test in the program.
        expect(pass_lines > fail_lines, "There were % more failing tests than passing! (expected)", fail_lines - pass_lines);
    }, halt_on_fail = true);
}

#load "../module.jai";
#import "Basic";
#import "File";
