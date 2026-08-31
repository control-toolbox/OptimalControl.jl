# [The `@Lie` macro](@id geometry-lie-macro)

```@meta
Draft = false
```

`@Lie` lets you write brackets the way you'd write them on paper: square brackets for a Lie
bracket, curly braces for a Poisson bracket.

```@example main
using OptimalControl
```

## Why a macro

`@Lie [X, Y]` reads as $[X, Y]$; `@Lie {H, K}` reads as $\{H, K\}$ — both expand to a call to
[`ad`](@ref) or [`Poisson`](@ref) respectively.

## Lie brackets

```@example main
F1 = VectorField(x -> [0, -x[3], x[2]])
F2 = VectorField(x -> [x[3], 0, -x[1]])

F12 = @Lie [F1, F2]
F12([1.0, 2.0, 3.0])
```

## Poisson brackets

```@example main
H0(x, p) = p[1] * x[2] + p[2] * (-x[1])
H1(x, p) = p[2]

H01 = @Lie {H0, H1}
H01([1.0, 2.0], [3.0, 4.0])
```

## Nesting

```@example main
F3 = VectorField(x -> [x[1], x[2], x[3]])
F123 = @Lie [[F1, F2], F3]
F123([1.0, 2.0, 3.0])
```

```@example main
H001 = @Lie {H0, {H0, H1}}
H001([1.0, 2.0], [3.0, 4.0])
```

## Arithmetic and evaluation points

`@Lie` brackets combine with ordinary arithmetic once evaluated:

```@example main
x = [1.0, 2.0, 3.0]   # F1, F2 are 3-D vector fields, defined above
@Lie [F1, F2](x) + 4 * [F1, F2](x)
```

**Parenthesise when you evaluate** — a trailing keyword binds to the macro, not to the call:
write `(@Lie [F, G](x))`, never `@Lie [F, G](x) atol=1e-6`, if you're combining the result with
anything else on the same line.

## Keywords

`is_autonomous=`, `is_variable=`, and `ad_backend=` all work exactly as on `ad`/`Poisson`,
inferred from typed `VectorField`/`Hamiltonian` operands or given explicitly for plain
functions:

```@example main
X(t, x) = [t + x[2], -x[1]]
Y(t, x) = [x[1], t * x[2]]

Z = @Lie [X, Y] is_autonomous=false
Z(1.0, [1.0, 2.0])
```

## What it needs in scope

The macro's expansion emits fully qualified `CTLie.*` and `CTBase.Traits.*` names, so both
modules must be resolvable at the call site. `using OptimalControl` re-exports both module
aliases:

```@example main
CTLie, CTBase
```

which is why they appear in `names(OptimalControl)` at all — not because you're expected to use
them directly, but because `@Lie`'s expansion needs them in scope.

## A trap to know about

The old `autonomous=`/`variable=` keywords are rejected at macro-expansion time, not silently
accepted:

```julia
julia> @Lie [F1, F2] autonomous=false
ERROR: IncorrectArgument: @Lie: unknown keyword argument
Got       autonomous
Expected  is_autonomous, is_variable, or ad_backend
Context   @Lie macro keyword parsing
```

## See also

- [Lie derivative and Lie bracket](@ref geometry-ad)
- [Poisson bracket](@ref geometry-poisson)
- [Singular control](@ref examples-singular-control) — where iterated `{...}` brackets are used
  in practice.
