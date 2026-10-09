# [Accessors](@id flows-accessors)

A flow keeps what it was built from: its Hamiltonian, its vector field, the
pseudo-Hamiltonian and the control law, and its integrator. This page shows how to read them
back, and on which flows.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
nothing # hide
```

We take the flow of the energy-minimal double integrator, built from the problem and the
control law $u = p_2$ (see [From an OCP](@ref flows-from-ocp)), and the point
$x = (-1, 0)$, $p = (12, 6)$: the start of the optimal extremal.

```@example main
ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end

f = Flow(ocp, (x, p) -> p[2])
x, p = [-1, 0], [12, 6]
nothing # hide
```

## The Hamiltonian

`hamiltonian(f)` returns the maximised Hamiltonian
$\mathbf{H}(x, p) = H(x, p, u(x, p)) = p_1 v + p_2^2/2$:

```@example main
H = hamiltonian(f)
H(x, p)   # 12 × 0 + 6²/2
```

## The Hamiltonian vector field

`hamiltonian_vector_field(f)` returns
$\vec{\mathbf{H}} = (\nabla_p \mathbf{H}, -\nabla_x \mathbf{H})$, as the pair
$(\dot x, \dot p) = ((v, p_2), (0, -p_1))$:

```@example main
Hv = hamiltonian_vector_field(f)
Hv(x, p)
```

## The pseudo-Hamiltonian and the control law

`pseudo_hamiltonian(f)` returns $H(x, p, u) = p_1 v + p_2 u - u^2/2$, and `control_law(f)`
the law you passed:

```@example main
Hp = pseudo_hamiltonian(f)
u = control_law(f)
Hp(x, p, u(x, p)), u(x, p)
```

```@example main
@assert H(x, p) == 18 && Hp(x, p, 6) == 18 && u(x, p) == 6                       # hide
@assert all(Hv(x, p) .≈ ([0, 6], [0, -12]))                                      # hide
@assert H(0.0, x, p, Float64[]) == 18 && u(0.0, x, p, Float64[]) == 6            # hide
nothing                                                                          # hide
```

These functions take the short form of their arguments, as above, or the full form with the
time and the variable: `H(t, x, p, v)`, `Hv(t, x, p, v)`, `Hp(t, x, p, u, v)`,
`u(t, x, p, v)`, with `v = Float64[]` for a problem without a variable.

## Gradients

`get_hamiltonian_gradient(f)` returns the gradient of $\mathbf{H}$ with respect to $x$ and
$p$, and `get_variable_gradient(f)` its gradient with respect to the variable.
`get_pseudo_hamiltonian_gradient` and `get_pseudo_variable_gradient` do the same for $H$,
before the law is substituted. They only take the full form `(t, x, p, v)`
([CTFlows#438](https://github.com/control-toolbox/CTFlows.jl/issues/438)):

```@example main
∇H = get_hamiltonian_gradient(f)
∇H(0.0, x, p, Float64[])   # (∇ₓH, ∇ₚH) = ((0, 12), (0, 6))
```

```@example main
@assert all(∇H(0.0, x, p, Float64[]) .≈ ([0, 12], [0, 6]))   # hide
nothing                                                     # hide
```

## Without a flow

`hamiltonian_vector_field` also applies to a `Hamiltonian`, without building a flow:

```@example main
Hv2 = hamiltonian_vector_field(Hamiltonian((x, p) -> p[1] * x[2] + p[2]^2 / 2))
Hv2(x, p)
```

## On which flow

What a flow can give back depends on what it was built from:

| Flow built from | `hamiltonian` | `hamiltonian_vector_field` | `pseudo_hamiltonian`, `control_law` | `vector_field` |
| --- | :-: | :-: | :-: | :-: |
| `ocp, law` with a law `u(x, p)`, or `PseudoHamiltonian(Hp), law` | ✓ | ✓ | ✓ | ✓ |
| `Hamiltonian(H)` | ✓ | ✓ | ✗ | ✓ |
| `HamiltonianVectorField(Hv)` | ✗ | ✓ | ✗ | ✓ |
| `VectorField(f)`, `ControlledVectorField(f), law`, `ocp, OpenLoop(…)` | ✗ | ✗ | ✗ | ✓ |

On a flow of the state, `vector_field` returns the vector field that is integrated:

```@example main
Fx = vector_field(Flow(VectorField(x -> -x)))
Fx(2.0)
```

An accessor that does not apply raises an error. For a Hamiltonian flow, the error says what
the flow holds and what to use instead:

```@repl main
try # hide
hamiltonian(Flow(HamiltonianVectorField((x, p) -> ([x[2], p[2]], [0, -p[1]]))))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

On a flow of the state, it is a `MethodError` for now
([CTFlows#438](https://github.com/control-toolbox/CTFlows.jl/issues/438)).

## The system and the integrator

A flow is made of a **system**, the mathematical object it integrates, and an
**integrator**. Both are reached with qualified names, since they are not exported:

```@example main
CTFlows.Flows.integrator(f)
```

The options of the integrator are those of [Flows overview](@ref flows-overview), given when
the flow is built.

## See also

- [From an OCP](@ref flows-from-ocp): the flow used on this page.
- [From Hamiltonians](@ref flows-from-hamiltonians): every constructor in the table above.
- [Geometry overview](@ref geometry-overview): Lie derivatives and brackets of these
  Hamiltonians and vector fields.
