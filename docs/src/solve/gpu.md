# [GPU](@id solve-gpu)

GPU support runs through [ExaModels.jl](https://exanauts.github.io/ExaModels.jl/stable) and
[MadNLPGPU.jl](https://github.com/MadNLP/MadNLP.jl), NVIDIA GPUs only, via
[CUDA.jl](https://github.com/JuliaGPU/CUDA.jl).

!!! note "What you are reading depends on the machine that built this page"

    Every block below is executed when the documentation is built. With a functional CUDA
    device you are reading real GPU output; without one, you are reading the failure this exact
    code really produces. The first block says which of the two it is.

## Prerequisites

```@example gpu
using OptimalControl
using MadNLPGPU
using CUDA
using CUDSS

println("CUDA.functional() = ", CUDA.functional())
```

Check `CUDA.functional()` before assuming a `:gpu` solve will actually run on the device.

!!! warning "All three — and `CUDSS` is the one you will forget"

    The `CTSolversMadNLPGPU` extension is armed by `MadNLPGPU`, `CUDA` **and** `CUDSS`
    together. Load only the first two — the pair every GPU tutorial shows — and the extension
    does not load, so the GPU solver strategies are never registered.

    It used to work by accident. Up to MadNLPGPU 0.8, `CUDSS` was a hard dependency, so
    `using MadNLPGPU` pulled it in and the third trigger was satisfied without anyone asking.
    From 0.9 onward it is a weak dependency and you must load it yourself.

    The error names exactly which one is missing — load `MadNLPGPU` and `CUDA` but not
    `CUDSS`, and it reports `Missing CUDSS` with the hint `using CUDSS`.

`ExaModels` needs no `using` of its own. It is a dependency of OptimalControl, so the module is
already bound after `using OptimalControl` and `:exa` works without it. Importing it explicitly
also brings its `objective` and `constraint` into scope, both of which collide with the
accessors of the same name — see
[#882](https://github.com/control-toolbox/OptimalControl.jl/issues/882). If you do need
ExaModels' own API, import it qualified: `using ExaModels: ExaModels`.

## The problem must be coordinatewise

`:exa` — the only GPU-capable modeler — requires dynamics (and any path constraint) written
one coordinate at a time, `∂(x₁)(t) == ...`, not `ẋ(t) == [...]`. See
[Abstract syntax (`@def`)](@ref modelling-abstract-syntax) for the two forms side by side.

```@example gpu
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    v ∈ R, variable
    x(0) == [0, 1]
    x(1) == [0, -1]
    ∂(x₁)(t) == x₂(t)   # coordinatewise
    ∂(x₂)(t) == u(t)    # — not ẋ(t) == [x₂(t), u(t)]
    0 ≤ x₁(t) + v^2 ≤ 1.1
    -10 ≤ u(t) ≤ 10
    1 ≤ v ≤ 2
    ∫(u(t)^2 + v) → min
end
```

## Descriptive mode

The `:gpu` parameter token selects GPU-optimized defaults:

```@example gpu
try
    global sol = solve(ocp, :exa, :madnlp, :gpu; grid_size=100, display=false)
    println("objective  = ", objective(sol))
    println("iterations = ", iterations(sol))
catch e
    println("GPU solve failed — no functional device on this machine.")
    println("CUDA.functional() = ", CUDA.functional())
    println("Exception: ", first(sprint(showerror, e), 400))
end
```

Completion fills in the rest — the first match containing `:gpu` is the same method:

```@example gpu
try
    global sol = solve(ocp, :gpu; grid_size=100, display=false)
    println("objective = ", objective(sol))
catch e
    println("Exception: ", first(sprint(showerror, e), 400))
end
```

Solver verbosity is a separate concern: `display=false` above silences the OptimalControl-level
report, and the underlying solver takes its own options — `print_level=MadNLP.ERROR` for
MadNLP, which needs `using MadNLP` in scope. See [Options](@ref solve-options).

`:gpu` changes what a strategy's own defaults are: `Exa{GPU}` uses a CUDA differentiation
backend, `MadNLP{GPU}` uses the `CUDSSSolver` linear solver instead of MUMPS. `describe(:gpu)`
lists every strategy with a GPU-parameterized variant — this call needs nothing GPU-specific
and runs fine on CPU alone:

```@example gpu
describe(:gpu)
```

## Explicit mode

Constructing the components does not touch the device, so this block runs anywhere:

```@example gpu
disc = OptimalControl.Collocation(; grid_size=100, scheme=:midpoint)
mod = OptimalControl.Exa{GPU}()
slv = OptimalControl.MadNLP{GPU}()
nothing # hide
```

Running them is what needs the hardware:

```@example gpu
try
    global result = solve(ocp; discretizer=disc, modeler=mod, solver=slv)
    println("objective = ", objective(result))
catch e
    println("Exception: ", first(sprint(showerror, e), 400))
end
```

## What combinations work

Only `:exa × {:madnlp, :madncl}` on `:gpu` — the two `:gpu` entries of
[`methods`](@ref)`()` (see [Choosing a method](@ref solve-choosing-a-method)). Everything else
is a compile-time or runtime error. These are type-system and routing errors, not
hardware-dependent ones, so they raise identically on every machine:

`ADNLP`'s parameter is constrained to `<:CPU`:

```@repl gpu
try # hide
OptimalControl.ADNLP{GPU}()
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

Same for `Ipopt`:

```@repl gpu
try # hide
OptimalControl.Ipopt{GPU}()
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

Descriptively, the same combinations fail earlier still — no entry in `methods()` carries
`:adnlp` together with `:gpu`, so completion cannot resolve the description at all:

```@repl gpu
try # hide
solve(ocp, :adnlp, :gpu)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Performance notes

GPU solving amortizes best on large-scale problems (thousands of variables/constraints) or
repeated solves in a loop, where the per-call setup overhead is paid once. For small problems,
plain CPU solving is typically faster.

The idiomatic guard is `CUDA.functional()` — pick the strategy, then solve:

```@example gpu
strategy = CUDA.functional() ? :gpu : :cpu
println("strategy = ", strategy)
```

```@example gpu
if CUDA.functional()
    t = @elapsed solve(ocp, :gpu; grid_size=1000, display=false)
    println("GPU solve at grid_size=1000: ", round(t; digits=2), " s")
else
    println("No functional device here, so there is no GPU timing to report.")
    println("On a CUDA machine this block prints the :gpu solve time at grid_size=1000.")
end
```

## See also

- [Overview](@ref solve-overview) — CPU solving basics.
- [Choosing a method](@ref solve-choosing-a-method) — the full method list, GPU entries included.
- [Explicit mode](@ref solve-explicit-mode) — typed components in general.
- The same `:cpu`/`:gpu` distinction applies to `Flow`; see [Flows overview](@ref flows-overview).
