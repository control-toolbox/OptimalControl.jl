# [Overview](@id geometry-overview)

```@meta
Draft = false
```

Some flows can't be built directly from an optimal control problem — the control law itself
has to be *derived* first, for example a singular control on an arc where the usual
maximization condition degenerates. Deriving it needs differential-geometry tools: Lie
derivatives, Lie brackets, Poisson brackets. This section is that toolkit. It moved to its own
package, **CTLie**, in v2.1.0-beta.

```@example main
using OptimalControl
```

## What this is for

- Computing a **singular control** — the standard chain of iterated Poisson brackets
  ($H_{01}$, $H_{001}$, $H_{101}$, ...) that gives $u_{\text{sing}}$ on a singular arc.
- Checking **controllability** via the Lie brackets of the system's vector fields.
- Building a **Hamiltonian from a vector field** — the canonical lift used throughout the
  indirect-methods section.

## The four operations

| Operation | Signature | What it computes |
| --- | --- | --- |
| [`Lift`](@ref) | `Lift(X)` | the Hamiltonian $H_X(x,p) = \langle p, X(x)\rangle$ of a vector field $X$ |
| [`ad`](@ref) | `ad(X, f)` / `ad(X, Y)` | Lie derivative of a scalar `f`, or Lie bracket of a vector field `Y`, along $X$ |
| [`Poisson`](@ref) | `Poisson(H, G)` | the Poisson bracket of two Hamiltonians |
| [`∂ₜ`](@ref) | `∂ₜ(f)` | the partial time derivative of a non-autonomous `f` |

## Two vocabularies

Two kinds of objects appear throughout: **vector fields** live on the state space
($X : x \mapsto X(x)$), **Hamiltonians** live on the cotangent space
($H : (x, p) \mapsto H(x,p)$). `ad` and its bracket operate on the first vocabulary, `Poisson`
on the second. [`Lift`](@ref) is the bridge from one to the other.

## The bridge identity

Lifting turns a Lie bracket into a Poisson bracket: $\{H_X, H_Y\} = H_{[X,Y]}$, i.e.
`Poisson(Lift(X), Lift(Y)) ≈ Lift(ad(X, Y))`. It is the single best check that the two halves
of the toolkit agree — not a linear example, where the bracket is trivially zero:

```@example main
X(x) = [x[1]^2, x[2]^2]
Y(x) = [x[2], -x[1]]

lhs = Poisson(Lift(X), Lift(Y))
rhs = Lift(ad(X, Y))

x, p = [1.0, 2.0], [3.0, 4.0]
lhs(x, p), rhs(x, p)
```

## Autonomous, non-autonomous, variable

Every operation here takes `is_autonomous::Bool` and `is_variable::Bool` keywords (default
`true`/`false` — time-independent, no extra parameter). Operands that disagree — one
autonomous, one not, say — throw a `PreconditionError` naming both traits explicitly; see
[Lie derivative and Lie bracket](@ref geometry-ad) for the exact message.

## Automatic differentiation

Everything here is AD-backed **except `Lift`**, which is a purely algebraic rearrangement
($H(x,p) = p \cdot X(x)$, no derivative involved). See
[Choosing an AD backend](@ref geometry-ad-backend) for how the derivatives themselves are
computed and how to change the backend.

## Coming from v2.0

| v2.0 | v2.1 |
| --- | --- |
| `Lie(X, f)` / `Lie(X, Y)` | `ad(X, f)` / `ad(X, Y)` |
| `X ⋅ f` | `ad(X, f)` — no operator replacement |
| `HamiltonianLift` | `LiftedHamiltonianFunction` (written `OptimalControl.LiftedHamiltonianFunction`) |

See [Migrating to v2.1](@ref migration) for the full picture, including the throwing shims that
catch the old names.

## See also

- [Lifting a vector field](@ref geometry-lift)
- [Lie derivative and Lie bracket](@ref geometry-ad)
- [Poisson bracket](@ref geometry-poisson)
- [The `@Lie` macro](@ref geometry-lie-macro)
- [Choosing an AD backend](@ref geometry-ad-backend)
