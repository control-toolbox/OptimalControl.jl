# [Your first problem](@id getting-started-first-problem)

The shortest complete story: define a problem, solve it, look at the result. Fifteen lines,
no options, no theory.

## The problem

A point mass moves on a line under a bounded force: state $x = (q, v)$ (position, velocity),
scalar control $u$ (the force). Starting at rest at $q=-1$, reach $q=0$ at rest, in one unit of
time, minimising the energy spent:

```math
\min \frac{1}{2}\int_0^1 u(t)^2\,\mathrm dt \quad\text{s.t.}\quad \dot q = v,\ \dot v = u,\
\ x(0) = (-1, 0),\ x(1) = (0, 0).
```

## Define it

```@example main
using OptimalControl
using NLPModelsIpopt

ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end
nothing # hide
```

See [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) for what each line above means.

## Solve it

```@example main
sol = solve(ocp)
nothing # hide
```

## Look at it

```@example main
using Plots
plot(sol)
```

```@example main
objective(sol), iterations(sol), successful(sol)
```

`control(sol)` is a function of time; because the control here is scalar, calling it returns a
`Number`, not a length-1 vector — [1-D is a scalar](@ref modelling-abstract-syntax) throughout
the package:

```@example main
control(sol)(0.5)
```

See [Solution](@ref results-solution) for the rest of what a solution carries, and
[Plotting](@ref results-plot) for what else `plot` can show.

## What just happened

`solve(ocp)` was called with no method at all, so it ran the default:
`(:collocation, :adnlp, :ipopt, :cpu)`. That default, what the four tokens mean, and how to
override any of them, are the subject of [Choosing a method](@ref solve-choosing-a-method).

## Next

- [Choosing a method](@ref solve-choosing-a-method) — pick a different solver, modeler, or grid.
- [Guided tour](@ref getting-started-guided-tour) — the same problem in more depth, plus the
  indirect (Pontryagin) method and a second, harder problem.
- [Example gallery](@ref examples-gallery) — worked problems covering singular arcs, state
  constraints, free variables, and more.
