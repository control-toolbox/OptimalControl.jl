# [GPU](@id solve-gpu)

```@meta
Draft = true
```

GPU support runs through [ExaModels.jl](https://exanauts.github.io/ExaModels.jl/stable) and
[MadNLPGPU.jl](https://github.com/MadNLP/MadNLP.jl), NVIDIA GPUs only, via
[CUDA.jl](https://github.com/JuliaGPU/CUDA.jl).

!!! note "This page doesn't execute"

    Unlike every other page in this section, the code blocks here are not run when the docs
    are built — there is no CUDA-capable GPU in CI or in this development environment. Loading
    `CUDA`/`MadNLPGPU` and *constructing* CPU-side handles works fine without a device, but the
    GPU-parameterized solver strategies pull in extensions (CUDSS in particular) that only
    finish loading with real GPU hardware present. Everything below is accurate as prose and
    matches the source it describes, but treat it as reference, not as tested output.

## Prerequisites

```julia
using OptimalControl
using ExaModels
using MadNLPGPU
using CUDA
```

Check `CUDA.functional()` before assuming a `:gpu` solve will actually run on the device.

## The problem must be coordinatewise

`:exa` — the only GPU-capable modeler — requires dynamics (and any path constraint) written
one coordinate at a time, `∂(x₁)(t) == ...`, not `ẋ(t) == [...]`. See
[Abstract syntax](@ref modelling-abstract-syntax) for the two forms side by side.

```julia
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

```julia
sol = solve(ocp, :exa, :madnlp, :gpu; grid_size=100, print_level=MadNLP.ERROR)

# or, letting completion fill in the rest — first match with :gpu:
sol = solve(ocp, :gpu; grid_size=100, print_level=MadNLP.ERROR)
```

`:gpu` changes what a strategy's own defaults are: `Exa{GPU}` uses a CUDA differentiation
backend, `MadNLP{GPU}` uses the `CUDSSSolver` linear solver instead of MUMPS. `describe(:gpu)`
lists every strategy with a GPU-parameterized variant (`:exa`, `:madnlp`, `:madncl`, plus the
indirect-side `:di` and `:sciml`) — this call needs nothing GPU-specific and runs fine on CPU
alone.

## Explicit mode

```julia
disc = OptimalControl.Collocation(grid_size=100, scheme=:midpoint)
mod = OptimalControl.Exa{GPU}()
sol = OptimalControl.MadNLP{GPU}(print_level=MadNLP.ERROR)

result = solve(ocp; discretizer=disc, modeler=mod, solver=sol)
```

## What combinations work

Only `:exa × {:madnlp, :madncl}` on `:gpu` — the two entries at the end of
[`methods`](@ref)`()` (see [Choosing a method](@ref solve-choosing-a-method)). Everything else
is a compile-time or runtime error, confirmed directly against the type system:

- `OptimalControl.ADNLP{GPU}()` — `TypeError`, `ADNLP`'s parameter is constrained to `<:CPU`.
- `OptimalControl.Ipopt{GPU}()` — same, `Ipopt`'s parameter is `<:CPU`-only.
- Descriptively, `solve(ocp, :adnlp, :gpu)` or `solve(ocp, :ipopt, :gpu)` fail as
  `AmbiguousDescription`: no entry in `methods()` has `:adnlp` or `:ipopt` together with `:gpu`.

## Performance notes

GPU solving amortizes best on large-scale problems (thousands of variables/constraints) or
repeated solves in a loop, where the per-call setup overhead is paid once. For small problems,
plain CPU solving is typically faster.

```julia
if CUDA.functional()
    sol = solve(ocp, :gpu)
else
    sol = solve(ocp, :cpu)
end
```

## See also

- [Overview](@ref solve-overview) — CPU solving basics.
- [Choosing a method](@ref solve-choosing-a-method) — the full method list, GPU entries included.
- [Explicit mode](@ref solve-explicit-mode) — typed components in general.
- The same `:cpu`/`:gpu` distinction applies to `Flow`; see [Flows overview](@ref flows-overview).
