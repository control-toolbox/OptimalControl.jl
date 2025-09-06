# OptimalControl.jl

<!-- 
For instructions on how to customize this README.template.md and use the centralized workflow,
please see the user guide: https://github.com/orgs/control-toolbox/discussions/67
-->

The OptimalControl.jl package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

| **Category** | **Badge** |
|-----------------------|-----------|
| **Documentation** | [![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://control-toolbox.org/OptimalControl.jl/stable/) [![Dev Docs](https://img.shields.io/badge/docs-dev-8A2BE2.svg)](https://control-toolbox.org/OptimalControl.jl/dev/) |
| **CI / Build** | [![Build Status](https://github.com/control-toolbox/OptimalControl.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/control-toolbox/OptimalControl.jl/actions/workflows/CI.yml?query=branch%3Amain) |
| **Test Coverage** | [![Coverage](https://codecov.io/gh/control-toolbox/OptimalControl.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/control-toolbox/OptimalControl.jl) |
| **Package Evaluation** | [![PkgEval](https://img.shields.io/badge/Julia-package-purple)](https://juliahub.com/ui/Packages/General/OptimalControl) [![Dependencies](https://juliahub.com/docs/General/OptimalControl/stable/deps.svg)](https://juliahub.com/ui/Packages/General/OptimalControl?t=2) |
| **Release / Version** | [![Release](https://juliahub.com/docs/General/OptimalControl/stable/version.svg)](https://github.com/control-toolbox/OptimalControl.jl/releases) |
| **Citation** | [![DOI](https://zenodo.org/badge/541187171.svg)](https://zenodo.org/doi/10.5281/zenodo.16753152) |
| **License** | [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/control-toolbox/OptimalControl.jl/blob/master/LICENSE) |
| **Code Style / Quality** | [![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle) [![Aqua.jl](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl) |
| **Downloads** | [![Monthly](https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Fmonthly_downloads/OptimalControl&query=total_requests&suffix=%2Fmonth&label=Monthly%20Downloads)](https://juliapkgstats.com/pkg/OptimalControl) [![Total](https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads/OptimalControl&query=total_requests&label=Total%20Downloads)](https://juliapkgstats.com/pkg/OptimalControl) |

## About control-toolbox

The **control-toolbox** ecosystem brings together <a href="https://julialang.org" style="display:inline-flex; align-items:center;">
  <img src="https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/master/images/julia.ico" width="16em" style="margin-right:0.3em;">
  Julia
</a> packages for mathematical control and its applications.  

- The root package, [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl), provides tools to model and solve optimal control problems defined by ordinary differential equations. It supports both direct and indirect methods, and can run on CPU or GPU.  

<p align="right">
  <a href="http://control-toolbox.org/OptimalControl.jl">
    <img src="https://img.shields.io/badge/Documentation-OptimalControl.jl-blue" alt="Documentation OptimalControl.jl">
  </a>
</p>

- Complementing it, [OptimalControlProblems.jl](https://github.com/control-toolbox/OptimalControlProblems.jl) offers a curated collection of benchmark optimal control problems formulated with ODEs in Julia. Each problem is available both in the **OptimalControl** DSL and in **JuMP**, with discretised versions ready to be solved using the solver of your choice. This makes the package particularly useful for benchmarking and comparing different solution strategies.  

<p align="right">
  <a href="http://control-toolbox.org/OptimalControlProblems.jl">
    <img src="https://img.shields.io/badge/Documentation-OptimalControlProblems.jl-blue" alt="Documentation OptimalControlProblems.jl">
  </a>
</p>

## Installation

To install OptimalControl please 
<a href="https://docs.julialang.org/en/v1/manual/getting-started/">open Julia's interactive session (known as REPL)</a> 
and press <kbd>]</kbd> key in the REPL to use the package mode, then add the package:

```julia
julia> ]
pkg> add OptimalControl
```

> [!TIP]
> If you are new to Julia, please follow this [guidelines](https://github.com/orgs/control-toolbox/discussions/64).

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

## Contributing

[issue-url]: https://github.com/control-toolbox/OptimalControl.jl/issues
[first-good-issue-url]: https://github.com/control-toolbox/OptimalControl.jl/contribute

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue][issue-url].  
Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions). You can find first good issues (if any 🙂) [here][first-good-issue-url]. You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

>[!NOTE]
> If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).
