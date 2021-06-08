#scope_export

// This is written in a pretty hard-n-fast way, really just tried to make a
// drop in replacement for assert that gives some more info and can infer
// what was supposed to happen in a less "failure at line X" kinda way.
// Think of it as a proof of concept that's stable enough to be used.

// @Note(Judah): This definitely needs to be rewritten at some point in the
// future to allow more extensibility and usability in a CI/CD pipeline.

/*
    @Todo:
    - Major cleanup (especially in expect)
    - Gather more information from expressions (more than just what kind of operator was used)
    - Make the error output better, improve output when something passes but should_fail is set
    - Have expect compile_report if not called from within a set
    - Expects in loops cause desyncs because they're not treated as being in a loop
*/

set :: (name: string, $code: Code, exit_on_first_fail := true, loc := #caller_location)
{
    total_tests := 0;
    passing_tests := 0;

    if FIRST_SET_EXECUTED print("> Running sets\n\n");
    filename := path_strip_extension(path_filename(loc.fully_pathed_filename));
    print("> % :: %\n", to_casey_case(filename, true), name);

    __expr_strings: [..]string;
    // __expr_locs: [..]Source_Code_Location;

    submit_calls_to_expect :: (exprs: *[..]string, block: *Code_Block)
    {
        for block.statements
        {
            if it.kind == .PROCEDURE_CALL {
                proc := cast(*Code_Procedure_Call)it;
                if proc.procedure_expression.kind != .IDENT continue;
                ident := cast(*Code_Ident)proc.procedure_expression;
                if ident.name != "expect" continue;

                for arg: proc.arguments_unsorted
                {
                    expr := arg.expression;
                    node := cast(*Code_Node)*arg;

                    // @Todo(Judah): Make expects that get called in loops only add one expr string
                    location: Source_Code_Location;
                    location.line_number = node.l0;
                    location.character_number = node.c0;
                    // location.fully_pathed_filename = node.filename;
                    if node.enclosing_load {
                        location.fully_pathed_filename = node.enclosing_load.fully_pathed_filename;
                    }

                    if expr.kind == {
                        case .BINARY_OPERATOR; {
                            binop := cast(*Code_Binary_Operator)expr;

                            left_or_right_is_pointer := false;
                            if !left_or_right_is_pointer && binop.right.kind == .LITERAL {
                                left_or_right_is_pointer = (cast(*Code_Literal)binop.right).value_type == .POINTER;
                            }
                            if !left_or_right_is_pointer && binop.left.kind == .LITERAL {
                                left_or_right_is_pointer = (cast(*Code_Literal)binop.left).value_type == .POINTER;
                            }

                            if left_or_right_is_pointer {
                                array_add(exprs, "pointer comparison");
                                continue it;
                            }

                            if cast(Operator_Type)binop.operator_type == {
                                case .IS_EQUAL; {
                                    array_add(exprs, "equality check");
                                    continue it;
                                }
                                case .IS_NOT_EQUAL; {
                                    array_add(exprs, "inequality check");
                                    continue it;
                                }
                                case .LESS_EQUALS; {
                                    array_add(exprs, "less-than or equal to check");
                                    continue it;
                                }
                                case .GREATER_EQUALS; {
                                    array_add(exprs, "greater-than or equal to check");
                                    continue it;
                                }
                                case .LOGICAL_AND; {
                                    array_add(exprs, "logical and check");
                                    continue it;
                                }
                                case .LOGICAL_OR; {
                                    array_add(exprs, "logical or check");
                                    continue it;
                                }
                                case; {
                                    if binop.operator_type == {
                                        case #char "<"; {
                                            array_add(exprs, "less-than check");
                                            continue it;
                                        }
                                        case #char ">"; {
                                            array_add(exprs, "greater-than check");
                                            continue it;
                                        }
                                        case; {
                                            str: string = ---;
                                            str.count = 1;
                                            str.data = *cast(u8)binop.operator_type;
                                            array_add(exprs, tprint("% check", str));
                                            continue it;
                                        }
                                    }
                                }
                            }
                        }

                        case .UNARY_OPERATOR; {
                            array_add(exprs, "unary check");
                            continue it;
                        }

                        case .LITERAL; {
                            literal := cast(*Code_Literal)expr;
                            print("Literal: %\n", literal.value_type);
                            array_add(exprs, "literal check");
                            continue it;
                        }

                        case .PROCEDURE_CALL; {
                            proc := cast(*Code_Procedure_Call)expr;

                            if proc.procedure_expression.kind != .IDENT {
                                print("Procedure expression kind was: %\n", proc.procedure_expression.kind);
                                array_add(exprs, "procedure call check");
                                continue it;
                            }

                            proc_name := (cast(*Code_Ident)proc.procedure_expression).name;
                            array_add(exprs, tprint("procedure '%'", proc_name));
                            continue it;
                        }

                        // @Todo(Judah): Handle when just booleans without comparsions are passed in
                        // case .IDENT; {
                        // }

                        case; {
                            array_add(exprs, tprint("% #%", ident.name, exprs.count + 1));
                            continue it;
                        }
                    }
                }
            }
            else if it.kind == .BLOCK {
                submit_calls_to_expect(exprs, cast(*Code_Block)it);
            }
        }
    }

    root := compiler_get_nodes(code);
    if root.kind == .BLOCK {
        block := cast(*Code_Block)root;
        submit_calls_to_expect(*__expr_strings, block);
    }

    __start := get_time();
    {
        #insert_internal code;
    }
    __end := get_time();

    print("> %/% test(s) passed! Set took % seconds\n\n", passing_tests, total_tests, __end - __start);

    FIRST_SET_EXECUTED = false;
    array_reset_keeping_memory(*__expr_strings); // This should be faster than calling array_reset after every set?
}

expect :: (expr: bool, note := "", note_args: ..Any, should_fail := false, loc := #caller_location) #expand
{
    filename := condense_path(loc.fully_pathed_filename);

    // Bandaid for now
    print("\t[%] % %:% :: ", formatInt(`total_tests + 1, minimum_digits = 3), filename, loc.line_number, loc.character_number);

    if `total_tests >= `__expr_strings.count {
        if note.count > 0 print(tprint("% ", note), ..note_args);
        else print("unknown check ");
    }
    else {
        print("% ", `__expr_strings[`total_tests]);
    }

    if expr {
        if should_fail {
            print_color("FAIL (unexpected pass)\n", color = FOREGROUND_RED);

            if `exit_on_first_fail {
                end := get_time();
                print("> Test #% failed! Set took % seconds\n\n", `total_tests + 1, end - `__start);

                error: string;
                error_base := "Expectation failed";

                if note.count > 0
                    error = tprint(tprint("%: %\n", error_base, note), ..note_args);
                else
                    error = tprint("%!\n", error_base);

                compiler_report(error, loc);
            }
        }
        else {
            `passing_tests += 1;
            print_color("OK\n", color = FOREGROUND_GREEN);
        }
    }
    else {
        print_color("FAIL", note, color = FOREGROUND_RED);

        if should_fail {
            print(" (expected failure)\n");
            `passing_tests += 1;
        }
        else {
            if note.count > 0 print(tprint(" (%)", note), ..note_args);
            print("\n");

            if `exit_on_first_fail {
                end := get_time();
                print("> Test #% failed! Set took % seconds\n\n", `total_tests + 1, end - `__start);

                error: string;
                error_base := "Expectation failed";

                if note.count > 0
                    error = tprint(tprint("%: %\n", error_base, note), ..note_args);
                else
                    error = tprint("%!\n", error_base);

                compiler_report(error, loc);
            }
        }
    }

    `total_tests += 1;
}

#scope_file
FIRST_SET_EXECUTED := true;

condense_path :: (path: string) -> string
{
    already_found_last := false;
    last_index := 0;

    for <path.count - 1..0
    {
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

is_upper         :: inline (chr: u8) -> bool { return chr >= #char "A" && chr <= #char "Z"; }
is_lower         :: inline (chr: u8) -> bool { return chr >= #char "a" && chr <= #char "z"; }
is_word_boundary :: inline (chr: u8) -> bool { return chr == #char "_" || chr == #char " " || chr == #char "." || chr == #char "-"; }

to_casey_case :: (convert: string, separate_words_with_underscores := false) -> string
{
    builder: String_Builder;
    defer free_buffers(*builder);

    next_should_be_upper := false;
    for i: 0..convert.count - 1
    {
        chr := convert.data[i];

        if i == 0 {
            append(*builder, to_upper(chr));
            continue;
        }

        if is_word_boundary(chr) {
            next_should_be_upper = true;
            if separate_words_with_underscores append(*builder, "_");
            continue;
        }

        if next_should_be_upper {
            append(*builder, to_upper(chr));
            next_should_be_upper = false;
            continue;
        }

        append(*builder, to_lower(chr));
    }

    return builder_to_string(*builder);
}

// Set to 'true' to run tests for 'expect'

#if !true #run {
    set("Expect vs assert", #code {
        // Tests that are expected to pass
        expect(1 == 1);
        assert(1 == 1);

        expect(1 <= 2);
        assert(1 <= 2);

        expect(1 >= 0);
        assert(1 >= 0);

        value := 10;
        sq := value * value;
        expect(((x: int) -> int { return x * x; })(value) == sq, "lambda didn't evaluate to %", sq);
        assert(((x: int) -> int { return x * x; })(value) == sq, "lambda didn't evaluate to %", sq);

        x := 0;
        while x < 1000 x += 1;
        expect(x == 1000);
        assert(x == 1000);

        // Tests that are expected to fail
        less_than_zero :: (n: int) -> bool { return n < 0; }
        expect(less_than_zero(10), should_fail = true);
        assert(!less_than_zero(10)); // Doesn't have should_fail

        expect(!0 == false, should_fail = true);
        assert(!0 != false); // Doesn't have should fail

        expect(!1 == true, should_fail = true);
        assert(!1 != true);
    });

    set("Casey case conversion", #code {
        str: string = ---;
        {
            str = "hello_world";
            expect(to_casey_case(str) == "HelloWorld");
        }
        {
            str = "This_is_A_test";
            expect(to_casey_case(str) == "ThisIsATest");
        }
        {
            str = "also_A_Test";
            expect(to_casey_case(str, true) == "Also_A_Test");
        }
        {
            str = "someTestThisIs";
            expect(to_casey_case(str) == "SomeTestThisIs", should_fail = true);
        }
    });
}

#import "Basic";
#import "String";
#import "Compiler";
#import "Print_Color";
