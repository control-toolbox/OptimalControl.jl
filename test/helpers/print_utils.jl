"""
Module d'affichage pour tests de solve OptimalControl.

Responsabilité unique : Formatage et affichage des résultats de tests.
Inspiré de CTBenchmarks.jl pour cohérence avec l'écosystème control-toolbox.

Exports:
- prettytime: Format temps avec unités adaptatives
- prettymemory: Format mémoire avec unités binaires
- print_test_line: Affiche ligne de tableau alignée
- print_summary: Affiche résumé final
"""
module TestPrintUtils

using Printf
using OptimalControl

# Exports explicites (ISP - Interface Segregation)
export prettytime, prettymemory, print_test_header, print_test_line, print_summary

"""
    prettytime(t::Real) -> String

Format un temps en secondes avec unités adaptatives.

Responsabilité unique : Conversion temps → string formaté.
Inspiré de CTBenchmarks.jl.

# Arguments
- `t::Real`: Temps en secondes

# Returns
- `String`: Temps formaté (e.g., "2.345 s", "123.4 ms")

# Examples
```julia
julia> prettytime(0.001234)
"1.234 ms"

julia> prettytime(2.5)
"2.500 s "
```
"""
function prettytime(t::Real)
    t_abs = abs(t)
    if t_abs < 1e-6
        value, units = t * 1e9, "ns"
    elseif t_abs < 1e-3
        value, units = t * 1e6, "μs"
    elseif t_abs < 1
        value, units = t * 1e3, "ms"
    else
        value, units = t, "s "
    end
    return string(@sprintf("%.3f", value), " ", units)
end

"""
    prettymemory(bytes::Integer) -> String

Format une taille mémoire avec unités binaires.

Responsabilité unique : Conversion bytes → string formaté.
Inspiré de CTBenchmarks.jl.

# Arguments
- `bytes::Integer`: Taille en bytes

# Returns
- `String`: Mémoire formatée (e.g., "1.2 MiB", "512 bytes")

# Examples
```julia
julia> prettymemory(1048576)
"1.00 MiB"

julia> prettymemory(512)
"512 bytes"
```
"""
function prettymemory(bytes::Integer)
    if bytes < 1024
        return string(bytes, " bytes")
    elseif bytes < 1024^2
        value, units = bytes / 1024, "KiB"
    elseif bytes < 1024^3
        value, units = bytes / 1024^2, "MiB"
    else
        value, units = bytes / 1024^3, "GiB"
    end
    return string(@sprintf("%.2f", value), " ", units)
end

"""
    print_test_header(show_memory::Bool = false)

Display table header with column names.

# Arguments
- `show_memory`: Show memory column (default: false)
"""
function print_test_header(show_memory::Bool = false)
    println()
    printstyled("OptimalControl Solve Tests\n"; color=:cyan, bold=true)
    printstyled("==========================\n"; color=:cyan)
    println()
    
    # Table header (aligned with data columns)
    print("   ")  # Space for the ✓/✗ symbol (2 characters)
    print(" | ")
    print(rpad("Type", 4))
    print(" | ")
    print(rpad("Problem", 8))
    print(" | ")
    print(rpad("Disc", 8))
    print(" | ")
    print(rpad("Modeler", 12))
    print(" | ")
    print(rpad("Solver", 6))
    print(" | ")
    print(lpad("Time", 12))
    print(" | ")
    print(lpad("Iters", 5))
    print(" | ")
    print(lpad("Objective", 14))
    print(" | ")
    print(lpad("Reference", 14))
    print(" | ")
    print(lpad("Error", 7))
    
    if show_memory
        print(" | ")
        print(lpad("Memory", 10))
    end
    
    println()
    flush(stdout)
end

"""
    print_test_line(
        test_type::String,
        problem::String,
        discretizer::String,
        modeler::String,
        solver::String,
        success::Bool,
        time::Real,
        obj::Real,
        ref_obj::Real,
        iterations::Union{Int, Nothing} = nothing,
        memory_bytes::Union{Int, Nothing} = nothing,
        show_memory::Bool = false
    )

Display a formatted table line for a test result.

Single responsibility: Formatted display of a result line.
Format inspired by print_benchmark_line() in CTBenchmarks.jl.

# Architecture
- Uses prettytime() and prettymemory() (DRY)
- Fixed columns with rpad/lpad for alignment
- Colors via printstyled for readability
- Flush stdout for real-time display
- Phantom '-' sign for positive objectives (alignment)

# Output format
```
  ✓ | Beam     | midpoint | ADNLP | Ipopt  |   2.345 s |   15 |  8.898598e+00 |  8.898598e+00 | 0.00%
```

# Arguments
- `test_type`: Test type ("CPU" or "GPU")
- `problem`: Problem name (e.g., "Beam", "Goddard")
- `discretizer`: Discretizer name (e.g., "midpoint", "trapeze")
- `modeler`: Modeler name (e.g., "ADNLP", "Exa")
- `solver`: Solver name (e.g., "Ipopt", "MadNLP")
- `success`: Test success status
- `time`: Execution time in seconds
- `obj`: Obtained objective value
- `ref_obj`: Reference objective value
- `iterations`: Number of iterations (optional)
- `memory_bytes`: Allocated memory in bytes (optional)
- `show_memory`: Show memory (default: false)
"""
function print_test_line(
    test_type::String,
    problem::String,
    discretizer::String,
    modeler::String,
    solver::String,
    success::Bool,
    time::Real,
    obj::Real,
    ref_obj::Real,
    iterations::Union{Int, Nothing} = nothing,
    memory_bytes::Union{Int, Nothing} = nothing,
    show_memory::Bool = false
)
    # Relative error calculation
    rel_error = abs(obj - ref_obj) / abs(ref_obj) * 100
    
    # Colored status (✓ green or ✗ red)
    if success
        printstyled("  ✓"; color=:green, bold=true)
    else
        printstyled("  ✗"; color=:red, bold=true)
    end
    
    print(" | ")
    
    # Type column: CPU or GPU
    printstyled(rpad(test_type, 4); color=:magenta)
    print(" | ")
    
    # Fixed columns with rpad/lpad (like CTBenchmarks)
    # Problem: 8 characters
    printstyled(rpad(problem, 8); color=:cyan, bold=true)
    print(" | ")
    
    # Discretizer: 8 characters
    printstyled(rpad(discretizer, 8); color=:blue)
    print(" | ")
    
    # Modeler: 12 characters
    printstyled(rpad(modeler, 12); color=:magenta)
    print(" | ")
    
    # Solver: 6 characters
    printstyled(rpad(solver, 6); color=:yellow)
    print(" | ")
    
    # Time: right-aligned, 12 characters
    print(lpad(prettytime(time), 12))
    print(" | ")
    
    # Iterations: right-aligned, 5 characters
    iter_str = iterations === nothing ? "N/A" : string(iterations)
    print(lpad(iter_str, 5))
    print(" | ")
    
    # Objective: scientific format with phantom sign for alignment
    # Add space instead of '-' for positive values
    obj_str = @sprintf("%.6e", obj)
    if obj >= 0
        obj_str = " " * obj_str  # Phantom sign
    end
    print(lpad(obj_str, 14))
    print(" | ")
    
    # Reference: scientific format with phantom sign
    ref_str = @sprintf("%.6e", ref_obj)
    if ref_obj >= 0
        ref_str = " " * ref_str  # Phantom sign
    end
    print(lpad(ref_str, 14))
    print(" | ")
    
    # Error: scientific notation with 2 decimal places
    err_str = @sprintf("%.2e", rel_error / 100)  # Convert to fraction then scientific format
    err_color = rel_error < 1 ? :green : (rel_error < 5 ? :yellow : :red)
    printstyled(lpad(err_str, 7); color=err_color)
    
    # Memory: optional, right-aligned, 10 characters
    if show_memory
        print(" | ")
        if memory_bytes !== nothing
            mem_str = prettymemory(memory_bytes)
        else
            mem_str = "N/A"
        end
        print(lpad(mem_str, 10))
    end
    
    println()
    flush(stdout)  # Real-time display
end

"""
    print_summary(total::Int, passed::Int, total_time::Real)

Display a final summary with test statistics.

Single responsibility: Display global summary.

# Arguments
- `total`: Total number of tests
- `passed`: Number of successful tests
- `total_time`: Total execution time in seconds

# Output format
```
✓ Summary: 16/16 tests passed (100.0% success rate) in 45.234 s
```
"""
function print_summary(total::Int, passed::Int, total_time::Real)
    println()
    success_rate = (passed / total) * 100
    
    # Symbol and color based on result
    if passed == total
        printstyled("✓ Summary: "; color=:green, bold=true)
    else
        printstyled("⚠ Summary: "; color=:yellow, bold=true)
    end
    
    # Statistics
    println("$passed/$total tests passed ($(round(success_rate, digits=1))% success rate) in $(prettytime(total_time))")
    println()
end

end # module TestPrintUtils
