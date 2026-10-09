# [Lie derivative and Lie bracket](@id geometry-ad)

`ad(X, g)` differentiates along a vector field $X$. It computes the Lie derivative of $g$ when
$g$ returns a scalar, and the Lie bracket $[X, g]$ when $g$ returns a vector.

```@example main
using OptimalControl
```

## Lie derivative

The **Lie derivative** of a function $f : \mathbb{R}^n \to \mathbb{R}$ along a vector field
$X$ is the derivative of $f$ in the direction of $X$:

```math
(\mathcal{L}_X f)(x) = f'(x) \cdot X(x) = \sum_{i=1}^n \frac{\partial f}{\partial x_i}(x)\, X_i(x).
```

For the harmonic oscillator, $X(x) = (x_2, -x_1)$, and its energy
$f(x) = x_1^2 + x_2^2$, $\mathcal{L}_X f = 2x_1 x_2 - 2x_2 x_1 = 0$: the energy is constant
along the trajectories.

```@example main
X(x) = [x[2], -x[1]]
f(x) = x[1]^2 + x[2]^2

Xf = ad(X, f)
Xf([1.0, 2.0])
```

## Lie bracket

The **Lie bracket** of two vector fields $X$ and $Y$ is the vector field

```math
[X, Y](x) = Y'(x) \cdot X(x) - X'(x) \cdot Y(x),
```

where $X'(x)$ is the Jacobian matrix of $X$ at $x$. With $Y(x) = (x_1^2, x_2^2)$,
$Y' X = (2x_1 x_2, -2x_1 x_2)$ and $X' Y = (x_2^2, -x_1^2)$, so
$[X, Y](1, 2) = (4 - 4, -4 + 1) = (0, -3)$:

```@example main
Y(x) = [x[1]^2, x[2]^2]

Z = ad(X, Y)
Z([1.0, 2.0])
```

```@example main
@assert Xf([1.0, 2.0]) == 0 && Z([1.0, 2.0]) ≈ [0, -3]   # hide
nothing                                                 # hide
```

## Typed operands and nested brackets

On `VectorField`s, `ad` returns a `VectorField`, which can be bracketed again. The bracket
$[[X, Y], Y]$ at $x = (1, 2)$ is $(4, -2)$:

```@example main
XV = VectorField(x -> [x[2], -x[1]])
YV = VectorField(x -> [x[1]^2, x[2]^2])

ZV = ad(XV, YV)
ZV isa VectorField, ad(ZV, YV)([1.0, 2.0])
```

```@example main
@assert ZV isa VectorField && ad(ZV, YV)([1.0, 2.0]) ≈ [4, -2]   # hide
nothing                                                         # hide
```

The macro [`@Lie`](@ref geometry-lie-macro) writes the same bracket `@Lie [[XV, YV], YV]`.

## Time and variable

The derivatives are taken with respect to $x$ only. For a vector field $X(t, x)$ and a
function $f(t, x)$, pass `is_autonomous=false`. With $X(t, x) = (t + x_2, -x_1)$ and
$f(t, x) = t + x_1^2 + x_2^2$, $\mathcal{L}_X f = 2x_1(t + x_2) - 2x_2 x_1 = 2 t x_1$, which
is $2$ at $t = 1$, $x = (1, 2)$:

```@example main
Xt(t, x) = [t + x[2], -x[1]]
ft(t, x) = t + x[1]^2 + x[2]^2

ad(Xt, ft; is_autonomous=false)(1.0, [1.0, 2.0])
```

For a vector field $X(x, v)$ and a function $f(x, v)$, pass `is_variable=true`. With
$X(x, v) = (x_2 + v, -x_1)$ and $f(x, v) = x_1^2 + x_2^2 + v$,
$\mathcal{L}_X f = 2 x_1 v$:

```@example main
Xv(x, v) = [x[2] + v, -x[1]]
fv(x, v) = x[1]^2 + x[2]^2 + v

ad(Xv, fv; is_variable=true)([1.0, 2.0], 1.0)
```

```@example main
@assert ad(Xt, ft; is_autonomous=false)(1.0, [1.0, 2.0]) ≈ 2   # hide
@assert ad(Xv, fv; is_variable=true)([1.0, 2.0], 1.0) ≈ 2      # hide
nothing                                                       # hide
```

Typed operands carry these traits, and must agree:

```@repl main
Xa = VectorField(x -> [x[2], -x[1]]);
Xb = VectorField((t, x) -> [t + x[2], -x[1]]; is_autonomous=false);
try # hide
ad(Xa, Xb)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## [Partial time derivative](@id geometry-ad-time)

For a function $f(t, x, \ldots)$, `∂ₜ(f)` computes the partial derivative with respect to
time:

```math
(\partial_t f)(t, x, \ldots) = \frac{\partial f}{\partial t}(t, x, \ldots).
```

With $g(t, x) = t^2 + x_1 x_2$, $\partial_t g = 2t = 6$ at $t = 3$:

```@example main
g(t, x) = t^2 + x[1] * x[2]
dg = ∂ₜ(g)
dg(3.0, [1.0, 2.0])
```

`∂ₜ` also applies to a `VectorField` or a `Hamiltonian`. Its result always depends on time,
even when the input does not, and is then zero:

```@example main
dXV = ∂ₜ(XV)
dXV(1.0, [1.0, 2.0])
```

```@example main
@assert dg(3.0, [1.0, 2.0]) ≈ 6 && dXV(1.0, [1.0, 2.0]) == [0, 0]   # hide
nothing                                                            # hide
```

Together with the Poisson bracket, `∂ₜ` gives the time derivative of a function along an
extremal (see [Poisson bracket](@ref geometry-poisson-total)).

## Errors

| Situation | Exception |
| --- | --- |
| a `Hamiltonian` given to `ad` | `IncorrectArgument`, pointing to `Poisson` |
| operands with different dependences on time or on the variable | `PreconditionError` |
| an in-place `VectorField` | `NotImplemented` |
| a `HamiltonianVectorField` | `NotImplemented` |

```@repl main
H = Hamiltonian((x, p) -> x[1] + p[1]);
try # hide
ad(H, x -> x)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl main
Xip = VectorField((dx, x) -> (dx .= [x[2], -x[1]]); is_inplace=true);
try # hide
ad(Xip, x -> x[1]^2)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## See also

- [Poisson bracket](@ref geometry-poisson): the bracket of Hamiltonians, and
  $\{H_X, H_Y\} = H_{[X, Y]}$.
- [The `@Lie` macro](@ref geometry-lie-macro): the bracket notation.
- [AD backend](@ref geometry-ad-backend): how the derivatives are computed.
