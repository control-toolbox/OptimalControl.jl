# [Simulation](@id flows-simulation)

Sometimes you don't want an optimum — you have a controlled system and a specific control
(open-loop or feedback), and you want the trajectory it produces.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NLPModelsIpopt
using Plots
nothing # hide
```

## The idea

A controlled vector field $\dot x = f(x, u)$ plus a control — given as a function of time
(open loop) or of state (feedback) — is enough to integrate a trajectory. No cost, no PMP, no
`@def`: just `ControlledVectorField` and a law.

## Open loop

```@example main
fc(x, u) = -x + u

f_ol = Flow(ControlledVectorField(fc), OpenLoop(t -> 1.0))
traj_ol = f_ol((0.0, 1.0), 1.0)
state(traj_ol)(0.5)
```

!!! warning "`OpenLoop` is unconditionally non-autonomous"

    The law must be `u(t)` (or `u(t, v)` with a variable) — always a function of time, never a
    bare constant closure. `OpenLoop(() -> 1.0)` **builds without error** but fails on the
    first call, with a bare `MethodError` far from the actual mistake:

    ```@repl main
    bad_law = OpenLoop(() -> 1.0);   # constructs fine — the trap
    try # hide
    Flow(ControlledVectorField(fc), bad_law)(0.0, 1.0, 1.0)
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

    `OpenLoop(t -> 1.0)` above is the only correct spelling — there is no "autonomous open
    loop" any more. See [Migration](@ref migration) for the full list of silent v2.0 → v2.1
    semantics changes.

## Closed loop (feedback)

```@example main
f_cl = Flow(ControlledVectorField(fc), ClosedLoop(x -> 0.5x))
f_cl(0.0, 1.0, 1.0)
```

`DynClosedLoop` (the costate-carrying law kind) is rejected on a `ControlledVectorField` — it
has no costate to carry:

```@repl main
try # hide
Flow(ControlledVectorField(fc), DynClosedLoop((x, p) -> x))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## From an optimal control problem

```@example main
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

f_sim = Flow(ocp, OpenLoop(t -> 1.0))
traj_ocp = f_sim((t0, tf), x0)
nothing # hide
```

`Flow(ocp, OpenLoop(u))` returns a `ControlledFlow` whose trajectory **carries the objective**
— you can evaluate a candidate control's cost directly:

```@example main
objective(traj_ocp)
```

A flow built without an OCP has no cost to report — calling `objective` on it is a
`PreconditionError`, not a silent `0.0` or `NaN`:

```@repl main
try # hide
objective(traj_ol)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Inspecting the trajectory

Same accessors as a `solve`-returned [`Solution`](@ref results-solution):

```@example main
state(traj_ocp)(0.5), control(traj_ocp)(0.5), time_grid(traj_ocp)
```

## Plotting it

```@example main
plot(traj_ocp)
```

See [Plot](@ref results-plot) for every keyword.

## Point vs trajectory

`f(t0, x0, tf)` returns the endpoint only; `f((t0, tf), x0)` returns the full trajectory — same
convention as every other flow in this section.

The trajectory's own type — `CTFlows.Trajectories.StateFlowTrajectory` — is not re-exported;
never name it in your own code, only call the generic accessors on it.

## See also

- [Solution object](@ref results-solution) and [Plot](@ref results-plot) — the accessors used
  above, in full.
- [From an OCP](@ref flows-from-ocp) — the indirect-solving counterpart, where the law comes
  from the PMP instead of being handed to you.
- [No control](@ref modelling-without-control) — control-free problems, a
  related but distinct case.
