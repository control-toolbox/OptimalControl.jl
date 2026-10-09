# [Turnpike (bang–singular–bang)](@id examples-turnpike)

A scalar system, $\dot x = u$ with $u \in [-1, 1]$, is driven between two states over a fixed
horizon while minimising $\int x^2$. The dynamics are affine in $u$ and the cost does not
depend on $u$, so the pseudo-Hamiltonian is linear in $u$: the optimal control is bang,
$u = \pm 1$, except on an interval where the switching function vanishes, a **singular arc**.
This is the smallest problem with one, and unlike [Singular control](@ref examples-singular-control),
the singular control follows from the optimality conditions without Poisson brackets.

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

The horizon is fixed, $t_f = 2$, and the transfer goes from $x(0) = 1$ to $x(2) = 1/2$. The
state and the control are scalars, not vectors of length one:

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
t0, tf = 0.0, 2.0
x0, xf = 1.0, 0.5

ocp = @def begin
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    x(t0) == x0
    x(tf) == xf
    ẋ(t) == u(t)
    ∫(x(t)^2) → min
end
nothing # hide
```

```@raw html
</div>
<div>
```

```math
\begin{aligned}
& \text{Minimise} && \int_0^2 x(t)^2 \,\mathrm{d}t \\
& \text{subject to} && \dot x(t) = u(t), \\[0.5em]
& && -1 \le u(t) \le 1, \\[0.5em]
& && x(0) = 1, \quad x(2) = 1/2.
\end{aligned}
```

```@raw html
</div>
</div>
```

## Direct method

```@example main
direct_sol = solve(ocp; grid_size=100, display=false)
plt = plot(direct_sol, :state, :control; label="direct", size=(800, 400))
```

The state goes down to the origin as fast as it can, stays there, then climbs to the target.
The flat middle part, the *turnpike*, is the singular arc, where the control is $0$, inside
its bounds.

## The singular control

With $p^0 = -1$ (see [Notation and conventions](@ref modelling-formulation-conventions)), the
pseudo-Hamiltonian is

```math
H(x, p, u) = p\, u - x^2 .
```

It is linear in $u$, and maximised by $u = \operatorname{sign}(p)$: the switching function is
the costate $p$. Where $p$ vanishes on an interval, and not only at isolated times, this rule
does not give the control, which is *singular*. On such an interval, $\dot p = 0$; the adjoint
equation is $\dot p = -\partial_x H = 2x$, so $x = 0$ there, and then $\dot x = u$ gives

```math
u_{\text{sing}} = 0 .
```

The extremal is therefore bang–singular–bang:

| Arc | Interval | $u$ | $x$ |
| --- | --- | --- | --- |
| bang | $[0, t_1]$ | $-1$ | from $1$ to $0$ |
| singular | $[t_1, t_2]$ | $0$ | $0$ |
| bang | $[t_2, 2]$ | $+1$ | from $0$ to $1/2$ |

The state decreases at unit rate from $1$, so it reaches $0$ at $t_1 = 1$; it increases at unit
rate to $1/2$, so it leaves the arc at $t_2 = 3/2$. On the first arc, $\dot p = 2x = 2(1 - t)$
and $p(t_1) = 0$, so $p(t) = -(1 - t)^2$ and $p(0) = -1$. The cost is
$\int_0^1 (1 - t)^2 \,\mathrm{d}t + \int_{3/2}^2 (t - 3/2)^2 \,\mathrm{d}t = 1/3 + 1/24 = 3/8$.

## Indirect method

Each arc has its flow, with a constant control:

```@example main
f_minus = Flow(ocp, (x, p) -> -1)
f_sing = Flow(ocp, (x, p) -> 0)
f_plus = Flow(ocp, (x, p) -> 1)
nothing # hide
```

The unknowns are the initial costate $p_0$ and the two switching times; the horizon is fixed.
Three conditions close the system: the trajectory enters the singular arc at $x = 0$, with the
switching function $p = 0$, and it reaches the target at $t_f$:

```@example main
function shoot!(s, ξ, _)
    p0, t1, t2 = ξ
    x1, p1 = f_minus(t0, x0, p0, t1)
    x2, p2 = f_sing(t1, x1, p1, t2)
    x3, _ = f_plus(t2, x2, p2, tf)
    s[1] = x1          # enter the singular arc at x = 0
    s[2] = p1          # where the switching function vanishes
    s[3] = x3 - xf     # reach the target
    return nothing
end
nothing # hide
```

The direct solution gives the initial guess. The singular arc is where its switching function,
the costate, stays close to zero, as in the [Goddard tutorial](@extref Tutorials Initial-guess):

```@example main
tg = time_grid(direct_sol)
p_d = costate(direct_sol)

t12 = tg[abs.(p_d.(tg)) .≤ 1e-3]   # the grid points on the singular arc
ξ_guess = [p_d(t0), minimum(t12), maximum(t12)]
```

```@example main
prob = NonlinearProblem(shoot!, ξ_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, t1_sol, t2_sol = shooting_sol.u
```

The solver finds the values computed by hand, $p_0 = -1$, $t_1 = 1$ and $t_2 = 3/2$, with a
zero residual:

```@example main
s = zeros(3)
shoot!(s, shooting_sol.u, nothing)
s
```

## Comparison

The concatenation of the three flows at the switching times gives the whole extremal, and its
cost is $3/8$, as is the cost of the direct solution, up to the discretisation error:

```@example main
φ = f_minus * (t1_sol, f_sing) * (t2_sol, f_plus)
indirect_sol = φ((t0, tf), x0, p0_sol)
objective(direct_sol), objective(indirect_sol)
```

For the plot, the flows are built with `saveat`, so that the trajectory has 201 points (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
fine = (saveat=range(t0, tf, 201), dense=false)
φ_plot = Flow(ocp, (x, p) -> -1; fine...) *
    (t1_sol, Flow(ocp, (x, p) -> 0; fine...)) *
    (t2_sol, Flow(ocp, (x, p) -> 1; fine...))
plot!(plt, φ_plot((t0, tf), x0, p0_sol), :state, :control; label="indirect", linestyle=:dash)
```

```@example main
@assert isapprox(shooting_sol.u, [-1, 1, 3 / 2]; atol=1e-8) && maximum(abs, s) < 1e-10   # hide
@assert isapprox(objective(indirect_sol), 3 / 8; atol=1e-6)                              # hide
@assert isapprox(objective(direct_sol), 3 / 8; atol=1e-3)                                # hide
nothing                                                                                  # hide
```

## See also

- [Singular control](@ref examples-singular-control): a system with three states, where the
  singular control needs Poisson brackets.
- [Shooting](@ref flows-shooting): the shooting method, with switching times as unknowns.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time): bang arcs, without a
  singular arc between them.
- [Multi-phase flows](@ref flows-multi-phase): the concatenation of flows.
- The [Goddard tutorial](@extref Tutorials tutorial-goddard): the same workflow on a harder
  problem, with a singular arc and a boundary arc.
