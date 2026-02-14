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

Affiche l'en-tête du tableau avec les noms de colonnes.

# Arguments
- `show_memory`: Afficher la colonne mémoire (défaut: false)
"""
function print_test_header(show_memory::Bool = false)
    println()
    printstyled("OptimalControl Solve Tests\n"; color=:cyan, bold=true)
    printstyled("==========================\n"; color=:cyan)
    println()
    
    # En-tête du tableau (aligné avec les colonnes de données)
    print("   ")  # Espace pour le symbole ✓/✗ (2 caractères)
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

Affiche une ligne de tableau alignée pour un résultat de test.

Responsabilité unique : Affichage formaté d'une ligne de résultat.
Format inspiré de print_benchmark_line() dans CTBenchmarks.jl.

# Architecture
- Utilise prettytime() et prettymemory() (DRY)
- Colonnes fixes avec rpad/lpad pour alignement
- Couleurs via printstyled pour lisibilité
- Flush stdout pour affichage temps réel
- Signe '-' fantôme pour objectifs positifs (alignement)

# Format de sortie
```
  ✓ | Beam     | midpoint | ADNLPModeler | Ipopt  |   2.345 s |   15 |  8.898598e+00 |  8.898598e+00 | 0.00%
```

# Arguments
- `problem`: Nom du problème (e.g., "Beam", "Goddard")
- `discretizer`: Nom du discrétiseur (e.g., "midpoint", "trapeze")
- `modeler`: Nom du modeler (e.g., "ADNLPModeler", "ExaModeler")
- `solver`: Nom du solver (e.g., "Ipopt", "MadNLP")
- `success`: Statut de succès du test
- `time`: Temps d'exécution en secondes
- `obj`: Valeur objective obtenue
- `ref_obj`: Valeur objective de référence
- `iterations`: Nombre d'itérations (optionnel)
- `memory_bytes`: Mémoire allouée en bytes (optionnel)
- `show_memory`: Afficher la mémoire (défaut: false)
"""
function print_test_line(
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
    # Calcul erreur relative
    rel_error = abs(obj - ref_obj) / abs(ref_obj) * 100
    
    # Status coloré (✓ vert ou ✗ rouge)
    if success
        printstyled("  ✓"; color=:green, bold=true)
    else
        printstyled("  ✗"; color=:red, bold=true)
    end
    
    print(" | ")
    
    # Colonnes avec largeurs fixes (alignement comme CTBenchmarks)
    # Problem: 8 caractères
    printstyled(rpad(problem, 8); color=:cyan, bold=true)
    print(" | ")
    
    # Discretizer: 8 caractères
    printstyled(rpad(discretizer, 8); color=:blue)
    print(" | ")
    
    # Modeler: 12 caractères
    printstyled(rpad(modeler, 12); color=:magenta)
    print(" | ")
    
    # Solver: 6 caractères
    printstyled(rpad(solver, 6); color=:yellow)
    print(" | ")
    
    # Time: aligné à droite, 12 caractères
    print(lpad(prettytime(time), 12))
    print(" | ")
    
    # Iterations: aligné à droite, 5 caractères
    iter_str = iterations === nothing ? "N/A" : string(iterations)
    print(lpad(iter_str, 5))
    print(" | ")
    
    # Objective: format scientifique avec signe fantôme pour alignement
    # Ajouter un espace au lieu de '-' pour les valeurs positives
    obj_str = @sprintf("%.6e", obj)
    if obj >= 0
        obj_str = " " * obj_str  # Signe fantôme
    end
    print(lpad(obj_str, 14))
    print(" | ")
    
    # Reference: format scientifique avec signe fantôme
    ref_str = @sprintf("%.6e", ref_obj)
    if ref_obj >= 0
        ref_str = " " * ref_str  # Signe fantôme
    end
    print(lpad(ref_str, 14))
    print(" | ")
    
    # Error: notation scientifique avec 2 chiffres après la virgule
    err_str = @sprintf("%.2e", rel_error / 100)  # Convertir en fraction puis format scientifique
    err_color = rel_error < 1 ? :green : (rel_error < 5 ? :yellow : :red)
    printstyled(lpad(err_str, 7); color=err_color)
    
    # Memory: optionnel, aligné à droite, 10 caractères
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
    flush(stdout)  # Affichage temps réel
end

"""
    print_summary(total::Int, passed::Int, total_time::Real)

Affiche un résumé final des tests avec statistiques.

Responsabilité unique : Affichage du résumé global.

# Arguments
- `total`: Nombre total de tests
- `passed`: Nombre de tests réussis
- `total_time`: Temps total d'exécution en secondes

# Format de sortie
```
✓ Summary: 16/16 tests passed (100.0% success rate) in 45.234 s
```
"""
function print_summary(total::Int, passed::Int, total_time::Real)
    println()
    success_rate = (passed / total) * 100
    
    # Symbole et couleur selon résultat
    if passed == total
        printstyled("✓ Summary: "; color=:green, bold=true)
    else
        printstyled("⚠ Summary: "; color=:yellow, bold=true)
    end
    
    # Statistiques
    println("$passed/$total tests passed ($(round(success_rate, digits=1))% success rate) in $(prettytime(total_time))")
    println()
end

end # module TestPrintUtils
