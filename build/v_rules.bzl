"""Bazel rules for V language integration and c2v translation"""

def _v_object_impl(ctx):
    """Implementation of v_object rule"""
    
    # Try to get V from the toolchain first, fall back to local paths
    v_home = ctx.var.get("V_HOME", "")
    if not v_home:
        # Check for bzlmod-provided V toolchain
        if hasattr(ctx.attr, "_v_toolchain") and ctx.attr._v_toolchain:
            v_home = ctx.files._v_toolchain[0].dirname if ctx.files._v_toolchain else ""
        if not v_home:
            v_home = ctx.workspace_name + "/.build-tools/v"
    
    output = ctx.actions.declare_file(ctx.attr.output_name + ".o")
    
    args = ctx.actions.args()
    args.add("--v-home", v_home)
    args.add("--output", output.path)
    args.add("--target-name", ctx.attr.output_name)
    
    if ctx.attr.translate_from_c:
        args.add("--translate-c")
    
    for flag in ctx.attr.v_flags:
        args.add("--v-flag", flag)
    
    for src in ctx.files.srcs:
        args.add("--source", src.path)
    
    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = [output],
        executable = ctx.executable._v_compile_tool,
        arguments = [args],
        mnemonic = "VCompile",
        progress_message = "Compiling V: %s" % ctx.label.name,
    )
    
    return [DefaultInfo(files = depset([output]))]

v_object = rule(
    implementation = _v_object_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".v", ".c"],
            doc = "List of V or C source files",
        ),
        "output_name": attr.string(
            doc = "Base name for output files",
            mandatory = True,
        ),
        "translate_from_c": attr.bool(
            default = False,
            doc = "If true, use c2v to translate C sources to V first",
        ),
        "v_flags": attr.string_list(
            default = [],
            doc = "Additional flags to pass to the V compiler",
        ),
        "_v_compile_tool": attr.label(
            default = "//build:v_compile_tool",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Builds V source files or translates C to V and produces object files",
)

def _c2v_translate_impl(ctx):
    """Implementation of c2v_translate rule"""
    
    v_home = ctx.var.get("V_HOME", "")
    if not v_home:
        v_home = ctx.workspace_name + "/.build-tools/v"
    
    outputs = []
    for src in ctx.files.srcs:
        out_file = ctx.actions.declare_file(src.basename.replace(".c", ".v"))
        outputs.append(out_file)
    
    args = ctx.actions.args()
    args.add("--v-home", v_home)
    args.add("--output-dir", outputs[0].dirname)
    
    for src in ctx.files.srcs:
        args.add("--source", src.path)
    
    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = outputs,
        executable = ctx.executable._v_translate_tool,
        arguments = [args],
        mnemonic = "C2VTranslate",
        progress_message = "Translating C to V: %s" % ctx.label.name,
    )
    
    return [DefaultInfo(files = depset(outputs))]

c2v_translate = rule(
    implementation = _c2v_translate_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".c", ".h"],
            mandatory = True,
            doc = "List of C source files to translate",
        ),
        "_v_translate_tool": attr.label(
            default = "//build:v_translate_tool",
            executable = True,
            cfg = "exec",
        ),
    },
    doc = "Translates C sources to V without compiling",
)

def v_library(name, srcs, translate_from_c = False, v_flags = [], deps = [], **kwargs):
    """Build a V library
    
    Args:
        name: Name of the library
        srcs: List of V or C source files
        translate_from_c: If true, translate C sources to V first
        v_flags: Additional V compiler flags
        deps: Dependencies on other v_library targets
        **kwargs: Additional arguments passed to v_object
    """
    v_object(
        name = name,
        srcs = srcs,
        output_name = name,
        translate_from_c = translate_from_c,
        v_flags = v_flags,
        **kwargs
    )

def v_test(name, srcs, v_flags = [], deps = [], **kwargs):
    """Build and run V tests
    
    Args:
        name: Name of the test target
        srcs: List of V source files containing tests
        v_flags: Additional V compiler flags
        deps: Dependencies on other v_library targets
        **kwargs: Additional arguments passed to native.sh_test
    """
    # Create a library from the test sources  
    # Note: We pass test=true as a named flag, not a bare flag
    test_flags = v_flags + ["test=true"]
    
    v_object(
        name = name + "_lib",
        srcs = srcs,
        output_name = name + "_test",
        v_flags = test_flags,
    )
    
    # Collect all dependency data
    data_deps = [":" + name + "_lib"] + deps
    
    # Create a test runner script (placeholder until V runner is available)
    native.sh_test(
        name = name,
        srcs = ["//build:v_test_runner.sh"],
        args = ["$(location :" + name + "_lib)"],
        data = data_deps,
        **kwargs
    )
