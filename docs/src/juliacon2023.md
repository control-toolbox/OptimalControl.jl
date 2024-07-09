```@raw html
<img width="800" alt="juliacon" src="./assets/juliacon2023.jpg">
```

# Solving optimal control problems with Julia
### [Jean-Baptiste Caillau](http://caillau.perso.math.cnrs.fr), [Olivier Cots](https://ocots.github.io), [Joseph Gergaud](https://scholar.google.com/citations?user=pkH4An4AAAAJ&hl=fr), [Pierre Martinon](https://www.linkedin.com/in/pierre-martinon-b4603a17), [Sophia Sed](https://iww.inria.fr/sed-sophia)

```@raw html
<img width="800" alt="affiliations" src="./assets/affil.jpg">
```

# What it's about
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

# Where it comes from
- [BOCOP: the optimal control solver](https://www.bocop.org)
- [HamPath: indirect and Hamiltonian pathfollowing](http://www.hampath.org)
- [Coupling direct and indirect solvers, examples](https://ct.gitlabpages.inria.fr/gallery//notebooks.html)

# OptimalControl.jl
- [Basic example: double integrator](https://control-toolbox.org/docs/optimalcontrol/dev/tutorial-basic-example-f.html)
- [Basic example: double integrator (cont'ed)](https://control-toolbox.org/docs/optimalcontrol/dev/tutorial-basic-example.html)
- [Advanced example: Goddard problem](https://control-toolbox.org/docs/optimalcontrol/dev/tutorial-goddard.html)

# Wrap up
- [X] High level modelling of optimal control problems
- [X] Efficient numerical resolution coupling direct and indirect methods
- [X] Collection of examples 

# Future
- [ct_repl](./assets/repl.mp4)
- Additional solvers: direct shooting, collocation for BVP, Hamiltonian pathfollowing...
- ... and open to contributions!
- [CTProblems.jl](https://control-toolbox.org/docs/ctproblems/stable/problems-list.html)

# control-toolbox.org
- Open toolbox
- Collection of Julia Packages rooted at [OptimalControl.jl](https://control-toolbox.org/docs/optimalcontrol)

```@raw html
<a href="https://control-toolbox.org"><img width="800" alt="control-toolbox.org" src="./assets/control-toolbox.jpg"></a>
```

# Credits (not exhaustive!)
- [DifferentialEquations.jl](https://github.com/SciML/DifferentialEquations.jl)
- [JuMP](https://jump.dev/JuMP.jl),
  [InfiniteOpt.jl](https://docs.juliahub.com/InfiniteOpt/p3GvY/0.4.1),
  [ADNLPModels.jl](https://jso.dev/ADNLPModels.jl)
- [Ipopt](https://github.com/coin-or/ipopt)
- [JuliaDiff](https://juliadiff.org)
  ([FowardDiff.jl](https://juliadiff.org/ForwardDiff.jl),
  [Zygote.jl](https://fluxml.ai/Zygote.jl))
- [MLStyle.jl](https://thautwarm.github.io/MLStyle.jl)
- [REPLMaker.jl](https://docs.juliahub.com/ReplMaker)

