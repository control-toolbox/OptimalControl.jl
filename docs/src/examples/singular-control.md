# [Singular control](@id examples-singular-control)

For a control-affine system

```math
\dot q(t) = f_0(q(t)) + u(t)\, f_1(q(t)), \qquad u(t) \in [u_{\min}, u_{\max}],
```

the pseudo-Hamiltonian is $H = H_0 + u H_1$, where $H_i(q, p) = \langle p, f_i(q) \rangle$ are
the Hamiltonian lifts of the vector fields $f_0$ and $f_1$. The maximising control is given by
the sign of the **switching function** $H_1$. When $H_1$ vanishes on a time interval, the arc
is **singular**: the maximisation does not give the control, which is computed by
differentiating $H_1$ along the extremal.

This page computes a singular control by hand, then with the tools of
[Geometry](@ref geometry-overview), and checks it with the direct and the indirect methods.
For a simpler case, where the singular control follows from the optimality conditions without
brackets, see [Turnpike (bang–singular–bang)](@ref examples-turnpike).

```@example main
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5
using NonlinearSolve
using Plots
```

## The problem

A vehicle moves in the plane, in a drift field. Its state is $q = (x, y, \theta)$, where
$(x, y)$ is the position and $\theta$ the heading, and it turns at a bounded rate:

```math
\dot x(t) = \cos\theta(t), \quad \dot y(t) = \sin\theta(t) + x(t), \quad \dot\theta(t) = u(t),
\quad u(t) \in [-1, 1].
```

We look for the fastest transfer from the origin to the point $(1, 0)$, with free initial and
final headings:

```@example main
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    q = (x, y, θ) ∈ R³, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1
    -π / 2 ≤ θ(t) ≤ π / 2   # helps the direct method

    x(0) == 0
    y(0) == 0
    x(tf) == 1
    y(tf) == 0

    ∂(q)(t) == [cos(θ(t)), sin(θ(t)) + x(t), u(t)]

    tf → min
end
nothing # hide
```

The bound on $\theta$ keeps the direct method away from trajectories that turn the long way
round. It is not active at the solution, so the indirect method, which ignores it, finds the
same solution. The system is control-affine, with

```math
f_0(q) = \begin{pmatrix} \cos\theta \\ \sin\theta + x \\ 0 \end{pmatrix}, \qquad
f_1(q) = \begin{pmatrix} 0 \\ 0 \\ 1 \end{pmatrix}.
```

## Direct method

```@example main
direct_sol = solve(ocp; display=false)
variable(direct_sol)
```

```@example main
opt = (state_bounds_style=:none, control_bounds_style=:none)
plt = plot(direct_sol; label="direct", size=(800, 800), opt...)
```

The control stays strictly inside $[-1, 1]$: the arc is singular.

## The singular control by hand

With $p = (p_1, p_2, p_3)$ and the Mayer cost $t_f$ (see
[Notation and conventions](@ref modelling-formulation-conventions)), the pseudo-Hamiltonian is

```math
H(q, p, u) = p_1 \cos\theta + p_2 (\sin\theta + x) + p_3\, u = H_0 + u H_1,
\qquad H_0 = p_1 \cos\theta + p_2 (\sin\theta + x), \quad H_1 = p_3 .
```

On a singular arc, $H_1 = 0$, and so are its time derivatives. Along an extremal, the time
derivative of a function $G(q, p)$ is $\{H, G\}$, a Poisson bracket (see
[Time derivative along an extremal](@ref geometry-poisson-total)), with
$\{F, G\} = \nabla_p F \cdot \nabla_q G - \nabla_q F \cdot \nabla_p G$.

**First derivative.** Since $\{H_1, H_1\} = 0$,

```math
\dot H_1 = \{H_0 + u H_1, H_1\} = \{H_0, H_1\} =: H_{01}.
```

$H_1 = p_3$ depends only on $p_3$, so only the pair $(\theta, p_3)$ contributes:

```math
H_{01} = -\frac{\partial H_0}{\partial \theta} \frac{\partial H_1}{\partial p_3}
= p_1 \sin\theta - p_2 \cos\theta .
```

On the singular arc, $H_{01} = 0$, that is, $p_1 \sin\theta = p_2 \cos\theta$.

**Second derivative.**

```math
\dot H_{01} = \{H_0, H_{01}\} + u \{H_1, H_{01}\} =: H_{001} + u H_{101},
```

and it vanishes on the arc, so wherever $H_{101} \neq 0$,

```math
u_s = -\frac{H_{001}}{H_{101}} .
```

In $H_{001} = \{H_0, H_{01}\}$, only the pair $(x, p_1)$ contributes:
$H_{001} = -\frac{\partial H_0}{\partial x} \frac{\partial H_{01}}{\partial p_1} = -p_2 \sin\theta$.
In $H_{101} = \{H_1, H_{01}\}$, only the pair $(\theta, p_3)$ contributes:
$H_{101} = \frac{\partial H_1}{\partial p_3} \frac{\partial H_{01}}{\partial \theta} = p_1 \cos\theta + p_2 \sin\theta$.
Therefore

```math
u_s = \frac{p_2 \sin\theta}{p_1 \cos\theta + p_2 \sin\theta} .
```

!!! note "The denominator does not vanish"

    If $H_{101} = p_1 \cos\theta + p_2 \sin\theta$ were zero on the arc, then with
    $H_{01} = 0$,

    ```math
    \begin{pmatrix} \cos\theta & \sin\theta \\ \sin\theta & -\cos\theta \end{pmatrix}
    \begin{pmatrix} p_1 \\ p_2 \end{pmatrix} = \begin{pmatrix} 0 \\ 0 \end{pmatrix}.
    ```

    This matrix has determinant $-1$, so $p_1 = p_2 = 0$, and with $p_3 = 0$, $p = 0$. Then
    $H = 0$, which is impossible: for a minimum-time problem, $H = 1$ along the extremal.

**Simplification.** Multiply the numerator and the denominator by $\sin\theta$, and use
$p_1 \sin\theta = p_2 \cos\theta$ in the denominator:

```math
u_s = \frac{p_2 \sin^2\theta}{p_2 \cos^2\theta + p_2 \sin^2\theta} = \sin^2\theta .
```

The singular control depends on the heading only. Along the direct solution, it matches the
control:

```@example main
tg = time_grid(direct_sol)
θ(t) = state(direct_sol)(t)[3]
plt_u = plot(direct_sol, :control; label="direct", size=(800, 300), opt...)
plot!(plt_u, tg, t -> sin(θ(t))^2; label="sin²θ", linestyle=:dash)
```

## The singular control with brackets

The tools of [Geometry](@ref geometry-overview) compute the same brackets from the vector
fields: their lifts, then the iterated Poisson brackets with [`@Lie`](@ref geometry-lie-macro):

```@example main
F0(q) = [cos(q[3]), sin(q[3]) + q[1], 0]
F1(q) = [0, 0, 1]

H0 = Lift(F0)
H1 = Lift(F1)

H01 = @Lie {H0, H1}
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}

us_bracket(q, p) = -H001(q, p) / H101(q, p)
nothing # hide
```

At a point where $H_1 = H_{01} = 0$, that is, $p_3 = 0$ and $p_2 = p_1 \tan\theta$, the formula
gives $\sin^2\theta$:

```@example main
q_s = [0.3, -0.1, 0.5]
p_s = [1.7, 1.7 * tan(q_s[3]), 0]
us_bracket(q_s, p_s), sin(q_s[3])^2
```

```@example main
@assert isapprox(us_bracket(q_s, p_s), sin(q_s[3])^2; atol=1e-12)   # hide
nothing                                                            # hide
```

## Indirect method

Here the whole extremal is singular: the headings are free at both ends, so the
transversality conditions give $p_3(0) = p_3(t_f) = 0$, and $H_1 = p_3$ vanishes on the whole
interval. The flow uses the singular control over the whole horizon:

```@example main
u_s(q) = sin(q[3])^2
f = Flow(ocp, (q, p, tf) -> u_s(q))
nothing # hide
```

There are five unknowns, $p_0 \in \mathbb{R}^3$, the initial heading $\theta_0$ and the final
time $t_f$, and five conditions: the target (two equations), the transversality conditions of
the headings, and the transversality condition of the final time, $H(t_f) = 1$, where
$H(t_f) = H_0(t_f)$ since $p_3(t_f) = 0$:

```@example main
t0 = 0

function shoot!(s, ξ, _)
    p0, θ0, tf = ξ[1:3], ξ[4], ξ[5]
    q_tf, p_tf = f(t0, [0, 0, θ0], p0, tf; variable=tf)
    s[1] = q_tf[1] - 1               # x(tf) = 1
    s[2] = q_tf[2]                   # y(tf) = 0
    s[3] = p0[3]                     # free initial heading
    s[4] = p_tf[3]                   # free final heading
    s[5] = H0(q_tf, p_tf) - 1        # free final time
    return nothing
end
nothing # hide
```

The direct solution gives the initial guess:

```@example main
ξ_guess = [costate(direct_sol)(t0)..., state(direct_sol)(t0)[3], variable(direct_sol)]
prob = NonlinearProblem(shoot!, ξ_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(false))
p0_sol, θ0_sol, tf_sol = shooting_sol.u[1:3], shooting_sol.u[4], shooting_sol.u[5]
```

The residual is zero:

```@example main
s = zeros(5)
shoot!(s, shooting_sol.u, nothing)
s
```

## Comparison

The two methods find the same final time, up to the discretisation error of the direct
method:

```@example main
indirect_sol = f((t0, tf_sol), [0, 0, θ0_sol], p0_sol; variable=tf_sol)
variable(direct_sol), tf_sol
```

For the plot, the flow is built with `saveat`, so that the trajectory has 101 points (see
[Plotting a flow](@ref results-plot-flow)):

```@example main
f_plot = Flow(ocp, (q, p, tf) -> u_s(q); saveat=range(t0, tf_sol, 101), dense=false)
plot!(plt, f_plot((t0, tf_sol), [0, 0, θ0_sol], p0_sol; variable=tf_sol);
      label="indirect", linestyle=:dash, opt...)
```

Along the extremal, the switching function $H_1 = p_3$ stays zero, $\theta$ stays inside
$(-\pi/2, \pi/2)$, and the control computed with the brackets is $\sin^2\theta$:

```@example main
qs, ps = state(indirect_sol), costate(indirect_sol)
ts = range(t0, tf_sol, 5)
[(ps(t)[3], us_bracket(qs(t), ps(t)) - u_s(qs(t))) for t in ts]
```

```@example main
@assert maximum(abs, s) < 1e-8                                                        # hide
@assert isapprox(variable(direct_sol), tf_sol; rtol=1e-3)                            # hide
@assert all(abs(ps(t)[3]) < 1e-6 for t in range(t0, tf_sol, 21))                      # hide
@assert all(abs(us_bracket(qs(t), ps(t)) - u_s(qs(t))) < 1e-6 for t in range(t0, tf_sol, 21))   # hide
@assert all(abs(qs(t)[3]) < π / 2 - 0.1 for t in range(t0, tf_sol, 21))               # hide
nothing                                                                               # hide
```

## See also

- [Poisson bracket](@ref geometry-poisson): the brackets and the singular-control formula, in
  general.
- [The `@Lie` macro](@ref geometry-lie-macro): the bracket notation used above.
- [Lift](@ref geometry-lift): the Hamiltonian lift of a vector field.
- [Shooting](@ref flows-shooting): the shooting method.
- The [Goddard tutorial](@extref Tutorials tutorial-goddard): a problem with bang, singular
  and boundary arcs.
