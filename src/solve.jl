# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Default options
__display() = true
__initial_guess() = nothing

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Main solve function
function _solve(
    ocp::CTModels.AbstractOptimalControlProblem,
    initial_guess,
    discretizer::CTDirect.AbstractOptimalControlDiscretizer,
    modeler::CTModels.AbstractOptimizationModeler,
    solver::CTSolvers.AbstractOptimizationSolver;
    display::Bool=__display(),
)::CTModels.AbstractOptimalControlSolution

    # Validate initial guess against the optimal control problem before discretization.
    # Any inconsistency should trigger a CTBase.IncorrectArgument from the validator.
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)
    CTModels.validate_initial_guess(ocp, normalized_init)

    discrete_problem = CTDirect.discretize(ocp, discretizer)
    return CommonSolve.solve(
        discrete_problem, normalized_init, modeler, solver; display=display
    )
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Method registry: available resolution methods for optimal control problems.

const AVAILABLE_METHODS = (
    (:collocation, :adnlp, :ipopt),
    (:collocation, :adnlp, :madnlp),
    (:collocation, :adnlp, :knitro),
    (:collocation, :exa, :ipopt),
    (:collocation, :exa, :madnlp),
    (:collocation, :exa, :knitro),
)

available_methods() = AVAILABLE_METHODS

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Discretizer helpers (symbol  type and options).

function _get_unique_symbol(
    method::Tuple{Vararg{Symbol}}, allowed::Tuple{Vararg{Symbol}}, tool_name::AbstractString
)
    hits = Symbol[]
    for s in method
        if s in allowed
            push!(hits, s)
        end
    end
    if length(hits) == 1
        return hits[1]
    elseif isempty(hits)
        msg = "No $(tool_name) symbol from $(allowed) found in method $(method)."
        throw(CTBase.IncorrectArgument(msg))
    else
        msg = "Multiple $(tool_name) symbols $(hits) found in method $(method); at most one is allowed."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _get_discretizer_symbol(method::Tuple)
    return _get_unique_symbol(method, CTDirect.discretizer_symbols(), "discretizer")
end

function _build_discretizer_from_method(method::Tuple, discretizer_options::NamedTuple)
    disc_sym = _get_discretizer_symbol(method)
    return CTDirect.build_discretizer_from_symbol(disc_sym; discretizer_options...)
end

function _discretizer_options_keys(method::Tuple)
    disc_sym = _get_discretizer_symbol(method)
    disc_type = CTDirect._discretizer_type_from_symbol(disc_sym)
    keys = CTModels.options_keys(disc_type)
    keys === missing && return ()
    return keys
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Modeler helpers (symbol  type).

function _get_modeler_symbol(method::Tuple)
    return _get_unique_symbol(method, CTModels.modeler_symbols(), "NLP model")
end

function _normalize_modeler_options(options)
    if options === nothing
        return NamedTuple()
    elseif options isa NamedTuple
        return options
    elseif options isa Tuple
        return (; options...)
    else
        msg = "modeler_options must be a NamedTuple or tuple of pairs, got $(typeof(options))."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _modeler_options_keys(method::Tuple)
    model_sym = _get_modeler_symbol(method)
    model_type = CTModels._modeler_type_from_symbol(model_sym)
    keys = CTModels.options_keys(model_type)
    keys === missing && return ()
    return keys
end

function _build_modeler_from_method(method::Tuple, modeler_options::NamedTuple)
    model_sym = _get_modeler_symbol(method)
    return CTModels.build_modeler_from_symbol(model_sym; modeler_options...)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Solver helpers (symbol  type).

function _get_solver_symbol(method::Tuple)
    return _get_unique_symbol(method, CTSolvers.solver_symbols(), "solver")
end

function _build_solver_from_method(method::Tuple, solver_options::NamedTuple)
    solver_sym = _get_solver_symbol(method)
    return CTSolvers.build_solver_from_symbol(solver_sym; solver_options...)
end

function _solver_options_keys(method::Tuple)
    solver_sym = _get_solver_symbol(method)
    solver_type = CTSolvers._solver_type_from_symbol(solver_sym)
    keys = CTModels.options_keys(solver_type)
    keys === missing && return ()
    return keys
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Option routing helpers for description mode.

const _OCP_TOOLS = (:discretizer, :modeler, :solver, :solve)

function _extract_option_tool(raw)
    if raw isa Tuple{Any,Symbol}
        value, tool = raw
        if tool in _OCP_TOOLS
            return value, tool
        end
    end
    return raw, nothing
end

function _route_option_for_description(
    key::Symbol, raw_value, owners::Vector{Symbol}, source_mode::Symbol
)
    value, explicit_tool = _extract_option_tool(raw_value)

    if explicit_tool !== nothing
        if !(explicit_tool in owners)
            msg = "Keyword option $(key) cannot be routed to $(explicit_tool); valid tools are $(owners)."
            throw(CTBase.IncorrectArgument(msg))
        end
        return value, explicit_tool
    end

    if isempty(owners)
        msg = "Keyword option $(key) does not belong to any recognized component for the selected method."
        throw(CTBase.IncorrectArgument(msg))
    elseif length(owners) == 1
        return value, owners[1]
    else
        if source_mode === :description
            msg =
                "Keyword option $(key) is ambiguous between tools $(owners). " *
                "Disambiguate it by writing $(key) = (value, :tool), for example " *
                "$(key) = (value, :discretizer) or $(key) = (value, :solver)."
            throw(CTBase.IncorrectArgument(msg))
        else
            msg =
                "Ambiguous keyword option $(key) when routing from explicit mode; " *
                "internal calls should use the (value, tool) form."
            throw(CTBase.IncorrectArgument(msg))
        end
    end
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Display helpers.

function _display_ocp_method(
    io::IO,
    method::Tuple,
    discretizer::CTDirect.AbstractOptimalControlDiscretizer,
    modeler::CTModels.AbstractOptimizationModeler,
    solver::CTSolvers.AbstractOptimizationSolver;
    display::Bool,
)
    display || return nothing

    version_str = string(Base.pkgversion(@__MODULE__))

    print(io, "▫ This is CTSolvers version v", version_str, " running with: ")
    for (i, m) in enumerate(method)
        sep = i == length(method) ? ".\n\n" : ", "
        printstyled(io, string(m) * sep; color=:cyan, bold=true)
    end

    model_pkg = CTModels.tool_package_name(modeler)
    solver_pkg = CTModels.tool_package_name(solver)

    if model_pkg !== missing && solver_pkg !== missing
        println(
            io,
            "   ┌─ The NLP is modelled with ",
            model_pkg,
            " and solved with ",
            solver_pkg,
            ".",
        )
        println(io, "   │")
    end

    # Discretizer options (including grid size and scheme)
    disc_vals = CTModels._options_values(discretizer)
    disc_srcs = CTModels._option_sources(discretizer)

    mod_vals = CTModels._options_values(modeler)
    mod_srcs = CTModels._option_sources(modeler)

    sol_vals = CTModels._options_values(solver)
    sol_srcs = CTModels._option_sources(solver)

    has_disc = !isempty(propertynames(disc_vals))
    has_mod = !isempty(propertynames(mod_vals))
    has_sol = !isempty(propertynames(sol_vals))

    if has_disc || has_mod || has_sol
        println(io, "   Options:")

        if has_disc
            println(io, "   ├─ Discretizer:")
            for name in propertynames(disc_vals)
                src = haskey(disc_srcs, name) ? disc_srcs[name] : :unknown
                println(io, "   │    ", name, " = ", disc_vals[name], "  (", src, ")")
            end
        end

        if has_mod
            println(io, "   ├─ Modeler:")
            for name in propertynames(mod_vals)
                src = haskey(mod_srcs, name) ? mod_srcs[name] : :unknown
                println(io, "   │    ", name, " = ", mod_vals[name], "  (", src, ")")
            end
        end

        if has_sol
            println(io, "   └─ Solver:")
            for name in propertynames(sol_vals)
                src = haskey(sol_srcs, name) ? sol_srcs[name] : :unknown
                println(io, "        ", name, " = ", sol_vals[name], "  (", src, ")")
            end
        end
    end

    println(io)

    return nothing
end

function _display_ocp_method(
    method::Tuple,
    discretizer::CTDirect.AbstractOptimalControlDiscretizer,
    modeler::CTModels.AbstractOptimizationModeler,
    solver::CTSolvers.AbstractOptimizationSolver;
    display::Bool,
)
    return _display_ocp_method(
        stdout, method, discretizer, modeler, solver; display=display
    )
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Top-level solve entry: unifies explicit and description modes.

const _SOLVE_INITIAL_GUESS_ALIASES = (:initial_guess, :init, :i)
const _SOLVE_DISCRETIZER_ALIASES = (:discretizer, :d)
const _SOLVE_MODELER_ALIASES = (:modeler, :modeller, :m)
const _SOLVE_SOLVER_ALIASES = (:solver, :s)
const _SOLVE_DISPLAY_ALIASES = (:display,)
const _SOLVE_MODELER_OPTIONS_ALIASES = (:modeler_options,)

solve_ocp_option_keys_explicit_mode() = (:initial_guess, :display)

struct _ParsedTopLevelKwargs
    initial_guess
    display
    discretizer
    modeler
    solver
    modeler_options
    other_kwargs::NamedTuple
end

function _take_solve_kwarg(
    kwargs::NamedTuple, names::Tuple{Vararg{Symbol}}, default; only_solve_owner::Bool=false
)
    present = Symbol[]
    for n in names
        if haskey(kwargs, n)
            if only_solve_owner
                raw = kwargs[n]
                _, explicit_tool = _extract_option_tool(raw)
                if !(explicit_tool === nothing || explicit_tool === :solve)
                    continue
                end
            end
            push!(present, n)
        end
    end

    if isempty(present)
        return default, kwargs
    elseif length(present) == 1
        name = present[1]
        value = kwargs[name]
        remaining = (; (k => v for (k, v) in pairs(kwargs) if k != name)...)
        return value, remaining
    else
        msg =
            "Conflicting aliases $(present) for argument $(names[1]). " *
            "Use only one of $(names)."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _parse_top_level_kwargs(kwargs::NamedTuple)
    initial_guess, kwargs1 = _take_solve_kwarg(
        kwargs, _SOLVE_INITIAL_GUESS_ALIASES, __initial_guess()
    )
    display, kwargs2 = _take_solve_kwarg(kwargs1, _SOLVE_DISPLAY_ALIASES, __display())
    discretizer, kwargs3 = _take_solve_kwarg(kwargs2, _SOLVE_DISCRETIZER_ALIASES, nothing)
    modeler, kwargs4 = _take_solve_kwarg(kwargs3, _SOLVE_MODELER_ALIASES, nothing)
    solver, kwargs5 = _take_solve_kwarg(kwargs4, _SOLVE_SOLVER_ALIASES, nothing)
    modeler_options, other_kwargs = _take_solve_kwarg(
        kwargs5, _SOLVE_MODELER_OPTIONS_ALIASES, nothing
    )

    return _ParsedTopLevelKwargs(
        initial_guess, display, discretizer, modeler, solver, modeler_options, other_kwargs
    )
end

function _parse_top_level_kwargs_description(kwargs::NamedTuple)
    # Defaults identical to the explicit-mode parser, but reserved keywords can
    # be routed through the central option router in the future if they become
    # shared between components. For now, initial_guess, display and
    # modeler_options are treated as belonging solely to the top-level solve.

    initial_guess = __initial_guess()
    display = __display()
    discretizer = nothing
    modeler = nothing
    solver = nothing
    modeler_options = nothing

    # Reserved keywords
    initial_guess_raw, kwargs1 = _take_solve_kwarg(
        kwargs, _SOLVE_INITIAL_GUESS_ALIASES, __initial_guess(); only_solve_owner=true
    )
    value, _ = _route_option_for_description(
        :initial_guess, initial_guess_raw, Symbol[:solve], :description
    )
    initial_guess = value

    display_raw, kwargs2 = _take_solve_kwarg(
        kwargs1, _SOLVE_DISPLAY_ALIASES, __display(); only_solve_owner=true
    )
    display_unwrapped, _ = _extract_option_tool(display_raw)
    display = display_unwrapped

    modeler_options_raw, kwargs3 = _take_solve_kwarg(
        kwargs2, _SOLVE_MODELER_OPTIONS_ALIASES, nothing; only_solve_owner=true
    )
    modeler_options_unwrapped, _ = _extract_option_tool(modeler_options_raw)
    modeler_options = modeler_options_unwrapped

    # Explicit components, if any
    discretizer, kwargs4 = _take_solve_kwarg(kwargs3, _SOLVE_DISCRETIZER_ALIASES, nothing)
    modeler, kwargs5 = _take_solve_kwarg(kwargs4, _SOLVE_MODELER_ALIASES, nothing)
    solver, kwargs6 = _take_solve_kwarg(kwargs5, _SOLVE_SOLVER_ALIASES, nothing)

    # Everything else goes to other_kwargs and will be routed to discretizer
    # or solver by the description-mode splitter.
    other_pairs = Pair{Symbol,Any}[]
    for (k, v) in pairs(kwargs6)
        push!(other_pairs, k => v)
    end

    return _ParsedTopLevelKwargs(
        initial_guess,
        display,
        discretizer,
        modeler,
        solver,
        modeler_options,
        (; other_pairs...),
    )
end

function _ensure_no_ambiguous_description_kwargs(method::Tuple, kwargs::NamedTuple)
    disc_keys = Set(_discretizer_options_keys(method))
    model_keys = Set(_modeler_options_keys(method))
    solver_keys = Set(_solver_options_keys(method))

    for (k, raw) in pairs(kwargs)
        owners = Symbol[]

        if (k in _SOLVE_INITIAL_GUESS_ALIASES) ||
           (k in _SOLVE_DISCRETIZER_ALIASES) ||
           (k in _SOLVE_MODELER_ALIASES) ||
           (k in _SOLVE_SOLVER_ALIASES) ||
           (k in _SOLVE_DISPLAY_ALIASES) ||
           (k in _SOLVE_MODELER_OPTIONS_ALIASES)
            push!(owners, :solve)
        end

        if k in disc_keys
            push!(owners, :discretizer)
        end
        if k in model_keys
            push!(owners, :modeler)
        end
        if k in solver_keys
            push!(owners, :solver)
        end

        _route_option_for_description(k, raw, owners, :description)
    end

    return nothing
end

function _has_explicit_components(parsed::_ParsedTopLevelKwargs)
    return (parsed.discretizer !== nothing) ||
           (parsed.modeler !== nothing) ||
           (parsed.solver !== nothing)
end

function _ensure_no_unknown_explicit_kwargs(parsed::_ParsedTopLevelKwargs)
    allowed = Set(solve_ocp_option_keys_explicit_mode())
    union!(allowed, Set((:discretizer, :modeler, :solver)))
    unknown = [k for (k, _) in pairs(parsed.other_kwargs) if !(k in allowed)]
    if !isempty(unknown)
        msg = "Unknown keyword options in explicit mode: $(unknown)."
        throw(CTBase.IncorrectArgument(msg))
    end
end

function _build_description_from_components(discretizer, modeler, solver)
    syms = Symbol[]
    if discretizer !== nothing
        push!(syms, CTModels.get_symbol(discretizer))
    end
    if modeler !== nothing
        push!(syms, CTModels.get_symbol(modeler))
    end
    if solver !== nothing
        push!(syms, CTModels.get_symbol(solver))
    end
    return Tuple(syms)
end

function _solve_from_components_and_description(
    ocp::CTModels.AbstractOptimalControlProblem, method::Tuple, parsed::_ParsedTopLevelKwargs
)
    # method is a COMPLETE description (e.g., (:collocation, :adnlp, :ipopt))

    # 1. Discretizer
    discretizer = if parsed.discretizer === nothing
        _build_discretizer_from_method(method, NamedTuple())
    else
        parsed.discretizer
    end

    # 2. Modeler (no modeler_options in explicit mode)
    modeler = if parsed.modeler === nothing
        _build_modeler_from_method(method, NamedTuple())
    else
        parsed.modeler
    end

    # 3. Solver (no solver-specific kwargs in explicit mode)
    solver = if parsed.solver === nothing
        _build_solver_from_method(method, NamedTuple())
    else
        parsed.solver
    end

    _display_ocp_method(method, discretizer, modeler, solver; display=parsed.display)

    return _solve(
        ocp, parsed.initial_guess, discretizer, modeler, solver; display=parsed.display
    )
end

function _solve_explicit_mode(
    ocp::CTModels.AbstractOptimalControlProblem, parsed::_ParsedTopLevelKwargs
)
    # 1. No modeler_options in explicit mode
    if parsed.modeler_options !== nothing
        msg = "modeler_options is not allowed in explicit mode; pass a modeler instance instead."
        throw(CTBase.IncorrectArgument(msg))
    end

    # 2. Unknown options check
    _ensure_no_unknown_explicit_kwargs(parsed)

    # 3. If all components are provided explicitly, call the low-level API
    #    directly without going through the description/method registry. This
    #    allows arbitrary user-defined components (e.g., test doubles) that do
    #    not participate in the symbol registry.
    has_discretizer = parsed.discretizer !== nothing
    has_modeler = parsed.modeler !== nothing
    has_solver = parsed.solver !== nothing

    if has_discretizer && has_modeler && has_solver
        return _solve(
            ocp,
            parsed.initial_guess,
            parsed.discretizer,
            parsed.modeler,
            parsed.solver;
            display=parsed.display,
        )
    end

    # 4. Otherwise, build a partial description from the provided components
    #    and delegate to the description-based pipeline to complete missing
    #    pieces using the central method registry.
    partial_desc = _build_description_from_components(
        parsed.discretizer, parsed.modeler, parsed.solver
    )
    method = CTBase.complete(partial_desc...; descriptions=available_methods())

    return _solve_from_components_and_description(ocp, method, parsed)
end

# ------------------------------------------------------------------------
# ------------------------------------------------------------------------
# Description-based solve (including the default solve(ocp) case).

function _split_kwargs_for_description(method::Tuple, parsed::_ParsedTopLevelKwargs)
    # All top-level kwargs except initial_guess, display, modeler_options
    # are in parsed.other_kwargs. Among them, some belong to the discretizer,
    # some to the modeler, and some to the solver.
    disc_keys = Set(_discretizer_options_keys(method))
    model_keys = Set(_modeler_options_keys(method))
    solver_keys = Set(_solver_options_keys(method))

    disc_pairs = Pair{Symbol,Any}[]
    model_pairs = Pair{Symbol,Any}[]
    solver_pairs = Pair{Symbol,Any}[]
    for (k, raw) in pairs(parsed.other_kwargs)
        owners = Symbol[]
        if k in disc_keys
            push!(owners, :discretizer)
        end
        if k in model_keys
            push!(owners, :modeler)
        end
        if k in solver_keys
            push!(owners, :solver)
        end

        value, tool = _route_option_for_description(k, raw, owners, :description)

        if tool === :discretizer
            push!(disc_pairs, k => value)
        elseif tool === :modeler
            push!(model_pairs, k => value)
        elseif tool === :solver
            push!(solver_pairs, k => value)
        else
            msg = "Unsupported tool $(tool) for option $(k)."
            throw(CTBase.IncorrectArgument(msg))
        end
    end

    disc_kwargs = (; disc_pairs...)
    model_kwargs = (; model_pairs...)
    solver_kwargs = (; solver_pairs...)

    # Normalize user-supplied modeler_options (which may be nothing, a NamedTuple,
    # or a tuple of pairs) and merge them with any untagged options that belong
    # to the modeler for the selected method. We explicitly build a NamedTuple
    # here instead of relying on generic union operators, to avoid type surprises
    # and keep the API contract of _build_modeler_from_method, which expects a
    # NamedTuple of keyword arguments.
    base_modeler_opts = _normalize_modeler_options(parsed.modeler_options)
    combined_modeler_opts = (; base_modeler_opts..., model_kwargs...)

    return (
        initial_guess=parsed.initial_guess,
        display=parsed.display,
        disc_kwargs=disc_kwargs,
        modeler_options=combined_modeler_opts,
        solver_kwargs=solver_kwargs,
    )
end

function _solve_from_complete_description(
    ocp::CTModels.AbstractOptimalControlProblem,
    method::Tuple{Vararg{Symbol}},
    parsed::_ParsedTopLevelKwargs,
)::CTModels.AbstractOptimalControlSolution
    pieces = _split_kwargs_for_description(method, parsed)

    discretizer = _build_discretizer_from_method(method, pieces.disc_kwargs)
    modeler = _build_modeler_from_method(method, pieces.modeler_options)
    solver = _build_solver_from_method(method, pieces.solver_kwargs)

    _display_ocp_method(method, discretizer, modeler, solver; display=pieces.display)

    return _solve(
        ocp, pieces.initial_guess, discretizer, modeler, solver; display=pieces.display
    )
end

function _solve_descriptif_mode(
    ocp::CTModels.AbstractOptimalControlProblem, description::Symbol...; kwargs...
)::CTModels.AbstractOptimalControlSolution
    method = CTBase.complete(description...; descriptions=available_methods())

    _ensure_no_ambiguous_description_kwargs(method, (; kwargs...))

    parsed = _parse_top_level_kwargs_description((; kwargs...))

    if _has_explicit_components(parsed)
        msg = "Cannot mix explicit components (discretizer/modeler/solver) with a description."
        throw(CTBase.IncorrectArgument(msg))
    end

    return _solve_from_complete_description(ocp, method, parsed)
end

function CommonSolve.solve(
    ocp::CTModels.AbstractOptimalControlProblem, description::Symbol...; kwargs...
)::CTModels.AbstractOptimalControlSolution
    parsed = _parse_top_level_kwargs((; kwargs...))

    if _has_explicit_components(parsed) && !isempty(description)
        msg = "Cannot mix explicit components (discretizer/modeler/solver) with a description."
        throw(CTBase.IncorrectArgument(msg))
    end

    if _has_explicit_components(parsed)
        # Explicit mode: components provided directly by the user.
        return _solve_explicit_mode(ocp, parsed)
    else
        # Description mode: description may be empty (solve(ocp)) or partial.
        return _solve_descriptif_mode(ocp, description...; kwargs...)
    end
end
