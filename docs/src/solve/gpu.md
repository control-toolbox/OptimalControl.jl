# [GPU](@id solve-gpu)

GPU support runs through [ExaModels.jl](https://madsuite-org.github.io/ExaModels.jl/stable/) and
[MadNLPGPU.jl](https://madsuite-org.github.io/MadNLP.jl/stable/), NVIDIA GPUs only, via
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

!!! warning "All three, and `CUDSS` is the one you will forget"

    The GPU solvers need `MadNLPGPU`, `CUDA` **and** `CUDSS`, loaded together. `CUDSS` (the
    sparse linear solver on the GPU) is a weak dependency of `MadNLPGPU`: `using MadNLPGPU`
    does not load it. Load only the first two, and the GPU solve fails with an
    `ExtensionError` that reports `Missing CUDSS`, with the hint `using CUDSS`.

`ExaModels` needs no `using` of its own: it comes with OptimalControl, and `:exa` works
without it. Importing it explicitly would also bring its `objective` and `constraint` into
scope, which collide with the accessors of the same name. If you need ExaModels' own API,
import it qualified: `using ExaModels: ExaModels`.

## The problem

`:exa`, the only GPU-capable modeler, needs a problem written with
[`@def`](@ref modelling-abstract-syntax). The dynamics and the path constraints can be written
in vector form, as here, or coordinate by coordinate:

```@example gpu
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    v ∈ R, variable
    x(0) == [0, 1]
    x(1) == [0, -1]
    ẋ(t) == [x₂(t), u(t)]
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

## What `:gpu` changes

`describe(:gpu)` lists every strategy with a GPU variant. It needs nothing GPU-specific and
runs on CPU alone:

```@example gpu
describe(:gpu)
```

Only `:exa`, `:madnlp` and `:madncl` have one. The parameter changes the defaults of their
options. Constructing the strategies does not touch the device, so this runs anywhere:

```@example gpu
Base.CoreLogging.disable_logging(Base.CoreLogging.Warn) # hide
modeler = OptimalControl.Exa{GPU}()
solver = OptimalControl.MadNLP{GPU}()
println("Exa{GPU} backend:          ", options(modeler)[:backend])
println("MadNLP{GPU} linear_solver: ", options(solver)[:linear_solver])
Base.CoreLogging.disable_logging(Base.CoreLogging.BelowMinLevel) # hide
nothing # hide
```

```@example gpu
modeler = OptimalControl.Exa()      # same as OptimalControl.Exa{CPU}()
solver = OptimalControl.MadNLP()    # same as OptimalControl.MadNLP{CPU}()
println("Exa{CPU} backend:          ", options(modeler)[:backend])
println("MadNLP{CPU} linear_solver: ", options(solver)[:linear_solver])
```

On the GPU, ExaModels evaluates the model with a CUDA backend, and MadNLP factorizes its linear
systems with cuDSS instead of MUMPS.

## Explicit mode

Constructing the components does not touch the device, so this block runs anywhere:

```@example gpu
discretizer = OptimalControl.Collocation(; grid_size=100, scheme=:midpoint)
modeler = OptimalControl.Exa{GPU}()
solver = OptimalControl.MadNLP{GPU}()
nothing # hide
```

Running them is what needs the hardware:

```@example gpu
try
    global sol = solve(ocp; discretizer=discretizer, modeler=modeler, solver=solver)
    println("objective = ", objective(sol))
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

GPU solving is beneficial for:

- **large-scale problems**: thousands of variables and constraints, for instance fine grids;
- **dense computations**: problems with many nonlinear constraints;
- **repeated solves**: the GPU initialization overhead is paid once.

For small problems, CPU solving is usually faster.

The idiomatic guard is `CUDA.functional()`: pick the parameter, then solve:

```@example gpu
parameter = CUDA.functional() ? :gpu : :cpu
println("parameter = ", parameter)
```

On a machine with a functional GPU, this block compares the same method on CPU and GPU, on a
fine grid (each solve is run once first, so that compilation is not timed):

```@example gpu
using MadNLP
if CUDA.functional()
    for p in (:cpu, :gpu)
        solve(ocp, :exa, :madnlp, p; grid_size=1000, display=false, print_level=MadNLP.ERROR)
        t = @elapsed solve(ocp, :exa, :madnlp, p; grid_size=1000, display=false, print_level=MadNLP.ERROR)
        println(p, " at grid_size=1000: ", round(t; digits=3), " s")
    end
else
    println("No functional GPU on the machine that built this page: no timing to compare.")
end
```

## See also

- [Solve overview](@ref solve-overview) — CPU solving basics.
- [Choosing a method](@ref solve-choosing-a-method) — the full method list, GPU entries included.
- [Explicit mode](@ref solve-explicit-mode) — typed components in general.
- The same `:cpu`/`:gpu` distinction applies to `Flow`; see [Flows overview](@ref flows-overview).
