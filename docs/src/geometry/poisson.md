# [Poisson bracket](@id geometry-poisson)

```@meta
Draft = false
```

For two Hamiltonians $H, G$,

```math
\{H, G\}(x,p) = \nabla_p H \cdot \nabla_x G - \nabla_x H \cdot \nabla_p G.
```

```@example main
using OptimalControl
```

## On plain functions

```@example main
H(x, p) = p[1] * x[2] + p[2] * x[1]
G(x, p) = x[1]^2 + p[2]^2

B = Poisson(H, G)
x, p = [1.0, 2.0], [3.0, 4.0]
B(x, p)
```

Antisymmetry, $\{H,G\} = -\{G,H\}$, checked directly:

```@example main
Poisson(H, G)(x, p) + Poisson(G, H)(x, p)
```

## On typed Hamiltonians

Wrapping the inputs as `Hamiltonian`s makes `Poisson` return a `Hamiltonian` too — it **nests**:

```@example main
HT = Hamiltonian(H)
GT = Hamiltonian(G)

BT = Poisson(HT, GT)
typeof(BT)
```

```@example main
BTT = Poisson(BT, GT)   # {{H, G}, G} — a second-order bracket
BTT(x, p)
```

## The bridge to Lie brackets

$\{H_X, H_Y\} = H_{[X,Y]}$ — lifting turns a Poisson bracket into a Lie bracket, and vice versa:

```@example main
X(x) = [x[1]^2, x[2]^2]
Y(x) = [x[2], -x[1]]

Poisson(Lift(X), Lift(Y))(x, p), Lift(ad(X, Y))(x, p)
```

## Non-autonomous and variable forms

```@example main
Ht(t, x, p) = t + p[1] * x[2] + p[2] * x[1]
Gt(t, x, p) = t^2 + x[1]^2 + p[2]^2

Bt = Poisson(Ht, Gt; is_autonomous=false)
Bt(1.0, x, p)
```

## Application: singular controls

For a pseudo-Hamiltonian $H = H_0 + u H_1$, if the switching function $H_1$ vanishes on an
interval (a singular arc), the control there is recovered from the iterated Poisson brackets

```math
H_{01} = \{H_0, H_1\}, \qquad H_{001} = \{H_0, H_{01}\}, \qquad H_{101} = \{H_1, H_{01}\},
```

giving

```math
u_{\text{sing}} = -\frac{H_{001}}{H_{101}}, \qquad H_{101} \neq 0.
```

```@example main
H0(x, p) = p[1] * x[2] + p[2] * (-x[1])
H1(x, p) = p[2]

H01 = Poisson(H0, H1)
H001 = Poisson(H0, H01)
H101 = Poisson(H1, H01)

H001(x, p), H101(x, p)
```

See the [example gallery](@ref examples-gallery) for a complete singular-control application on
a real problem.

## A trap to know about

`Poisson` is not defined on vector fields — lift them first:

```@example main
XV = VectorField(x -> [x[2], -x[1]])
try
    Poisson(XV, x -> x[1])
catch e
    println(e)
end
```

## See also

- [Lie derivative and Lie bracket](@ref geometry-ad) — the vector-field-side counterpart.
- [The `@Lie` macro](@ref geometry-lie-macro) — `{H, G}` notation for this bracket.
- [Example gallery](@ref examples-gallery) — the worked application.
