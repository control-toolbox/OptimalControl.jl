# [Save & load](@id results-save-load)

Persist a solution to disk and read it back — for expensive solves you don't want to redo,
warm starts across sessions, or sharing a result with someone who doesn't have the code that
produced it.

```@example main
using OptimalControl
using NLPModelsIpopt

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end

sol = solve(ocp; display=false)
nothing # hide
```

Two functions cover the whole API — `export_ocp_solution` and `import_ocp_solution` — each
with a `format=` keyword picking the backend:

```julia
export_ocp_solution(sol; format::Symbol=:JLD, filename::String="solution")
import_ocp_solution(ocp; format::Symbol=:JLD, filename::String="solution")
```

`import_ocp_solution` takes the **model**, not a filename, as its positional argument — the
solution is reconstructed against it, so the model has to be given explicitly rather than
inferred from the file.

## JLD2

Exact round-trip of the underlying Julia values — the format to reach for by default.

```@example main
using JLD2
export_ocp_solution(sol; format=:JLD, filename="solution")

sol_reloaded = import_ocp_solution(ocp; format=:JLD, filename="solution")
objective(sol_reloaded) == objective(sol)
```

## JSON3

Portable, human-readable, at the cost of not being Julia-specific:

```@example main
using JSON3
export_ocp_solution(sol; format=:JSON, filename="solution")

sol_json = import_ocp_solution(ocp; format=:JSON, filename="solution")
objective(sol_json) ≈ objective(sol)
```

## Which format

JLD2 round-trips Julia values exactly — the same types come back out. JSON3 is text, portable
across languages and tools, but floating-point round-tripping through it isn't guaranteed
bit-exact in general the way JLD2's is — use JLD2 unless portability specifically matters.

## Reloading as an initial guess

A reloaded solution works as a warm start exactly like a freshly-computed one — see
[Initial guess](@ref solve-initial-guess) for everything else `init=` accepts:

```@example main
sol_warm = solve(ocp; init=sol_reloaded, display=false)
nothing # hide
```

## Without the extension

Both functions are extensions — nothing works until the matching package is loaded:

```julia
julia> using OptimalControl
julia> export_ocp_solution(sol; format=:JLD)
ERROR: ExtensionError: missing dependencies to export solutions to JLD2 format
Missing  JLD2
Hint     Run: using JLD2
```

Same pattern for `format=:JSON`, naming `JSON3` instead. An invalid `format` is caught before
either extension is even needed:

```@repl main
try # hide
export_ocp_solution(sol; format=:XML)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Filenames have no extension of their own

`filename` is a **base name** — the extension is added automatically (`.jld2` or `.json`),
which is why the same `filename=` works unchanged for both formats above. Including the
extension yourself doesn't get stripped — it gets doubled:

```@example main
export_ocp_solution(sol; format=:JLD, filename="sol.jld2")
isfile("sol.jld2.jld2")
```

## See also

- [Solution object](@ref results-solution) — what gets saved and reloaded.
- [Initial guess](@ref solve-initial-guess) — every other way to seed a solve, warm start included.
