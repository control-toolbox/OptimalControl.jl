# [Save & load](@id results-save-load)

A solution can be written to disk and read back later: to keep the result of an expensive
solve, to restart from it in another session, or to share it with someone who does not have
the code that produced it.

The examples use the energy-minimal double integrator of
[Your first problem](@ref getting-started-first-problem).

::: details The problem used on this page

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
nothing # hide
```

:::

```@example main
sol = solve(ocp; display=false)
nothing # hide
```

Two functions do the work, `export_ocp_solution` and `import_ocp_solution`. The `format`
keyword chooses the file format:

```julia
export_ocp_solution(sol; format=:JLD, filename="solution")
import_ocp_solution(ocp; format=:JLD, filename="solution")
```

`import_ocp_solution` takes the **model** as its positional argument: the file holds the
values of the solution (grid, trajectories, multipliers, solver information), and the
solution is rebuilt against the model. Pass the model the solution was computed from. With
another model, the import fails with an `IncorrectArgument` that lists what differs between
the file and the model (dimensions, constraints).

## JLD2

[JLD2](https://github.com/JuliaIO/JLD2.jl) writes a binary file, `solution.jld2`:

```@example main
using JLD2
export_ocp_solution(sol; format=:JLD, filename="solution")

sol_jld = import_ocp_solution(ocp; format=:JLD, filename="solution")
objective(sol_jld) == objective(sol)
```

## JSON

[JSON](https://github.com/JuliaIO/JSON.jl) writes a text file, `solution.json`, which other
languages and tools can read:

```@example main
using JSON
export_ocp_solution(sol; format=:JSON, filename="solution")

sol_json = import_ocp_solution(ocp; format=:JSON, filename="solution")
objective(sol_json) == objective(sol)
```

## What comes back

Both formats give back the same solution, value for value: the time grid, the state, control
and costate on that grid, the variable, the multipliers, the solver's status, message and
iteration count, and, for the solution of a concatenation of flows, its
[switching structure](@ref flows-multi-phase-switching). The model is the one you pass:

```@example main
tg = time_grid(sol)
time_grid(sol_json) == tg,
all(state(sol_json)(t) == state(sol)(t) for t in tg),
status(sol_json), iterations(sol_json) == iterations(sol),
model(sol_json) === ocp
```

```@example main
for s in (sol_jld, sol_json)                                                  # hide
    @assert time_grid(s) == tg                                                # hide
    @assert all(state(s)(t) == state(sol)(t) for t in tg)                     # hide
    @assert all(control(s)(t) == control(sol)(t) for t in tg)                 # hide
    @assert all(costate(s)(t) == costate(sol)(t) for t in tg)                 # hide
    @assert successful(s) && status(s) == status(sol)                        # hide
end                                                                           # hide
nothing                                                                       # hide
```

So the choice is about the file, not the content. JLD2 is compact (here about 35 kB) but
readable from Julia only. JSON is about 3 times larger, and readable anywhere.

```@example main
filesize("solution.jld2"), filesize("solution.json")
```

## Reloading as an initial guess

A reloaded solution is a warm start, like a freshly computed one (see
[Initial guess](@ref solve-initial-guess) for everything `init` accepts). Started from the
solution, the solver stops at once, with 0 iterations. From scratch it needs 1 here, since
this problem is a quadratic program; on a nonlinear problem the saving is larger.

```@example main
sol_warm = solve(ocp; init=sol_jld, display=false)
iterations(sol), iterations(sol_warm)
```

```@example main
@assert successful(sol_warm)                                  # hide
@assert isapprox(objective(sol_warm), objective(sol); atol=1e-8)   # hide
nothing                                                       # hide
```

## File names

`filename` is the name of the file without its extension: `.jld2` or `.json` is added, which
is why the same `filename="solution"` works for both formats above. A name that already ends
with the extension is used as it is:

```@example main
export_ocp_solution(sol; format=:JLD, filename="sol.jld2")
isfile("sol.jld2")
```

```@example main
@assert isfile("sol.jld2") && !isfile("sol.jld2.jld2")    # hide
rm.(["sol.jld2", "solution.jld2", "solution.json"])         # hide
nothing                                                     # hide
```

## Without JLD2 or JSON

Both formats need their package. Without it, the call raises an error that names the
package to load:

```@eval
Main.CTBase.DevTools.repl_without_extensions(
    :OptimalControl,
    "using OptimalControl",
    "using NLPModelsIpopt",
    """
    ocp = @def begin
        t ∈ [0, 1], time
        x ∈ R, state
        u ∈ R, control
        x(0) == 1
        ẋ(t) == u(t)
        ∫(u(t)^2) → min
    end""",
    "sol = solve(ocp; display=false)",
    "export_ocp_solution(sol; format=:JLD)",
)
```

and the same with `JSON` for `format=:JSON`. A format other than `:JLD` and `:JSON` is
rejected before any package is needed:

```@repl main
export_ocp_solution(sol; format=:XML)
```

## See also

- [Solution object](@ref results-solution): what is saved and read back.
- [Initial guess](@ref solve-initial-guess): every way to start a solve, warm starts included.
