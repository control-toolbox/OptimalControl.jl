# [From Hamiltonians and vector fields](@id flows-from-hamiltonians)

```@meta
Draft = false
```

Every constructor below builds a flow **without** an OCP — the building blocks
[From an OCP](@ref flows-from-ocp) is itself assembled from. One section per constructor.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
nothing # hide
```

## From a vector field

The plain ODE case, $\dot x = f(x)$ (or `f(t, x)` if non-autonomous — see below):

```@example main
f = Flow(VectorField(x -> -x))
f(0.0, 1.0, 1.0)   # (t0, x0, tf) → x(tf), exp(-1)
```

## From a Hamiltonian

$\vec H = (\partial_p H, -\partial_x H)$ is obtained by automatic differentiation:

```@example main
h(x, p) = 0.5 * (x^2 + p^2)
fh = Flow(Hamiltonian(h))
fh(0.0, 1.0, 0.0, 1.0)   # (t0, x0, p0, tf) → (x(tf), p(tf))
```

`Hamiltonian` defaults to the natural 2-arg autonomous form `h(x, p)`. A 3-arg
`h(t, x, p)` silently mis-dispatches unless declared explicitly non-autonomous — see below.

## From a Hamiltonian vector field

Same system, but $\vec H$ given directly — no AD:

```@example main
hvf(x, p) = (p, -x)
fhvf = Flow(HamiltonianVectorField(hvf))
fhvf(0.0, 1.0, 0.0, 1.0)
```

## From a pseudo-Hamiltonian and a control law

$\tilde H(x,p,u)$ plus a law $u^*(x,p)$ — `Flow` substitutes and differentiates through it
(AD), same as [From an OCP](@ref flows-from-ocp)'s default `hamiltonian_type=:total`:

```@example main
htilde(x, p, u) = p * u - 0.5 * u^2
law(x, p) = p   # the maximiser of h̃ above
fph = Flow(PseudoHamiltonian(htilde), DynClosedLoop(law))
fph(0.0, 1.0, 0.0, 1.0)
```

## From a pseudo-Hamiltonian vector field and a control law

Same idea, vector-field form: $\tilde{\vec H}(x,p,u) = (\partial_p\tilde H, -\partial_x\tilde H)$
given directly. No `hamiltonian_type=` here — there's no pseudo-Hamiltonian scalar to
differentiate two different ways, so passing it is rejected:

```@example main
htildevf(x, p, u) = (u, 0.0)
fphvf = Flow(PseudoHamiltonianVectorField(htildevf), DynClosedLoop(law))
fphvf(0.0, 1.0, 0.0, 1.0)
```

```@repl main
try # hide
Flow(
    PseudoHamiltonianVectorField(htildevf),
    DynClosedLoop(law);
    hamiltonian_type=:partial,
)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## From a SciML problem

An `ODEFunction`/`ODEProblem` from the SciML ecosystem works directly — reachable through
`OrdinaryDiffEqTsit5` alone, nothing extra to load:

```@example main
rhs!(dx, x, p, t) = (dx[1] = -x[1]; nothing)
f_fun = Flow(ODEFunction(rhs!))
nothing # hide
```

SciML-backed flows are always `NonFixed` — even with no real free variable, a call needs
`variable=nothing`:

```@repl main
try # hide
f_fun(0.0, [1.0], 1.0)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@example main
f_fun(0.0, [1.0], 1.0; variable=nothing)
```

```@example main
prob = ODEProblem(rhs!, [1.0], (0.0, 1.0))
f_prob = Flow(prob)
typeof(f_prob)
```

## Non-autonomous and variable-dependent forms

`is_autonomous=` and `is_variable=` (not `autonomous=`, an old spelling that no longer
exists) declare the extra arguments a function needs:

```@example main
g(t, x) = -t * x
fg = Flow(VectorField(g; is_autonomous=false))
fg(0.0, 1.0, 1.0)
```

The stale form fails two ways at once — there is no `Flow(::Function)` at all, and even fixed
to the right type, the keyword itself changed name:

```@repl main
try # hide
VectorField(g; autonomous=false)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

`is_inplace=` similarly declares an in-place (mutating, `f!(dx, x)`) vs out-of-place
(`f(x) -> dx`) function — inferred automatically in most cases, settable explicitly when it
isn't.

## Summary table

| Constructor | Uses AD? | Returns |
| --- | --- | --- |
| `Flow(VectorField(f))` | no | `StateFlow` |
| `Flow(Hamiltonian(h))` | yes | `HamiltonianFlow` |
| `Flow(HamiltonianVectorField(hvf))` | no | `HamiltonianFlow` |
| `Flow(PseudoHamiltonian(h̃), law)` | yes | `HamiltonianFlow` |
| `Flow(PseudoHamiltonianVectorField(h̃vf), law)` | no | `HamiltonianFlow` |
| `Flow(ODEFunction(...))` / `Flow(ODEProblem(...))` | no | `StateFlow` / `SciMLProblemFlow` |

## See also

- [From an OCP](@ref flows-from-ocp) — the same constructors, specialised: an OCP supplies
  $\tilde H$ automatically, you only supply the law.
- [What you can get back from a flow](@ref flows-accessors) — which accessor works on which of
  the flows built here.
- [Lift and Poisson brackets](@ref geometry-lift) — the differential-geometric layer these
  constructors sit on top of.
