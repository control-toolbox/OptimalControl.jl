# OptimalControl.jl

```@meta
CurrentModule =  OptimalControl
```

The OptimalControl.jl package is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox).
The control-toolbox ecosystem gathers Julia packages for mathematical control and applications. It aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods.

## Installation

To install OptimalControl.jl please 
[open Julia's interactive session (known as REPL)](https://docs.julialang.org/en/v1/manual/getting-started)
and press `]` key in the REPL to use the package mode, then add the package:

```julia
julia> ]
pkg> add OptimalControl
```

## Mathematical problem

A (nonautonomous) optimal control problem with possibly free initial and final times can be described as minimising the cost functional

```math
g(t_0, x(t_0), t_f, x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))~\mathrm{d}t
```

where the state $x$ and the control $u$ are functions subject, for $t \in [t_0, t_f]$,
to the differential constraint

```math
   \dot{x}(t) = f(t, x(t), u(t))
```

and other constraints such as

```math
\begin{array}{llcll}
~\xi_l  &\le& \xi(t, u(t))        &\le& \xi_u, \\
\eta_l &\le& \eta(t, x(t))       &\le& \eta_u, \\
\psi_l &\le& \psi(t, x(t), u(t)) &\le& \psi_u, \\
\phi_l &\le& \phi(t_0, x(t_0), t_f, x(t_f)) &\le& \phi_u.
\end{array}
```

## Basic usage

Let us model, solve and plot a simple optimal control problem.

```julia
using OptimalControl
using NLPModelsIpopt
using Plots

ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [ -1, 0 ]
    x(1) == [ 0, 0 ]
    ẋ(t) == [ x₂(t), u(t) ]
    ∫( 0.5u(t)^2 ) → min
end

sol = solve(ocp)

plot(sol)
```

For more details about this problem, please check the
[basic example tutorial](@ref tutorial-basic). 
For a comprehensive introduction to the syntax used above to describe the optimal control problem, check the
[abstract syntax tutorial](@ref tutorial-abstract).

## Citing us

If you use OptimalControl.jl in your work, please cite us:

> Caillau, J.-B., Cots, O., Gergaud, J., Martinon, P., & Sed, S. *OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's*. [doi.org/10.5281/zenodo.13336563](https://doi.org/10.5281/zenodo.13336563)

or in bibtex format:

```bibtex
@software{Caillau_OptimalControl_jl_a_Julia,
author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia},
doi = {10.5281/zenodo.13336563},
license = {["MIT"]},
title = {{OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's}},
url = {https://control-toolbox.org/OptimalControl.jl}
}
```

## Contributing

If you think you found a bug or if you have a feature request / suggestion, feel free to open an 
[issue](https://github.com/control-toolbox/OptimalControl.jl/issues).
Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). 
If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions).
You can find first good issues (if any 🙂) [here](https://github.com/control-toolbox/OptimalControl.jl/contribute). You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).
