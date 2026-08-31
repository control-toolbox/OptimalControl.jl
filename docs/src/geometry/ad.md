# [Lie derivative and Lie bracket](@id geometry-ad)

```@meta
Draft = false
```

`ad(X, foo)` is one function with two meanings, chosen by what `foo` returns.

```@example main
using OptimalControl
```

## One function, two meanings

- `foo` scalar-valued → the **Lie derivative** of `foo` along `X`.
- `foo` vector-valued → the **Lie bracket** of `X` and `foo`.

## Lie derivative

For a vector field $X$ and a scalar function $f$,

```math
(\mathcal{L}_X f)(x) = f'(x) \cdot X(x).
```

```@example main
X(x) = [x[2], -x[1]]
f(x) = x[1]^2 + x[2]^2   # energy of the harmonic oscillator

Xf = ad(X, f)
Xf([1.0, 2.0])
```

Energy is conserved along $X$'s flow, so the Lie derivative vanishes everywhere.

## Lie bracket

For two vector fields $X, Y$,

```math
[X, Y](x) = J_Y(x)\,X(x) - J_X(x)\,Y(x),
```

where $J$ denotes the Jacobian.

```@example main
Y(x) = [x[1]^2, x[2]^2]
Z = ad(X, Y)
Z([1.0, 2.0])
```

## Typed operands

Wrapping the inputs as `VectorField`s makes `ad` return a `VectorField` too — so it **nests**:

```@example main
XV = VectorField(x -> [x[2], -x[1]])
YV = VectorField(x -> [x[1]^2, x[2]^2])

ZV = ad(XV, YV)
typeof(ZV)
```

```@example main
ZZV = ad(ZV, YV)   # ad(ad(X, Y), Y) — a second-order bracket
ZZV([1.0, 2.0])
```

## Non-autonomous and variable fields

`is_autonomous=` and `is_variable=` work exactly as on [`Lift`](@ref); both operands must agree,
or you get a `PreconditionError` naming both traits:

```@repl main
Xa = VectorField(x -> [x[2], -x[1]]);
Xb = VectorField((t, x) -> [t + x[2], -x[1]]; is_autonomous=false);

try # hide
ad(Xa, Xb)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Partial time derivative

`∂ₜ` computes $\partial f / \partial t$ for a non-autonomous `f`, `VectorField`, or
`Hamiltonian` — its result is **always** `NonAutonomous`, regardless of whether the input
already was:

```@example main
g(t, x) = t^2 + x[1] * x[2]
dg = ∂ₜ(g)
dg(3.0, [1.0, 2.0])   # ∂g/∂t = 2t = 6
```

```@example main
dXV = ∂ₜ(XV)   # XV::VectorField from above — still NonAutonomous
typeof(dXV)
```

## Errors you will meet

| Situation | Exception |
| --- | --- |
| `ad` given an `AbstractHamiltonian` | `IncorrectArgument` — points at `Poisson` |
| time/variable dependence mismatch between operands | `PreconditionError` |
| an `InPlace` operand | `NotImplemented` |
| a `HamiltonianVectorField` passed to `ad` | `NotImplemented` |

```@repl main
H = Hamiltonian((x, p) -> x[1] + p[1]);
try # hide
ad(H, x -> x)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

`ad` also refuses an `InPlace` operand:

```@repl main
Xip = VectorField((dx, x) -> (dx .= [x[2], -x[1]]); is_inplace=true);
try # hide
ad(Xip, x -> x[1]^2)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## Coming from v2.0

| v2.0 | v2.1 |
| --- | --- |
| `Lie(X, f)` | `ad(X, f)` |
| `X ⋅ f` | `ad(X, f)` — **no operator replacement**, `⋅` is gone |

See [Migrating to v2.1](@ref migration) for the throwing shim on `Lie`.

## See also

- [Poisson bracket](@ref geometry-poisson) — the Hamiltonian-side counterpart, linked by
  `Poisson(Lift(X), Lift(Y)) ≈ Lift(ad(X, Y))`.
- [The `@Lie` macro](@ref geometry-lie-macro) — `ad`/`Poisson` with bracket notation.
