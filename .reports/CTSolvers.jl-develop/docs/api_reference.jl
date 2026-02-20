# ==============================================================================
# CTSolvers API Reference Generator
# ==============================================================================
#
# This file generates the API reference documentation for CTSolvers.
# It uses CTBase.automatic_reference_documentation to scan source files
# and generate documentation pages.
#
# ==============================================================================

"""
    generate_api_reference(src_dir::String, ext_dir::String)

Generate the API reference documentation for CTSolvers.
Returns the list of pages.
"""
function generate_api_reference(src_dir::String, ext_dir::String)
    # Helper to build absolute paths
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    ext(files...) = [abspath(joinpath(ext_dir, f)) for f in files]

    # Symbols to exclude from documentation
    EXCLUDE_SYMBOLS = Symbol[
        :include,
        :eval,
    ]

    pages = [

        # ───────────────────────────────────────────────────────────────────
        # DOCP
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.DOCP => src(
                    joinpath("DOCP", "DOCP.jl"),
                    joinpath("DOCP", "accessors.jl"),
                    joinpath("DOCP", "building.jl"),
                    joinpath("DOCP", "contract_impl.jl"),
                    joinpath("DOCP", "types.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="DOCP",
            title_in_menu="DOCP",
            filename="docp",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Modelers
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Modelers => src(
                    joinpath("Modelers", "Modelers.jl"),
                    joinpath("Modelers", "abstract_modeler.jl"),
                    joinpath("Modelers", "adnlp.jl"),
                    joinpath("Modelers", "exa.jl"),
                    joinpath("Modelers", "validation.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Modelers",
            title_in_menu="Modelers",
            filename="modelers",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Optimization
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Optimization => src(
                    joinpath("Optimization", "Optimization.jl"),
                    joinpath("Optimization", "abstract_types.jl"),
                    joinpath("Optimization", "builders.jl"),
                    joinpath("Optimization", "building.jl"),
                    joinpath("Optimization", "contract.jl"),
                    joinpath("Optimization", "solver_info.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Optimization",
            title_in_menu="Optimization",
            filename="optimization",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Options
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Options => src(
                    joinpath("Options", "Options.jl"),
                    joinpath("Options", "extraction.jl"),
                    joinpath("Options", "not_provided.jl"),
                    joinpath("Options", "option_definition.jl"),
                    joinpath("Options", "option_value.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Options",
            title_in_menu="Options",
            filename="options",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Orchestration
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Orchestration => src(
                    joinpath("Orchestration", "Orchestration.jl"),
                    joinpath("Orchestration", "disambiguation.jl"),
                    joinpath("Orchestration", "routing.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Orchestration",
            title_in_menu="Orchestration",
            filename="orchestration",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Solvers
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Solvers => src(
                    joinpath("Solvers", "Solvers.jl"),
                    joinpath("Solvers", "abstract_solver.jl"),
                    joinpath("Solvers", "common_solve_api.jl"),
                    joinpath("Solvers", "ipopt.jl"),
                    joinpath("Solvers", "knitro.jl"),
                    joinpath("Solvers", "madncl.jl"),
                    joinpath("Solvers", "madnlp.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Solvers",
            title_in_menu="Solvers",
            filename="solvers",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Strategies — Contract (abstract types, default implementations)
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Strategies => src(
                    joinpath("Strategies", "Strategies.jl"),
                    joinpath("Strategies", "contract", "abstract_strategy.jl"),
                    joinpath("Strategies", "contract", "metadata.jl"),
                    joinpath("Strategies", "contract", "strategy_options.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Strategies — Contract",
            title_in_menu="Strategies (Contract)",
            filename="strategies_contract",
        ),

        # ───────────────────────────────────────────────────────────────────
        # Strategies — API (registry, builders, introspection, configuration)
        # ───────────────────────────────────────────────────────────────────
        CTBase.automatic_reference_documentation(;
            subdirectory="api",
            primary_modules=[
                CTSolvers.Strategies => src(
                    joinpath("Strategies", "api", "builders.jl"),
                    joinpath("Strategies", "api", "configuration.jl"),
                    joinpath("Strategies", "api", "disambiguation.jl"),
                    joinpath("Strategies", "api", "introspection.jl"),
                    joinpath("Strategies", "api", "registry.jl"),
                    joinpath("Strategies", "api", "utilities.jl"),
                    joinpath("Strategies", "api", "validation_helpers.jl"),
                ),
            ],
            exclude=EXCLUDE_SYMBOLS,
            public=true,
            private=true,
            title="Strategies — API",
            title_in_menu="Strategies (API)",
            filename="strategies_api",
        ),

    ]

    # ───────────────────────────────────────────────────────────────────
    # Extension: Ipopt
    # ───────────────────────────────────────────────────────────────────
    CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)
    if !isnothing(CTSolversIpopt)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory="api",
                primary_modules=[
                    CTSolversIpopt => ext("CTSolversIpopt.jl"),
                ],
                external_modules_to_document=[CTSolvers],
                exclude=EXCLUDE_SYMBOLS,
                public=true,
                private=true,
                title="Ipopt Extension",
                title_in_menu="Ipopt",
                filename="ext_ipopt",
            ),
        )
    end

    # ───────────────────────────────────────────────────────────────────
    # Extension: MadNLP
    # ───────────────────────────────────────────────────────────────────
    CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)
    if !isnothing(CTSolversMadNLP)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory="api",
                primary_modules=[
                    CTSolversMadNLP => ext("CTSolversMadNLP.jl"),
                ],
                external_modules_to_document=[CTSolvers],
                exclude=EXCLUDE_SYMBOLS,
                public=true,
                private=true,
                title="MadNLP Extension",
                title_in_menu="MadNLP",
                filename="ext_madnlp",
            ),
        )
    end

    # ───────────────────────────────────────────────────────────────────
    # Extension: MadNCL
    # ───────────────────────────────────────────────────────────────────
    CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)
    if !isnothing(CTSolversMadNCL)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory="api",
                primary_modules=[
                    CTSolversMadNCL => ext("CTSolversMadNCL.jl"),
                ],
                external_modules_to_document=[CTSolvers],
                exclude=EXCLUDE_SYMBOLS,
                public=true,
                private=true,
                title="MadNCL Extension",
                title_in_menu="MadNCL",
                filename="ext_madncl",
            ),
        )
    end

    # ───────────────────────────────────────────────────────────────────
    # Extension: Knitro
    # ───────────────────────────────────────────────────────────────────
    CTSolversKnitro = Base.get_extension(CTSolvers, :CTSolversKnitro)
    if !isnothing(CTSolversKnitro)
        push!(
            pages,
            CTBase.automatic_reference_documentation(;
                subdirectory="api",
                primary_modules=[
                    CTSolversKnitro => ext("CTSolversKnitro.jl"),
                ],
                external_modules_to_document=[CTSolvers],
                exclude=EXCLUDE_SYMBOLS,
                public=true,
                private=true,
                title="Knitro Extension",
                title_in_menu="Knitro",
                filename="ext_knitro",
            ),
        )
    end

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