# [Lift](@id geometry-lift)

```@meta
Draft = false
```

Given a vector field $X : \mathbb{R}^n \to \mathbb{R}^n$, its **lift** is the Hamiltonian

```math
H_X(x, p) = \langle p, X(x) \rangle = \sum_{i=1}^n p_i X_i(x).
```

It is a purely algebraic construction — no differentiation, no AD.

```@example main
using OptimalControl
```

## From a plain function

```@example main
X(x) = [x[2], -x[1]]
H = Lift(X)
H([1.0, 2.0], [3.0, 4.0])
```

`H` is an `OptimalControl.LiftedHamiltonianFunction` — a callable, not a `Hamiltonian`:

```@example main
typeof(H)
```

## From a typed vector field

Lifting a typed `VectorField` instead gives back a real `Hamiltonian`:

```@example main
XV = VectorField(x -> [x[2], -x[1]])
HV = Lift(XV)
HV isa AbstractHamiltonian
```

```@example main
HV([1.0, 2.0], [3.0, 4.0])
```

## Non-autonomous and variable forms

```@example main
Xt(t, x) = [t * x[2], -x[1]]
Ht = Lift(Xt; is_autonomous=false)
Ht(2.0, [1.0, 2.0], [3.0, 4.0])   # H(t, x, p)
```

```@example main
Xv(x, v) = [x[2] + v, -x[1]]
Hv = Lift(Xv; is_variable=true)
Hv([1.0, 2.0], [3.0, 4.0], 1.0)   # H(x, p, v)
```

## Which one do I get

| You lift | You get | Signature |
| --- | --- | --- |
| `f::Function` | `OptimalControl.LiftedHamiltonianFunction` (`<: Function`) | `h(x,p)`, `h(t,x,p)`, `h(x,p,v)`, `h(t,x,p,v)` depending on the keywords |
| `X::AbstractVectorField` | `Hamiltonian` | same call signatures, inherited from `X`'s own traits |

!!! warning "`Lift(f::Function)` is not an `AbstractHamiltonian`"

    `OptimalControl.LiftedHamiltonianFunction <: Function` only, **not** `<: AbstractHamiltonian` — a change
    from v2.0, where the plain-function form and the typed-`VectorField` form both produced the
    same kind of object. Any `isa`/`<:` test against the old hierarchy is now quietly wrong:

    ```@example main
    H = Lift(X)          # X::Function
    H isa AbstractHamiltonian
    ```

    Only the plain-`Function` overload changed — `Lift(X::AbstractVectorField)` still returns a
    `Hamiltonian`, confirmed above. See [Migration](@ref migration) for the full list of
    silent v2.0 → v2.1 semantics changes.

## What you can do with it

Feed a lift straight into [`Poisson`](@ref) (see
[The bridge identity](@ref geometry-overview)), or into [`Flow`](@ref) to integrate the
associated Hamiltonian system — see
[From Hamiltonians and vector fields](@ref flows-from-hamiltonians).

## A trap to know about

Lifting a `HamiltonianVectorField` doesn't work — it already lives on the cotangent space, so
there's nothing left to lift:

```@repl main
hvf = HamiltonianVectorField((x, p) -> (p, -x));
try # hide
Lift(hvf)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

The message talks about `ad`, not `Lift` — both operations share the same internal guard
against `HamiltonianVectorField` operands, so the wording doesn't adapt to which one triggered
it. Harmless, but don't be thrown by it: the operation that actually failed is `Lift`.

## See also

- [Overview](@ref geometry-overview) — the bridge identity this page is one half of.
- [Poisson bracket](@ref geometry-poisson) — what a lift is usually fed into.
- [From Hamiltonians and vector fields](@ref flows-from-hamiltonians) — turning a lift into a
  flow.
