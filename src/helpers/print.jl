# Display helpers for OptimalControl

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

# Notes
- By default, only user-specified options are displayed
- Set `show_sources=true` to see where options were defined
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

    # Header with method
    print(io, "▫ OptimalControl v", version_str, " solving with: ")

    discretizer_id = OptimalControl.id(typeof(discretizer))
    modeler_id = OptimalControl.id(typeof(modeler))
    solver_id = OptimalControl.id(typeof(solver))

    printstyled(io, discretizer_id; color=:cyan, bold=true)
    print(io, " → ")
    printstyled(io, modeler_id; color=:cyan, bold=true)
    print(io, " → ")
    printstyled(io, solver_id; color=:cyan, bold=true)

    # NOTE: if we want to display extra method hints later, re-enable cleaned_method logic.
    # cleaned_method = CTBase.remove(method, (discretizer_id, modeler_id, solver_id))
    # if !isempty(cleaned_method)
    #     print(io, " (")
    #     for (i, m) in enumerate(cleaned_method)
    #         sep = i == length(cleaned_method) ? "" : ", "
    #         printstyled(io, string(m) * sep; color=:cyan, bold=true)
    #     end
    #     print(io, ")")
    # end

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
            user_items = Tuple{Symbol, Any}[]
            for (key, opt) in pairs(opts.options)
                if OptimalControl.is_user(opts, key)
                    push!(user_items, (key, opt))
                end
            end
            sort!(user_items, by = x -> string(x[1]))
            n = length(user_items)
            if n == 0
                print(io, " (no user options)")
            elseif n <= 2
                print(io, " (")
                for (i, (key, opt)) in enumerate(user_items)
                    sep = i == n ? "" : ", "
                    src = show_sources ? " [" * string(CTSolvers.Options.source(opt)) * "]" : ""
                    print(io, string(key), " = ", CTSolvers.Options.value(opt), src, sep)
                end
                print(io, ")")
            else
                # Multiline with truncation after 3 items
                print(io, "\n     ")
                shown = first(user_items, 3)
                for (i, (key, opt)) in enumerate(shown)
                    sep = i == length(shown) ? "" : ", "
                    src = show_sources ? " [" * string(CTSolvers.Options.source(opt)) * "]" : ""
                    print(io, string(key), " = ", CTSolvers.Options.value(opt), src, sep)
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