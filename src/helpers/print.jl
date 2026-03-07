# Display helpers for OptimalControl

# ============================================================================
# Solver output detection
# ============================================================================

"""
$(TYPEDSIGNATURES)

Check if a solver will produce output based on its options.

This function uses multiple dispatch to check solver-specific options that control
output verbosity. It is used to conditionally print a `▫` symbol before the solver
starts printing.

# Arguments
- `solver::CTSolvers.AbstractNLPSolver`: The solver instance to check

# Returns
- `Bool`: `true` if the solver will print output, `false` otherwise

# Examples
```julia
julia> sol = CTSolvers.Ipopt(print_level=0)
julia> OptimalControl.will_solver_print(sol)
false

julia> sol = CTSolvers.Ipopt(print_level=5)
julia> OptimalControl.will_solver_print(sol)
true
```

# Notes
- Default behavior assumes solver will print (returns `true`)
- Each solver type has a specialized method checking its specific options
- Used internally by `display_ocp_configuration` to conditionally print `▫`

See also: [`display_ocp_configuration`](@ref)
"""
function will_solver_print(solver::CTSolvers.AbstractNLPSolver)
    # Default: assume solver will print
    return true
end

"""
$(TYPEDSIGNATURES)

Check if Ipopt will produce output based on `print_level` option.

Ipopt is silent when `print_level = 0`, verbose otherwise.
"""
function will_solver_print(solver::CTSolvers.Ipopt)
    opts = CTSolvers.options(solver)
    print_level = get(opts.options, :print_level, nothing)
    return print_level === nothing || CTSolvers.value(print_level) > 0
end

"""
$(TYPEDSIGNATURES)

Check if Knitro will produce output based on `outlev` option.

Knitro is silent when `outlev = 0`, verbose otherwise.
"""
function will_solver_print(solver::CTSolvers.Knitro)
    opts = CTSolvers.options(solver)
    outlev = get(opts.options, :outlev, nothing)
    return outlev === nothing || CTSolvers.value(outlev) > 0
end

"""
$(TYPEDSIGNATURES)

Check if MadNLP will produce output based on `print_level` option.

MadNLP is silent when `print_level = MadNLP.ERROR`, verbose otherwise.
Default is `MadNLP.INFO` which prints output.
"""
function will_solver_print(solver::CTSolvers.MadNLP)
    opts = CTSolvers.options(solver)
    print_level = get(opts.options, :print_level, nothing)
    # Default is INFO, which prints. ERROR is silent.
    if print_level === nothing
        return true  # Default prints
    end
    # Need to check against MadNLP.ERROR
    # We use string comparison to avoid requiring MadNLP to be loaded
    pl_val = CTSolvers.value(print_level)
    return string(pl_val) != "ERROR"
end

"""
$(TYPEDSIGNATURES)

Check if MadNCL will produce output based on `print_level` and `ncl_options.verbose`.

MadNCL is silent when either:
- `print_level = MadNLP.ERROR`, or
- `ncl_options.verbose = false`
"""
function will_solver_print(solver::CTSolvers.MadNCL)
    opts = CTSolvers.options(solver)
    
    # Check print_level
    print_level = get(opts.options, :print_level, nothing)
    if print_level !== nothing
        pl_val = CTSolvers.value(print_level)
        if string(pl_val) == "ERROR"
            return false
        end
    end
    
    # Check ncl_options.verbose
    ncl_options = get(opts.options, :ncl_options, nothing)
    if ncl_options !== nothing
        ncl_opts_val = CTSolvers.value(ncl_options)
        if hasfield(typeof(ncl_opts_val), :verbose) && !ncl_opts_val.verbose
            return false
        end
    end
    
    return true
end

# ============================================================================
# Parameter extraction helpers
# ============================================================================

"""
    _extract_strategy_parameters(discretizer, modeler, solver)

Extract parameter types from strategies and convert to symbols.

Returns a NamedTuple with fields:
- `disc`: Discretizer parameter symbol or `nothing`
- `mod`: Modeler parameter symbol or `nothing`
- `sol`: Solver parameter symbol or `nothing`
- `params`: Vector of non-nothing parameter symbols
"""
function _extract_strategy_parameters(discretizer, modeler, solver)
    disc_param = CTSolvers.Strategies.get_parameter_type(typeof(discretizer))
    mod_param = CTSolvers.Strategies.get_parameter_type(typeof(modeler))
    sol_param = CTSolvers.Strategies.get_parameter_type(typeof(solver))

    disc_param_sym = disc_param === nothing ? nothing : CTSolvers.id(disc_param)
    mod_param_sym = mod_param === nothing ? nothing : CTSolvers.id(mod_param)
    sol_param_sym = sol_param === nothing ? nothing : CTSolvers.id(sol_param)

    params = filter(!isnothing, [disc_param_sym, mod_param_sym, sol_param_sym])

    return (disc=disc_param_sym, mod=mod_param_sym, sol=sol_param_sym, params=params)
end

"""
    _determine_parameter_display_strategy(params)

Determine how to display parameters based on their values.

Returns a NamedTuple with fields:
- `show_inline`: Whether to show parameters inline with each component
- `common`: Common parameter to show at end, or `nothing`
"""
function _determine_parameter_display_strategy(params)
    if isempty(params)
        return (show_inline=false, common=nothing)
    elseif allequal(params)
        return (show_inline=false, common=first(params))
    else
        return (show_inline=true, common=nothing)
    end
end

# ============================================================================
# Formatting helpers
# ============================================================================

"""
    _print_component_with_param(io, component_id, show_inline, param_sym)

Print a component ID with optional inline parameter.
"""
function _print_component_with_param(io, component_id, show_inline, param_sym)
    printstyled(io, component_id; color=:cyan, bold=true)
    if show_inline && param_sym !== nothing
        print(io, " (")
        printstyled(io, string(param_sym); color=:magenta, bold=true)
        print(io, ")")
    end
end

"""
    _build_source_tag(source, common_param, params, show_sources)

Build the source tag for an option based on its source and parameter context.
"""
function _build_source_tag(source, common_param, params, show_sources)
    if source == :computed
        # Determine parameter for tag
        if common_param !== nothing
            tag_param = common_param
        elseif !isempty(params)
            tag_param = first(params)
        else
            tag_param = nothing
        end
        param_str = tag_param !== nothing ? string(tag_param) : "parameter"
        src_tag = " [" * param_str * "-dependent]"
        if show_sources
            src_tag = " [computed, " * param_str * "-dependent]"
        end
        return src_tag
    elseif show_sources && source == :user
        return " [user]"
    end
    return ""
end

# ============================================================================
# Display configuration
# ============================================================================

"""
$(TYPEDSIGNATURES)

Display the optimal control problem resolution configuration (discretizer → modeler → solver) with user options.

This function prints a formatted representation of the solving strategy, showing the component
types and their configuration options. The display is compact by default and only shows
user-specified options.

# Arguments
- `io::IO`: Output stream for printing
- `discretizer::CTDirect.AbstractDiscretizer`: Discretization strategy
- `modeler::CTSolvers.AbstractNLPModeler`: NLP modeling strategy  
- `solver::CTSolvers.AbstractNLPSolver`: NLP solver strategy
- `display::Bool`: Whether to print the configuration (default: `true`)
- `show_options::Bool`: Whether to show component options (default: `true`)
- `show_sources::Bool`: Whether to show option sources (default: `false`)

# Examples
```julia
julia> disc = CTDirect.Collocation()
julia> mod = CTSolvers.ADNLP()
julia> sol = CTSolvers.Ipopt()
julia> OptimalControl.display_ocp_configuration(stdout, disc, mod, sol)
▫ OptimalControl v1.1.8-beta solving with: collocation → adnlp → ipopt

  📦 Configuration:
   ├─ Discretizer: collocation (no user options)
   ├─ Modeler: adnlp (no user options)
   └─ Solver: ipopt (no user options)
```

With parameterized strategies (parameter extracted automatically):
```julia
julia> disc = CTDirect.Collocation()
julia> mod = CTSolvers.Exa()  # GPU-optimized
julia> sol = CTSolvers.MadNLP()
julia> OptimalControl.display_ocp_configuration(stdout, disc, mod, sol)
▫ OptimalControl v1.1.8-beta solving with: collocation → exa (gpu) → madnlp

  📦 Configuration:
   ├─ Discretizer: collocation (no user options)
   ├─ Modeler: exa (backend = cuda [gpu-dependent])
   └─ Solver: madnlp (no user options)
```

# Notes
- Both user-specified and computed options are always displayed
- Computed options show `[parameter-dependent]` tag (e.g., `[cpu-dependent]`)
- Set `show_sources=true` to also see `[user]`/`[computed]` source tags
- Set `show_options=false` to show only component IDs
- The function returns `nothing` and only produces side effects

See also: [`solve_explicit`](@ref), [`get_strategy_registry`](@ref)
"""
function display_ocp_configuration(
    io::IO,
    discretizer::CTDirect.AbstractDiscretizer,
    modeler::CTSolvers.AbstractNLPModeler,
    solver::CTSolvers.AbstractNLPSolver;
    display::Bool=true,
    show_options::Bool=true,
    show_sources::Bool=false,
)
    display || return nothing

    version_str = string(Base.pkgversion(OptimalControl))

    # Extract parameters from strategies
    param_info = _extract_strategy_parameters(discretizer, modeler, solver)
    display_strategy = _determine_parameter_display_strategy(param_info.params)

    # Header with method
    print(io, "▫ OptimalControl v", version_str, " solving with: ")

    discretizer_id = OptimalControl.id(typeof(discretizer))
    modeler_id = OptimalControl.id(typeof(modeler))
    solver_id = OptimalControl.id(typeof(solver))

    _print_component_with_param(io, discretizer_id, display_strategy.show_inline, param_info.disc)
    print(io, " → ")
    _print_component_with_param(io, modeler_id, display_strategy.show_inline, param_info.mod)
    print(io, " → ")
    _print_component_with_param(io, solver_id, display_strategy.show_inline, param_info.sol)

    # Add common parameter at end if applicable
    if !display_strategy.show_inline && display_strategy.common !== nothing
        print(io, " (")
        printstyled(io, string(display_strategy.common); color=:magenta, bold=true)
        print(io, ")")
    end

    println(io)

    # Combined configuration + options (compact default)
    println(io, "")
    println(io, "  📦 Configuration:")

    discretizer_pkg = OptimalControl.id(typeof(discretizer))
    model_pkg = OptimalControl.id(typeof(modeler))
    solver_pkg = OptimalControl.id(typeof(solver))

    disc_opts = show_options ? OptimalControl.options(discretizer) : nothing
    mod_opts = show_options ? OptimalControl.options(modeler) : nothing
    sol_opts = show_options ? OptimalControl.options(solver) : nothing

    function print_component(line_prefix, label, pkg, opts)
        print(io, line_prefix)
        printstyled(io, label; bold=true)
        print(io, ": ")
        printstyled(io, pkg; color=:cyan, bold=true)
        if show_options && opts !== nothing
            # Collect both user and computed options
            all_items = Tuple{Symbol, Any, Symbol}[]  # (key, opt, source)
            for (key, opt) in pairs(opts.options)
                if OptimalControl.is_user(opts, key)
                    push!(all_items, (key, opt, :user))
                elseif OptimalControl.is_computed(opts, key)
                    push!(all_items, (key, opt, :computed))
                end
            end
            sort!(all_items, by = x -> string(x[1]))
            n = length(all_items)
            if n == 0
                print(io, " (no user options)")
            elseif n <= 2
                print(io, " (")
                for (i, (key, opt, source)) in enumerate(all_items)
                    sep = i == n ? "" : ", "
                    src_tag = _build_source_tag(source, display_strategy.common, param_info.params, show_sources)
                    print(io, string(key), " = ", CTSolvers.value(opt), src_tag, sep)
                end
                print(io, ")")
            else
                # Multiline with truncation after 3 items
                print(io, "\n     ")
                shown = first(all_items, 3)
                for (i, (key, opt, source)) in enumerate(shown)
                    sep = i == length(shown) ? "" : ", "
                    src_tag = _build_source_tag(source, display_strategy.common, param_info.params, show_sources)
                    print(io, string(key), " = ", CTSolvers.value(opt), src_tag, sep)
                end
                remaining = n - length(shown)
                if remaining > 0
                    print(io, ", … (+", remaining, ")")
                end
            end
        end
        println(io)
    end

    print_component("   ├─ ", "Discretizer", discretizer_pkg, disc_opts)
    print_component("   ├─ ", "Modeler", model_pkg, mod_opts)
    print_component("   └─ ", "Solver", solver_pkg, sol_opts)

    println(io)
    
    # Print ▫ before solver output if solver will print
    if will_solver_print(solver)
        print(io, "▫ ")
    end
    
    return nothing
end

"""
$(TYPEDSIGNATURES)

Display the optimal control problem resolution configuration to standard output.

This is a convenience method that prints to `stdout` by default. See the main method
for full documentation of all parameters and behavior.

# Arguments
- `discretizer::CTDirect.AbstractDiscretizer`: Discretization strategy
- `modeler::CTSolvers.AbstractNLPModeler`: NLP modeling strategy  
- `solver::CTSolvers.AbstractNLPSolver`: NLP solver strategy
- `display::Bool`: Whether to print the configuration (default: `true`)
- `show_options::Bool`: Whether to show component options (default: `true`)
- `show_sources::Bool`: Whether to show option sources (default: `false`)

# Examples
```julia
julia> disc = CTDirect.Collocation()
julia> mod = CTSolvers.ADNLP()
julia> sol = CTSolvers.Ipopt()
julia> OptimalControl.display_ocp_configuration(disc, mod, sol)
▫ OptimalControl v1.1.8-beta solving with: collocation → adnlp → ipopt

  📦 Configuration:
   ├─ Discretizer: collocation (no user options)
   ├─ Modeler: adnlp (no user options)
   └─ Solver: ipopt (no user options)
```

See also: [`display_ocp_configuration(io::IO, ...)`](@ref)
"""
function display_ocp_configuration(
    discretizer::CTDirect.AbstractDiscretizer,
    modeler::CTSolvers.AbstractNLPModeler,
    solver::CTSolvers.AbstractNLPSolver;
    display::Bool=true,
    show_options::Bool=true,
    show_sources::Bool=false,
)
    return display_ocp_configuration(
        stdout, discretizer, modeler, solver;
        display=display, show_options=show_options, show_sources=show_sources,
    )
end