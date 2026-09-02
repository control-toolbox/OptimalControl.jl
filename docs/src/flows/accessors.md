# [Accessors](@id flows-accessors)

Building a flow doesn't throw away what it was built from — a flow remembers its Hamiltonian,
its vector field, the control law you passed in, and the underlying integrator. This page is
the map of what you can pull back out, and from which kind of flow.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
using NLPModelsIpopt
nothing # hide
```

## What a flow remembers

Every flow wraps a **system** (the mathematical object — a Hamiltonian, a vector field, a
pseudo-Hamiltonian plus a law...) and an **integrator**. The four accessors below read off the
system; the last section reaches the integrator directly.

## The Hamiltonian

```@example main
h(x, p) = 0.5 * (x^2 + p^2)
f = Flow(Hamiltonian(h))
H = hamiltonian(f)
H(0.0, 1.0, 0.0, 1.0)   # H(t, x, p, v)
```

## The Hamiltonian vector field

```@example main
hamiltonian_vector_field(f)
```

Returns a [`HamiltonianVectorField`](@ref) — $(\partial_p H, -\partial_x H)$ — whether or not
the flow was built with AD.

## The pseudo-Hamiltonian and the control law

Only available on flows built from a pseudo-Hamiltonian (or an OCP, which is one under the
hood) plus a law:

```@example main
htilde(x, p, u) = p * u - 0.5 * u^2
law_fun(x, p) = p
f_ph = Flow(PseudoHamiltonian(htilde), DynClosedLoop(law_fun))

H̃ = pseudo_hamiltonian(f_ph)
H̃(0.0, 1.0, 0.0, 1.0, 1.0)   # H̃(t, x, p, u, v)
```

```@example main
control_law(f_ph)(1.0, 0.5)   # the law you passed in, u(x, p)
```

## Gradients

Four functions, each returning a struct-wrapped callable (not a bare function or a vector) —
expect `(t, x, p, v)`-shaped arguments when calling what they return:

```@example main
get_hamiltonian_gradient(f_ph)
```

```@example main
get_variable_gradient(f_ph)
```

`get_pseudo_hamiltonian_gradient(f_ph)` and `get_pseudo_variable_gradient(f_ph)` mirror the
two above, taken on $\tilde H$ before the law is substituted in rather than on the composed $H$.

## Building the Hamiltonian vector field from a Hamiltonian, without a flow

`hamiltonian_vector_field` also works directly on an `AbstractHamiltonian`, no `Flow` needed:

```@example main
hamiltonian_vector_field(Hamiltonian(h))
```

## What is available on which flow

Not every accessor makes sense on every flow — and the failure mode differs by *why* it
doesn't apply, confirmed live rather than assumed uniform:

| Built from | `hamiltonian` | `hamiltonian_vector_field` | `pseudo_hamiltonian` | `control_law` |
| --- | --- | --- | --- | --- |
| `Hamiltonian(h)` | ✅ | ✅ | ✗ `IncorrectArgument` | ✗ `IncorrectArgument` |
| `HamiltonianVectorField(hvf)` | ✗ `IncorrectArgument` | ✅ | ✗ `MethodError` | ✗ `MethodError` |
| `PseudoHamiltonian(h̃), law` | ✅ | ✅ | ✅ | ✅ |
| `ocp, law` | ✅ | ✅ | ✅ | ✅ |
| `VectorField(f)` | ✗ `MethodError` | ✗ `MethodError` (use `vector_field`) | ✗ `MethodError` | ✗ `MethodError` |

`IncorrectArgument` shows up where the flow *could* answer in principle but deliberately
doesn't have enough information (a `HamiltonianVectorField`-built flow has no scalar
Hamiltonian to hand back, only its vector field — the error says so and suggests
`hamiltonian_vector_field` instead). `MethodError` shows up where the accessor simply has no
method for that system type at all — a `VectorField`-built flow was never given anything
Hamiltonian-shaped, so none of the four Hamiltonian-side accessors apply; use
`vector_field` instead:

```@example main
vector_field(Flow(VectorField(x -> -x)))
```

```@repl main
try # hide
hamiltonian(Flow(HamiltonianVectorField((x, p) -> (p, -x))))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## The underlying system and integrator

Escape hatch, for when nothing above is specific enough — `system`/`integrator` stay
deliberately unexported (too generic a name for a DSL surface), reach them qualified:

```@example main
CTFlows.Flows.system(f)
```

```@example main
CTFlows.Flows.integrator(f)
```

## See also

- [From an OCP](@ref flows-from-ocp) — the most common source of a flow with all four
  accessors available.
- [From Hamiltonians](@ref flows-from-hamiltonians) — every constructor in
  the table above, built and shown in full.
- [Geometry](@ref geometry-overview) — the Lie-theoretic tools these systems are built on.
