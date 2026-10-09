# [Energy minimisation](@id examples-double-integrator-energy)

A wagon moves along a rail, and we control its acceleration with a force $u$. Its state is
$x = (q, v)$, where $q$ is the position and $v$ the velocity.

```@raw html
<img src="../assets/chariot_q.svg" alt="" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

The mass is one and there is no friction, so the dynamics are

```math
\dot q(t) = v(t), \quad \dot v(t) = u(t), \quad u(t) \in \mathbb{R},
```

the [double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674).
We transfer the wagon from rest at $q = -1$, at $t_0 = 0$, to rest at $q = 0$, at $t_f = 1$,
with the least energy, $\frac12 \int_0^1 u(t)^2 \, \mathrm{d}t$. This is the problem of
[Your first problem](@ref getting-started-first-problem): this page solves it by the direct
and the indirect methods, and compares them with the exact solution.

We use OptimalControl to define the problem, NLPModelsIpopt to solve it by a direct method,
OrdinaryDiffEqTsit5 and NonlinearSolve for the indirect method, and Plots to see the result.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
t0, tf = 0, 1
x0, xf = [-1, 0], [0, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫(u(t)^2) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

```math
\begin{aligned}
& \text{Minimise} && \frac{1}{2}\int_0^1 u^2(t) \,\mathrm{d}t \\
& \text{subject to} && \dot{x}(t) = (v(t), u(t)), \\[0.5em]
& && x(0) = (-1, 0), \\[0.5em]
& && x(1) = (0, 0).
\end{aligned}
```

```@raw html
</div>
</div>
```

See [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) for every form these lines can
take.

## Direct method

The direct method[^1] discretises the problem in time and solves the resulting nonlinear
program, here with Ipopt:

```@example main
direct_sol = solve(ocp; display=false)
objective(direct_sol)
```

```@example main
plt = plot(direct_sol; label="direct", size=(800, 600))
```

## The exact solution

With the conventions of [Notation and conventions](@ref modelling-formulation-conventions)
($p^0 = -1$), the pseudo-Hamiltonian is

```math
H(x, p, u) = p_1 v + p_2 u - \frac{u^2}{2}.
```

It is maximised by $u = p_2$. The adjoint equations, $\dot p_1 = 0$ and $\dot p_2 = -p_1$, give
$p_1 = a$ and $p_2 = b - at$, so the control is affine, $u(t) = b - at$. The final conditions,
$v(1) = b - a/2 = 0$ and $q(1) = -1 + b/2 - a/6 = 0$, give $a = 12$ and $b = 6$:

```math
p(0) = (12, 6), \qquad u(t) = 6 - 12t, \qquad J = \frac12 \int_0^1 (6 - 12t)^2 \, \mathrm{d}t = 6.
```

## Indirect method

The indirect method, [indirect simple shooting](@extref Tutorials tutorial-iss), computes the
extremal from its initial costate. The flow of the
Hamiltonian system, with the maximising control in feedback form, integrates $(x, p)$ from
$(x_0, p_0)$:

```@example main
# maximising control, H(x, p, u) = p₁v + p₂u - u²/2
u_max(x, p) = p[2]

f = Flow(ocp, u_max)
nothing # hide
```

The shooting function measures how far the flow from $(x_0, p_0)$ lands from the target:

```@example main
S(p0) = f(t0, x0, p0, tf)[1] - xf
nothing # hide
```

We solve $S(p_0) = 0$ with a Newton method, starting from the costate of the direct solution:

```@example main
nle!(s, p0, _) = (s .= S(p0))

p0_guess = costate(direct_sol)(t0)
prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol = shooting_sol.u
```

The residual is zero, and the initial costate is the exact one, $(12, 6)$:

```@example main
S(p0_sol)
```

## Comparison

The extremal integrated from `p0_sol` is a solution of the problem, with its cost:

```@example main
indirect_sol = f((t0, tf), x0, p0_sol)
objective(direct_sol), objective(indirect_sol)
```

For the plot, the flow is built with `saveat`, so that the trajectory has 101 points (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
f_plot = Flow(ocp, u_max; saveat=range(t0, tf, 101), dense=false)
plot!(plt, f_plot((t0, tf), x0, p0_sol); label="indirect", linestyle=:dash)
```

The indirect cost is the exact value, $6$. The direct cost differs by the discretisation error
of the default grid.

```@example main
@assert isapprox(p0_sol, [12, 6]; atol=1e-8) && maximum(abs, S(p0_sol)) < 1e-8   # hide
@assert isapprox(objective(indirect_sol), 6; atol=1e-8)                          # hide
@assert isapprox(objective(direct_sol), 6; rtol=1e-3)                            # hide
@assert isapprox(p0_guess, [12, 6]; rtol=1e-2)                                   # hide
@assert maximum(abs(control(indirect_sol)(t) - (6 - 12t)) for t in 0:0.1:1) < 1e-8   # hide
nothing                                                                          # hide
```

## Notes

- [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) can replace
  NonlinearSolve to solve the shooting equations.
- [From an OCP](@ref flows-from-ocp) explains the flow of a problem, and
  [Shooting](@ref flows-shooting) the shooting method.
- The [Goddard tutorial](@extref Tutorials tutorial-goddard) uses the same steps on a problem
  with bang, singular and boundary arcs.
- [State constraint](@ref examples-state-constraint) adds a bound on the velocity or the
  position to this problem.

[^1]: J. T. Betts, *Practical methods for optimal control using nonlinear programming*, SIAM, Philadelphia, PA, 2001.
