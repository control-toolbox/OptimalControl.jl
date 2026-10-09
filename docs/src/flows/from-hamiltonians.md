# [From Hamiltonians](@id flows-from-hamiltonians)

The constructors on this page build a flow without an optimal control problem: from a
Hamiltonian, a Hamiltonian vector field, a pseudo-Hamiltonian and a control law, or a plain
vector field. They are the building blocks [From an OCP](@ref flows-from-ocp) is made of, and
they are useful when you have worked out the Hamiltonian yourself.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
nothing # hide
```

## Extremals

We take the energy-minimal double integrator again: $\dot q = v$, $\dot v = u$, cost
$\frac12\int u^2$, from $x_0 = (-1, 0)$ to $(0, 0)$ on $[0, 1]$. With the notation of
[Notation and conventions](@ref modelling-formulation-conventions) and $p^0 = -1$, the
pseudo-Hamiltonian is

```math
H(x, p, u) = p_1 v + p_2 u - \frac{u^2}{2},
```

maximised by $u(x, p) = p_2$. The maximised Hamiltonian is
$\mathbf{H}(x, p) = p_1 v + p_2^2/2$, and the pairs $(x, p)$ solutions of its Hamiltonian
system

```math
\dot x = \nabla_p \mathbf{H}(x, p), \qquad \dot p = -\nabla_x \mathbf{H}(x, p)
```

are the **extremals**. From the initial costate $p_0 = (12, 6)$, the extremal reaches the
target: $x(1) = (0, 0)$ and $p(1) = (12, -6)$. Each constructor below computes it from a
different description of the same system.

```@example main
t0, tf = 0, 1
x0 = [-1, 0]
p0 = [12, 6]
nothing # hide
```

## From a Hamiltonian

Give $\mathbf{H}(x, p)$; its Hamiltonian vector field
$\vec{\mathbf{H}} = (\nabla_p \mathbf{H}, -\nabla_x \mathbf{H})$ is computed by automatic
differentiation:

```@example main
H(x, p) = p[1] * x[2] + p[2]^2 / 2

f_h = Flow(Hamiltonian(H))
xf, pf = f_h(t0, x0, p0, tf)
```

```@example main
@assert isapprox(xf, [0, 0]; atol=1e-8) && isapprox(pf, [12, -6]; atol=1e-8)   # hide
nothing                                                                        # hide
```

A Hamiltonian is `H(x, p)` by default. If it depends on time, write `H(t, x, p)` and declare
it with `Hamiltonian(H; is_autonomous=false)`; if it depends on a variable, `H(x, p, v)`
with `is_variable=true`. Without the declaration, the call fails with a `MethodError`.

## From a Hamiltonian vector field

Give $\vec{\mathbf{H}}$ directly, as a function returning the pair $(\dot x, \dot p)$. No
automatic differentiation is involved:

```@example main
Hv(x, p) = ([x[2], p[2]], [0, -p[1]])

f_hv = Flow(HamiltonianVectorField(Hv))
f_hv(t0, x0, p0, tf)
```

## From a pseudo-Hamiltonian and a control law

Give $H(x, p, u)$ and the law $u(x, p)$: the flow is the one of
$\bar H(x, p) = H(x, p, u(x, p))$, differentiated through the law by automatic
differentiation. This is what [From an OCP](@ref flows-from-ocp) does, with the
pseudo-Hamiltonian read from the problem.

```@example main
Hp(x, p, u) = p[1] * x[2] + p[2] * u - u^2 / 2
law(x, p) = p[2]

f_hp = Flow(PseudoHamiltonian(Hp), DynClosedLoop(law))
f_hp(t0, x0, p0, tf)
```

`hamiltonian_type=:partial` freezes the control instead of differentiating through the law
(see [Total or partial Hamiltonian](@ref flows-from-ocp-total-partial)).

## From a pseudo-Hamiltonian vector field and a control law

Give $(\nabla_p H, -\nabla_x H)$ as a function of $(x, p, u)$, and the law:

```@example main
Hpv(x, p, u) = ([x[2], u], [0, -p[1]])

f_hpv = Flow(PseudoHamiltonianVectorField(Hpv), DynClosedLoop(law))
f_hpv(t0, x0, p0, tf)
```

```@example main
for g in (f_hv, f_hp, f_hpv)                                                   # hide
    xg, pg = g(t0, x0, p0, tf)                                                 # hide
    @assert isapprox(xg, [0, 0]; atol=1e-8) && isapprox(pg, [12, -6]; atol=1e-8)   # hide
end                                                                            # hide
nothing                                                                        # hide
```

Here the partial derivatives are given, so there is nothing to differentiate through the
law, and `hamiltonian_type` is not an option of this flow. Passing it raises an error, which
reads as an unknown integrator option:

```@repl main
try # hide
Flow(PseudoHamiltonianVectorField(Hpv), DynClosedLoop(law); hamiltonian_type=:partial)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## From a vector field

A flow of the state alone, $\dot x = f(x)$, or $f(t, x)$ when declared with
`is_autonomous=false`. With the optimal control $u(t) = 6 - 12t$ written as a function of
time, the state reaches the target:

```@example main
f_x = Flow(VectorField((t, x) -> [x[2], 6 - 12t]; is_autonomous=false))
f_x(t0, x0, tf)
```

```@example main
@assert isapprox(f_x(t0, x0, tf), [0, 0]; atol=1e-8)   # hide
nothing                                                # hide
```

To simulate a control system under a given control, open-loop or feedback, see
[Simulation](@ref flows-simulation).

## From a SciML problem

An `ODEFunction` or an `ODEProblem` of the SciML ecosystem can be used directly, with
`OrdinaryDiffEqTsit5` alone. The parameter `p` of the SciML function `f!(dx, x, p, t)` is the
**variable** of the flow, passed with the keyword `variable`. Here $\dot x = -p\,x$:

```@example main
rhs!(dx, x, p, t) = (dx[1] = -p * x[1]; nothing)

f_ode = Flow(ODEFunction(rhs!))
f_ode(0, [1.0], 1; variable=2)   # exp(-2)
```

```@example main
@assert isapprox(f_ode(0, [1.0], 1; variable=2)[1], exp(-2); atol=1e-8)   # hide
nothing                                                                    # hide
```

So the keyword is required even when the function does not use `p`: pass
`variable=nothing`. Without it, the call raises an error:

```@repl main
try # hide
f_ode(0, [1.0], 1)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

An `ODEProblem` works the same way:

```@example main
f_prob = Flow(ODEProblem(rhs!, [1.0], (0.0, 1.0), 2.0))
f_prob(0, [1.0], 1; variable=2)
```

## Summary

| Constructor | You give | Automatic differentiation | Point call returns |
| --- | --- | --- | --- |
| `Flow(Hamiltonian(H))` | $\mathbf{H}(x, p)$ | yes | `(x(tf), p(tf))` |
| `Flow(HamiltonianVectorField(Hv))` | $(\nabla_p \mathbf{H}, -\nabla_x \mathbf{H})$ | no | `(x(tf), p(tf))` |
| `Flow(PseudoHamiltonian(Hp), law)` | $H(x, p, u)$ and $u(x, p)$ | yes | `(x(tf), p(tf))` |
| `Flow(PseudoHamiltonianVectorField(Hpv), law)` | $(\nabla_p H, -\nabla_x H)$ and $u(x, p)$ | no | `(x(tf), p(tf))` |
| `Flow(VectorField(f))` | $f(x)$ | no | `x(tf)` |
| `Flow(ODEFunction(f!))`, `Flow(ODEProblem(…))` | a SciML function or problem | no | `x(tf)` |

`Hamiltonian`, `HamiltonianVectorField`, `PseudoHamiltonian`, `PseudoHamiltonianVectorField`
and `VectorField` take the keywords `is_autonomous=false` and `is_variable=true` for a
function of time or of a variable. Every `Flow` takes the integrator options of
[Flows overview](@ref flows-overview). Called on a time
span, `f((t0, tf), x0, p0)` returns a trajectory: see [Simulation](@ref flows-simulation).

## See also

- [From an OCP](@ref flows-from-ocp): the same flows, with the problem supplying the
  pseudo-Hamiltonian; you only write the law.
- [Accessors](@ref flows-accessors): read the Hamiltonian, its vector field and the law back
  from a flow.
- [Lift](@ref geometry-lift): the Hamiltonian lift of a vector field, and the other tools of
  the geometry section.
