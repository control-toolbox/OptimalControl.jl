# [Time minimisation (bang–bang)](@id examples-double-integrator-time)

```@raw html
<ExampleFacts id="double-integrator-time" />
```

The wagon of [Energy minimisation](@ref examples-double-integrator-energy) again, with a
bounded force this time, $|u| \le 1$: we transfer it from rest at $q = -1$ to rest at $q = 0$
**as fast as possible**. The dynamics are those of the double integrator,

```math
\dot q(t) = v(t), \quad \dot v(t) = u(t), \quad u(t) \in [-1, 1],
```

with the limit conditions $x(0) = (-1, 0)$ and $x(t_f) = (0, 0)$, where $x = (q, v)$ and the
final time $t_f$ is free.

We load OptimalControl and the packages that the direct and indirect methods need:

```@example main
using OptimalControl        # define the problem, solve it, build the flows
using NLPModelsIpopt        # NLP solver of the direct method
using OrdinaryDiffEqTsit5   # integrator of the flows
using NonlinearSolve        # solver of the shooting equations
using Plots                 # plots of the solutions
```

## The problem

The final time is a variable of the problem, and the cost:

:::tabs key:example-problem

== @def

```@example main
t0 = 0
x0, xf = [-1, 0], [0, 0]

ocp = @def begin
    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    tf → min
end
nothing # hide
```

== Mathematics

```math
\begin{aligned}
& \text{Minimise} && t_f \\[0.5em]
& \text{subject to} && \dot x(t) = (v(t), u(t)), \\[0.5em]
& && -1 \le u(t) \le 1, \\[0.5em]
& && x(0) = (-1, 0), \\[0.5em]
& && x(t_f) = (0, 0).
\end{aligned}
```

:::

## Direct method

We solve it by the [direct method](@ref solve-overview-direct-method), with 200 time steps:

```@example main
direct_sol = solve(ocp; grid_size=200, display=false)
variable(direct_sol)
```

```@example main
plt = plot(direct_sol; label="direct", size=(800, 920), legend=false)
```

The control is $+1$, then $-1$: the wagon accelerates as much as it can, then brakes as much
as it can.

## The exact solution

With the conventions of [Notation and conventions](@ref modelling-formulation-conventions),
the cost $t_f$ is a Mayer cost, so the pseudo-Hamiltonian is

```math
H(x, p, u) = p_1 v + p_2 u,
```

where $p = (p_1, p_2)$ is the costate. It is linear in $u$, and maximised by
$u = \operatorname{sign}(p_2)$: the control is **bang–bang**, and $p_2$ is the **switching
function**. Since $\dot p_1 = 0$ and $\dot p_2 = -p_1$, $p_2$ is affine, so it changes sign at
most once, at a time $t_1$, from $u = +1$ to $u = -1$.

On $[0, t_1]$, $v = t$ and $q = -1 + t^2/2$. On $[t_1, t_f]$, the wagon brakes, and stops at
$t_f = 2t_1$, at $q = -1 + t_1^2$. The target gives $t_1 = 1$ and $t_f = 2$.

The switching condition $p_2(t_1) = 0$ gives $p_2(0) = p_1$. For a free final time with a Mayer
cost, the transversality condition is $\mathbf{H}(t_f) = -p^0 = 1$ ($p^0 = -1$ in the normal
case), that is,
$p_2(t_f) \times (-1) = 1$, with $v(t_f) = 0$. Since $p_2(t_f) = p_2(0) - 2p_1 = -p_1$, we get
$p_1 = 1$:

```math
p(0) = (1, 1), \qquad t_1 = 1, \qquad t_f = 2.
```

## Indirect method

We solve it by [shooting](@ref flows-shooting), the indirect method. The two arcs have their
flows, with the control $+1$ and $-1$:

```@example main
f_max = Flow(ocp, (x, p, v) -> 1; label="u = +1")
f_min = Flow(ocp, (x, p, v) -> -1; label="u = -1")
nothing # hide
```

The shooting function has four unknowns, $p_0$, $t_1$ and $t_f$, and four conditions: the
target, the switch, and the transversality condition. The final time is a variable of the
problem, so it is passed to the flows when they are called, by the keyword `variable=tf`:

```@example main
H = hamiltonian(f_min)   # Hamiltonian of the last arc, H(x, p, tf)

function shoot!(s, ξ, _)
    p0, t1, tf = ξ[1:2], ξ[3], ξ[4]
    x1, p1 = f_max(t0, x0, p0, t1; variable=tf)
    x2, p2 = f_min(t1, x1, p1, tf; variable=tf)
    s[1:2] = x2 - xf             # target
    s[3] = p1[2]                 # switching function at t1
    s[4] = H(x2, p2, tf) - 1     # transversality, free final time
    return nothing
end
nothing # hide
```

The direct solution gives the initial guess: its costate at $t_0$, its final time, and the
switching time, where its switching function $p_2$ changes sign:

```@example main
tg = time_grid(direct_sol)
p_d = costate(direct_sol)

p0_guess = p_d(t0)
t1_guess = tg[findfirst(t -> p_d(t)[2] < 0, tg)]
tf_guess = variable(direct_sol)

ξ_guess = [p0_guess..., t1_guess, tf_guess]
```

We solve the shooting equations:

```@example main
prob = NonlinearProblem(shoot!, ξ_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, t1_sol, tf_sol = shooting_sol.u[1:2], shooting_sol.u[3], shooting_sol.u[4]
```

These are the exact values, $p_0 = (1, 1)$, $t_1 = 1$ and $t_f = 2$, and the residual is zero:

```@example main
s = zeros(4)
shoot!(s, shooting_sol.u, nothing)
s
```

```@example main
@assert isapprox(shooting_sol.u, [1, 1, 1, 2]; atol=1e-8) && maximum(abs, s) < 1e-8   # hide
@assert isapprox(t1_guess, 1; atol=2e-2) && isapprox(tf_guess, 2; atol=1e-3)          # hide
nothing                                                                               # hide
```

## Comparison

The concatenation of the two flows at $t_1$ gives the whole extremal (see
[Multi-phase flows](@ref flows-multi-phase)):

```@example main
φ = f_max * (t1_sol, f_min)
indirect_sol = φ((t0, tf_sol), x0, p0_sol; variable=tf_sol)
state(indirect_sol)(tf_sol)
```

```@example main
# switching_style=:none removes the vertical line drawn at the switching time t1
plot!(plt, indirect_sol; label="indirect", linestyle=:dash, switching_style=:none)
plot!(plt; subplot=1, legend=:best)   # one legend, on the first subplot
```

The two final times agree up to the discretisation error of the direct method:

```@example main
variable(direct_sol), tf_sol
```

## Notes

- [Shooting](@ref flows-shooting) explains the method on this problem: which unknown goes
  with which condition, `unsafe=true`, and how to check that a zero of the shooting function
  is an extremal.
- [MINPACK.jl](@extref Tutorials Resolution-of-the-shooting-equation) can replace
  NonlinearSolve to solve the shooting equations.
- The [Goddard tutorial](@extref Tutorials tutorial-goddard) uses the same steps on a problem
  with bang, singular and boundary arcs.

```@raw html
<ExampleNav id="double-integrator-time" />
```

```@example main
Main.gallery_thumbnail(plot(indirect_sol, :control; size=(480, 300), legend=false), "double-integrator-time")  # hide
nothing  # hide
```
