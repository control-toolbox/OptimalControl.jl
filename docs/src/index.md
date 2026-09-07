# OptimalControl.jl

The OptimalControl.jl package is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox). The control-toolbox ecosystem gathers Julia packages for mathematical control and applications. It aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods, both on CPU and GPU.

```@raw html
<style>
.oc-logo { width: 200px; margin: 1.5rem auto; }
.oc-logo--light { display: block; }
.oc-logo--dark  { display: none; }
.dark .oc-logo--light { display: none; }
.dark .oc-logo--dark  { display: block; }
</style>
<img src="./assets/logo.svg"      alt="OptimalControl.jl logo" class="oc-logo oc-logo--light" />
<img src="./assets/logo-dark.svg" alt="OptimalControl.jl logo" class="oc-logo oc-logo--dark" />
```

## Motivation

To our knowledge, OptimalControl.jl is the only Julia package that unifies both direct
and indirect methods for optimal control within a single, coherent framework. This fills
a gap in a landscape where existing tools are fragmented across programming languages and
paradigms, and are usually restricted to a single family of methods.

The package provides a domain-specific language that closely matches mathematical
notation, together with multiple discretization schemes and shooting methods, and planned
support for homotopy continuation methods.

Its modeler–solver separation makes it agnostic to the underlying NLP modeling backend
and optimization solver, and enables seamless execution on both CPU and GPU with minimal
user intervention.

Combined with an ecosystem of domain-specific applications, tutorials, and benchmarking
tools, this design targets researchers and engineers working in optimal control, control
theorists developing new algorithms, and students learning the field through interactive
tutorials.

## Installation

See [Installation](@ref getting-started-installation) — one package to add, plus a handful of
optional pieces (a solver, plotting, flows, saving) loaded only when you use them.

## Basic usage

Let us model, solve and plot a simple optimal control problem.

```@example main
using OptimalControl
using NLPModelsIpopt  # Ipopt solver extension (needed for solve)
using Plots           # plotting extension (needed for plot)

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
plot(sol)
```

That is the whole program — model, solve, plot. Each step has its own guide:

- For more details about the example, see the [energy minimisation page](@ref examples-double-integrator-energy).  
- The `@def` macro defines the problem. See the [abstract syntax guide](@ref modelling-abstract-syntax).  
- The `solve` function has many options. See the [solve overview](@ref solve-overview).  
- The `plot` function is flexible. See the [plot guide](@ref results-plot).

## Where to go next

| Section | What's there |
| --- | --- |
| [Getting started](@ref getting-started-installation) | Install, solve your first problem, then a longer guided tour covering both the direct and indirect methods. |
| [Modelling](@ref modelling-formulation) | The `@def` DSL, the macro-free functional API, control-free (parameter estimation) problems, and problem introspection. |
| [Solve (direct)](@ref solve-overview) | Discretize-and-transcribe methods: choosing a strategy, initial guesses, options, explicit mode, GPU. |
| [Results](@ref results-solution) | Read a `Solution` — trajectories, costate, duals, status — plot it, save it, reload it. |
| [Flows (indirect)](@ref flows-overview) | The Pontryagin Maximum Principle as code: build, integrate, and shoot with Hamiltonian flows. |
| [Geometry](@ref geometry-overview) | The Lie-theoretic tools (`Lift`, `ad`, `Poisson`, `@Lie`) behind singular-control problems. |
| [Examples](@ref examples-gallery) | A gallery of complete problems worked end to end, direct and indirect, from energy minimisation to state constraints. |
| [API reference](@ref api-modelling) | Every re-exported symbol, organised by theme. |
| [Migrating to v2.1](@ref migration) | What changed since v2.0 and how to update your code. |

## Mathematical formulation

Optimal control problems are stated in Bolza form — a cost functional combining a boundary
term (Mayer), a pointwise cost evaluated on the initial and final times and states and on
the optimisation variables, and an integral term (Lagrange) accumulated along the
trajectory. The problem is subject to dynamics and box/path/boundary constraints, with
optionally free times and extra optimisation variables. See
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

## Testing

OptimalControl.jl is the umbrella package of a multi-repository ecosystem, and testing is
organized in layers. Each sub-package (`CTBase`, `CTDirect`, `CTFlows`, `CTModels`, `CTLie`,
`CTSolvers`, `CTParser`) has its own test suite combining unit tests, integration
tests, and code-quality checks (e.g. with [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl)).
At the umbrella level, OptimalControl.jl adds strong end-to-end integration tests that
solve complete optimal control problems with both direct and indirect methods.

Continuous integration runs on Linux, macOS, and Windows, on both CPU and GPU (via a
self-hosted CUDA runner), through reusable workflows centralized in
[CTActions](https://github.com/control-toolbox/CTActions). Code coverage is tracked on
[Codecov](https://codecov.io), and downstream packages are guarded against regressions
through dedicated breakage tests.

Beta versions are distributed during development via a local registry,
[ct-registry](https://github.com/control-toolbox/ct-registry). Part of the test code is
written with the help of AI agents, always under human review.

## Reproducibility

```@setup main
using Pkg
using InteractiveUtils
```

Every page on this site executes its code when the documentation is built, against a
single pinned environment. You can inspect that environment below, or download it and
rebuild it locally.

| Download | Contents |
| --- | --- |
| [`Project.toml`](assets/Project.toml) | the packages this documentation depends on directly |
| [`Manifest.toml`](assets/Manifest.toml) | the exact version of every package in the resolved dependency tree |

::: details Environment used to build this documentation

**Julia version and operating system**

```@example main
versioninfo() # hide
```

**Direct dependencies**

```@example main
Pkg.status() # hide
```

**Full dependency tree**

```@example main
Pkg.status(; mode = PKGMODE_MANIFEST) # hide
```

:::
