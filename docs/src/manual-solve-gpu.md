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


```julia
▫ This is OptimalControl version v1.1.2 running with: direct, exa, madnlp.

▫ The optimal control problem is solved with CTDirect version v0.17.2.

   ┌─ The NLP is modelled with ExaModels and solved with MadNLPMumps.
   │
   ├─ Number of time steps⋅: 250
   └─ Discretisation scheme: midpoint

▫ This is MadNLP version v0.8.12, running with cuDSS v0.6.0

Number of nonzeros in constraint Jacobian............:     2256
Number of nonzeros in Lagrangian Hessian.............:     1251

Total number of variables............................:      754
                     variables with only lower bounds:        0
                variables with lower and upper bounds:      252
                     variables with only upper bounds:        0
Total number of equality constraints.................:      504
Total number of inequality constraints...............:      251
        inequality constraints with only lower bounds:        0
   inequality constraints with lower and upper bounds:      251
        inequality constraints with only upper bounds:        0

iter    objective    inf_pr   inf_du inf_compl lg(mu)  ||d||  lg(rg) alpha_du alpha_pr  ls
   0  1.0200000e+00 1.10e+00 1.00e+00 1.01e+01  -1.0 0.00e+00    -  0.00e+00 0.00e+00   0
   1  1.0199978e+00 1.10e+00 1.45e+00 8.73e-02  -1.0 1.97e+02    -  5.05e-03 4.00e-07h  1
   ...
  27  9.8891249e+00 2.22e-16 7.11e-15 1.60e-09  -9.0 2.36e-04    -  1.00e+00 1.00e+00h  1

Number of Iterations....: 27

                                   (scaled)                 (unscaled)
Objective...............:   9.8891248915014458e+00    9.8891248915014458e+00
Dual infeasibility......:   7.1054273576010019e-15    7.1054273576010019e-15
Constraint violation....:   2.2204460492503131e-16    2.2204460492503131e-16
Complementarity.........:   1.5999963912421547e-09    1.5999963912421547e-09
Overall NLP error.......:   1.5999963912421547e-09    1.5999963912421547e-09

Number of objective function evaluations             = 28
Number of objective gradient evaluations             = 28
Number of constraint evaluations                     = 28
Number of constraint Jacobian evaluations            = 28
Number of Lagrangian Hessian evaluations             = 27
Total wall-clock secs in solver (w/o fun. eval./lin. alg.)  =  0.126
Total wall-clock secs in linear solver                      =  0.103
Total wall-clock secs in NLP function evaluations           =  0.022
Total wall-clock secs                                       =  0.251

EXIT: Optimal Solution Found (tol = 1.0e-08).
```
