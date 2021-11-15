#scope_export;
expect :: (expr: bool, error_message := "", args: ..Any, expected_to_fail := false, loc := #caller_location) -> bool #expand {
    iteration := find_or_cache_expect(loc);
    passed := expr && !expected_to_fail || !expr && expected_to_fail;
    if passed && iteration > 0 return true;

    flags: Log_Flags;
    builder: String_Builder;
    defer if builder.base_buffer.occupied > 0 {
        log(builder_to_string(*builder), flags = flags);
        // free_buffers(*builder);
    }

    filename := condense_path(loc.fully_pathed_filename);
    line, column := formatInt(loc.line_number, 10, 2), formatInt(loc.character_number, 10, 2);

    print_to_builder(*builder, "\t[%] % %:%", formatInt(total_expects, 10, 3), filename, line, column);
    total_expects += 1;

    if passed {
        if iteration <= 0 append(*builder, " pass");
        expects_passed += 1;
        return true;
    }

    append(*builder, ifx expected_to_fail " unexpected pass" else " fail");
    if iteration > 0 print_to_builder(*builder, ", iteration %", iteration);

    if error_message.count {
        append(*builder, " :: ");
        print_to_builder(*builder, error_message, ..args);
    }

    if halt_on_first_fail {
        log(builder_to_string(*builder));
        compiler_report("Testing halted due to failed expectation!", loc = loc);
        return false; // Unreachable
    }

    flags = .ERROR;
    return false;
}

test :: (test_name: string, body: Code, halt_on_fail := true, loc := #caller_location) #expand {
    if tests_ran == 0 log("> Running tests\n\n");

    filename := condense_path(loc.fully_pathed_filename);
    log("> % :: % %:%",
        test_name,
        filename,
        loc.line_number,
        loc.character_number,
        flags = .VERBOSE_ONLY
    );

    halt_on_first_fail = halt_on_fail;

    __start := get_time();
    #insert body;
    __end := get_time();

    log("> %/% test% passed. Time: % seconds\n\n",
        expects_passed,
        total_expects,
        ifx total_expects == 1 "" else "s",
        __end - __start,
        flags = .VERBOSE_ONLY
    );

    tests_ran += 1;
    expects_passed = 0;
    total_expects = 0;
    halt_on_first_fail = false;
}

#scope_file
locations: Table(u64, int);

tests_ran := 0;
total_expects := 0;
expects_passed := 0;
halt_on_first_fail := false;

get_hash :: inline (loc: Source_Code_Location, identifier: s64) -> u64 {
    hash := cast(u64)loc.fully_pathed_filename.data * cast,no_check(u64)(loc.line_number + 1) * cast(u64)(identifier + 1);
    return hash;
}

find_or_cache_expect :: (location: Source_Code_Location) -> iteration: int {
    hash := get_hash(location, 0);

    iteration, found := table_find(locations, hash);
    if !found {
        table_add(*locations, hash, 0);
        return 0;
    }

    iteration += 1;
    table_set(*locations, hash, iteration);
    return iteration;
}

condense_path :: (path: string) -> string {
    already_found_last := false;
    last_index := 0;

    for < path.count - 1..0 {
        if path.data[it] == #char "/" || path.data[it] == #char "\\" {
            if already_found_last {
                last_index = it + 1;
                break;
            }
            else {
                already_found_last = true;
            }
        }
    }

    len := path.count;
    if len < 0 len = 0;

    return slice(path, last_index, len);
}

// Tests for expect itself
#if false #run {
    set_build_options_dc(.{ do_output = false });

    test("Condense Path", #code {
        path: string = ---;

        path = "path/to/my/file.txt";
        expect(condense_path(path) == "my/file.txt");

        path = "path\\to\\my-folder\\and\\file.filename";
        expect(condense_path(path) == "and\\file.filename");

        path = "a-path/with\\mixed/slashes";
        expect(condense_path(path) == "mixed/slashes");

        path = "\\//////////\\\\////";
        expect(condense_path(path) == "/");

        path = "//\\\\\\\\\\\\\\\\\\\\////\\\\\\\\";
        expect(condense_path(path) == "\\");
    });
}

#import "Basic";
#import "String";
#import "Compiler";
#import "Hash_Table";
#import "Program_Print";
