# [Geometry overview](@id geometry-overview)

Optimal control theory relies on tools from differential geometry: to analyse Hamiltonian
systems, compute singular controls, or study controllability. This section presents the
operators that OptimalControl provides for this: the Hamiltonian lift, Lie derivatives, Lie
brackets, Poisson brackets and partial time derivatives. They come from the package CTLie, and
`using OptimalControl` makes them available.

```@example main
using OptimalControl
```

## What this is for

- Computing a **singular control**: on an arc where the switching function vanishes, its
  successive time derivatives are Poisson brackets ($H_{01}$, $H_{001}$, $H_{101}$, …), and
  they give the control (see [Poisson bracket](@ref geometry-poisson-singular)).
- Checking **controllability**, with the Lie brackets of the vector fields of the system.
- Building a **Hamiltonian from a vector field**, the lift, to integrate its flow (see
  [From Hamiltonians](@ref flows-from-hamiltonians)).

## Summary

| Operation | Notation | Julia | Page |
| --- | --- | --- | --- |
| Hamiltonian lift | $H_X(x, p) = \langle p, X(x) \rangle$ | `Lift(X)` | [Lift](@ref geometry-lift) |
| Lie derivative | $(\mathcal{L}_X f)(x) = f'(x) \cdot X(x)$ | `ad(X, f)` | [Lie derivative and Lie bracket](@ref geometry-ad) |
| Lie bracket | $[X, Y](x) = Y'(x) \cdot X(x) - X'(x) \cdot Y(x)$ | `ad(X, Y)` or `@Lie [X, Y]` | [Lie derivative and Lie bracket](@ref geometry-ad) |
| Poisson bracket | $\{H, G\} = \nabla_p H \cdot \nabla_x G - \nabla_x H \cdot \nabla_p G$ | `Poisson(H, G)` or `@Lie {H, G}` | [Poisson bracket](@ref geometry-poisson) |
| Partial time derivative | $\partial_t f(t, x, \ldots)$ | `∂ₜ(f)` | [Lie derivative and Lie bracket](@ref geometry-ad-time) |

`ad(X, f)` computes a Lie derivative when `f` returns a scalar, and a Lie bracket when it
returns a vector. The macro [`@Lie`](@ref geometry-lie-macro) writes the brackets as on paper.

## Two kinds of objects

**Vector fields** live on the state space, $X : x \mapsto X(x)$, and **Hamiltonians** on the
cotangent space, $H : (x, p) \mapsto H(x, p)$. `ad` acts on vector fields, `Poisson` on
Hamiltonians, and the lift takes a vector field to a Hamiltonian.

Each can be a plain Julia function or a typed object, `VectorField(f)` or `Hamiltonian(h)`.
On plain functions, the default is a function of the state only (`x` or `(x, p)`): the
keywords `is_autonomous=false` (an argument `t` first) and `is_variable=true` (an argument `v`
last) describe the other cases. A typed object carries this information itself, and the
operations return typed objects, which can be nested. Two operands must have the same
dependence on time and on the variable.

## [The bridge identity](@id geometry-overview-bridge)

The lift turns a Lie bracket into a Poisson bracket:

```math
\{H_X, H_Y\} = H_{[X, Y]}.
```

Indeed, $\nabla_p H_X = X$ and $\nabla_x H_Y = Y'^{\top} p$, so
$\{H_X, H_Y\} = \langle p, Y' X \rangle - \langle p, X' Y \rangle = \langle p, [X, Y] \rangle$.
For $X(x) = (x_1^2, x_2^2)$ and $Y(x) = (x_2, -x_1)$, the bracket is
$[X, Y](x) = (x_2^2 - 2x_1 x_2,\ 2 x_1 x_2 - x_1^2)$, so at $x = (1, 2)$, $[X, Y] = (0, 3)$,
and at $p = (3, 4)$ both sides equal $12$:

```@example main
X(x) = [x[1]^2, x[2]^2]
Y(x) = [x[2], -x[1]]

x, p = [1.0, 2.0], [3.0, 4.0]
Poisson(Lift(X), Lift(Y))(x, p), Lift(ad(X, Y))(x, p)
```

```@example main
@assert ad(X, Y)(x) ≈ [0, 3]                                              # hide
@assert Poisson(Lift(X), Lift(Y))(x, p) ≈ 12 && Lift(ad(X, Y))(x, p) ≈ 12   # hide
nothing                                                                    # hide
```

## Automatic differentiation

`ad`, `Poisson`, `∂ₜ` and `@Lie` compute their derivatives by automatic differentiation;
`Lift` needs none. [AD backend](@ref geometry-ad-backend) shows how to choose the backend.

## See also

- [Lift](@ref geometry-lift)
- [Lie derivative and Lie bracket](@ref geometry-ad)
- [Poisson bracket](@ref geometry-poisson)
- [The `@Lie` macro](@ref geometry-lie-macro)
- [AD backend](@ref geometry-ad-backend)
- [Singular control](@ref examples-singular-control): these tools on a complete problem.
