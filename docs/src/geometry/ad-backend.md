# [AD backend](@id geometry-ad-backend)

`ad`, `Poisson`, `∂ₜ` and `@Lie` compute their derivatives by automatic differentiation (AD);
`Lift` computes none. This page shows which AD backend they use, and how to change it.

```@example main
using OptimalControl
```

## The default

```@example main
dg_ad_backend()
```

The default backend calls [DifferentiationInterface](https://github.com/JuliaDiff/DifferentiationInterface.jl)
with ForwardDiff, on the CPU. OptimalControl depends on both packages, so nothing else needs
to be installed. `describe` lists the options of the backend, and their defaults on the CPU
and on the GPU:

::: details `describe(:di)`

```@example main
describe(:di)
```

:::

## Choosing a backend

A backend is built with `CTBase.Differentiation.DifferentiationInterface`, whose option
`ad_backend` is a backend type of [ADTypes](https://github.com/SciML/ADTypes.jl).
DifferentiationInterface re-exports these types; add it to your environment to use them. For
example, ForwardDiff with a chunk size of one:

```@example main
using DifferentiationInterface: AutoForwardDiff

backend = CTBase.Differentiation.DifferentiationInterface(; ad_backend=AutoForwardDiff(chunksize=1))
```

Every operation accepts `ad_backend=` for one call:

```@example main
X(x) = [x[2], -x[1]]
f(x) = x[1]^2 + x[2]^2 + x[1]

ad(X, f; ad_backend=backend)([1.0, 2.0])   # 2x₁x₂ - 2x₂x₁ + x₂
```

`dg_ad_backend!` changes the default for the rest of the session. Keep the previous one to
restore it:

```@example main
previous = dg_ad_backend()
dg_ad_backend!(backend)
ad(X, f)([1.0, 2.0])
```

```@example main
dg_ad_backend!(previous)
dg_ad_backend()
```

```@example main
@assert ad(X, f; ad_backend=backend)([1.0, 2.0]) ≈ 2   # hide
@assert ad(X, f)([1.0, 2.0]) ≈ 2                       # hide
@assert dg_ad_backend() === previous                   # hide
nothing                                                # hide
```

## GPU

The GPU backend is built with the parameter `GPU`. Its default is Mooncake, since ForwardDiff
does not run on GPU arrays:

```@example main
CTBase.Differentiation.DifferentiationInterface{GPU}()
```

It differentiates functions of `CuArray`s, and needs CUDA and Mooncake to be loaded, as
`Flow(…; method=:gpu)` does (see [Flows overview](@ref flows-overview)).

## See also

- [Geometry overview](@ref geometry-overview): the operations that use this backend.
- [GPU](@ref solve-gpu): solving on a GPU.
- [Flows overview](@ref flows-overview): the `method=:cpu` and `method=:gpu` options of
  `Flow`.
