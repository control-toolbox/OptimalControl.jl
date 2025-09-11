# [Solve on GPU](@id manual-solve-gpu)

```@meta
CollapsedDocStrings = false
```

In this manual, we explain how to use the [`solve`](@ref) function from [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) on GPU. We rely on [ExaModels.jl](https://exanauts.github.io/ExaModels.jl/stable) and [MadNLPGPU.jl](https://github.com/MadNLP/MadNLP.jl) and currently only provide support for NVIDIA thanks to [CUDA.jl](https://github.com/JuliaGPU/CUDA.jl). Consider the following simple Lagrange optimal control problem:

 ```julia
using OptimalControl
using MadNLPGPU
using CUDA

ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    v ∈ R, variable
    x(0) == [0, 1]
    x(1) == [0, -1]
    ∂(x₁)(t) == x₂(t)
    ∂(x₂)(t) == u(t)
    0 ≤ x₁(t) + v^2 ≤ 1.1
    -10 ≤ u(t) ≤ 10
    1 ≤ v ≤ 2
    ∫(u(t)^2 + v) → min
end
```

!!! note
    We have used MadNLPGPU instead of MadNLP, that is able to solve on GPU (leveraging [CUDSS.jl](https://github.com/exanauts/CUDSS.jl)) optimisation problems modelled with ExaModels.jl. As a direct transcription towards an `ExaModels.ExaModel` is performed, there are limitations on the syntax:  
    - dynamics must be declared coordinate by coordinate (not globally as a vector valued expression)
    - nonlinear constraints (boundary, variable, control, state, mixed ones, see [Constraints](@ref manual-abstract-constraints) must also be scalar expressions (linear constraints *aka.* ranges, on the other hand, can be vectors)
    - all expressions must only involve algebraic operations that are known to ExaModels (check the [documentation](https://exanauts.github.io/ExaModels.jl/stable)), although one can provide additional user defined functions through *registration* (check [ExaModels API](https://exanauts.github.io/ExaModels.jl/stable/core/#ExaModels.@register_univariate-Tuple%7BAny,%2520Any,%2520Any%7D)) 

Computation on GPU is currently only tested with CUDA, and the associated backend must be passed to ExaModels as is done below (also note the `:exa` keyword to indicate the modeller, and `:madnlp` for the solver):

```julia
sol = solve(ocp, :exa, :madnlp; exa_backend=CUDABackend())
```

```
▫ This is OptimalControl version v1.1.0 running with: direct, exa, madnlp.

▫ The optimal control problem is solved with CTDirect version v0.16.0.

   ┌─ The NLP is modelled with ExaModels and solved with MadNLP.
   │
   ├─ Number of time steps⋅: 250
   └─ Discretisation scheme: trapeze

▫ This is MadNLP version v0.8.7, running with cuDSS v0.4.0

Number of nonzeros in constraint Jacobian............:     2506
Number of nonzeros in Lagrangian Hessian.............:     2006

Total number of variables............................:      754
                     variables with only lower bounds:        0
                variables with lower and upper bounds:      252
                     variables with only upper bounds:        0
Total number of equality constraints.................:      504
Total number of inequality constraints...............:      251
        inequality constraints with only lower bounds:        0
   inequality constraints with lower and upper bounds:      251
        inequality constraints with only upper bounds:        0

iter    objective    inf_pr   inf_du lg(mu)  ||d||  lg(rg) alpha_du alpha_pr  ls
   0  1.0200000e+00 1.10e+00 1.00e+00  -1.0 0.00e+00    -  0.00e+00 0.00e+00   0
  ...
  26  9.8902986e+00 2.22e-16 7.11e-15  -9.0 1.32e-04    -  1.00e+00 1.00e+00h  1

Number of Iterations....: 26

                                   (scaled)                 (unscaled)
Objective...............:   9.8902986337530514e+00    9.8902986337530514e+00
Dual infeasibility......:   7.1054273576010019e-15    7.1054273576010019e-15
Constraint violation....:   2.2204460492503131e-16    2.2204460492503131e-16
Complementarity.........:   4.8363494304578671e-09    4.8363494304578671e-09
Overall NLP error.......:   4.8363494304578671e-09    4.8363494304578671e-09

...

EXIT: Optimal Solution Found (tol = 1.0e-08).
```
