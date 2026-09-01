# Thematic API reference manifest.
#
# Each theme is a literal, hand-maintained list of symbols — no scraping of
# docs/reports/99-api-coverage.md. That file is prose meant for a human to
# read and copy from, not a machine-parseable format: an earlier version of
# this script tried to extract symbols from it automatically and silently
# picked up names from sentences that explicitly said *not* to document them
# (e.g. "solve_explicit ... not documented as available"), and lost the
# module qualification some symbols need to resolve in `@docs` (a bare
# `constraint` does not resolve; `CTModels.Components.constraint` does).
#
# When 99-api-coverage.md changes, update the lists below by hand and rerun
# `julia --project=docs docs/make.jl` to check the completeness error and the
# build log for new "undefined binding" / "no docs found" warnings.

const EXCLUDE_SYMBOLS = [:include, :eval, :OptimalControl]

# Re-exported purely as escape hatches for generated code / cross-package
# qualification (see docs/reports/99-api-coverage.md §1 "Module aliases").
# They carry no docstring of their own (`@doc` on a bare module without one
# resolves to Julia's generic "here are its exports" filler, identical across
# all of them — not worth transcluding). Described in prose on qualified.md
# instead of `@docs`, so they need an explicit exemption from the
# completeness check below.
const MODULE_ALIASES = [:CTBase, :CTLie, :CTFlows, :CTModels, :ADNLPModels, :ExaModels]

const API_THEMES = [
    (
        id="modelling",
        title="Modelling",
        symbols=[
            Symbol("@def"),
            Symbol("@init"),
            :time!,
            :state!,
            :control!,
            :variable!,
            :dynamics!,
            :objective!,
            Symbol("CTModels.Building.constraint!"),
            :time_dependence!,
            :build,
            :build_initial_guess,
        ],
    ),
    (
        id="problem",
        title="Problem",
        symbols=[
            # Dimensions and names
            :state_dimension,
            :state_name,
            :state_components,
            :control_dimension,
            :control_name,
            :control_components,
            :variable_dimension,
            :variable_name,
            :variable_components,
            :components,
            :dimension,
            :name,
            # Generic component accessors
            :index,
            :expression,
            :criterion,
            # Times
            :initial_time,
            :final_time,
            :times,
            :time_name,
            :initial_time_name,
            :final_time_name,
            :has_fixed_initial_time,
            :has_free_initial_time,
            :has_fixed_final_time,
            :has_free_final_time,
            :is_initial_time_fixed,
            :is_initial_time_free,
            :is_final_time_fixed,
            :is_final_time_free,
            # Dynamics and cost
            :dynamics,
            :mayer,
            :lagrange,
            :has_mayer_cost,
            :has_lagrange_cost,
            :is_mayer_cost_defined,
            :is_lagrange_cost_defined,
            # Constraints
            Symbol("CTModels.Models.constraint"),
            :constraints,
            :path_constraints_nl,
            :boundary_constraints_nl,
            :state_constraints_box,
            :control_constraints_box,
            :variable_constraints_box,
            :dim_path_constraints_nl,
            :dim_boundary_constraints_nl,
            :dim_state_constraints_box,
            :dim_control_constraints_box,
            :dim_variable_constraints_box,
            # Definition
            :definition,
            :has_abstract_definition,
            :is_abstractly_defined,
            # Traits
            :is_autonomous,
            :is_nonautonomous,
            :is_variable,
            :is_nonvariable,
            :has_variable,
            :has_control,
            :is_control_free,
        ],
    ),
    (
        id="solving",
        title="Solving",
        symbols=[
            # `solve` and `methods` are bare-name qualified below (Pair form): both are
            # generic functions the wider Julia/SciML ecosystem extends heavily, and a
            # bare `:solve`/`:methods` pulls in every loaded package's docstring for the
            # binding, not just ours (traced in the Phase D campaign report — e.g. Base's
            # own `methods` docstring cross-references `which`/`@which`/`methodswith`,
            # none of which resolve in this build).
            :solve => "solve(::CTModels.AbstractModel, ::Symbol...)",
            :solve =>
                "solve(::CTModels.AbstractModel, ::CTModels.AbstractInitialGuess, " *
                "::CTSolvers.DOCP.AbstractDiscretizer, " *
                "::CTSolvers.Modelers.AbstractNLPModeler, " *
                "::CTSolvers.Solvers.AbstractNLPSolver)",
            :methods => "methods()",
            :discretize,
            :ocp_model,
            :nlp_model,
            :ocp_solution,
            :get_build_examodel,
        ],
    ),
    (
        id="options",
        title="Options and strategies",
        symbols=[
            :route_to,
            :bypass,
            :force,
            :options,
            :option_names,
            :option_type,
            :option_default,
            :option_defaults,
            :option_description,
            :option_value,
            :option_source,
            :has_option,
            :is_user,
            :is_default,
            :is_computed,
            :id,
            :metadata,
            :create_registry,
            :strategy_ids,
            :type_from_id,
            Symbol("CTBase.Strategies.parameter"),
            :default_parameter,
            :available_parameters,
            :CPU,
            :GPU,
            :describe,
        ],
    ),
    (
        id="solution",
        title="Solution",
        symbols=[
            # Trajectories
            :state,
            :control,
            :costate,
            Symbol("CTModels.Solutions.variable"),
            :time_grid,
            # Objective
            Symbol("CTModels.Solutions.objective"),
            # Status
            :status,
            :message,
            :successful,
            :iterations,
            :constraints_violation,
            :infos,
            :model,
            # Emptiness
            :is_empty,
            :is_empty_time_grid,
            # Duals
            :dual,
            :path_constraints_dual,
            :boundary_constraints_dual,
            :state_constraints_lb_dual,
            :state_constraints_ub_dual,
            :control_constraints_lb_dual,
            :control_constraints_ub_dual,
            :variable_constraints_lb_dual,
            :variable_constraints_ub_dual,
            :dim_dual_state_constraints_box,
            :dim_dual_control_constraints_box,
            :dim_dual_variable_constraints_box,
        ],
    ),
    (
        id="flows",
        title="Flows",
        symbols=[
            :Flow,
            :control_law,
            :pseudo_hamiltonian,
            :hamiltonian,
            :hamiltonian_vector_field,
            :vector_field,
            :get_hamiltonian_gradient,
            :get_variable_gradient,
            :get_pseudo_hamiltonian_gradient,
            :get_pseudo_variable_gradient,
            :MultiPhaseFlow,
            :MultiPhaseStateFlow,
            :MultiPhaseHamiltonianFlow,
            :AnyMultiPhaseFlow,
            :n_phases,
            :get_flow,
            :get_flows,
            :get_switching_time,
            :get_switching_times,
            :get_jump,
            :get_jumps,
            :SciML,
            :AbstractIntegrator,
            :AbstractIntegrationResult,
            :final_state,
            :evaluate_at,
        ],
    ),
    (
        id="geometry",
        title="Geometry",
        symbols=[
            :ad,
            :Lift,
            :Poisson,
            Symbol("∂ₜ"),
            :dg_ad_backend,
            Symbol("dg_ad_backend!"),
            Symbol("@Lie"),
        ],
    ),
    (
        id="types",
        title="Types",
        symbols=[
            # Vector fields
            :AbstractVectorField,
            :VectorField,
            :AbstractControlledVectorField,
            :ControlledVectorField,
            :ComposedVectorField,
            :controlled_vector_field,
            # Hamiltonians
            :AbstractHamiltonian,
            :Hamiltonian,
            :ComposedHamiltonian,
            :AbstractHamiltonianVectorField,
            :HamiltonianVectorField,
            :AbstractPseudoHamiltonian,
            :PseudoHamiltonian,
            # Pseudo-Hamiltonian fields
            :AbstractPseudoHamiltonianVectorField,
            :PseudoHamiltonianVectorField,
            # Control laws
            :AbstractControlLaw,
            :ControlLaw,
            :OpenLoop,
            :ClosedLoop,
            :DynClosedLoop,
            # Constraints and multipliers
            :AbstractPathConstraint,
            :PathConstraint,
            :StateConstraint,
            :ControlConstraint,
            :MixedConstraint,
            :AbstractMultiplier,
            :Multiplier,
        ],
    ),
    (
        id="io",
        title="Plotting and I/O",
        symbols=[:plot, Symbol("plot!"), :export_ocp_solution, :import_ocp_solution],
    ),
    (
        id="qualified",
        title="Qualified access",
        symbols=[
            Symbol("CTModels.Building.PreModel"),
            Symbol("CTModels.Models.Model"),
            Symbol("CTModels.Solutions.Solution"),
            Symbol("CTModels.Solutions.AbstractSolution"),
            Symbol("CTModels.Init.AbstractInitialGuess"),
            Symbol("CTModels.Init.InitialGuess"),
            Symbol("CTSolvers.Modelers.ADNLP"),
            Symbol("CTSolvers.Modelers.Exa"),
            Symbol("CTSolvers.Solvers.Ipopt"),
            Symbol("CTSolvers.Solvers.MadNLP"),
            Symbol("CTSolvers.Solvers.MadNCL"),
            Symbol("CTSolvers.Solvers.Knitro"),
            Symbol("CTSolvers.Solvers.Uno"),
            Symbol("CTSolvers.DOCP.AbstractDiscretizer"),
            Symbol("CTSolvers.DOCP.DiscretizedModel"),
            Symbol("CTSolvers.Modelers.AbstractNLPModeler"),
            Symbol("CTSolvers.Solvers.AbstractNLPSolver"),
            :LiftedHamiltonianFunction,
            Symbol("CTBase.Exceptions.CTException"),
            Symbol("CTBase.Exceptions.IncorrectArgument"),
            Symbol("CTBase.Exceptions.PreconditionError"),
            Symbol("CTBase.Exceptions.NotImplemented"),
            Symbol("CTBase.Exceptions.ParsingError"),
            Symbol("CTBase.Exceptions.AmbiguousDescription"),
            Symbol("CTBase.Exceptions.ExtensionError"),
            Symbol("CTBase.Core.NotProvided"),
            Symbol("CTBase.Core.NotProvidedType"),
            Symbol("CTBase.Core.ctNumber"),
            Symbol("CTBase.Strategies.AbstractStrategy"),
            Symbol("CTBase.Strategies.StrategyRegistry"),
            Symbol("CTBase.Strategies.StrategyMetadata"),
            Symbol("CTBase.Strategies.StrategyOptions"),
            Symbol("CTBase.Strategies.RoutedOption"),
            Symbol("CTBase.Strategies.BypassValue"),
            Symbol("CTBase.Strategies.AbstractStrategyParameter"),
            Symbol("CTBase.Options.OptionDefinition"),
            Symbol("CTBase.Options.OptionValue"),
        ],
    ),
    (id="deprecated", title="Deprecated", symbols=[:Lie, Symbol("⋅"), :HamiltonianLift]),
]

# Symbols exported by `names(OptimalControl)` are checked for full coverage
# below. Theme entries that are module-qualified (e.g. `CTModels.Solutions.variable`)
# stand in for the bare exported name (`variable`) for that check — see
# `_bare_name`.
#
# A theme entry can also be a `Pair` (e.g. `:solve => "solve(::CTModels.AbstractModel,
# ::Symbol...)"`): the key is what the coverage check sees, the value is the exact
# signature written into the `@docs` block. Needed whenever a bare name would pull in
# a foreign package's docstring for the same generic function (`:solve` collides with
# `CommonSolve.solve`, `:methods` with `Base.methods` — see docs/reports/99-api-coverage.md
# and control-toolbox/OptimalControl.jl's Phase D campaign report for how this was found).
_bare_name(s::Symbol) = Symbol(split(String(s), ".")[end])
_bare_name(p::Pair) = _bare_name(first(p))
_doc_entry(s::Symbol) = s
_doc_entry(p::Pair) = last(p)

const _COVERED_BARE_NAMES = let
    covered = Set{Symbol}()
    for theme in API_THEMES
        for s in theme.symbols
            push!(covered, _bare_name(s))
        end
    end
    covered
end

let
    exported = Set(setdiff(names(OptimalControl), (:OptimalControl,)))
    covered = union(_COVERED_BARE_NAMES, MODULE_ALIASES)
    missing_syms = setdiff(exported, covered)
    # `qualified` intentionally lists names not in `names(OptimalControl)`
    # (they are only reachable as `OptimalControl.X`), so they are excluded
    # from the stale check.
    qualified_bare = Set(
        _bare_name(s) for s in first(t.symbols for t in API_THEMES if t.id == "qualified")
    )
    stale_syms = setdiff(covered, union(exported, qualified_bare))

    if !isempty(missing_syms)
        error("API reference is missing exported symbols: $missing_syms")
    end
    if !isempty(stale_syms)
        error("API reference contains stale symbols: $stale_syms")
    end
end

function _generate_theme_page(docs_src, theme)
    page = joinpath(docs_src, "api", "$(theme.id).md")
    mkpath(dirname(page))
    open(page, "w") do io
        println(io, "# [$(theme.title)](@id api-$(theme.id))")
        println(io)
        if theme.id == "qualified"
            println(
                io,
                "These names are not exported by `using OptimalControl`, but they are " *
                "reachable as `OptimalControl.X`.",
            )
            println(io)
            println(
                io,
                "A handful of module names are re-exported purely as escape hatches for " *
                "generated code and cross-package qualification — `CTBase`, `CTLie`, " *
                "`CTFlows`, `CTModels`, `ADNLPModels`, `ExaModels`. They carry no " *
                "documentation of their own; see [Ecosystem](@ref api-ecosystem) for what " *
                "each package is for.",
            )
            println(io)
            println(
                io,
                "`CTDirect.Collocation` (the ADNLP/Exa discretizer, selected via " *
                "`discretizer=CTDirect.Collocation()`) has no docstring upstream yet — " *
                "tracked in [control-toolbox/CTDirect.jl#623]" *
                "(https://github.com/control-toolbox/CTDirect.jl/issues/623).",
            )
            println(io)
        end
        if theme.id == "deprecated"
            println(
                io,
                "Removed v2.0 names, re-introduced as throwing shims: calling one always " *
                "raises a `PreconditionError` naming its v2.1.0-beta replacement, so a " *
                "search for the old name lands on an explanation rather than nothing. See " *
                "[Migrating to v2.1](@ref migration) for the full picture.",
            )
            println(io)
            println(
                io,
                "!!! warning \"`⋅`'s entry below is misleading\"\n" *
                "    `⋅` is `LinearAlgebra.dot`, re-exported unchanged — the docstring " *
                "Documenter shows for it below is `dot`'s own, generic one. What actually " *
                "changed is a *method* on it: `X ⋅ f` for `X::AbstractVectorField` always " *
                "throws, pointing at `ad(X, f)`. That override has no separate docstring of " *
                "its own to display here.",
            )
            println(io)
        end
        println(io, "```@docs; canonical=true")
        for s in theme.symbols
            println(io, _doc_entry(s))
        end
        return println(io, "```")
    end
    return theme.title => "api/$(theme.id).md"
end

function generate_api_reference(src_dir::String, ext_dir::String)
    docs_src = abspath(joinpath(@__DIR__, "src"))
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    mkpath(joinpath(docs_src, "api"))

    pages = [_generate_theme_page(docs_src, t) for t in API_THEMES]

    helpers = src(
        joinpath("helpers", "component_checks.jl"),
        joinpath("helpers", "component_completion.jl"),
        joinpath("helpers", "descriptive_routing.jl"),
        joinpath("helpers", "describe.jl"),
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
    )

    internals = CTBase.automatic_reference_documentation(;
        subdirectory="api",
        primary_modules=[OptimalControl => helpers],
        external_modules_to_document=[CTBase, CTModels, CTSolvers],
        exclude=EXCLUDE_SYMBOLS,
        public=false,
        private=true,
        title="Internals",
        title_in_menu="Internals",
        filename="internals",
    )
    push!(pages, internals)

    return pages
end

function with_api_reference(f::Function, src_dir::String, ext_dir::String)
    pages = generate_api_reference(src_dir, ext_dir)
    try
        f(pages)
    finally
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
