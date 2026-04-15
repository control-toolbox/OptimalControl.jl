---
title: 'OptimalControl.jl: A Julia package for modeling and solving optimal control problems with ODEs'
tags:
  - Julia
  - optimal control
  - ordinary differential equations
  - direct methods
  - indirect methods
  - scientific computing
  - mathematical optimization
authors:
  - name: Jean-Baptiste Caillau
    orcid: 0000-0002-1719-2016
    affiliation: "1"
  - name: Olivier Cots
    orcid: 0000-0002-4703-4369
    affiliation: "2"
    corresponding: true
  - name: Joseph Gergaud
    orcid: 0009-0005-9825-8652
    affiliation: "2"
  - name: Pierre Martinon
    orcid: 0000-0003-0571-2376
    affiliation: "3"
  - name: Sophia Sed
    affiliation: "4"

affiliations:
  - name: "Université Côte d'Azur, CNRS, Inria, LJAD, France"
    index: 1
  - name: "Université Toulouse, CNRS, ENSEEIHT-IRIT, France"
    index: 2
  - name: "CAGE team, Inria Paris, France"
    index: 3
  - name: "Inria Sophia Antipolis Méditerranée, France"
    index: 4

date: 12 April 2026
bibliography: paper.bib
archive_doi: 10.5281/zenodo.13336563
---

# Summary

[OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) [@OptimalControl_jl] is a Julia [@Bezanson2017] package for modeling and solving optimal control problems governed by ordinary differential equations (ODEs). As the core of the [control-toolbox ecosystem](https://control-toolbox.org), it provides a unified framework that supports both direct and indirect solution methods with applications spanning aerospace, medical imaging, epidemiology, and quantum control.

The package features an expressive domain-specific language (DSL) built around the `@def` macro, enabling users to define control problems using notation that closely resembles standard mathematical formulations. Problems are solved through direct transcription, converting the continuous problem into a nonlinear program (NLP) using discretization schemes including Euler, trapezoidal, midpoint, and high-order Gauss-Legendre collocation. Alternatively, indirect shooting methods based on Pontryagin's Maximum Principle can be employed. The architecture relies on a modeler-solver separation that provides a modular and extensible foundation, enabling seamless execution on both CPU and GPU with minimal user intervention.

The ecosystem includes extensive [tutorial resources](https://control-toolbox.org/Tutorials.jl), a benchmark problem collection ([OptimalControlProblems.jl](https://control-toolbox.org/OptimalControlProblems.jl) [@OptimalControlProblems_jl] with formulations in OptimalControl DSL and [JuMP](https://jump.dev/JuMP.jl) [@Lubin2023]), and performance comparison tools ([CTBenchmarks.jl](https://control-toolbox.org/CTBenchmarks.jl)). Integration with Julia's ecosystem enables access to state-of-the-art tools: NLP solvers [IPOPT](https://coin-or.github.io/Ipopt) [@Wachter2006] and [MadNLP.jl](https://github.com/MadNLP/MadNLP.jl) [@SHIN2024110651; @SHIN2021693], automatic differentiation and NLP modeling through JuliaSmoothOptimizers' [ADNLPModels](https://jso.dev/ADNLPModels.jl) [@ADNLPModels_jl], GPU acceleration via [ExaModels.jl](https://github.com/exanauts/ExaModels.jl) [@shin2023accelerating], numerical integration from SciML's [DifferentialEquations.jl](https://docs.sciml.ai/DiffEqDocs) [@rackauckas2017differentialequations], and visualization through [Plots.jl](https://docs.juliaplots.org) [@PlotsJL].

# Statement of Need

OptimalControl.jl is, to our knowledge, the only Julia package that unifies both direct and indirect methods for optimal control within a single, coherent framework.

This unified approach addresses a gap in the current optimal control software landscape. Existing tools are fragmented across programming languages and paradigms. Legacy packages such as [HamPath](https://gitlab.inria.fr/ct/hampath) [@caillau2012differential], [NutoPy](https://ct.gitlabpages.inria.fr/nutopy) [@CAILLAU202213], and [COTCOT](https://github.com/mctao-inria/cotcot) [@bonnard2007second] implement sophisticated indirect methods but rely on Fortran implementations with MATLAB or Python interfaces, leading to complex and less extensible workflows. Proprietary solvers like [GPOPS-II](https://gpops2.com) [@Patterson2014] limit transparency and reproducibility. Open-source tools such as [BOCOP](https://github.com/control-toolbox/bocop) [@Bonnans2017], [ACADO](https://acado.github.io) [@Houska2011], and [acados](https://docs.acados.org) [@Verschueren2021] provide valuable direct method implementations but are not natively integrated into a modern, high-level scientific computing ecosystem. Python-based tools such as [Dymos](https://openmdao.github.io/dymos) [@Falck2021], [Pyomo.DAE](https://pyomo.readthedocs.io/en/stable/modeling_extensions/dae.html) [@Nicholson2018], [do-mpc](https://www.do-mpc.com) [@Fiedler2023], and [GEKKO](https://gekko.readthedocs.io) [@Beal2018] offer complementary capabilities but are similarly limited to direct transcription approaches within the Python ecosystem.

Within Julia, most existing packages target specific domains: [RobustAndOptimalControl.jl](https://juliacontrol.github.io/RobustAndOptimalControl.jl) for linear systems, [QuantumControl.jl](https://juliaquantumcontrol.github.io/QuantumControl.jl) and [Piccolo.jl](https://github.com/harmoniqs/Piccolo.jl) for quantum optimal control, [DirectTrajectoryOptimization.jl](https://github.com/thowell/DirectTrajectoryOptimization.jl) for trajectory problems, [LinearMPC.jl](https://darnstrom.github.io/LinearMPC.jl/stable/) [@arnstrom2022daqp] and [ModelPredictiveControl.jl](https://juliacontrol.github.io/ModelPredictiveControl.jl/stable/) [@Gagnon_ModelPredictiveControl_jl_advanced_process_2024] for model predictive control, and [InfiniteOpt.jl](https://infiniteopt.github.io/InfiniteOpt.jl) [@pulsipher2022unifying] for infinite-dimensional optimization. In contrast with InfiniteOpt.jl that is designed as an extension of [JuMP.jl](https://jump.dev/JuMP.jl), our plan is to provide a modeler agnostic approach, able to accept general Julia code and leverage various optimization solvers. Besides, contributing to general-purpose NLP modeling frameworks like JuMP or [CasADi](https://web.casadi.org) [@Andersson2019] would not address the specific needs of optimal control: these tools lack native support for shooting methods based on Pontryagin's Maximum Principle and that heavily rely on differential geometric primitives.

OptimalControl.jl fills this gap by providing a DSL that matches mathematical notation, multiple discretization schemes and shooting methods, with planned support for homotopy continuation methods. The modeler-solver separation enables complementary use with InfiniteOpt.jl (JuMP-based) through alternative NLP modeling backends (currently ADNLPModels, ExaModels) and solvers. GPU acceleration and an ecosystem with domain-specific applications, tutorials, and benchmarking tools complete the offering. Target users include researchers and engineers working in optimal control, control theorists developing new algorithms, and students learning optimal control through interactive tutorials.

# State of the Field

## Comparison with existing software

OptimalControl.jl requires Julia version 1.10 or later and is registered in the Julia General registry, enabling straightforward installation via `Pkg.add("OptimalControl")`.

- **Legacy tools (COTCOT, HamPath, NutoPy)**: These Fortran packages excel at indirect methods and homotopy continuation but require multi-language setup (Fortran plus Matlab / Python). OptimalControl.jl provides both direct and indirect methods in pure Julia with straightforward installation via package manager.

- **Direct method tools (BOCOP, ACADO, GPOPS-II, acados, nosnoc)**: Strong direct method implementations: [GPOPS-II](https://gpops2.com) [@Patterson2014] delivers mature methods with MATLAB and C++ implementations but is proprietary; [acados](https://docs.acados.org) [@Verschueren2021] targets real-time MPC on embedded systems; [nosnoc](https://github.com/nosnoc/nosnoc) [@Nurkanovic2022] specializes in nonsmooth optimal control; [CasADi](https://web.casadi.org) [@Andersson2019], used as symbolic backend by several of these tools, is a general NLP modeler rather than an optimal control solver. OptimalControl.jl offers an open-source alternative with expressive DSL, native Julia ecosystem integration, GPU support, and unified direct and indirect approaches.

- **Julia packages**: RobustAndOptimalControl.jl targets linear systems; QuantumControl.jl, Piccolo.jl and DirectTrajectoryOptimization.jl serve specific domains; [LinearMPC.jl](https://darnstrom.github.io/LinearMPC.jl/stable/) [@arnstrom2022daqp] and [ModelPredictiveControl.jl](https://juliacontrol.github.io/ModelPredictiveControl.jl/stable/) [@Gagnon_ModelPredictiveControl_jl_advanced_process_2024] focus on model predictive control. InfiniteOpt.jl addresses a very rich range of problems, including optimization on PDE's or with chance constraints, focusing on direct transcription methods. OptimalControl.jl works seamlessly on both CPU and GPU, and adds tools to do shooting in a unified framework plus systematic benchmarking through OptimalControlProblems.jl and CTBenchmarks.jl.

# Illustrative Example

The following example illustrates both direct and indirect solution approaches for a constrained energy minimization problem. The workflow demonstrates a practical strategy: a direct method on a coarse grid first identifies the problem structure and provides an initial guess for the indirect method, which then computes a solution up to arbitrary precision via shooting based on Pontryagin's Maximum Principle.

**Definition of the optimal control problem:**

```julia
# Problem definition: energy-optimal control with state constraint
using OptimalControl
t0 = 0
tf = 1
x0 = [-1, 0]
x_target = [0, 0]
v_max = 1.2
ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0              # initial condition
    x(tf) == x_target        # terminal condition
    v(t) ≤ v_max             # state constraint
    ∂(x)(t) == [v(t), u(t)]  # dynamics
    0.5∫(u(t)^2) → min       # minimize control energy
end
```

**Direct method:** The problem is transcribed to an NLP using a midpoint discretization scheme and solved with an interior-point solver.

```julia
using NLPModelsIpopt
direct_sol = solve(ocp; grid_size=50)
```

**Extract initial guess from direct solution:** The initial costate and the two switching times are recovered from the direct solution to initialize the indirect method.

```julia
t = time_grid(direct_sol)           # the time grid as a vector
x = state(direct_sol)               # the state as a function of time
p = costate(direct_sol)             # the costate as a function of time
p0 = p(t0)                          # initial costate
g(x) = v_max - x[2]                 # constraint: g(x) ≥ 0
I = findall(t -> g(x(t)) ≤ 1e-3, t) # times where constraint is active
t1 = t[first(I)]                    # entry time
t2 = t[last(I)]                     # exit time
initial_guess = [p0..., t1, t2]     # initial guess for shooting
```

**Indirect method:** The indirect method applies Pontryagin's Maximum Principle. The solution has three phases (unconstrained-constrained-unconstrained arcs), requiring definition of Hamiltonian flows for each phase and a shooting function to enforce boundary conditions.

```julia
using OrdinaryDiffEq, NonlinearSolve

# Define Hamiltonian flows based on Pontryagin's Maximum Principle
f_interior = Flow(ocp, (x, p) -> p[2]) # u(x, p) is p[2]
f_boundary = Flow(ocp, (x, p) -> 0,    # u(x, p) is 0
                       (x, u) -> g(x), # when g(x) = 0 (constrained arc)
                       (x, p) -> p[1]) # associated multiplier is p[1]

# Shooting function
function shoot!(s, ξ, _) # unused last parameter (required by NonlinearSolve)
    p0, t1, t2 = ξ[1:2], ξ[3], ξ[4]
    x1, p1 = f_interior(t0, x0, p0, t1)    # flow on unconstrained arc [t0, t1]
    x2, p2 = f_boundary(t1, x1, p1, t2)    # flow on constrained arc [t1, t2]
    xf, pf = f_interior(t2, x2, p2, tf)    # flow on unconstrained arc [t2, tf]
    s[1:2] = xf - x_target                 # terminal condition
    s[3] = g(x1)                           # entry condition on constraint
    s[4] = p1[2]                           # switching phase condition
end

# Solve shooting problem
shooting_sol = solve(NonlinearProblem(shoot!, initial_guess))
p0, t1, t2 = shooting_sol.u[1:2], shooting_sol.u[3], shooting_sol.u[4]
```

**Trajectory reconstruction and visualization:** The trajectory is reconstructed by concatenating the three flows using the `*` operator (and indicating the internal times when to concatenate, `t1` and `t2`). Then both solutions are compared visually.

```julia
# Reconstruct trajectory by concatenating flows
φ = f_interior * (t1, f_boundary) * (t2, f_interior)
indirect_sol = φ((t0, tf), x0, p0; saveat=range(t0, tf, 100))

# Compare both solutions
using Plots
plot(direct_sol; label="Direct")
plot!(indirect_sol; label="Indirect", color=2, linestyle=:dash)
```

![Comparison of direct and indirect solutions showing state trajectories (position and velocity), costate variables, and control inputs. The three arc structure is very well captured by the first direct solve, allowing convergence to arbitrary precision of the final shooting.](plot.svg){width="100%"}

# Software Design

The package architecture balances expressiveness, performance, and extensibility through modular design. The core is organized across internal packages within the [control-toolbox organization](https://github.com/control-toolbox), each hosted as an independent Julia package and registered in the General registry: [CTBase.jl](https://github.com/control-toolbox/CTBase.jl) defines the core types (optimal control models, solutions, initial guesses) and their accessors; [CTParser.jl](https://github.com/control-toolbox/CTParser.jl) implements the `@def` DSL macro; [CTDirect.jl](https://github.com/control-toolbox/CTDirect.jl) handles direct transcription and NLP interfacing; and [CTFlows.jl](https://github.com/control-toolbox/CTFlows.jl) provides Hamiltonian flows and shooting for indirect methods. OptimalControl.jl re-exports these packages as a unified entry point. Contributors interested in a specific functionality can work directly on the relevant sub-package, each of which has its own documentation, tests, and continuous integration. The delegation of specific responsibilities is as follows:

- **DSL parsing**: [MLStyle.jl](https://thautwarm.github.io/MLStyle.jl) [@MLStyle_jl] enables pattern matching on abstract syntax trees generated from `@def` macro invocations. This design choice separates problem specification from solution methods, and allows a syntax as close as possible to the mathematical description of the problem.

- **Problem models and solutions**: Structured types represent optimal control models, solutions, and initial guesses. Each type provides textual visualization, accessor methods for introspection, and visual plotting capabilities for solutions. Extensible abstractions enable addition of new problem classes without modifying core code.

- **Discretization**: Direct transcription converts continuous problems into NLPs. Supporting multiple discretization schemes (Euler, midpoint, trapezoidal, Gauss-Legendre) required careful abstraction to share transcription logic while allowing scheme-specific implementations.

- **Modelers and solvers**: We chose a clear modeler-solver separation: discretization produces ADNLPModels (able to deal with arbitrary user defined functions) or ExaModels [@shin2023accelerating] instances compatible with multiple NLP solvers (IPOPT via NLPModelsIpopt.jl [@Orban_NLPModelsIpopt_jl], Knitro [@Byrd2006], MadNLP, and [Uno](https://github.com/cvanaret/Uno) [@VanaretLeyffer2026]). These NLP solvers rely on linear solvers such as [MUMPS.jl](https://github.com/JuliaSmoothOptimizers/MUMPS.jl) [@Montoison_MUMPS_jl; @MUMPS:1; @MUMPS:2] for CPU computations or [CUDSS.jl](https://github.com/exanauts/CUDSS.jl) [@CUDSS_nvidia] for GPU acceleration with MadNLP. Automatic differentiation via ForwardDiff.jl [@RevelsLubinPapamarkou2016] and DifferentiationInterface.jl [@dalle2026commoninterfaceautomaticdifferentiation] avoids manual derivative coding.

- **Indirect methods**: Hamiltonian flows integrate with DifferentialEquations.jl to access adaptive stepping, event handling, and multiple ODE solvers without reimplementation. Shooting methods rely on NonlinearSolve.jl [@pal2024nonlinearsolve] or [MINPACK.jl](https://github.com/sglyon/MINPACK.jl) for root-finding. Future extensions will incorporate homotopy continuation methods leveraging bifurcation analysis tools like [BifurcationKit.jl](https://github.com/bifurcationkit/BifurcationKit.jl) [@veltz:hal-02902346].

**Key design trade-offs:**

1. **DSL vs. programmatic API**: We prioritized a mathematical DSL to reduce cognitive load for domain experts, accepting increased parsing complexity handled internally. Currently we do not address optimization of PDE or stochastic systems.

2. **GPU acceleration strategy**: The modeler-solver separation enables seamless CPU-to-GPU transition. Users simply select the appropriate modeler-solver pair: ExaModels with MadNLP and the CUDSS linear solver for GPU execution. This modular approach minimizes maintenance burden while enabling GPU performance without reimplementing transcription logic. As for now, GPU support is limited to the ExaModels + MadNLP modeler-solver combination.

3. **Method coverage**: Supporting both direct and indirect approaches increases code complexity but serves distinct user needs: direct methods for constrained problems with many variables, indirect methods for theoretical analysis and smaller problems requiring high accuracy. Both approaches resort to iterative solvers and may converge or not, *e.g.* depending on the initial guess. In the case of optimization solvers, the full output status of the solver is returned allowing *a posteriori* analysis.

# Research Impact Statement

OptimalControl.jl has been applied in published research across multiple domains. Independent external adoption demonstrates the package's broader impact: @ferede2025icra used it for drone racing trajectory optimization, @caio2025application for epidemiological models using indirect methods, @morsky2025vaccination for vaccination strategies under social norms, @opmeer2025optimal for optimal harvesting of age-structured populations, and @evangelakos2025fast for fast charging protocols for quantum batteries.

Research by close collaborators further demonstrates the package's versatility across aerospace (@herasimenka2026lowthrust), epidemiology (@bliman:hal-05194927), quantum control (@beschastnyi2025pulse), microbial growth control (@innerarityimizcoz:hal-05369609), and theoretical optimal control (@bouali:hal-04928858; @lutz:hal-05047678; @bayen2026minimum; @bonnard2026zermelo).

The [control-toolbox organization](https://control-toolbox.org) hosts domain-specific application packages built on OptimalControl.jl: medical imaging optimization ([MagneticResonanceImaging.jl](https://control-toolbox.org/MagneticResonanceImaging.jl)), gene regulatory networks ([PWLdynamics.jl](https://agustinyabo.github.io/PWLdynamics.jl)), spacecraft orbital transfers ([Kepler.jl](https://control-toolbox.org/Kepler.jl)), epidemiological modeling ([SIRcontrol.jl](https://anasxbouali.github.io/SIRcontrol.jl)), and variational calculus ([CalculusOfVariations.jl](https://control-toolbox.org/CalculusOfVariations.jl)).

The package serves educational purposes through [Tutorials.jl](https://control-toolbox.org/Tutorials.jl) covering topics from linear-quadratic regulators to Model Predictive Control. These resources are used in academic courses and workshops. [OptimalControlProblems.jl](https://control-toolbox.org/OptimalControlProblems.jl) provides standardized test problems formulated in both OptimalControl DSL and JuMP, enabling systematic performance comparisons through [CTBenchmarks.jl](https://control-toolbox.org/CTBenchmarks.jl).

Development involves international collaborations with CNES (French space agency), Thales Alenia Space, Inria, and CNRS. The package development began in September 2022, with the first public release in February 2023. As of March 2026, OptimalControl.jl has published more than 40 releases with contributions from multiple developers across the control-toolbox ecosystem packages, demonstrating sustained community engagement.

# AI Usage Disclosure

The core software implementation, algorithms, and architectural design of OptimalControl.jl were developed by the authors. Generative AI has been used to assist with code refactoring and generation of unit and integration tests. This paper was drafted by the authors and subsequently revised with AI assistance for restructuring according to JOSS format requirements and language editing. All technical content, examples, and claims reflect the authors' work and judgment.

# Acknowledgements

We thank the [control-toolbox community](https://control-toolbox.org/contributors) and the broader Julia ecosystem for contributions that shaped the package design and educational resources. Development has been supported by partnerships with CNES, Thales Alenia Space, Inria, and CNRS. The software is distributed under the MIT license (see [LICENSE](https://github.com/control-toolbox/OptimalControl.jl/blob/main/LICENSE)) and uses centralized GitHub Actions workflows for continuous integration, documentation, and testing across the ecosystem. We welcome community contributions following the guidelines in [CONTRIBUTING.md](https://github.com/control-toolbox/OptimalControl.jl/blob/main/CONTRIBUTING.md).

# References