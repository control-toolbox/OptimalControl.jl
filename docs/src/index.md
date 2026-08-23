# OptimalControl.jl

The OptimalControl.jl package is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox). The control-toolbox ecosystem gathers Julia packages for mathematical control and applications. It aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods, both on CPU and GPU.

## Installation

See [Installation](@ref getting-started-installation) — one package to add, plus a handful of
optional pieces (a solver, plotting, flows, saving) loaded only when you use them.

## Basic usage

Let us model, solve and plot a simple optimal control problem.

```@example main
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
    ∫( 0.5u(t)^2 ) → min
end

sol = solve(ocp)
plot(sol; layout=:group)
```

- For more details, see the [energy minimisation example](@ref examples-double-integrator-energy).  
- The `@def` macro defines the problem. See the [abstract syntax guide](@ref modelling-abstract-syntax).  
- The `solve` function has many options. See the [solve overview](@ref solve-overview).  
- The `plot` function is flexible. See the [plot guide](@ref results-plot).

## Where to go next

| Section | What's there |
| --- | --- |
| [Getting started](@ref getting-started-guided-tour) | Install, solve your first problem, then a longer guided tour covering both the direct and indirect methods. |
| [Modelling](@ref modelling-formulation) | The `@def` DSL, the macro-free functional API, control-free (parameter estimation) problems, and problem introspection. |
| [Solve (direct)](@ref solve-overview) | Discretize-and-transcribe methods: choosing a strategy, initial guesses, options, explicit mode, GPU. |
| [Results](@ref results-solution) | Read a `Solution` — trajectories, costate, duals, status — plot it, save it, reload it. |
| [Flows (indirect)](@ref flows-overview) | The Pontryagin Maximum Principle as code: build, integrate, and shoot with Hamiltonian flows. |
| [Geometry](@ref geometry-overview) | The Lie-theoretic tools (`Lift`, `ad`, `Poisson`, `@Lie`) behind singular-control problems. |
| [Examples](@ref examples-gallery) | Six worked problems, direct and indirect, from energy minimisation to state constraints. |
| [API reference](@ref api-modelling) | Every re-exported symbol, organised by theme. |
| [Migrating to v2.1](@ref migration) | What changed since v2.0 and how to update your code. |

## Mathematical formulation

Optimal control problems are stated in Bolza form — a cost functional combining a terminal
(Mayer) and an integral (Lagrange) term, subject to dynamics and box/path/boundary
constraints, with optionally free times and extra optimisation variables. See
[Formulation](@ref modelling-formulation) for the full mathematical setting.

## Citing us

If you use OptimalControl.jl in your work, please cite us:

> Caillau, J.-B., Cots, O., Gergaud, J., Martinon, P., & Sed, S. *OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's*. [doi.org/10.5281/zenodo.13336563](https://doi.org/10.5281/zenodo.13336563)

or in bibtex format:

```bibtex
@software{OptimalControl_jl,
author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia},
doi = {10.5281/zenodo.13336563},
license = {MIT},
title = {{OptimalControl.jl: a Julia package to model and solve optimal control problems with ODE's}},
url = {https://control-toolbox.org/OptimalControl.jl}
}
```

## Contributing

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue](https://github.com/control-toolbox/OptimalControl.jl/issues). Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions). You can find first good issues (if any 🙂) [here](https://github.com/control-toolbox/OptimalControl.jl/contribute). You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

!!! note

    If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).

## Reproducibility

```@setup main
using Pkg
using InteractiveUtils
using Markdown

# Download links for the benchmark environment
function _downloads_toml(DIR)
    link_manifest = joinpath("assets", DIR, "Manifest.toml")
    link_project = joinpath("assets", DIR, "Project.toml")
    return Markdown.parse("""
    You can download the exact environment used to build this documentation:
    - 📦 [Project.toml]($link_project) - Package dependencies
    - 📋 [Manifest.toml]($link_manifest) - Complete dependency tree with versions
    """)
end
```

```@example main
_downloads_toml(".") # hide
```

```@raw html
<details style="margin-bottom: 0.5em; margin-top: 1em;"><summary style="margin-bottom: 0px; margin-top: 0px;">ℹ️ Version info</summary>
```

```@example main
versioninfo() # hide
```

```@raw html
</details>
```

```@raw html
<details style="margin-bottom: 0.5em;"><summary style="margin-bottom: 0px; margin-top: 0px;">📦 Package status</summary>
```

```@example main
Pkg.status() # hide
```

```@raw html
</details>
```

```@raw html
<details style="margin-bottom: 0.5em;"><summary style="margin-bottom: 0px; margin-top: 0px;">📚 Complete manifest</summary>
```

```@example main
Pkg.status(; mode = PKGMODE_MANIFEST) # hide
```

```@raw html
</details>
```
