# [Shooting](@id flows-shooting)

The maximum principle gives the extremals, but not the initial costate, the switching times
or a free final time. **Shooting** finds them: write the conditions the extremal must satisfy
as equations in these unknowns, integrate the flows to evaluate them, and solve the equations
with a nonlinear solver. The direct method gives the starting point.

This page is about the method. The example
[Time minimisation (bang–bang)](@ref examples-double-integrator-time) tells the whole story of
the problem used here, from the derivation of the exact solution to the comparison of the
direct and indirect solutions.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NonlinearSolve
using NLPModelsIpopt
nothing # hide
```

## Unknowns and conditions

A shooting function has as many unknowns as conditions. Each unknown comes with the condition
that fixes it:

| Unknown | Condition |
| :--- | :--- |
| initial costate $p_0$ | the final conditions on the state, and the transversality conditions on the costate for the components the problem leaves free |
| a switching time $t_i$ | the switching function vanishes at $t_i$ |
| the entry and exit times of a boundary arc | the junction conditions (see [Constrained arcs](@ref flows-constrained-arcs)) |
| a free final time $t_f$ | the transversality condition on the maximised Hamiltonian at $t_f$ |
| a variable that enters the dynamics or the cost | its transversality condition, on the costate of the variable (see [From an OCP](@ref flows-from-ocp-variable-costate)) |

The structure of the extremal, the sequence of its arcs, is not an unknown: it is chosen
first, from the maximum principle or from a direct solution, and the shooting function is
written for it.

## The shooting function

The problem of this page is the minimum-time transfer of the double integrator, whose extremal
is $u = +1$ then $u = -1$:

::: details The problem, and its two arcs

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
    x(0) == x0
    x(tf) == xf
    ẋ(t) == [v(t), u(t)]
    tf → min
end

f_max = Flow(ocp, (x, p, v) -> 1; label="u = +1")
f_min = Flow(ocp, (x, p, v) -> -1; label="u = -1")
nothing # hide
```

:::

With $p^0 = -1$ and the Mayer cost $t_f$, the pseudo-Hamiltonian is $H = p_1 v + p_2 u$,
maximised by $u = \operatorname{sign}(p_2)$: the switching function is $p_2$. There are four
unknowns, $p_0 \in \mathbb{R}^2$, $t_1$ and $t_f$, and four conditions:

- the target, $x(t_f) = (0, 0)$ (two equations);
- the switch, $p_2(t_1) = 0$;
- the transversality condition of the free final time: for the Mayer cost $t_f$, the
  maximised Hamiltonian equals $-p^0 = 1$ at $t_f$ (see
  [Notation and conventions](@ref modelling-formulation-conventions)).

The pseudo-Hamiltonian is not written again: it is built from the problem (see
[Hamiltonians of a problem](@ref modelling-hamiltonians)). The problem has a variable, $t_f$,
so its natural call is `H(x, p, u, tf)`. The shooting function integrates the two arcs and
returns the four residuals. It is written in place, as `NonlinearSolve` expects:

```@example main
H = pseudo_hamiltonian(ocp)   # H(x, p, u, tf) = p₁v + p₂u

function shoot!(s, ξ, _)
    p0, t1, tf = ξ[1:2], ξ[3], ξ[4]
    x1, p1 = f_max(t0, x0, p0, t1; variable=tf, unsafe=true)
    x2, p2 = f_min(t1, x1, p1, tf; variable=tf, unsafe=true)
    s[1:2] = x2 - xf             # target
    s[3] = p1[2]                 # switching function at t1
    s[4] = H(x2, p2, -1, tf) - 1 # transversality, free final time
    return nothing
end
nothing # hide
```

## `unsafe=true`

While it searches, a nonlinear solver tries unknowns that are far from the solution, and the
integration can fail on them. By default a flow then raises an error, which would stop the
search. With `unsafe=true`, the flow returns what the integrator computed instead, and the
residual is just large. On $\dot x = x^2$, which blows up before $t = 1$ from $x(0) = 10$:

```@repl main
f_blowup = Flow(VectorField(x -> x^2));
Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do # hide
f_blowup(0, 10.0, 1)
end # hide
```

```@repl main
f_blowup(0, 10.0, 1; unsafe=true)
```

This is why `shoot!` above calls the flows with `unsafe=true`.

## Where the initial guess comes from

A shooting method converges from a good initial guess, and the direct method provides one:

- the initial costate is the costate of the direct solution at the initial time,
  `costate(sol)(t0)`: it is accurate to the step of the grid, which is enough for the
  shooting to converge;
- a switching time is where the switching function, evaluated on the costate of the direct
  solution, changes sign;
- the final time, and the other variables, are `variable(sol)`.

```@example main
sol_d = solve(ocp; display=false)

p_d = costate(sol_d)
tg = time_grid(sol_d)

p0_guess = p_d(t0)
t1_guess = tg[findfirst(t -> p_d(t)[2] < 0, tg)]
tf_guess = variable(sol_d)

ξ_guess = [p0_guess; t1_guess; tf_guess]
```

Other sources are a previous shooting solution, on a nearby problem
([discrete continuation](@extref Tutorials tutorial-continuation)), or values computed by hand
on a simpler problem.

## Solving the shooting equations

```@repl main
prob = NonlinearProblem(shoot!, ξ_guess);
sol = NonlinearSolve.solve(prob, SimpleNewtonRaphson(); abstol=1e-10, reltol=1e-10);
sol.retcode
p0_s, t1_s, tf_s = sol.u[1:2], sol.u[3], sol.u[4]
```

Newton's method differentiates the shooting function with `ForwardDiff`, through the flows and
the switching time $t_1$, which is an unknown: its Jacobian is exact, with respect to the
switching times and the final time as with respect to the initial costate.

```@example main
using ForwardDiff: ForwardDiff                                                          # hide
J = ForwardDiff.jacobian((s, ξ) -> shoot!(s, ξ, nothing), zeros(4), ξ_guess)            # hide
h = 1e-6                                                                                # hide
fd = map(1:4) do j                                                                      # hide
    e = zeros(4); e[j] = h                                                              # hide
    sp, sm = zeros(4), zeros(4)                                                         # hide
    shoot!(sp, ξ_guess + e, nothing); shoot!(sm, ξ_guess - e, nothing)                  # hide
    (sp - sm) / 2h                                                                      # hide
end                                                                                     # hide
@assert isapprox(J, reduce(hcat, fd); atol=1e-5)                                        # hide
nothing                                                                                 # hide
```

## Checking the solution

A zero of the shooting function satisfies the conditions that were written, and nothing
else. A few checks make sure it is an extremal of the problem.

**The residuals vanish.**

```@repl main
s = zeros(4);
shoot!(s, sol.u, nothing)
s
```

**The concatenation of the arcs reaches the target.** The point call of a concatenation
returns the pair `(x, p)` (see [Multi-phase flows](@ref flows-multi-phase)):

```@repl main
f_bb = f_max * (t1_s, f_min);
xf_s, pf_s = f_bb(t0, x0, p0_s, tf_s; variable=tf_s);
xf_s
```

**The control maximises the Hamiltonian on each arc.** The shooting function only asks the
switching function to vanish at $t_1$. The maximisation condition also asks it to have the
sign of the control on each arc, $p_2 > 0$ where $u = +1$ and $p_2 < 0$ where $u = -1$:

```@repl main
extremal = f_bb((t0, tf_s), x0, p0_s; variable=tf_s);
p₂(t) = costate(extremal)(t)[2];
minimum(p₂, range(t0, t1_s; length=100)[1:(end - 1)])
maximum(p₂, range(t1_s, tf_s; length=100)[2:end])
```

**The direct and indirect costs agree.** The final time is the cost, so the indirect and the direct solutions agree when their
final times do:

```@repl main
tf_s
objective(sol_d)
```

```@example main
@assert string(sol.retcode) == "Success"                                       # hide
@assert isapprox(sol.u, [1, 1, 1, 2]; atol=1e-8) && maximum(abs, s) < 1e-10   # hide
@assert isapprox(xf_s, xf; atol=1e-8)                                          # hide
@assert minimum(p₂, range(t0, t1_s; length=100)[1:(end - 1)]) > 0               # hide
@assert maximum(p₂, range(t1_s, tf_s; length=100)[2:end]) < 0                   # hide
@assert isapprox(objective(sol_d), tf_s; atol=1e-6)                            # hide
nothing                                                                        # hide
```

The solver finds $p_0 = (1, 1)$, $t_1 = 1$ and $t_f = 2$, the exact values derived in
[Time minimisation (bang–bang)](@ref examples-double-integrator-time).

## Going further

The [examples](@ref examples-gallery) shoot on other structures, for instance
[Turnpike (bang–singular–bang)](@ref examples-turnpike), with two switching times around a
singular arc, and [State constraint](@ref examples-state-constraint), with a boundary arc.

## See also

- [From an OCP](@ref flows-from-ocp): the flows a shooting function is made of.
- [Multi-phase flows](@ref flows-multi-phase): concatenations of arcs.
- [Solve overview](@ref solve-overview): the direct method used for the initial guess.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time): this example in
  full.
