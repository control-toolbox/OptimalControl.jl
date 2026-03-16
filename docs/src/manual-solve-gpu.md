# [Solve on GPU](@id manual-solve-gpu)


```@meta
Draft = false
```

This manual explains how to solve optimal control problems on GPU using the [`solve`](@ref) function. GPU acceleration is available through [ExaModels.jl](https://exanauts.github.io/ExaModels.jl/stable) and [MadNLPGPU.jl](https://github.com/MadNLP/MadNLP.jl), with current support for NVIDIA GPUs via [CUDA.jl](https://github.com/JuliaGPU/CUDA.jl).

For basic CPU solving, see [Solve a problem](@ref manual-solve).

## Prerequisites

You need to load the GPU-capable packages:

```@example gpu
using OptimalControl
using MadNLPGPU
using CUDA
nothing # hide
```

!!! warning "CUDA required"

    GPU solving requires a CUDA-capable GPU and properly configured CUDA drivers. Check `CUDA.functional()` to verify your setup.

## Problem definition

Consider the following optimal control problem. Note the **coordinate-by-coordinate** dynamics declaration required by ExaModels:

```@example gpu
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    v ∈ R, variable
    x(0) == [0, 1]
    x(1) == [0, -1]
    ∂(x₁)(t) == x₂(t)  # Coordinate-by-coordinate
    ∂(x₂)(t) == u(t)   # (not ẋ(t) == [x₂(t), u(t)])
    0 ≤ x₁(t) + v^2 ≤ 1.1
    -10 ≤ u(t) ≤ 10
    1 ≤ v ≤ 2
    ∫(u(t)^2 + v) → min
end
nothing # hide
```

!!! note "ExaModels syntax requirements"

    When using the `:exa` modeler (required for GPU):
    
    - Dynamics **must** be declared coordinate-by-coordinate: `∂(x₁)(t) == ...` instead of `ẋ(t) == [...]`
    - Nonlinear constraints must be scalar expressions
    - Only ExaModels-supported operations are allowed
    
    See the [ExaModels documentation](https://exanauts.github.io/ExaModels.jl/stable) for details.

## Descriptive mode with `:gpu` token

The simplest way to solve on GPU is using the `:gpu` parameter token:

```julia
sol = solve(ocp, :exa, :madnlp, :gpu; grid_size=100, print_level=MadNLP.ERROR)
```

Or with partial description (auto-completes to `:collocation, :exa, :madnlp, :gpu`):

```julia
sol = solve(ocp, :gpu; grid_size=100, print_level=MadNLP.ERROR)
```

### What the `:gpu` token does

The `:gpu` parameter token automatically selects GPU-optimized defaults:

**For `Exa` modeler:**

- Sets `backend` to CUDA backend
- Enables GPU-optimized automatic differentiation

**For `MadNLP` solver:**

- Sets `linear_solver` to `MadNLPGPU.CUDSSSolver` (instead of `MadNLP.MumpsSolver`)
- Configures GPU-specific solver options

You can inspect these defaults:

```@example gpu
modeler = OptimalControl.Exa{GPU}()
opts = options(modeler)
opts[:backend]
```

```@example gpu
solver = OptimalControl.MadNLP{GPU}()
opts = options(solver)
opts[:linear_solver]
```

Compare with CPU defaults:

```@example gpu
modeler = OptimalControl.Exa{CPU}()
opts = options(modeler)
opts[:backend]
```

```@example gpu
solver = OptimalControl.MadNLP{CPU}()
opts = options(solver)
opts[:linear_solver]
```

## Explicit mode with parameterized types

For full control, use explicit mode with GPU-parameterized types:

```julia
disc = OptimalControl.Collocation(grid_size=100, scheme=:midpoint)
mod  = OptimalControl.Exa{GPU}()
sol  = OptimalControl.MadNLP{GPU}(print_level=MadNLP.ERROR)

result = solve(ocp; discretizer=disc, modeler=mod, solver=sol)
nothing # hide
```

This gives you:

- Explicit type annotations (`Exa{GPU}`, `MadNLP{GPU}`)
- Full control over each component's options
- Type safety at compile time

## Supported GPU combinations

Only specific strategy combinations support GPU execution:

**✅ Supported:**

- `:collocation` + `:exa` + `:madnlp` + `:gpu`
- `:collocation` + `:exa` + `:madncl` + `:gpu`

**❌ Not supported:**

```julia
# ERROR: ADNLP doesn't support GPU
solve(ocp, :adnlp, :madnlp, :gpu)

# ERROR: Ipopt doesn't support GPU  
solve(ocp, :exa, :ipopt, :gpu)
```

In explicit mode:

```julia
# ERROR: ADNLP{GPU} is not defined
mod = OptimalControl.ADNLP{GPU}()

# ERROR: Ipopt{GPU} is not defined
sol = OptimalControl.Ipopt{GPU}()
```

## Performance considerations

GPU solving is beneficial for:

- **Large-scale problems**: Thousands of variables and constraints
- **Dense computations**: Problems with many nonlinear constraints
- **Repeated solves**: Amortize GPU initialization overhead

For small problems, CPU solving may be faster due to GPU overhead.

### Checking CUDA availability

```julia
if CUDA.functional()
    println("CUDA is available")
    sol = solve(ocp, :gpu)
else
    println("CUDA not available, using CPU")
    sol = solve(ocp, :cpu)
end
```

## See also

- **[Basic solve](@ref manual-solve)**: CPU solving with descriptive mode
- **[Explicit mode](@ref manual-solve-explicit)**: typed components
- **[Advanced options](@ref manual-solve-advanced)**: option routing and introspection
- **[ExaModels.jl](https://exanauts.github.io/ExaModels.jl/stable)**: GPU-capable NLP modeler
- **[MadNLPGPU.jl](https://github.com/MadNLP/MadNLP.jl)**: GPU-accelerated NLP solver
