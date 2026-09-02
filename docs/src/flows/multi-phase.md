# [Multi-phase flows](@id flows-multi-phase)

Bang-bang switchings, jumps at a boundary arc's entry/exit, phase changes of any kind: a
sequence of flows, each active on its own sub-interval, concatenated into one callable object —
itself a flow.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
nothing # hide
```

## Concatenating two flows

`*` glues two flows together at a switching time — the result is itself a flow:

```@example main
f1 = Flow(VectorField(x -> 0.0))    # constant
f2 = Flow(VectorField(x -> 1.0))    # unit slope

f = f1 * (1.0, f2)                  # f1 until t=1, then f2
typeof(f)
```

```@example main
f(0.0, 0.0, 2.0)   # one unit of f1's flat, then one of f2's slope-1
```

## Jumps

A jump inserts a discontinuity in the state at the switching time — `f1 * (t1, jump, f2)`,
where `jump` is a plain function of the state:

```@example main
jump(x) = x + 10.0
fj = f1 * (1.0, jump, f2)
fj(0.0, 0.0, 2.0)   # +10 landed at t=1, then one more unit of slope
```

On a **Hamiltonian** flow, the jump can act on state and costate separately — a 4-arg form,
`h1 * (t, jump_x, jump_p, h2)`:

```@example main
htilde(x, p, u) = p * u - 0.5 * u^2
law(x, p) = p
h1 = Flow(PseudoHamiltonian(htilde), DynClosedLoop(law))
h2 = Flow(PseudoHamiltonian(htilde), DynClosedLoop(law))

hj = h1 * (1.0, x -> x, p -> p, h2)   # identity jumps, written out
typeof(hj)
```

## Jumps as callables

A jump argument can be a function (as above), `nothing` for the identity (no jump at all), or
— accepted in addition to the two — a plain `Vector` added to the state/costate directly:

```@example main
h_identity = h1 * (1.0, nothing, nothing, h2)   # nothing ≡ no jump
h_vec = h1 * (1.0, [0.0, 0.0], h2)   # a bare vector jump works too
nothing # hide
```

## Calling a multi-phase flow

Exactly like any other flow — point form for the endpoint, trajectory form for the full path;
`variable=` still mandatory on a `NonFixed` problem, same rule as everywhere else in this
section.

## Inspecting one

```@example main
n_phases(f)
```

```@example main
get_switching_time(f, 1)
```

```@example main
get_switching_times(f)
```

```@example main
get_flow(f, 1) === f1
```

```@example main
length(get_flows(f))
```

`get_jump(mp, i)`/`get_jumps(mp)` read back the jump functions the same way, on a flow built
with jumps.

## Worked example: bang-bang time-optimal double integrator

Minimise the final time for $\ddot q = u$, $u \in [-1,1]$, from $(q,v)=(-1,0)$ to $(0,0)$. The
optimum is $t_f = 2$, reached by one switch at $t=1$: $u=+1$ then $u=-1$.

```@example main
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    q(0) == -1
    v(0) == 0
    q(tf) == 0
    v(tf) == 0
    ẋ(t) == [v(t), u(t)]
    tf → min
end

f_plus = Flow(ocp, (x, p, v) -> 1.0)
f_minus = Flow(ocp, (x, p, v) -> -1.0)

t1 = 1.0
tf = 2.0
p0 = [1.0, 1.0]   # the PMP's predicted initial costate

f_bb = f_plus * (t1, f_minus)
xf, pf = f_bb(0.0, [-1.0, 0.0], p0, tf; variable=tf)
xf   # ≈ [0, 0], the target
```

## See also

- [Constrained arcs](@ref flows-constrained-arcs) — assembling arcs around a boundary arc
  specifically, where the jump usually comes from a costate discontinuity.
- [Shooting](@ref flows-shooting) — solving for the switching time(s)
  themselves, not just assuming them known as here.
- [From an OCP](@ref flows-from-ocp) — the single-arc case this section generalises.
- [Time minimisation (bang–bang)](@ref examples-double-integrator-time) — the full story behind
  the double-integrator example used throughout this page.
