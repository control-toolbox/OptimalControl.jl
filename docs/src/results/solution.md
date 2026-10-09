# [Solution object](@id results-solution)

This page is about what you do once a problem has been solved: print the solution, plot
it, read its trajectories and its objective, check that the solver converged, and read the
Lagrange multipliers. It mirrors [Inspect a problem](@ref modelling-inspect): that page reads
a *model* back, this one reads a *solution* back.

## A solution to read

We take the energy-minimal double integrator, whose solution is known in closed form:
u(t) = 6 − 12t, q(t) = −1 + 3t² − 2t³, v(t) = 6t − 6t², and the cost is J = 6 (see
[First problem](@ref getting-started-first-problem)).

```@example main
using OptimalControl
using NLPModelsIpopt

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end

sol = solve(ocp; display=false)
nothing # hide
```

A solution prints as a summary:

```@example main
sol
```

and plots in one line, once a plotting package is loaded (see
[Plot a solution](@ref results-plot)):

```@example main
using Plots
plot(sol)
```

## The `Solution` type

`solve` returns an `OptimalControl.Solution`. The type is not exported: you read a solution
through the functions below, never through its fields. They return functions of time where
the fields store values on a grid, and they apply the conventions of the rest of the site,
such as "1-D is a scalar". Every function on this page is listed with its signature in the
[API reference](@ref api-solution).

## [Trajectories](@id results-solution-trajectories)

`state`, `control` and `costate` return **functions of time**:

```@example main
x = state(sol)
u = control(sol)
p = costate(sol)
x(0.25), u(0.25), p(0.25)
```

The closed form gives x(0.25) = (−0.84375, 1.125), u(0.25) = 3 and p₁ = 12.

```@example main
@assert isapprox(x(0.25), [-0.84375, 1.125]; atol=1e-3)   # hide
@assert isapprox(u(0.25), 3; atol=1e-3)                    # hide
@assert isapprox(p(0.25)[1], 12; atol=1e-2)                # hide
nothing                                                    # hide
```

These functions interpolate: they can be called anywhere in the time horizon, not only at the
grid points. `time_grid(sol)` returns the grid (`times(sol)` is the same vector), 251 points
here since the default `grid_size` is 250 steps:

```@example main
length(time_grid(sol)), 0.25 ∈ time_grid(sol)
```

```@example main
@assert times(sol) == time_grid(sol)       # hide
@assert length(time_grid(sol)) == 251      # hide
nothing                                    # hide
```

**1-D is a scalar here too**: with a 1-D control, `u(t)` is a `Number`, not a length-1
vector, as everywhere else on the site ([functional-API callbacks](@ref modelling-functional-api-shapes),
[abstract syntax](@ref modelling-abstract-syntax-control)):

```@example main
typeof(u(0.25))
```

`variable(sol)` is a value, not a function of time: a `Float64` for a 1-D variable, a vector
otherwise, and an empty vector when the problem has no variable, as here:

```@example main
variable(sol)
```

!!! note "The costate is shifted by half a step"

    The costate of a direct solve is the multiplier of the discretised dynamics: with the
    default `:midpoint` scheme, there is one per step, and it approximates p at the
    *middle* of the step. So `p(t)` is close to the exact costate at t + h/2, with h the
    step. Here p₂(t) = 6 − 12t, h = 0.004, and p₂(0.25) is 6 − 12 × 0.252 = 2.976, not 3:

    ```@example main
    p(0.25)[2]
    ```

    The difference vanishes as the grid is refined. With the Gauss–Legendre schemes, the
    shift is a full step: `p(t)` is close to the exact costate at t + h
    ([CTDirect#640](https://github.com/control-toolbox/CTDirect.jl/issues/640)). For an
    accurate initial costate, for instance to start a [shooting method](@ref flows-shooting),
    the multiplier of the initial condition is better: see
    [Dual variables](@ref results-solution-duals).

```@example main
@assert isapprox(p(0.25)[2], 6 - 12 * (0.25 + 0.002); atol=1e-3)   # hide
nothing                                                            # hide
```

| Function | Returns |
| --- | --- |
| `state(sol)` | x(t), a function of time |
| `control(sol)` | u(t), a function of time |
| `costate(sol)` | p(t), a function of time |
| `variable(sol)` | the optimisation variable: a number, a vector, or an empty vector |
| `time_grid(sol)`, `times(sol)` | the discretisation grid, a vector |

## The time horizon

`initial_time` and `final_time` read the endpoints back. On a fixed-time problem they give
what you wrote in the `@def`:

```@example main
initial_time(sol), final_time(sol)
```

When a time is an optimisation variable, its value is not in the model: the model only
records *which* component of the variable holds it. The accessor reads that component of the
solution's variable for you. The second problem of this page is a minimum-time transfer, with
the control in [−1, 1] and the speed capped at 0.75. Its labels are used in
[Dual variables](@ref results-solution-duals) below.

```@example main
ocp_free = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0, (tf_pos)
    -1 ≤ u(t) ≤ 1, (u_box)
    v(t) ≤ 0.75, (v_max)
    x(0) == [-1, 0], (start)
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol_free = solve(ocp_free; display=false)

initial_time(sol_free), final_time(sol_free)
```

The optimal control accelerates at u = 1 until the speed reaches 0.75 (t = 0.75), coasts at
that speed, then brakes at u = −1 for 0.75 time units. Accelerating and braking each cover
0.75²/2 = 0.28125 of the unit distance, which leaves 0.4375 to coast, in 0.4375/0.75 = 7/12. So
t_f = 0.75 + 7/12 + 0.75 = 25/12 ≈ 2.0833. The final time is also the variable, here a number:

```@example main
variable(sol_free)
```

```@example main
@assert isapprox(final_time(sol_free), 25 / 12; atol=1e-4)    # hide
@assert variable(sol_free) == final_time(sol_free)            # hide
@assert variable(sol_free) isa Float64                        # hide
nothing                                                       # hide
```

## The objective

```@example main
objective(sol)
```

The closed form gives J = 6. On the minimum-time problem, the objective is the final time.

```@example main
@assert isapprox(objective(sol), 6; atol=1e-3)                          # hide
@assert isapprox(objective(sol_free), final_time(sol_free); atol=1e-8)  # hide
nothing                                                                 # hide
```

## Did it converge

`successful` says whether the solver reported success. `status` and `message` give its
verdict, `iterations` and `constraints_violation` two figures to judge it by:

```@example main
successful(sol), status(sol), message(sol)
```

```@example main
iterations(sol), constraints_violation(sol)
```

`infos(sol)` returns a `Dict` of anything else the solver reported (empty with Ipopt).

```@example main
@assert successful(sol) && successful(sol_free)   # hide
@assert status(sol) == :first_order               # hide
nothing                                           # hide
```

!!! warning "`success` is not `successful`"

    `success` is a Julia function, about the exit status of a process. Calling it on a
    solution raises an error that points to `successful`:

    ```@repl main
    try # hide
    success(sol)
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

    See [Migration](@ref migration) for every renamed function.

What to do when a solve fails (a better initial guess, a finer grid, other tolerances) is the
subject of [Initial guess](@ref solve-initial-guess) and [Options](@ref solve-options).

| Function | Returns |
| --- | --- |
| `objective(sol)` | the value of the cost |
| `successful(sol)` | `true` if the solver reported success |
| `status(sol)` | the solver's status, a `Symbol` such as `:first_order` |
| `message(sol)` | the solver's message, a `String` |
| `iterations(sol)` | the number of iterations |
| `constraints_violation(sol)` | the largest constraint violation |
| `infos(sol)` | a `Dict` of anything else the solver reported |

## [Dual variables](@id results-solution-duals)

The Lagrange multipliers of the constraints measure how much the cost would change if a
constraint were relaxed. A constraint with a [label](@ref modelling-abstract-syntax) is read
with `dual(sol, ocp, :label)`. For a boundary or a variable constraint, the multiplier is a
number or a vector:

```@example main
dual(sol_free, ocp_free, :tf_pos)
```

The constraint t_f ≥ 0 is inactive, so its multiplier is zero.

```@example main
dual(sol_free, ocp_free, :start)
```

The multiplier of the initial condition x(0) = x₀ is the initial costate p(t₀). Here the
costate is p(t) = (4/3, 1 − 4t/3) on the first arc, so p(0) = (4/3, 1). This is a more
accurate value than `costate(sol)(0)`, which is shifted by half a step (see
[Trajectories](@ref results-solution-trajectories)).

```@example main
@assert isapprox(dual(sol_free, ocp_free, :tf_pos), 0; atol=1e-8)       # hide
@assert isapprox(dual(sol_free, ocp_free, :start), [4/3, 1]; atol=1e-2)  # hide
nothing                                                                  # hide
```

For a path constraint, the multiplier is a function of time. It is nonzero only where the
constraint is active: the control bound while u = ±1, the speed bound while coasting.

```@example main
μ_u = dual(sol_free, ocp_free, :u_box)
μ_v = dual(sol_free, ocp_free, :v_max)
[(t, μ_u(t), μ_v(t)) for t in (0.3, 1.0, 1.8)]
```

```@example main
plot(time_grid(sol_free), [μ_u, μ_v]; label=["μ_u" "μ_v"], xlabel="t")
```

```@example main
@assert μ_u(0.3) < -1e-3 && μ_u(1.8) > 1e-3 && abs(μ_u(1.0)) < 1e-6   # hide
@assert μ_v(1.0) < -1e-3 && abs(μ_v(0.3)) < 1e-6                       # hide
nothing                                                                # hide
```

!!! note "Sign and scale of the multipliers"

    For a box constraint, on a state, control or variable component, the solver returns
    separate non-negative multipliers for the lower and the upper bound. `dual` returns
    their difference μ = μ_lb − μ_ub: μ > 0 where the lower bound is active, μ < 0 where
    the upper bound is active, μ = 0 where the constraint is inactive. Above, u = 1 on
    the first arc, so μ_u < 0, and u = −1 on the last one, so μ_u > 0.

    The multipliers of the **path constraints**, those that are not boxes (such as
    `v(t) + u(t) ≤ 1`), differ in two ways
    ([CTDirect#639](https://github.com/control-toolbox/CTDirect.jl/issues/639)):

    - they keep the solver's sign, which is the opposite: positive where the upper bound is
      active;
    - they are divided by the time step, whereas the multipliers of box constraints are not.
      So box multipliers are of the order of the step, and decrease when the grid is
      refined.

    With `:exa`, the multipliers of the path and boundary constraints are not
    available yet, and come back as zeros
    ([CTDirect#405](https://github.com/control-toolbox/CTDirect.jl/issues/405)).

The box multipliers can also be read per group, without a label: one function for the lower
bounds and one for the upper bounds, for the state, the control and the variable. For the
state and the control, they are functions of time, with one entry per component:

```@example main
state_constraints_lb_dual(sol_free)(1.0), state_constraints_ub_dual(sol_free)(1.0)
```

```@example main
control_constraints_lb_dual(sol_free)(1.8), control_constraints_ub_dual(sol_free)(1.8)
```

For the variable, they are values:

```@example main
variable_constraints_lb_dual(sol_free), variable_constraints_ub_dual(sol_free)
```

The multipliers of the path constraints (boxes excluded) and of the boundary constraints,
together:
`path_constraints_dual(sol)` is a function of time, `boundary_constraints_dual(sol)` a vector,
here with the 4 boundary conditions of `ocp_free` (x(0) = x₀ counts for two).

```@example main
boundary_constraints_dual(sol_free)
```

```@example main
@assert boundary_constraints_dual(sol_free)[1:2] ≈ dual(sol_free, ocp_free, :start)   # hide
@assert dim_boundary_constraints_nl(sol_free) == 4                                     # hide
@assert dim_path_constraints_nl(sol_free) == 0                                         # hide
@assert dim_dual_state_constraints_box(sol_free) == 2                                  # hide
nothing                                                                                # hide
```

| Function | Returns |
| --- | --- |
| `dual(sol, ocp, :label)` | the multiplier of a labelled constraint: a number, a vector, or a function of time |
| `state_constraints_lb_dual(sol)`, `state_constraints_ub_dual(sol)` | the state box multipliers, functions of time |
| `control_constraints_lb_dual(sol)`, `control_constraints_ub_dual(sol)` | the control box multipliers, functions of time |
| `variable_constraints_lb_dual(sol)`, `variable_constraints_ub_dual(sol)` | the variable box multipliers |
| `path_constraints_dual(sol)` | the path multipliers, boxes excluded, a function of time |
| `boundary_constraints_dual(sol)` | the boundary multipliers, a vector |
| `dim_dual_state_constraints_box(sol)`, `dim_dual_control_constraints_box(sol)`, `dim_dual_variable_constraints_box(sol)` | the number of box-constrained components |
| `dim_path_constraints_nl(sol)`, `dim_boundary_constraints_nl(sol)` | the number of path (boxes excluded) and boundary constraints |

## Back to the model

`model(sol)` returns the problem the solution was computed from, so everything on
[Inspect a problem](@ref modelling-inspect) works on it:

```@example main
model(sol) === ocp
```

## Solutions from a flow

A [flow](@ref flows-overview) integrated from a problem returns a `Solution` too. Here the
flow of the energy problem, with the control u = p₂ given by the maximum principle, from the
initial costate p(0) = (12, 6):

```@example main
using OrdinaryDiffEqTsit5
f = Flow(ocp, (x, p) -> p[2])
sol_flow = f((t0, tf), x0, [12, 6])
state(sol_flow)(tf), objective(sol_flow)
```

```@example main
@assert isapprox(state(sol_flow)(tf), [0, 0]; atol=1e-8)   # hide
@assert isapprox(objective(sol_flow), 6; atol=1e-8)        # hide
nothing                                                    # hide
```

The trajectories, `objective`, `time_grid`, `model` and `plot` work as above. What comes from a
solver does not: a flow's solution carries no multipliers, so `dual` raises an error, and
`iterations` and `constraints_violation` are `NotProvided`.

```@example main
iterations(sol_flow), constraints_violation(sol_flow)
```

```@example main
@assert iterations(sol_flow) isa OptimalControl.NotProvidedType   # hide
nothing                                                            # hide
```

## See also

- [Inspect a problem](@ref modelling-inspect): the model-side mirror of this page.
- [Plot a solution](@ref results-plot): draw everything read here.
- [Save and load](@ref results-save-load): write a solution to disk and read it back.
- [Migration](@ref migration): every renamed function, `success` → `successful` included.
