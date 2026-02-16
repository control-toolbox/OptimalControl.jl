try
    using Revise
catch
    println("🔧 Revise not found - continuing without hot reload")
end

using Pkg
Pkg.activate(@__DIR__)

# Add OptimalControl in development mode
if !haskey(Pkg.project().dependencies, "OptimalControl")
    Pkg.develop(path=joinpath(@__DIR__, ".."))
end

using OptimalControl
using NLPModelsIpopt
import MadNLP
import MadNLPMumps

# Include shared test problems via TestProblems module
# include(joinpath(@__DIR__, "..", "test", "problems", "TestProblems.jl"))
# using .TestProblems

# Create test arguments similar to test_canonical.jl
function create_test_components()
    # Discretizer
    discretizer = OptimalControl.Collocation(grid_size=100, scheme=:midpoint)
    
    # Modeler
    modeler = OptimalControl.ADNLP()
    
    # Solver - use real Ipopt solver
    solver = OptimalControl.Ipopt(print_level=0)
    
    # Method tuple
    method = (:collocation, :adnlp, :ipopt)
    
    return method, discretizer, modeler, solver
end

# Create additional test configurations
function create_test_variants()
    variants = []
    
    # Variant 1: Different discretizer
    discretizer1 = OptimalControl.Collocation(grid_size=50, scheme=:trapeze)
    modeler1 = OptimalControl.ADNLP()
    solver1 = OptimalControl.Ipopt(print_level=0)
    method1 = (:collocation, :ipopt, :adnlp)
    push!(variants, ("Trapezoidal Grid", method1, discretizer1, modeler1, solver1))
    
    # Variant 2: Different modeler
    discretizer2 = OptimalControl.Collocation(grid_size=75, scheme=:midpoint)
    modeler2 = OptimalControl.Exa()
    solver2 = OptimalControl.Ipopt(print_level=0)
    method2 = (:exa, :collocation, :cpu, :ipopt)
    push!(variants, ("Exa", method2, discretizer2, modeler2, solver2))
    
    # Variant 3: Different solver
    discretizer3 = OptimalControl.Collocation(grid_size=80, scheme=:midpoint)
    modeler3 = OptimalControl.ADNLP()
    solver3 = OptimalControl.MadNLP(print_level=MadNLP.ERROR)
    method3 = (:collocation, :optimized, :adnlp, :gpu, :madnlp)
    push!(variants, ("MadNLP Solver", method3, discretizer3, modeler3, solver3))
    
    return variants
end

# Copy the ORIGINAL display function from solve.jl
function original_display_ocp_method(
    io::IO,
    method::Tuple,
    discretizer,
    modeler,
    solver;
    display::Bool,
)
    display || return nothing

    version_str = string(Base.pkgversion(OptimalControl))

    print(io, "▫ This is OptimalControl version v", version_str, " running with: ")
    for (i, m) in enumerate(method)
        sep = i == length(method) ? ".\n\n" : ", "
        printstyled(io, string(m) * sep; color=:cyan, bold=true)
    end

    # Package information using id()
    model_pkg = OptimalControl.id(typeof(modeler))
    solver_pkg = OptimalControl.id(typeof(solver))

    println(
        io,
        "   ┌─ The NLP is modelled with ",
        model_pkg,
        " and solved with ",
        solver_pkg,
        ".",
    )
    println(io, "   │")

    # Options section
    disc_opts = OptimalControl.options(discretizer)
    mod_opts = OptimalControl.options(modeler)
    sol_opts = OptimalControl.options(solver)

    has_disc = !isempty(propertynames(disc_opts))
    has_mod = !isempty(propertynames(mod_opts))
    has_sol = !isempty(propertynames(sol_opts))

    if has_disc || has_mod || has_sol
        println(io, "   Options:")

        if has_disc
            println(io, "   ├─ Discretizer:")
            for name in propertynames(disc_opts)
                println(io, "   │    ", name, " = ", getproperty(disc_opts, name))
            end
        end

        if has_mod
            println(io, "   ├─ Modeler:")
            for name in propertynames(mod_opts)
                println(io, "   │    ", name, " = ", getproperty(mod_opts, name))
            end
        end

        if has_sol
            println(io, "   └─ Solver:")
            for name in propertynames(sol_opts)
                println(io, "        ", name, " = ", getproperty(sol_opts, name))
            end
        end
    end

    println(io)
    return nothing
end

function original_display_ocp_method(
    method,
    discretizer,
    modeler,
    solver;
    display::Bool,
)
    return original_display_ocp_method(
        stdout, method, discretizer, modeler, solver; display=display
    )
end

# Copy the display function here for testing and improvement
function improved_display_ocp_method(
    io::IO,
    method::Tuple,
    discretizer,
    modeler,
    solver;
    display::Bool,
    show_options::Bool=true,
    show_sources::Bool=false,
)
    display || return nothing

    # Get version info
    version_str = string(Base.pkgversion(OptimalControl))

    # Header with method
    print(io, "▫ OptimalControl v", version_str, " solving with: ")
    
    # First, get the strategy IDs from the actual components
    discretizer_id = OptimalControl.id(typeof(discretizer))
    modeler_id = OptimalControl.id(typeof(modeler))
    solver_id = OptimalControl.id(typeof(solver))
    
    # Always show: discretizer → modeler → solver using IDs
    printstyled(io, discretizer_id; color=:cyan, bold=true)
    print(io, " → ")
    printstyled(io, modeler_id; color=:cyan, bold=true)
    print(io, " → ")
    printstyled(io, solver_id; color=:cyan, bold=true)
    
    # Clean the method by removing strategy IDs and show remaining options
    cleaned_method = CTBase.remove(method, (discretizer_id, modeler_id, solver_id))
    if !isempty(cleaned_method)
        print(io, " (")
        for (i, m) in enumerate(cleaned_method)
            sep = i == length(cleaned_method) ? "" : ", "
            printstyled(io, string(m) * sep; color=:cyan, bold=true)
        end
        print(io, ")")
    end
    
    println(io)

    # Combined configuration + options (Proposition 3)
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
                    src = show_sources ? " [" * string(opt.source) * "]" : ""
                    print(io, string(key), " = ", opt.value, src, sep)
                end
                print(io, ")")
            else
                # Multiline with truncation after 3 items
                print(io, "\n     ")
                shown = first(user_items, 3)
                for (i, (key, opt)) in enumerate(shown)
                    sep = i == length(shown) ? "" : ", "
                    src = show_sources ? " [" * string(opt.source) * "]" : ""
                    print(io, string(key), " = ", opt.value, src, sep)
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
    #println(io, "🎯 Ready to solve!")
    return nothing
end

function improved_display_ocp_method(
    method,
    discretizer,
    modeler,
    solver;
    display::Bool,
    kwargs...
)
    return improved_display_ocp_method(
        stdout, method, discretizer, modeler, solver; display=display, kwargs...
    )
end

# Simple fallback for original display testing
function test_display_ocp_method(
    method,
    discretizer,
    modeler,
    solver;
    display::Bool,
)
    display || return nothing
    
    println("▫ Original display (simplified):")
    println("   Method: ", method)
    println("   Discretizer: ", typeof(discretizer))
    println("   Modeler: ", typeof(modeler))
    println("   Solver: ", typeof(solver))
    return nothing
end

# Create simple test problem
struct SimpleProblem
    x0::Vector{Float64}
    xf::Vector{Float64}
end

# Test problem
problem = SimpleProblem([0.0, 0.0], [1.0, 1.0])

# Create components
method, discretizer, modeler, solver = create_test_components()
variants = create_test_variants()

println("🧪 Testing ORIGINAL vs IMPROVED display functions:")
println("=" ^ 60)

println("\n📋 ORIGINAL DISPLAY:")
println("-" ^ 30)
# Call the ORIGINAL display function
original_display_ocp_method(
    method, discretizer, modeler, solver; display=true
)

println("\n📋 IMPROVED DISPLAY:")
println("-" ^ 30)
# Call the IMPROVED display function
improved_display_ocp_method(
    method, discretizer, modeler, solver; display=true
)

println("\n📋 IMPROVED DISPLAY (minimal):")
println("-" ^ 30)
# Call with minimal options
improved_display_ocp_method(
    method, discretizer, modeler, solver; display=true, show_options=false
)

println("\n📋 NEW display_ocp_configuration (default):")
println("-" ^ 30)
# Call the NEW display function with default parameters
OptimalControl.display_ocp_configuration(
    discretizer, modeler, solver; display=true
)

println("\n📋 NEW display_ocp_configuration (with sources):")
println("-" ^ 30)
# Call the NEW display function with sources shown
OptimalControl.display_ocp_configuration(
    discretizer, modeler, solver; display=true, show_sources=true
)

println("\n📋 NEW display_ocp_configuration (minimal):")
println("-" ^ 30)
# Call the NEW display function without options
OptimalControl.display_ocp_configuration(
    discretizer, modeler, solver; display=true, show_options=false
)

println("\n📋 TESTING DIFFERENT CONFIGURATIONS:")
println("-" ^ 30)
for (name, meth, disc, mod, solv) in variants
    println("\n🔸 Configuration: ", name)
    improved_display_ocp_method(
        meth, disc, mod, solv; display=true, show_options=true
    )
    
    println("\n🔸 Configuration: ", name, " (NEW display_ocp_configuration)")
    OptimalControl.display_ocp_configuration(
        disc, mod, solv; display=true
    )
end

println("=" ^ 60)
println("✅ Display comparison completed!")
