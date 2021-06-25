#run {
    target := get_build_options();
    target.output_type = .NO_OUTPUT;
    set_build_options(target);

    workspace := compiler_create_workspace();
    set_build_options(target, workspace);

    add_build_file("source/main.jai", workspace);
    add_build_string(tprint("RUN_TESTS :: true;"), workspace);
}

#import "File";
#import "Basic";
#import "String";
#import "Compiler";
