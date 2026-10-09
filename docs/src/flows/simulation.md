# [Simulation](@id flows-simulation)

Sometimes you do not look for an optimum: you have a control system and a given control,
open-loop or feedback, and you want the trajectory it produces, or the cost of that control
for a problem.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using Plots
nothing # hide
```

## The idea

A controlled vector field $\dot x = f(x, u)$ and a control are enough to integrate a
trajectory. The control is given as a function of time (open loop) or of the state
(feedback, closed loop). No cost, no costate: the vector field is a
`ControlledVectorField`, and the control a law `OpenLoop` or `ClosedLoop`.

## Open loop

Take $\dot x = -x + u$ with the constant control $u(t) = 1$. From $x(0) = 0$, the solution is
$x(t) = 1 - e^{-t}$:

```@example main
fc(x, u) = -x + u

f_ol = Flow(ControlledVectorField(fc), OpenLoop(t -> 1))
f_ol(0, 0.0, 1)   # 1 - exp(-1)
```

```@example main
@assert isapprox(f_ol(0, 0.0, 1), 1 - exp(-1); atol=1e-8)   # hide
nothing                                                     # hide
```

An open-loop law is always a function of time, `u(t)`, or `u(t, v)` with a variable. A
function without argument, such as `OpenLoop(() -> 1)`, is accepted when the law is built,
but the call then fails with a `MethodError`
([CTBase#570](https://github.com/control-toolbox/CTBase.jl/issues/570)):

```@repl main
try # hide
Flow(ControlledVectorField(fc), OpenLoop(() -> 1))(0, 0.0, 1)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Closed loop

A feedback is a function of the state, `u(x)`. With $u = x/2$, the system becomes
$\dot x = -x/2$, so from $x(0) = 1$, $x(1) = e^{-1/2}$:

```@example main
f_cl = Flow(ControlledVectorField(fc), ClosedLoop(x -> x / 2))
f_cl(0, 1.0, 1)   # exp(-1/2)
```

```@example main
@assert isapprox(f_cl(0, 1.0, 1), exp(-1 / 2); atol=1e-8)   # hide
nothing                                                     # hide
```

A law of the state and the costate, `DynClosedLoop`, is rejected here: the flow of a
controlled vector field has no costate.

```@repl main
try # hide
Flow(ControlledVectorField(fc), DynClosedLoop((x, p) -> p))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Evaluating a control on a problem

Built from an optimal control problem, the simulation also computes the cost of the control.
On the energy-minimal double integrator, the optimal control is $u(t) = 6 - 12t$, with
cost $6$ (see [Your first problem](@ref getting-started-first-problem)):

```@example main
t0, tf = 0, 1
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

f_opt = Flow(ocp, OpenLoop(t -> 6 - 12t))
traj = f_opt((t0, tf), x0)
state(traj)(tf), objective(traj)
```

The simulation reaches the target with the optimal cost. Another control costs less, but
misses the target: the constant $u = 1$ costs $1/2$ and ends at $x(1) = (-1/2, 1)$.

```@example main
traj_1 = Flow(ocp, OpenLoop(t -> 1))((t0, tf), x0)
state(traj_1)(tf), objective(traj_1)
```

```@example main
@assert isapprox(state(traj)(tf), [0, 0]; atol=1e-8) && isapprox(objective(traj), 6; atol=1e-8)        # hide
@assert isapprox(state(traj_1)(tf), [-0.5, 1]; atol=1e-8) && isapprox(objective(traj_1), 0.5; atol=1e-8)   # hide
nothing                                                                                                 # hide
```

The boundary conditions of the problem are not enforced: the simulation only integrates the
dynamics and the cost from $x_0$. A feedback works the same way, with
`Flow(ocp, ClosedLoop(x -> …))`.

## Reading and plotting the trajectory

The trajectory is read with the same functions as a [`Solution`](@ref results-solution):
`state`, `control`, `time_grid`, and `objective` when the flow comes from a problem.

```@example main
state(traj)(0.5), control(traj)(0.5)
```

```@example main
plot(traj)
```

There is no costate: `costate(traj)` raises an error, and so does `objective` on a flow built
without a problem.

```@repl main
try # hide
objective(f_ol((0, 1), 0.0))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## [What a flow returns](@id flows-simulation-returns)

Every flow is called in two ways: `f(t0, x0, tf)` returns the final state (with `p0`, the
final state and costate), and `f((t0, tf), x0)` returns the trajectory. The trajectory
depends on how the flow was built:

| Flow | Trajectory | Costate | Objective |
| --- | --- | :-: | :-: |
| `Flow(ocp, law)`, with a law `u(x, p)` ([From an OCP](@ref flows-from-ocp)) | a [`Solution`](@ref results-solution) | ✓ | ✓ |
| `Flow(ocp, OpenLoop(…))`, `Flow(ocp, ClosedLoop(…))` | a trajectory of the state | ✗ | ✓ |
| `Flow(ControlledVectorField(f), law)`, `Flow(VectorField(f))` | a trajectory of the state | ✗ | ✗ |
| `Flow(Hamiltonian(H))` and the other [Hamiltonian constructors](@ref flows-from-hamiltonians) | a trajectory of the state and costate | ✓ | ✗ |

```@example main
raises(f) = try f(); false catch; true end                                         # hide
sol_h = Flow(ocp, (x, p) -> p[2])((t0, tf), x0, [12, 6])                           # hide
@assert sol_h isa OptimalControl.Solution && !raises(() -> costate(sol_h))         # hide
@assert !(traj isa OptimalControl.Solution) && raises(() -> costate(traj))         # hide
traj_x = f_ol((0, 1), 0.0)                                                         # hide
@assert raises(() -> costate(traj_x)) && raises(() -> objective(traj_x))           # hide
traj_v = Flow(VectorField(x -> -x))((0, 1), 1.0)                                   # hide
@assert raises(() -> objective(traj_v))                                            # hide
traj_h = Flow(Hamiltonian((x, p) -> p[1] * x[2] + p[2]^2 / 2))((t0, tf), x0, [12, 6])   # hide
@assert !raises(() -> costate(traj_h)(0.5)) && raises(() -> objective(traj_h))     # hide
nothing                                                                            # hide
```

All of them are read with `state`, `costate` (when there is one), `time_grid` and `plot`. The
types of the trajectories are internal: call these functions on them, without naming the
types.

## See also

- [Solution object](@ref results-solution) and [Plot](@ref results-plot): the functions used
  above, in full.
- [From an OCP](@ref flows-from-ocp): the indirect method, where the law comes from the
  maximum principle.
- [Control-free problems](@ref modelling-without-control): problems without a control at all.
