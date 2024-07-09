```@raw html
<img width="800" alt="juliaopt2024" src="./assets/juliacon2024.jpg">
```

# Trajectory optimisation in space mechanics with Julia

### [Jean-Baptiste Caillau](http://caillau.perso.math.cnrs.fr), [Olivier Cots](https://ocots.github.io), [Alesia Herasimenka](https://www.uni.lu/snt-en/people/alesia-herasimenka) 

```@raw html
<img width="800" alt="affiliations" src="./assets/affil-lux.jpg">
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

## OptimalControl.jl for space mechanics

- [Basic example](tutorial-basic-example.html)
- [Goddard problem](tutorial-goddard.html)
- [Orbit transfer](application-orbit.html)
- [Solar sailing](application-sail.html)

## Wrap up

- High level modelling of optimal control problems
- Efficient numerical resolution coupling direct and indirect methods
- Collection of examples

## Future

- New applications (biology, space mechanics, quantum mechanics and more)
- Additional solvers: direct shooting, collocation for BVP, Hamiltonian pathfollowing...
- ... and open to contributions!

## control-toolbox.org

- Open toolbox
- Collection of Julia Packages rooted at [OptimalControl.jl](https://control-toolbox.org/docs/optimalcontrol)

```@raw html
<a href="https://control-toolbox.org"><img width="800" alt="control-toolbox.org" src="./assets/control-toolbox.jpg"></a>
```

## Credits (not exhaustive!)

- [ADNLPModels.jl](https://jso.dev/ADNLPModels.jl)
- [DifferentiationInterface.jl](https://gdalle.github.io/DifferentiationInterface.jl/DifferentiationInterface/stable)
- [DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl)
- [MLStyle.jl](https://thautwarm.github.io/MLStyle.jl)