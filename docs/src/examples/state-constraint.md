# [State constraint](@id examples-state-constraint)

This example shows how state constraints of different orders shape the solutions of the
energy-minimal double integrator, and how to compute them by the direct and the indirect
methods. Bryson et al.[^1] and Jacobson et al.[^2] solve such problems analytically.

A wagon moves along a rail, and we control its acceleration with a force $u$. Its state is
$x = (q, v)$, where $q$ is the position and $v$ the velocity.

```@raw html
<img src="../assets/chariot_q.svg" alt="" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

The mass is one and there is no friction, so the dynamics are those of the
[double integrator](https://en.wikipedia.org/w/index.php?title=Double_integrator&oldid=1071399674),
$\dot q = v$, $\dot v = u$, and we minimise the energy $\frac12 \int_0^1 u^2(t)\,\mathrm{d}t$.
Without a constraint, this is [Energy minimisation](@ref examples-double-integrator-energy).

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## [A first-order constraint: a speed limit](@id examples-state-constraint-first-order)

### [The problem](@id examples-state-constraint-first-order-problem)

The wagon goes from rest at $q = -1$ to rest at $q = 0$, as in the energy example, and its
velocity is bounded, $v(t) \le v_{\max} = 1.2$. Without the bound, the velocity
$v(t) = 6t - 6t^2$ reaches $1.5$ at $t = 1/2$, so the bound is active.

```@raw html
<div class="responsive-columns-left-priority">
<div>
```

```@example main
t0, tf = 0, 1
x0, xf = [-1, 0], [0, 0]
v_max = 1.2

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    v(t) ≤ v_max

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
& \text{subject to} && \dot x(t) = (v(t), u(t)), \\[0.5em]
& && v(t) \le v_{\max}, \\[0.5em]
& && x(0) = (-1, 0), \quad x(1) = (0, 0).
\end{aligned}
```

```@raw html
</div>
</div>
```

The constraint is of **first order**: with $c(x) = v_{\max} - v \ge 0$, the first derivative
already involves the control, $\frac{\mathrm{d}}{\mathrm{d}t} c(x(t)) = -u(t)$.

### [Direct method](@id examples-state-constraint-first-order-direct)

A direct method on a coarse grid shows the structure of the solution, and gives the initial
guess of the indirect method:

```@example main
direct_sol = solve(ocp; grid_size=50, display=false)
plt = plot(direct_sol; label="direct", size=(800, 600))
```

The solution has three arcs: an unconstrained arc, a **boundary arc** where $v = v_{\max}$,
and an unconstrained arc.

### [The exact solution](@id examples-state-constraint-first-order-exact)

With the conventions of [Notation and conventions](@ref modelling-formulation-conventions),
the pseudo-Hamiltonian is

```math
H(x, p, u, \mu) = p_1 v + p_2 u - \frac{u^2}{2} + \mu\, c(x), \qquad c(x) = v_{\max} - v,
```

with $\mu = 0$ off the boundary arc. On an unconstrained arc, $u = p_2$. Along the boundary
arc, $c(x(t)) = 0$, so its derivative $-u$ vanishes: $u = 0$. The zero control maximises $H$,
so $p_2 = 0$ along the arc, and the adjoint equation $\dot p_2 = -p_1 + \mu = 0$ gives the
multiplier, $\mu = p_1$. For a first-order constraint, the costate is continuous at the
junctions.

The costate $p_1$ is constant, so on the first arc, $u = p_2$ is affine, and it vanishes at the
entry time $t_1$: $u(t) = p_1 (t_1 - t)$. The velocity reaches $v_{\max}$ at $t_1$, so
$p_1 t_1^2 / 2 = v_{\max}$, and the last arc is symmetric. The distance covered,
$1 = \frac23 p_1 t_1^3 + v_{\max} (1 - 2t_1)$, then gives

```math
t_1 = \frac32 \Big( 1 - \frac{1}{v_{\max}} \Big) = 0.25, \qquad t_2 = 1 - t_1 = 0.75, \qquad
p(0) = (38.4,\ 9.6), \qquad \mu = 38.4 .
```

The cost is $\frac12 \cdot 2 \int_0^{t_1} p_1^2 (t_1 - t)^2 \,\mathrm{d}t = p_1^2 t_1^3 / 3 = 7.68$.

### [Indirect method](@id examples-state-constraint-first-order-indirect)

Each arc has its flow. The flow on the boundary arc takes the constraint $c$ and the
multiplier $\mu$, both as functions (see [Constrained arcs](@ref flows-constrained-arcs)):

```@example main
f_interior = Flow(ocp, (x, p) -> p[2])

c(x) = v_max - x[2]   # the constraint, c ≥ 0
μ(x, p) = p[1]        # the multiplier on the boundary arc

f_boundary = Flow(ocp, (x, p) -> 0; constraint=(x, u) -> c(x), multiplier=μ)
nothing # hide
```

Since the costate is continuous, the unknowns are $p_0 \in \mathbb{R}^2$ and the junction
times $t_1$ and $t_2$. The target gives two equations, the entry on the boundary,
$c(x(t_1)) = 0$, a third, and the switching condition $p_2(t_1) = 0$ the fourth:

```@example main
function shoot!(s, ξ, _)
    p0, t1, t2 = ξ[1:2], ξ[3], ξ[4]
    x1, p1 = f_interior(t0, x0, p0, t1)
    x2, p2 = f_boundary(t1, x1, p1, t2)
    x3, _ = f_interior(t2, x2, p2, tf)
    s[1:2] = x3 - xf      # target
    s[3] = c(x1)          # entry on the boundary
    s[4] = p1[2]          # switching condition
    return nothing
end
nothing # hide
```

The direct solution gives the initial guess: its costate at $t_0$, and the first and last grid
points where the constraint is active:

```@example main
tg = time_grid(direct_sol)
x_d = state(direct_sol)

active = findall(t -> 0 ≤ c(x_d(t)) ≤ 1e-3, tg)
ξ_guess = [costate(direct_sol)(t0)..., tg[first(active)], tg[last(active)]]
```

```@example main
prob = NonlinearProblem(shoot!, ξ_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, t1_sol, t2_sol = shooting_sol.u[1:2], shooting_sol.u[3], shooting_sol.u[4]
```

The shooting finds the exact values, $p_0 = (38.4, 9.6)$, $t_1 = 0.25$ and $t_2 = 0.75$.

### [Comparison](@id examples-state-constraint-first-order-comparison)

The concatenation of the three flows gives the extremal, with the cost $7.68$; the direct cost
differs by the discretisation error:

```@example main
φ = f_interior * (t1_sol, f_boundary) * (t2_sol, f_interior)
indirect_sol = φ((t0, tf), x0, p0_sol)
objective(direct_sol), objective(indirect_sol)
```

For the plot, the flows are built with `saveat`, so that the trajectory has 101 points (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
fine = (saveat=range(t0, tf, 101), dense=false)
φ_plot = Flow(ocp, (x, p) -> p[2]; fine...) *
    (t1_sol, Flow(ocp, (x, p) -> 0; constraint=(x, u) -> c(x), multiplier=μ, fine...)) *
    (t2_sol, Flow(ocp, (x, p) -> p[2]; fine...))
plot!(plt, φ_plot((t0, tf), x0, p0_sol); label="indirect", linestyle=:dash)
```

```@example main
@assert isapprox(shooting_sol.u, [38.4, 9.6, 0.25, 0.75]; atol=1e-8)   # hide
@assert isapprox(objective(indirect_sol), 7.68; atol=1e-6)              # hide
@assert isapprox(objective(direct_sol), 7.68; rtol=1e-2)                # hide
s = zeros(4); shoot!(s, shooting_sol.u, nothing)                        # hide
@assert maximum(abs, s) < 1e-10                                         # hide
nothing                                                                 # hide
```

## [A second-order constraint: the Bryson–Denham problem](@id examples-state-constraint-second-order)

### [The problem](@id examples-state-constraint-second-order-problem)

The wagon now starts at $q = 0$ with the velocity $1$, and must come back to $q = 0$ with the
velocity $-1$: $x(0) = (0, 1)$ and $x(1) = (0, -1)$. Its **position** is bounded,
$q(t) \le a$. This is the Bryson–Denham problem[^1]. The constraint is of **second order**:
with $c(x) = a - q$, the control appears only in the second derivative,

```math
\frac{\mathrm{d}}{\mathrm{d}t} c(x(t)) = -v(t), \qquad
\frac{\mathrm{d}^2}{\mathrm{d}t^2} c(x(t)) = -u(t),
```

so along a boundary arc, $v = 0$ and $u = 0$.

Without the constraint, $u = -2$ and $q(t) = t - t^2$, whose maximum is $1/4$, at $t = 1/2$.
With the constraint, the solution depends on $a$[^3]:

- for $a \ge 1/4$, the constraint is never active;
- for $1/6 \le a \le 1/4$, the trajectory **touches** $q = a$ at a single time, $t = 1/2$;
- for $a \le 1/6$, the trajectory stays on $q = a$ along a **boundary arc**, on
  $[3a, 1 - 3a]$.

We take $a = 0.2$ for a touch point, and $a = 0.1$ for a boundary arc:

```@example main
x0_bd, xf_bd = [0, 1], [0, -1]

function bryson_denham(a)
    return @def begin
        t ∈ [t0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control

        q(t) ≤ a

        x(t0) == x0_bd
        x(tf) == xf_bd

        ẋ(t) == [v(t), u(t)]

        0.5∫(u(t)^2) → min
    end
end
nothing # hide
```

### [Direct method](@id examples-state-constraint-second-order-direct)

```@example main
a_touch, a_arc = 0.2, 0.1
ocp_touch, ocp_arc = bryson_denham(a_touch), bryson_denham(a_arc)

sol_touch = solve(ocp_touch; grid_size=100, display=false)
sol_arc = solve(ocp_arc; grid_size=100, display=false)

legend_off = (state_style=(legend=false,), costate_style=(legend=false,))
plt_bd = plot(sol_touch; label="a = 0.2", size=(800, 600), legend_off...)
plot!(plt_bd, sol_arc; label="a = 0.1", linestyle=:dash, legend_off...)
```

### [The touch point](@id examples-state-constraint-touch)

For $a = 0.2$, the solution has two unconstrained arcs, on $[0, t_1]$ and $[t_1, 1]$, joined
at the contact time $t_1$, where $q(t_1) = a$ and $v(t_1) = 0$. At $t_1$, the costate
**jumps**: $p_q$ increases by $\Delta p_q \ge 0$, and $p_v$ is continuous.

By symmetry, $t_1 = 1/2$. On the first arc, $u = p_v$ is affine, so $q$ is a cubic, and the
conditions $q(0) = 0$, $v(0) = 1$, $q(1/2) = a$ and $v(1/2) = 0$ give
$u(t) = -3.2 + 4.8t$. Since $\dot p_v = -p_q$, $p_q = -4.8$ on $[0, 1/2)$, and by symmetry
$p_q = 4.8$ on $(1/2, 1]$:

```math
p(0) = (-4.8,\ -3.2), \qquad t_1 = 1/2, \qquad \Delta p_q = 9.6, \qquad J = 2.24 .
```

The unknowns of the shooting are $p_0$, $t_1$ and $\Delta p_q$; the target, $q(t_1) = a$ and
$v(t_1) = 0$ give four equations. A vector jump on a Hamiltonian flow is a jump of the costate
(see [Multi-phase flows](@ref flows-multi-phase)):

```@example main
f_touch = Flow(ocp_touch, (x, p) -> p[2])

function shoot_touch!(s, ξ, _)
    p0, t1, Δpq = ξ[1:2], ξ[3], ξ[4]
    x1, p1 = f_touch(t0, x0_bd, p0, t1)
    x2, _ = f_touch(t1, x1, p1 + [Δpq, 0], tf)   # costate jump at t1
    s[1:2] = x2 - xf_bd      # target
    s[3] = a_touch - x1[1]   # contact: q(t1) = a
    s[4] = x1[2]             # tangency: v(t1) = 0
    return nothing
end
nothing # hide
```

The direct solution gives the guess: the contact time is where $q$ is closest to $a$, and the
jump is the variation of its costate $p_q$ around that time:

```@example main
tg_t = time_grid(sol_touch)
p_t = costate(sol_touch)

t1_guess = tg_t[argmin(abs.(a_touch .- first.(state(sol_touch).(tg_t))))]
Δpq_guess = p_t(t1_guess + 0.05)[1] - p_t(t1_guess - 0.05)[1]
ξ_guess_t = [p_t(t0)..., t1_guess, Δpq_guess]

shooting_touch = NonlinearSolve.solve(NonlinearProblem(shoot_touch!, ξ_guess_t); show_trace=Val(false))
p0_touch, t1_touch, Δpq_touch = shooting_touch.u[1:2], shooting_touch.u[3], shooting_touch.u[4]
```

These are the exact values. The concatenation with the jump gives the extremal and its cost,
$2.24$:

```@example main
φ_touch = f_touch * (t1_touch, [Δpq_touch, 0], f_touch)
indirect_touch = φ_touch((t0, tf), x0_bd, p0_touch)
objective(sol_touch), objective(indirect_touch)
```

```@example main
@assert isapprox(shooting_touch.u, [-4.8, -3.2, 0.5, 9.6]; atol=1e-8)   # hide
@assert isapprox(objective(indirect_touch), 2.24; rtol=1e-5)           # hide
@assert isapprox(objective(sol_touch), 2.24; rtol=1e-2)                 # hide
nothing                                                                 # hide
```

### [The boundary arc](@id examples-state-constraint-boundary-arc)

For $a = 0.1$, the solution has three arcs: unconstrained on $[0, t_1]$, on the boundary
$q = a$ on $[t_1, t_2]$, and unconstrained on $[t_2, 1]$. The pseudo-Hamiltonian is

```math
H(x, p, u, \mu) = p_q v + p_v u - \frac{u^2}{2} + \mu\, (a - q).
```

Along the boundary arc, $u = 0$, so $p_v = 0$ by the maximisation condition. Then
$\dot p_v = -p_q = 0$, and $\dot p_q = \mu = 0$: the multiplier is zero, and the costate is
zero on the arc. It jumps at the entry and at the exit, by $(\Delta p_q^1, 0)$ and
$(\Delta p_q^2, 0)$.

On the first arc, the conditions $q(t_1) = a$, $v(t_1) = 0$ and $u(t_1) = p_v(t_1) = 0$ give
$t_1 = 3a$ and $u(t) = -\frac{2}{3a}\big(1 - \frac{t}{3a}\big)$, so $p_q = -\frac{2}{9a^2}$; the
last arc is symmetric:

```math
t_1 = 3a = 0.3, \quad t_2 = 1 - 3a = 0.7, \quad
p(0) = \Big( -\frac{2}{9a^2},\ -\frac{2}{3a} \Big), \quad
\Delta p_q^1 = \Delta p_q^2 = \frac{2}{9a^2}, \quad J = \frac{4}{9a} .
```

The flow on the boundary arc takes the constraint and its multiplier, here zero:

```@example main
f_free = Flow(ocp_arc, (x, p) -> p[2])
f_arc = Flow(ocp_arc, (x, p) -> 0; constraint=(x, u) -> a_arc - x[1], multiplier=(x, p) -> 0)

function shoot_arc!(s, ξ, _)
    p0, t1, t2, Δ1, Δ2 = ξ[1:2], ξ[3], ξ[4], ξ[5], ξ[6]
    x1, p1 = f_free(t0, x0_bd, p0, t1)
    p1⁺ = p1 + [Δ1, 0]                          # jump at the entry
    x2, p2 = f_arc(t1, x1, p1⁺, t2)
    x3, _ = f_free(t2, x2, p2 + [Δ2, 0], tf)    # jump at the exit
    s[1:2] = x3 - xf_bd      # target
    s[3] = a_arc - x1[1]     # entry: q(t1) = a
    s[4] = x1[2]             # tangency: v(t1) = 0
    s[5] = p1⁺[2]            # p_v = 0 on the arc
    s[6] = p1⁺[1]            # p_q = 0 on the arc
    return nothing
end
nothing # hide
```

The guess comes from the direct solution, as before:

```@example main
tg_a = time_grid(sol_arc)
x_a, p_a = state(sol_arc), costate(sol_arc)

active_a = findall(t -> 0 ≤ a_arc - x_a(t)[1] ≤ 1e-3, tg_a)
t1_g, t2_g = tg_a[first(active_a)], tg_a[last(active_a)]
Δ1_g = p_a(t1_g + 0.1)[1] - p_a(t1_g - 0.1)[1]
Δ2_g = p_a(t2_g + 0.1)[1] - p_a(t2_g - 0.1)[1]
ξ_guess_a = [p_a(t0)..., t1_g, t2_g, Δ1_g, Δ2_g]

shooting_arc = NonlinearSolve.solve(NonlinearProblem(shoot_arc!, ξ_guess_a); show_trace=Val(false))
p0_arc, t1_arc, t2_arc = shooting_arc.u[1:2], shooting_arc.u[3], shooting_arc.u[4]
Δ1, Δ2 = shooting_arc.u[5], shooting_arc.u[6]
(t1_arc, t2_arc), (Δ1, Δ2)
```

The junction times are $3a$ and $1 - 3a$, and the two jumps are equal, $2/(9a^2) \approx 22.2$.
The cost is $4/(9a) \approx 4.44$:

```@example main
φ_arc = f_free * (t1_arc, [Δ1, 0], f_arc) * (t2_arc, [Δ2, 0], f_free)
indirect_arc = φ_arc((t0, tf), x0_bd, p0_arc)
objective(sol_arc), objective(indirect_arc)
```

```@example main
a = a_arc                                                                         # hide
@assert isapprox(shooting_arc.u, [-2 / (9a^2), -2 / (3a), 3a, 1 - 3a, 2 / (9a^2), 2 / (9a^2)]; atol=1e-7)   # hide
@assert isapprox(objective(indirect_arc), 4 / (9a); rtol=1e-5)                   # hide
@assert isapprox(objective(sol_arc), 4 / (9a); rtol=1e-2)                         # hide
nothing                                                                           # hide
```

### [Comparison](@id examples-state-constraint-second-order-comparison)

The two indirect solutions, plotted with flows built with `saveat`:

```@example main
fine = (saveat=range(t0, tf, 101), dense=false)
ft = Flow(ocp_touch, (x, p) -> p[2]; fine...)
ff = Flow(ocp_arc, (x, p) -> p[2]; fine...)
fa = Flow(ocp_arc, (x, p) -> 0; constraint=(x, u) -> a_arc - x[1], multiplier=(x, p) -> 0, fine...)

plt_ind = plot((ft * (t1_touch, [Δpq_touch, 0], ft))((t0, tf), x0_bd, p0_touch);
               label="a = 0.2", size=(800, 600), legend_off...)
plot!(plt_ind, (ff * (t1_arc, [Δ1, 0], fa) * (t2_arc, [Δ2, 0], ff))((t0, tf), x0_bd, p0_arc);
      label="a = 0.1", linestyle=:dash, legend_off...)
```

The costate $p_q$ jumps once at the touch point, and twice around the boundary arc, where the
costate is zero.

## Notes

- [Constrained arcs](@ref flows-constrained-arcs) explains the flows on a boundary arc, with
  another Bryson–Denham instance.
- [Multi-phase flows](@ref flows-multi-phase) explains the concatenation of flows, and the jumps.
- [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) can replace
  NonlinearSolve to solve the shooting equations.

[^1]: A. E. Bryson, W. F. Denham and S. E. Dreyfus, *Optimal programming problems with inequality constraints I: necessary conditions for extremal solutions*, AIAA Journal 1 (1963), no. 11, 2544–2550. [doi.org/10.2514/3.2107](https://doi.org/10.2514/3.2107)

[^2]: D. H. Jacobson, M. M. Lele and J. L. Speyer, *New necessary conditions of optimality for control problems with state-variable inequality constraints*, Journal of Mathematical Analysis and Applications 35 (1971), 255–284.

[^3]: A. E. Bryson and Y.-C. Ho, *Applied Optimal Control: Optimization, Estimation and Control*, CRC Press, 1975.
