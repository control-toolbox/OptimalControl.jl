# ==============================================================================
# OptimalControl API Reference Generator
# ==============================================================================
#
# This file generates the API reference documentation for OptimalControl.
# It uses CTBase.automatic_reference_documentation to scan source files
# and generate documentation pages.
#
# ==============================================================================

"""
    generate_api_reference(src_dir::String, ext_dir::String)

Generate the API reference documentation for OptimalControl.
Returns the list of pages.
"""
function generate_api_reference(src_dir::String, ext_dir::String)
    # Helper to build absolute paths
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    ext(files...) = [abspath(joinpath(ext_dir, f)) for f in files]

    # Symbols to exclude from documentation
    EXCLUDE_SYMBOLS = Symbol[:include, :eval]

    pages = [

        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                OptimalControl => src(
                    joinpath("helpers", "component_checks.jl"),
                    joinpath("helpers", "component_completion.jl"),
                    joinpath("helpers", "descriptive_routing.jl"),
                    joinpath("helpers", "kwarg_extraction.jl"),
                    joinpath("helpers", "methods.jl"),
                    joinpath("helpers", "print.jl"),
                    joinpath("helpers", "registry.jl"),
                    joinpath("helpers", "strategy_builders.jl"),
                    joinpath("solve", "canonical.jl"),
                    joinpath("solve", "descriptive.jl"),
                    joinpath("solve", "dispatch.jl"),
                    joinpath("solve", "explicit.jl"),
                    joinpath("solve", "mode.jl"),
                    joinpath("solve", "mode_detection.jl"),
                ),
            ],
            external_modules_to_document=[CTBase, CTModels, CTSolvers],
            exclude=EXCLUDE_SYMBOLS,
            public=false,
            private=true,
            title="Private",
            title_in_menu="Private",
            filename="private",
        ),

        # # ───────────────────────────────────────────────────────────────────
        # # Main Module
        # # ───────────────────────────────────────────────────────────────────
        # CTBase.automatic_reference_documentation(;
        #     subdirectory="api",
        #     primary_modules=[
        #         OptimalControl => src(
        #             "OptimalControl.jl",
        #         ),
        #     ],
        #     external_modules_to_document=[CommonSolve, CTBase, CTDirect, CTFlows, CTModels, CTParser, CTSolvers],
        #     exclude=EXCLUDE_SYMBOLS,
        #     public=true,
        #     private=true,
        #     title="Main Module",
        #     title_in_menu="Main Module",
        #     filename="main_module",
        # ),

    ]

    return pages
end

"""
    with_api_reference(f::Function, src_dir::String, ext_dir::String)

Generates the API reference, executes `f(pages)`, and cleans up generated files.
"""
function with_api_reference(f::Function, src_dir::String, ext_dir::String)
    pages = generate_api_reference(src_dir, ext_dir)
    try
        f(pages)
    finally
        # Clean up generated files
        docs_src = abspath(joinpath(@__DIR__, "src"))
        _cleanup_pages(docs_src, pages)
    end
end

function _cleanup_pages(docs_src::String, pages)
    for p in pages
        val = last(p)
        if val isa AbstractString
            fname = endswith(val, ".md") ? val : val * ".md"
            full_path = joinpath(docs_src, fname)
            if isfile(full_path)
                rm(full_path)
                println("Removed temporary API doc: $full_path")
            end
        elseif val isa AbstractVector
            _cleanup_pages(docs_src, val)
        end
    end
end