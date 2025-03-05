```@raw html
<img width="800" alt="juliaopt2024" src="./assets/zhejiang-2025.jpg">
```

# Solving optimal control problems in Julia: the OptimalControl.jl package

### [Jean-Baptiste Caillau](http://caillau.perso.math.cnrs.fr), [Olivier Cots](https://ocots.github.io), [Joseph Gergaud](https://www.uni.lu/snt-en/people/alesia-herasimenka), [Pierre Martinon](https://github.com/PierreMartinon), [Sophia Sed](https://sed-sam-blog.gitlabpages.inria.fr)

```@raw html
<img width="800" alt="affiliations" src="./assets/affil.jpg">
```

## What it's about

- Nonlinear optimal control of ODEs:

```math
g(x(t_0),x(t_f)) + \int_{t_0}^{t_f} f^0(x(t), u(t))\, \mathrm{d}t \to \min
```

subject to

```math
\dot{x}(t) = f(x(t), u(t)),\quad t \in [t_0, t_f]
```

plus boundary, control and state constraints

- Our core interests: numerical & geometrical methods in control, applications

## OptimalControl.jl for trajectory optimisation

- [Basic example](tutorial-double-integrator-energy.html)
- [Goddard problem](tutorial-goddard.html)
- [Orbit transfer](https://control-toolbox.org/Kepler.jl)

## Wrap up

- High level modelling of optimal control problems
- Efficient numerical resolution coupling direct and indirect methods
- Collection of examples

## Future

- New applications (pace mechanics, biology, quantum mechanics and more)
- Additional solvers: optimisation on GPU, direct shooting, collocation for BVP, Hamiltonian pathfollowing...
- ... and open to contributions! If you like the package, please give us a star ⭐️

```@raw html
<a href="https://github.com/control-toolbox/OptimalControl.jl"><img width="800" alt="OptimalControl.jl" src="./assets/star.jpg"></a>
```

## control-toolbox.org

- Open toolbox
- Collection of Julia Packages rooted at [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl)

```@raw html
<a href="https://control-toolbox.org"><img width="800" alt="control-toolbox.org" src="./assets/control-toolbox.jpg"></a>
```

## Credits (not exhaustive!)

- [ADNLPModels.jl](https://jso.dev/ADNLPModels.jl)
- [DifferentiationInterface.jl](https://gdalle.github.io/DifferentiationInterface.jl/DifferentiationInterface/stable)
- [DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl)
- [Ipopt.jl](https://github.com/jump-dev/Ipopt.jl)
- [MadNLP.jl](https://github.com/MadNLP/MadNLP.jl)
- [MLStyle.jl](https://thautwarm.github.io/MLStyle.jl)

## Stand up for science 2025

```@raw html
<a href="https://standupforscience2025.org"><img width="100" alt="stand up for science 2025" src="./assets/standup.jpg"></a>
```

## Acknowledgements

Jean-Baptiste Caillau is partially funded by a **France 2030** support managed by the *Agence Nationale de la Recherche*, under the reference ANR-23-PEIA-0004 ([PDE-AI](https://pde-ai.math.cnrs.fr) project).

```@raw html
<img width="200" alt="affiliations" src="./assets/france-2030.png">
```