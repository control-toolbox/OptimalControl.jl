# [Shooting](@id flows-shooting)

The maximum principle gives the extremals, but not the initial costate, the switching times
or a free final time. **Shooting** finds them: write the conditions the extremal must satisfy
as equations in these unknowns, integrate the flows to evaluate them, and solve the equations
with a nonlinear solver. The direct method gives the starting point.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NonlinearSolve
using NLPModelsIpopt
nothing # hide
```

## The problem

We take the minimum-time transfer of the double integrator: minimise $t_f$ for
$\ddot q = u$, $u \in [-1, 1]$, from $(q, v) = (-1, 0)$ to $(0, 0)$:

```@example main
t0 = 0
x0 = [-1, 0]
xf = [0, 0]

ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    x(0) == x0, (start)
    x(tf) == xf
    ẋ(t) == [v(t), u(t)]
    tf → min
end
nothing # hide
```

With $p^0 = -1$ and the Mayer cost $t_f$, the pseudo-Hamiltonian is
$H = p_1 v + p_2 u$, maximised by $u = \operatorname{sign}(p_2)$: the **switching function**
is $p_2$. As on [Multi-phase flows](@ref flows-multi-phase), the solution is $u = +1$ then
$u = -1$, with $p_0 = (1, 1)$, $t_1 = 1$ and $t_f = 2$. Shooting will find these values.

```@example main
f_max = Flow(ocp, (x, p, v) -> 1)
f_min = Flow(ocp, (x, p, v) -> -1)
nothing # hide
```

## The shooting function

There are four unknowns, $p_0 \in \mathbb{R}^2$, $t_1$ and $t_f$, and four conditions:

- the target, $x(t_f) = (0, 0)$ (two equations);
- the switch: the switching function vanishes at $t_1$, $p_2(t_1) = 0$;
- the transversality condition of the free final time: for the Mayer cost $t_f$, the
  maximised Hamiltonian equals $-p^0 = 1$ at $t_f$, that is
  $p(t_f) \cdot f(x(t_f), u(t_f)) = 1$ (see
  [Notation and conventions](@ref modelling-formulation-conventions)).

The shooting function integrates the two arcs and returns the four residuals. It is written in
place, as `NonlinearSolve` expects:

```@example main
H(x, p, u) = p[1] * x[2] + p[2] * u   # p ⋅ f(x, u)

function shoot!(s, ξ, _)
    p0, t1, tf = ξ[1:2], ξ[3], ξ[4]
    x1, p1 = f_max(t0, x0, p0, t1; variable=tf, unsafe=true)
    x2, p2 = f_min(t1, x1, p1, tf; variable=tf, unsafe=true)
    s[1:2] = x2 - xf             # target
    s[3] = p1[2]                 # switching function at t1
    s[4] = H(x2, p2, -1) - 1     # transversality, free final time
    return nothing
end
nothing # hide
```

At the solution, the residuals vanish:

```@example main
s = zeros(4)
shoot!(s, [1, 1, 1, 2], nothing)
s
```

```@example main
@assert maximum(abs, s) < 1e-10   # hide
nothing                           # hide
```

## `unsafe=true`

While it searches, a nonlinear solver tries unknowns that are far from the solution, and the
integration can fail on them. By default a flow then raises an error, which would stop the
search. With `unsafe=true`, the flow returns what the integrator computed instead, and the
residual is just large. On $\dot x = x^2$, which blows up before $t = 1$ from $x(0) = 10$:

```@repl main
f_blowup = Flow(VectorField(x -> x^2));
try # hide
Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do # hide
f_blowup(0, 10.0, 1)
end # hide
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@example main
f_blowup(0, 10.0, 1; unsafe=true)
```

This is why `shoot!` above calls the flows with `unsafe=true`.

## Starting from the direct solution

A shooting method converges from a good initial guess. The direct method provides one:

- the initial costate is the multiplier of the initial condition, `dual(sol, ocp, :start)`
  (more accurate than `costate(sol)(0)`, see
  [Solution object](@ref results-solution-duals));
- the switching time is read off the control, where it changes sign;
- the final time is the variable.

```@example main
sol_d = solve(ocp; display=false)

p0_guess = dual(sol_d, ocp, :start)
tg = time_grid(sol_d)
t1_guess = tg[findfirst(t -> control(sol_d)(t) < 0, tg)]
tf_guess = variable(sol_d)

ξ_guess = [p0_guess; t1_guess; tf_guess]
```

## Solving the shooting equations

```@example main
prob = NonlinearProblem(shoot!, ξ_guess)
sol = NonlinearSolve.solve(prob, SimpleNewtonRaphson(); abstol=1e-10, reltol=1e-10)
sol.u, sol.retcode
```

The solver finds $p_0 = (1, 1)$, $t_1 = 1$ and $t_f = 2$.

```@example main
@assert string(sol.retcode) == "Success"                        # hide
@assert isapprox(sol.u, [1, 1, 1, 2]; atol=1e-8)                # hide
nothing                                                         # hide
```

## Checking the solution

The two arcs, concatenated at the switching time found, reach the target. The point call of
a concatenation returns `[x; p]` (see [Multi-phase flows](@ref flows-multi-phase)):

```@example main
p0_s, t1_s, tf_s = sol.u[1:2], sol.u[3], sol.u[4]

f_bb = f_max * (t1_s, f_min)
zf = f_bb(t0, x0, p0_s, tf_s; variable=tf_s)
zf[1:2]
```

The final time is the cost, so the indirect and the direct solutions agree when their final
times do:

```@example main
tf_s, objective(sol_d)
```

```@example main
@assert isapprox(zf[1:2], xf; atol=1e-8) && isapprox(objective(sol_d), tf_s; atol=1e-6)   # hide
nothing                                                                                   # hide
```

## More switches, other unknowns

Each additional switch adds an unknown time and a switching condition; a boundary arc adds
its entry and exit times, with the junction conditions (see
[Constrained arcs](@ref flows-constrained-arcs)). When the variable enters the dynamics or
the cost, its transversality condition uses the costate of the variable, computed with
`variable_costate=true` (see [From an OCP](@ref flows-from-ocp-variable-costate)). The
[examples](@ref examples-gallery) solve several such problems, for instance
[Turnpike (bang–singular–bang)](@ref examples-turnpike), with two switching times around a singular arc.

## See also

- [From an OCP](@ref flows-from-ocp): the flows a shooting function is made of.
- [Multi-phase flows](@ref flows-multi-phase): concatenations of arcs.
- [Solve overview](@ref solve-overview): the direct method used for the initial guess.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time): this example in
  full.
