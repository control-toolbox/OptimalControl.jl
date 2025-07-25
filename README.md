# OptimalControl.jl

[ci-img]: https://github.com/control-toolbox/OptimalControl.jl/actions/workflows/CI.yml/badge.svg?branch=main
[ci-url]: https://github.com/control-toolbox/OptimalControl.jl/actions/workflows/CI.yml?query=branch%3Amain

[co-img]: https://codecov.io/gh/control-toolbox/OptimalControl.jl/branch/main/graph/badge.svg?token=YM5YQQUSO3
[co-url]: https://codecov.io/gh/control-toolbox/OptimalControl.jl

[doc-dev-img]: https://img.shields.io/badge/docs-dev-8A2BE2.svg
[doc-dev-url]: https://control-toolbox.org/OptimalControl.jl/dev/

[doc-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[doc-stable-url]: https://control-toolbox.org/OptimalControl.jl/stable/

[release-img]: https://img.shields.io/github/v/release/control-toolbox/OptimalControl.jl.svg
[release-url]: https://github.com/control-toolbox/OptimalControl.jl/releases

[pkg-eval-img]: https://img.shields.io/badge/Julia-package-purple
[pkg-eval-url]: https://juliahub.com/ui/Packages/General/OptimalControl

[citation-img]: https://zenodo.org/badge/541187171.svg
[citation-url]: https://zenodo.org/doi/10.5281/zenodo.13336563

[licence-img]: https://img.shields.io/badge/License-MIT-yellow.svg
[licence-url]: https://github.com/control-toolbox/OptimalControl.jl/blob/master/LICENSE

[blue-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[blue-url]: https://github.com/JuliaDiff/BlueStyle

[downloads-month-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Fmonthly_downloads%2FOptimalControl&query=total_requests&suffix=%2Fmonth&label=Monthly%20Downloads
[downloads-month-url]: https://juliapkgstats.com/pkg/OptimalControl

[downloads-total-img]: https://img.shields.io/badge/dynamic/json?url=http%3A%2F%2Fjuliapkgstats.com%2Fapi%2Fv1%2Ftotal_downloads%2FOptimalControl&query=total_requests&&label=Total%20Downloads
[downloads-total-url]: https://juliapkgstats.com/pkg/OptimalControl

The OptimalControl.jl package is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox).
The control-toolbox ecosystem gathers Julia packages for mathematical control and applications. It aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods.

| **Name**          | **Badge**         |
:-------------------|:------------------|
| Documentation     | [![Documentation][doc-stable-img]][doc-stable-url] [![Documentation][doc-dev-img]][doc-dev-url]                   | 
| Code Status       | [![Build Status][ci-img]][ci-url] [![Covering Status][co-img]][co-url] [![pkgeval][pkg-eval-img]][pkg-eval-url] [![Code Style: Blue][blue-img]][blue-url]  |
| Licence           | [![License: MIT][licence-img]][licence-url]   |
| Release           | [![Release][release-img]][release-url]        |
| Citation          | [![DOI][citation-img]][citation-url]          |
| Downloads         | [![Month][downloads-month-img]][downloads-month-url]  [![Total][downloads-total-img]][downloads-total-url] |

## Installation

To install OptimalControl.jl please 
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
@software{Caillau_OptimalControl_jl_a_Julia,
author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia},
doi = {10.5281/zenodo.13336563},
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

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). 
If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions).
You can find first good issues (if any 🙂) [here][first-good-issue-url]. You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

>[!NOTE]
> If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).

## See also

We acknowledge support of colleagues from [ADNLPModels](https://jso.dev/ADNLPModels.jl/stable) @[Julia Smooth Optimizers](https://jso.dev) and [MadNLP](https://github.com/MadNLP/MadNLP.jl).
