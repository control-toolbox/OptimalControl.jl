# CTSolvers.jl

<!-- 
For instructions on how to customize this README.template.md and use the centralized workflow,
please see the user guide: https://github.com/orgs/control-toolbox/discussions/67
-->

The CTSolvers.jl repo is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

| **Category** | **Badge** |
|-----------------------|-----------|
| **Documentation** | [![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://control-toolbox.org/CTSolvers.jl/stable/) [![Dev Docs](https://img.shields.io/badge/docs-dev-8A2BE2.svg)](https://control-toolbox.org/CTSolvers.jl/dev/) |
| **CI / Build** | [![Build Status](https://github.com/control-toolbox/CTSolvers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/control-toolbox/CTSolvers.jl/actions/workflows/CI.yml?query=branch%3Amain) |
| **Test Coverage** | [![Coverage](https://codecov.io/gh/control-toolbox/CTSolvers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/control-toolbox/CTSolvers.jl) |
| **Release / Version** | [![Release](https://img.shields.io/github/v/release/control-toolbox/CTSolvers.jl.svg)](https://github.com/control-toolbox/CTSolvers.jl/releases) |
| **License** | [![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/control-toolbox/CTSolvers.jl/blob/master/LICENSE) |
| **Code Style / Quality** | [![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/JuliaDiff/BlueStyle) [![Aqua.jl](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl) |

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

## Contributing

[issue-url]: https://github.com/control-toolbox/CTSolvers.jl/issues
[first-good-issue-url]: https://github.com/control-toolbox/CTSolvers.jl/contribute

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue][issue-url].  
Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions). You can find first good issues (if any 🙂) [here][first-good-issue-url]. You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

>[!NOTE]
> If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).
