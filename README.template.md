# OptimalControl.jl

<!-- 
For instructions on how to customize this README.template.md and use the centralized workflow,
please see the user guide: https://github.com/orgs/control-toolbox/discussions/67
-->

The OptimalControl.jl package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

<!-- INCLUDE_BADGES: Documentation, CI, Coverage, PackageEvaluation, Release, Citation, License, CodeStyle, Downloads -->

<!-- INCLUDE_ABOUT -->

<!-- INCLUDE_INSTALL -->

## Motivation

The guiding philosophy of OptimalControl.jl is to offer, to our knowledge, the only Julia package that unifies both direct and indirect methods for optimal control within a single, coherent framework. This fills a gap in a landscape where existing tools are fragmented across programming languages and paradigms, and are usually restricted to a single family of methods. The package provides a domain-specific language that closely matches mathematical notation, together with multiple discretization schemes and shooting methods, and planned support for homotopy continuation methods. Its modeler–solver separation makes it agnostic to the underlying NLP modeling backend and optimization solver, and enables seamless execution on both CPU and GPU with minimal user intervention. Combined with an ecosystem of domain-specific applications, tutorials, and benchmarking tools, this design targets researchers and engineers working in optimal control, control theorists developing new algorithms, and students learning the field through interactive tutorials.

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

## Testing

OptimalControl.jl is the umbrella package of a multi-repository ecosystem with a layered testing strategy: each sub-package has its own suite combining unit tests, integration tests, and code-quality checks, while the umbrella package adds strong end-to-end tests solving complete problems by both direct and indirect methods. Continuous integration runs on Linux, macOS, and Windows, on both CPU and GPU, through reusable workflows centralized in [CTActions](https://github.com/control-toolbox/CTActions), with code coverage tracked on Codecov and downstream packages guarded against regressions through breakage tests. Part of the test code is written with AI assistance, always under human review.

## Citing us

If you use OptimalControl.jl in your work, please cite us:

> Caillau, J.-B., Cots, O., Gergaud, J., Martinon, P., & Sed, S. *OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's* [Computer software]. https://doi.org/10.5281/zenodo.13336563

or in BibTeX format:

```bibtex
@software{OptimalControl_jl,
author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia},
doi = {10.5281/zenodo.16753152},
license = {["MIT"]},
title = {{OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's}},
url = {https://control-toolbox.org/OptimalControl.jl}
}
```

<!-- INCLUDE_CONTRIBUTING -->
