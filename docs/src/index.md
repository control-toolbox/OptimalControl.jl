```@raw html
---
layout: home

hero:
  name: OptimalControl.jl
  text: Optimal control in Julia
  tagline: Model a problem as you write it on paper, solve it by direct and indirect methods, on CPU and GPU.
  image:
    light: /logo.svg
    dark: /logo-dark.svg
    alt: OptimalControl.jl logo
  actions:
    - theme: brand
      text: Get started
      link: /getting-started/installation
    - theme: alt
      text: Examples
      link: /examples/gallery
    - theme: alt
      text: GitHub
      link: https://github.com/control-toolbox/OptimalControl.jl
    - theme: alt
      text: Citing us
      link: /#home-citing

features:
  - title: Close to the mathematics
    details: The <code>@def</code> macro reads like the problem on paper. A functional API builds the same model from plain functions.
    link: /modelling/abstract-syntax
  - title: Direct methods
    details: Discretise, build the NLP with ADNLPModels or ExaModels, and solve it with Ipopt, MadNLP, Knitro and others.
    link: /solve/overview
  - title: Indirect methods
    details: Hamiltonian flows built from the problem, concatenated arc by arc, and shooting started from the direct solution.
    link: /flows/overview
  - title: GPU
    details: The same problem, solved on an NVIDIA GPU with ExaModels and MadNLP.
    link: /solve/gpu
  - title: Geometry
    details: Lifts, Lie and Poisson brackets and the <code>@Lie</code> macro, to compute singular controls.
    link: /geometry/overview
  - title: An ecosystem
    details: Tutorials, a collection of problems, benchmarks, and applications built on the package.
    link: /#home-beyond
---
```

## Installation

```julia
import Pkg
Pkg.add("OptimalControl")
```

A solver, plotting and the ODE integrators of the indirect method are separate packages,
loaded only when you use them: see [Installation](@ref getting-started-installation).

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
| :--- | :--- |
| [Getting started](@ref getting-started-installation) | Install, solve your first problem, then a longer guided tour covering both the direct and indirect methods. |
| [Modelling](@ref modelling-formulation) | The `@def` DSL, the macro-free functional API, control-free (parameter estimation) problems, problem introspection, and the discretised problem and its NLP. |
| [Solve (direct)](@ref solve-overview) | Discretise-and-transcribe methods: choosing a strategy, initial guesses, options, explicit mode, GPU. |
| [Results](@ref results-solution) | Read a `Solution` — trajectories, costate, duals, status — plot it, save it, reload it. |
| [Flows (indirect)](@ref flows-overview) | The Pontryagin Maximum Principle as code: build, integrate, and shoot with Hamiltonian flows. |
| [Geometry](@ref geometry-overview) | The Lie-theoretic tools (`Lift`, `ad`, `Poisson`, `@Lie`) behind singular-control problems. |
| [Examples](@ref examples-gallery) | A gallery of complete problems worked end to end, direct and indirect, from energy minimisation to state constraints. |
| [API reference](@ref api-modelling) | Every re-exported symbol, organised by theme. |
| [Errors](@ref errors) | The exceptions OptimalControl raises, and how to read them. |
| [Migrating from v2.0](@ref migration) | What changed since v2.0 and how to update your code. |
| [About](@ref about) | Why this package, how to contribute, how it is tested, and the environment of this site. |

## [Beyond this site](@id home-beyond)

| Site | What's there |
| :--- | :--- |
| [Tutorials](https://control-toolbox.org/Tutorials.jl/stable/) | Longer worked problems and techniques: continuation, initial guesses, MPC, NLP manipulation, … |
| [OptimalControlProblems.jl](https://control-toolbox.org/OptimalControlProblems.jl/stable/) | A collection of optimal control problems, each modelled with OptimalControl and JuMP. |
| [CTBenchmarks.jl](https://control-toolbox.org/CTBenchmarks.jl/stable/) | Benchmarks of solvers and modelling approaches on those problems: timings, memory, solver statistics. |
| [Applications](https://control-toolbox.org/applications/) | Applications built on the ecosystem, from bacterial growth and MRI to orbit transfer. |
| [control-toolbox](https://control-toolbox.org) | The ecosystem: every package, and the discussions. |

## [Citing us](@id home-citing)

If you use OptimalControl.jl in your work, please cite us:

> Caillau, J.-B., Cots, O., Gergaud, J., Martinon, P., & Sed, S. *OptimalControl.jl: a Julia package to model and solve optimal control problems with ODEs*. Journal of Open Source Software, 11(126), 10630, [doi.org/10.21105/joss.10630](https://doi.org/10.21105/joss.10630)

or in bibtex format:

```bibtex
@article{Caillau2026, 
  doi = {10.21105/joss.10630}, 
  url = {https://doi.org/10.21105/joss.10630}, 
  year = {2026}, 
  publisher = {The Open Journal}, 
  volume = {11}, 
  number = {126}, 
  pages = {10630}, 
  author = {Caillau, Jean-Baptiste and Cots, Olivier and Gergaud, Joseph and Martinon, Pierre and Sed, Sophia}, 
  title = {OptimalControl.jl: a Julia package to model and solve optimal control problems with ODEs}, 
  journal = {Journal of Open Source Software} 
}
```
