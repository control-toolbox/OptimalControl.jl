# [About](@id about)

## Motivation

To our knowledge, OptimalControl.jl is the only Julia package that unifies both direct
and indirect methods for optimal control within a single, coherent framework. This fills
a gap in a landscape where existing tools are fragmented across programming languages and
paradigms, and are usually restricted to a single family of methods.

The package provides a domain-specific language that closely matches mathematical
notation, together with multiple discretisation schemes and shooting methods. A solution
can warm-start the next solve, which makes discrete continuation (on the grid or on a
parameter of the problem) a loop of a few lines.

Its modeler–solver separation makes it agnostic to the underlying NLP modeling backend
and optimisation solver, and enables seamless execution on both CPU and GPU with minimal
user intervention.

Combined with an ecosystem of domain-specific applications, tutorials, and benchmarking
tools (see [Beyond this site](@ref home-beyond) on the home page), this design targets researchers and
engineers working in optimal control, control theorists developing new algorithms, and
students learning the field through interactive tutorials.

## Contributing

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue](https://github.com/control-toolbox/OptimalControl.jl/issues). Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions). You can find first good issues (if any 🙂) [here](https://github.com/control-toolbox/OptimalControl.jl/contribute). You may find other packages to contribute to at the [control-toolbox organisation](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organisation](https://github.com/control-toolbox).

!!! note

    If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).

## Testing

OptimalControl.jl is the umbrella package of a multi-repository ecosystem, and testing is
organised in layers. Each sub-package (`CTBase`, `CTDirect`, `CTFlows`, `CTModels`, `CTLie`,
`CTSolvers`, `CTParser`) has its own test suite combining unit tests, integration
tests, and code-quality checks (e.g. with [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl)).
At the umbrella level, OptimalControl.jl adds strong end-to-end integration tests that
solve complete optimal control problems with both direct and indirect methods.

Continuous integration runs on Linux, macOS, and Windows, on both CPU and GPU (via a
self-hosted CUDA runner), through reusable workflows centralised in
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
| :--- | :--- |
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
