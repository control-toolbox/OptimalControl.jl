# OptimalControl

[ci-img]: https://github.com/control-toolbox/OptimalControl.jl/actions/workflows/CI.yml/badge.svg?branch=main
[ci-url]: https://github.com/control-toolbox/OptimalControl.jl/actions/workflows/CI.yml?query=branch%3Amain

[co-img]: https://codecov.io/gh/control-toolbox/OptimalControl.jl/branch/main/graph/badge.svg?token=YM5YQQUSO3
[co-url]: https://codecov.io/gh/control-toolbox/OptimalControl.jl

[doc-dev-img]: https://img.shields.io/badge/docs-dev-8A2BE2.svg
[doc-dev-url]: https://control-toolbox.org/OptimalControl.jl/dev/

[doc-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[doc-stable-url]: https://control-toolbox.org/OptimalControl.jl/stable/

[release-img]: https://img.shields.io/github/v/release/control-toolbox/OptimalControl.jl.svg?style=round-square
[release-url]: https://github.com/control-toolbox/OptimalControl.jl/releases

The [OptimalControl.jl](https://juliahub.com/ui/Packages/General/OptimalControl) package is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox).
The control-toolbox ecosystem gathers Julia packages for mathematical control and applications. It aims to provide tools to model and solve optimal control problems by direct and indirect methods.

| **Documentation**  | **Code Status**  | **Release**  | **Citation** |
|:-------------------|:-----------------|:-------------|:-------------|
| [![Documentation][doc-stable-img]][doc-stable-url] [![Documentation][doc-dev-img]][doc-dev-url] | [![Build Status][ci-img]][ci-url] [![Covering Status][co-img]][co-url] [![pkgeval](https://juliahub.com/docs/General/OptimalControl/stable/pkgeval.svg)](https://juliahub.com/ui/Packages/General/OptimalControl) | [![Release][release-img]][release-url] | [![DOI](https://zenodo.org/badge/541187171.svg)](https://zenodo.org/doi/10.5281/zenodo.13336563) |

## Installation

To install a package from the control-toolbox ecosystem, please visit the [installation page](https://github.com/control-toolbox#installation). To install [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) please <a href="https://docs.julialang.org/en/v1/manual/getting-started/">open
Julia's interactive session (known as REPL)</a> and press <kbd>]</kbd> key in the REPL to use the package mode, then add the package:

```julia
julia> ]
pkg> add OptimalControl
```

## How to cite

If you use OptimalControl.jl in your work, please cite us:

> Caillau, J., Cots, O., Gergaud, J., Martinon, P., & Sed, S. *OptimalControl.jl: a Julia package to modelise and solve optimal control problems with ODE's* [Computer software]. https://doi.org/10.5281/zenodo.13336563

or in `bibtex` format:

```bibtex
@software{Caillau_OptimalControl_jl_a_Julia,
author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia},
doi = {10.5281/zenodo.13336563},
license = {["MIT"]},
title = {{OptimalControl.jl: a Julia package to modelise and solve optimal control problems with ODE's}},
url = {https://control-toolbox.org/OptimalControl.jl}
}
```


## See also

We acknowledge support of colleagues from [ADNLPModels](https://jso.dev/ADNLPModels.jl/stable) @[Julia Smooth Optimizers](https://jso.dev).
