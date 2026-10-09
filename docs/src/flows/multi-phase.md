# [Multi-phase flows](@id flows-multi-phase)

An optimal control is often made of several arcs: bang arcs, off arcs, singular or boundary
arcs, with possibly a jump of the costate at a junction. Each arc has its own flow, and the
flows are concatenated, at the switching times, into one flow.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using Plots
nothing # hide
```

## Concatenating two flows

`f1 * (t1, f2)` follows `f1` until `t1`, then `f2`. The result is itself a flow:

```@example main
f1 = Flow(VectorField(x -> 0))    # ẋ = 0
f2 = Flow(VectorField(x -> 1))    # ẋ = 1

f = f1 * (1, f2)
f(0, 0.0, 2)   # constant until t = 1, then one unit of slope 1
```

More arcs are added the same way: `f1 * (t1, f2) * (t2, f3)`.

## Jumps

A jump at the switching time is given between the time and the second flow. On a flow of the
state, `f1 * (t1, j, f2)` applies `x ← j(x)`, or `x ← x + j` when `j` is a vector:

```@example main
fj = f1 * (1, x -> x + 10, f2)
fj(0, 0.0, 2)   # +10 at t = 1, then one unit of slope 1
```

```@example main
@assert f(0, 0.0, 2) ≈ 1 && fj(0, 0.0, 2) ≈ 11   # hide
nothing                                          # hide
```

On a Hamiltonian flow, the state and the costate are integrated together, and a jump can act
on either:

- `h1 * (t1, j_x, j_p, h2)` applies `j_x` to the state and `j_p` to the costate, each a
  function, a vector to add, or `nothing` for no jump;
- `h1 * (t1, j, h2)` with a **vector** `j` is a jump of the **costate**, `p ← p + j`: the
  state is continuous, as at the junctions of a boundary arc (see
  [Constrained arcs](@ref flows-constrained-arcs));
- `h1 * (t1, j, h2)` with a **function** `j` maps the pair, `(x, p) ← j(x, p)`.

On the extremal of the energy problem, a costate jump of $(10, 0)$ at $t = 1/2$ leaves the
state continuous and shifts $p_1$ from $12$ to $22$:

```@example main
h = Flow(
    PseudoHamiltonian((x, p, u) -> p[1] * x[2] + p[2] * u - u^2 / 2),
    DynClosedLoop((x, p) -> p[2]),
)
h_jump = h * (0.5, [10, 0], h)
traj = h_jump((0, 1), [-1, 0], [12, 6])
state(traj)(0.5 - 1e-9) ≈ state(traj)(0.5 + 1e-9), costate(traj)(0.25), costate(traj)(0.75)
```

```@example main
@assert costate(traj)(0.25) ≈ [12, 3] && costate(traj)(0.75)[1] ≈ 22   # hide
nothing                                                                 # hide
```

## Inspecting a concatenation

```@example main
n_phases(f), get_switching_times(f), get_flow(f, 1) === f1
```

`get_flows`, `get_switching_time(f, i)`, `get_jump(f, i)` and `get_jumps(f)` read back the
other parts.

## The point call returns one vector

A concatenation is called like any flow: `f((t0, tf), x0, p0)` for the trajectory, and
`f(t0, x0, p0, tf)` for the final point, with `variable=` on a problem with a variable. One
difference: on Hamiltonian flows, the point call of a concatenation returns **one vector**
`[x; p]`, where a single flow returns the pair `(x, p)`
([CTFlows#439](https://github.com/control-toolbox/CTFlows.jl/issues/439)). Write
`zf = f(…)`, then `zf[1:n]` for the state and `zf[n+1:2n]` for the costate.

## Example: minimum time, bang–bang

Minimise $t_f$ for $\ddot q = u$, $u \in [-1, 1]$, from $(q, v) = (-1, 0)$ to $(0, 0)$.
With $p^0 = -1$, $H = p_1 v + p_2 u$ is maximised by $u = \operatorname{sign}(p_2)$. Here
$p_1$ is constant and $p_2 = p_2(0) - p_1 t$, so there is one switch, where $p_2$ vanishes.
By symmetry it happens at $t_f/2$, and the target gives $t_1 = 1$, $t_f = 2$. The
transversality condition $H(t_f) = 1$ for the Mayer cost $t_f$ (see
[Notation and conventions](@ref modelling-formulation-conventions)), at $u = -1$ and
$v(t_f) = 0$, gives $p_2(t_f) = -1$, so $p(0) = (1, 1)$.

```@example main
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    x(0) == [-1, 0]
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    tf → min
end

f_plus = Flow(ocp, (x, p, v) -> 1)
f_minus = Flow(ocp, (x, p, v) -> -1)

t1, tf = 1, 2
f_bb = f_plus * (t1, f_minus)
zf = f_bb(0, [-1, 0], [1, 1], tf; variable=tf)
xf, pf = zf[1:2], zf[3:4]
```

The concatenation reaches the target, with $p(t_f) = (1, -1)$.

```@example main
@assert isapprox(xf, [0, 0]; atol=1e-8) && isapprox(pf, [1, -1]; atol=1e-8)   # hide
nothing                                                                       # hide
```

## Example: off arc, then bang

This example comes from the v2.0.4 manual. Minimise the $L^1$ norm of the control,
$\int_0^1 |u|$, for $\dot x = -x + u$, $u \in [-1, 1]$, from $x(0) = -1$ to $x(1) = 0$:

```@example main
t0, tf1 = 0, 1
x0, xf1 = -1, 0

ocp_l1 = @def begin
    t ∈ [t0, tf1], time
    x ∈ R, state
    u ∈ R, control
    x(t0) == x0
    x(tf1) == xf1
    -1 ≤ u(t) ≤ 1
    ẋ(t) == -x(t) + u(t)
    ∫(abs(u(t))) → min
end
nothing # hide
```

With $p^0 = -1$, $H = p(-x + u) - |u|$ is maximised by $u = 0$ when $|p| < 1$, and by
$u = \operatorname{sign}(p)$ when $|p| > 1$. Since $\dot p = p$, $p(t) = p_0 e^t$: the
control is $u = 0$ (off arc) until $p$ reaches $1$, at $t_1 = -\ln p_0$, then $u = 1$
(bang arc). Integrating $\dot x = -x$ then $\dot x = -x + 1$ and asking $x(1) = 0$ gives

```math
p_0 = \frac{1}{x_0 - (x_f - 1)e^{t_f}}, \qquad t_1 = -\ln p_0 .
```

```@example main
p0 = 1 / (x0 - (xf1 - 1) * exp(tf1))
t1_l1 = -log(p0)

f_off = Flow(ocp_l1, (x, p) -> 0)    # off arc: u = 0
f_bang = Flow(ocp_l1, (x, p) -> 1)   # bang arc: u = 1

f_l1 = f_off * (t1_l1, f_bang)
sol_l1 = f_l1((t0, tf1), x0, p0)
state(sol_l1)(tf1), objective(sol_l1)
```

The flow reaches $x(1) = 0$, and its cost is the length of the bang arc, $t_f - t_1$:

```@example main
@assert abs(state(sol_l1)(tf1)) < 1e-8                         # hide
@assert isapprox(objective(sol_l1), tf1 - t1_l1; atol=1e-6)     # hide
nothing                                                          # hide
```

```@example main
plot(sol_l1)
```

## See also

- [Constrained arcs](@ref flows-constrained-arcs): arcs on the boundary of a state
  constraint, with costate jumps at the junctions.
- [Shooting](@ref flows-shooting): solve for the switching times and the initial costate,
  instead of taking them from the analysis as here.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time): the bang–bang example
  in full.
