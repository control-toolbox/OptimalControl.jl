# [Choosing an AD backend](@id geometry-ad-backend)

```@meta
Draft = false
```

```@example main
using OptimalControl
```

## Everything here is AD-backed, except `Lift`

[`ad`](@ref), [`Poisson`](@ref), [`∂ₜ`](@ref), and [`@Lie`](@ref) all differentiate under the
hood; [`Lift`](@ref) is purely algebraic and never touches a backend at all.

## The default

```@example main
dg_ad_backend()
```

`DifferentiationInterface{CPU}` over `ForwardDiff`, the same default used throughout
`CTBase`/`CTLie`.

## Reading the current backend

`dg_ad_backend()` (above) always returns the backend that will be used when no `ad_backend=`
keyword is given.

## Changing it globally

```@example main
import CTBase: Differentiation

dg_ad_backend!(Differentiation.DifferentiationInterface())
dg_ad_backend()
```

## Changing it for one call

Every operation in this section accepts its own `ad_backend=`, overriding the global setting
just for that call:

```@example main
X(x) = [x[2], -x[1]]
f(x) = x[1]^2 + x[2]^2

ad(X, f; ad_backend=Differentiation.DifferentiationInterface())([1.0, 2.0])
```

## GPU

A GPU-parameterized backend is constructed the same way, with the `GPU` strategy instead of
`CPU`:

```julia
import CTBase: Differentiation, Strategies

dg_ad_backend!(Differentiation.DifferentiationInterface{Strategies.GPU}())
```

This block is not executed on this page — no CUDA-capable GPU is available in this development
environment or in CI, the same caveat as [GPU](@ref solve-gpu) on the solve side.

## Introspection

```@example main
describe(:di)
```

## If nothing works

If `DifferentiationInterface` (and a concrete AD package, such as `ForwardDiff`) isn't loaded,
the extension that actually performs the differentiation never arms, and calling `ad`,
`Poisson`, `∂ₜ`, or `@Lie` fails. `OptimalControl` loads `DifferentiationInterface` and
`ForwardDiff` itself, so this only bites if you're using `CTLie` standalone.

## See also

- [Overview](@ref geometry-overview) — where each operation sits relative to AD.
- [GPU](@ref solve-gpu) — the same `CPU`/`GPU` strategy split on the solve side.
- [Flows overview](@ref flows-overview) — the `method=:cpu`/`:gpu` construction-time keyword on
  `Flow`.
