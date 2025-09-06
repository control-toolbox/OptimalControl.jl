# OptimalControl.jl

<!-- 
For instructions on how to customize this README.template.md and use the centralized workflow,
please see the user guide: https://github.com/orgs/control-toolbox/discussions/67
-->

The OptimalControl.jl package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

<!-- INCLUDE_BADGES: Documentation, CI, Coverage, PackageEvaluation, Release, Citation, License, CodeStyle, Downloads -->

<!-- INCLUDE_ABOUT -->

<!-- INCLUDE_INSTALL -->

## Basic usage

Let us model and solve a simple optimal control problem, then plot the solution:

```julia
using OptimalControl
using NLPModelsIpopt
using Plots

ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    0.5∫( u(t)^2 ) → min
end

sol = solve(ocp)

plot(sol)
```

For more details about this problem, please check the basic example presented in the [documentation](https://control-toolbox.org/OptimalControl.jl).

## Citing us

If you use OptimalControl.jl in your work, please cite us:

> Caillau, J.-B., Cots, O., Gergaud, J., Martinon, P., & Sed, S. *OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's* [Computer software]. https://doi.org/10.5281/zenodo.13336563

or in BibTeX format:

```bibtex
@software{OptimalControl_jl_a_Julia,
author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia},
doi = {10.5281/zenodo.16753152},
license = {["MIT"]},
title = {{OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's}},
url = {https://control-toolbox.org/OptimalControl.jl}
}
```

<!-- INCLUDE_CONTRIBUTING -->
