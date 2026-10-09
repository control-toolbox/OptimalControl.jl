# [Poisson bracket](@id geometry-poisson)

For two functions $H, G : \mathbb{R}^n \times (\mathbb{R}^n)^* \to \mathbb{R}$, the
**Poisson bracket** is

```math
\{H, G\}(x, p) = \sum_{i=1}^n \left( \frac{\partial H}{\partial p_i} \frac{\partial G}{\partial x_i}
- \frac{\partial H}{\partial x_i} \frac{\partial G}{\partial p_i} \right)
= \nabla_p H \cdot \nabla_x G - \nabla_x H \cdot \nabla_p G.
```

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
```

## Computing a bracket

With $H(x, p) = p_1 x_2 + p_2 x_1$ and $G(x, p) = x_1^2 + p_2^2$,
$\nabla_p H = (x_2, x_1)$, $\nabla_x G = (2x_1, 0)$, $\nabla_x H = (p_2, p_1)$ and
$\nabla_p G = (0, 2p_2)$, so $\{H, G\} = 2x_1 x_2 - 2p_1 p_2$, which is $-20$ at
$x = (1, 2)$, $p = (3, 4)$:

```@example main
H(x, p) = p[1] * x[2] + p[2] * x[1]
G(x, p) = x[1]^2 + p[2]^2

x, p = [1.0, 2.0], [3.0, 4.0]
Poisson(H, G)(x, p)
```

On `Hamiltonian`s, `Poisson` returns a `Hamiltonian`, which can be bracketed again:

```@example main
HT = Hamiltonian(H)
GT = Hamiltonian(G)

B = Poisson(HT, GT)
B isa Hamiltonian, Poisson(B, GT)(x, p)   # {{H, G}, G}
```

For functions of $(t, x, p)$, pass `is_autonomous=false`, and for functions of $(x, p, v)$,
`is_variable=true`. The derivatives are taken with respect to $x$ and $p$ only, so adding
terms in $t$ does not change the bracket:

```@example main
Ht(t, x, p) = t + H(x, p)
Gt(t, x, p) = t^2 + G(x, p)

Poisson(Ht, Gt; is_autonomous=false)(1.0, x, p)
```

```@example main
@assert Poisson(H, G)(x, p) ≈ -20 && Poisson(Ht, Gt; is_autonomous=false)(1.0, x, p) ≈ -20   # hide
@assert B isa Hamiltonian                                                                  # hide
nothing                                                                                    # hide
```

## Properties

The Poisson bracket is

- **bilinear**: $\{aF + bG, K\} = a\{F, K\} + b\{G, K\}$ for scalars $a, b$;
- **antisymmetric**: $\{F, G\} = -\{G, F\}$;
- a **derivation** (Leibniz rule): $\{FG, K\} = F\{G, K\} + G\{F, K\}$;
- and it satisfies the **Jacobi identity**:
  $\{\{F, G\}, K\} + \{\{K, F\}, G\} + \{\{G, K\}, F\} = 0$.

Checked at the point above, with a third function $K$:

```@example main
K(x, p) = x[1] * p[1] * p[2] + x[2]^3

antisymmetry = Poisson(H, G)(x, p) + Poisson(G, H)(x, p)
leibniz = Poisson((x, p) -> H(x, p) * G(x, p), K)(x, p) -
          (H(x, p) * Poisson(G, K)(x, p) + G(x, p) * Poisson(H, K)(x, p))
jacobi = Poisson(Poisson(H, G), K)(x, p) + Poisson(Poisson(K, H), G)(x, p) +
         Poisson(Poisson(G, K), H)(x, p)
antisymmetry, leibniz, jacobi
```

```@example main
@assert abs(antisymmetry) < 1e-10 && abs(leibniz) < 1e-10 && abs(jacobi) < 1e-10   # hide
nothing                                                                           # hide
```

The bracket of two lifts is the lift of the Lie bracket, $\{H_X, H_Y\} = H_{[X, Y]}$ (see
[The bridge identity](@ref geometry-overview-bridge)).

## [Time derivative along an extremal](@id geometry-poisson-total)

The Hamiltonian vector field of $H$ is $\vec{H} = (\nabla_p H, -\nabla_x H)$. The Poisson
bracket is the Lie derivative along it:

```math
\{H, G\} = \vec{H} \cdot G = \nabla_x G \cdot \nabla_p H - \nabla_p G \cdot \nabla_x H .
```

So along an integral curve of $\vec{H}$, that is, an extremal
$\dot x = \nabla_p H$, $\dot p = -\nabla_x H$, a function $G(t, x, p)$ varies as

```math
\frac{\mathrm{d}}{\mathrm{d}t}\, G(t, x(t), p(t)) = \partial_t G + \{H, G\}:
```

the partial time derivative, for the explicit dependence on $t$, plus the Poisson bracket,
for the motion along the flow. To check it, integrate the flow of a Hamiltonian that depends
on time, and compare the derivative of $G$ along it, by finite differences, with
$\partial_t G + \{H, G\}$:

```@example main
Hn(t, x, p) = p[1] * x[2] + p[2]^2 / 2 + t * x[1]
Gn(t, x, p) = t * p[1] + x[1] * x[2]

flow = Flow(Hamiltonian(Hn; is_autonomous=false); reltol=1e-12, abstol=1e-12)
G_along(t) = Gn(t, flow(0.0, x, p, t)...)

t, h = 0.5, 1e-4
xt, pt = flow(0.0, x, p, t)
lhs = (G_along(t + h) - G_along(t - h)) / 2h
rhs = ∂ₜ(Gn)(t, xt, pt) + Poisson(Hn, Gn; is_autonomous=false)(t, xt, pt)
lhs, rhs
```

```@example main
@assert isapprox(lhs, rhs; rtol=1e-6)   # hide
nothing                                 # hide
```

In particular, an autonomous $H$ is constant along its extremals, since $\{H, H\} = 0$.

## [Application: singular controls](@id geometry-poisson-singular)

Take a system $\dot x = F_0(x) + u F_1(x)$, whose pseudo-Hamiltonian
$H = H_0 + u H_1$ is linear in $u$, with $H_i = \langle p, F_i(x) \rangle$, the lifts of
$F_i$. The control maximises $H$, so it is given by the sign of the **switching function**
$H_1$, except on an arc where $H_1$ vanishes: a **singular arc**. There, the time derivatives
of $H_1$ vanish too. By the formula above, with $H$ autonomous,

```math
\frac{\mathrm{d}}{\mathrm{d}t} H_1 = \{H_0 + u H_1, H_1\} = H_{01}, \qquad
\frac{\mathrm{d}}{\mathrm{d}t} H_{01} = \{H_0 + u H_1, H_{01}\} = H_{001} + u\, H_{101},
```

where $H_{01} = \{H_0, H_1\}$, $H_{001} = \{H_0, H_{01}\}$ and $H_{101} = \{H_1, H_{01}\}$.
On the arc, $H_1 = H_{01} = 0$, and the second derivative gives the **singular control**

```math
u_s = -\frac{H_{001}}{H_{101}}, \qquad \text{where } H_{101} \neq 0.
```

For example, take the vehicle of [Singular control](@ref examples-singular-control):
$\dot x = \cos\theta$, $\dot y = \sin\theta + x$, $\dot\theta = u$, so
$H_0 = p_x \cos\theta + p_y (\sin\theta + x)$ and $H_1 = p_\theta$. Then

```math
H_{01} = p_x \sin\theta - p_y \cos\theta, \qquad
H_{001} = -p_y \sin\theta, \qquad
H_{101} = p_x \cos\theta + p_y \sin\theta .
```

On the singular arc, $p_\theta = 0$ and $p_y = p_x \tan\theta$, and the formula gives
$u_s = \sin^2\theta$:

```@example main
H0(q, p) = p[1] * cos(q[3]) + p[2] * (sin(q[3]) + q[1])
H1(q, p) = p[3]

H01 = Poisson(H0, H1)
H001 = Poisson(H0, H01)
H101 = Poisson(H1, H01)

q = [0.3, -0.1, 0.5]
p_s = [1.7, 1.7 * tan(q[3]), 0]   # a point where H₁ = H₀₁ = 0
H1(q, p_s), H01(q, p_s), -H001(q, p_s) / H101(q, p_s), sin(q[3])^2
```

```@example main
@assert abs(H01(q, p_s)) < 1e-12                                       # hide
@assert isapprox(-H001(q, p_s) / H101(q, p_s), sin(q[3])^2; atol=1e-12)   # hide
pq = [1.7, 1.2, -0.4]                                                  # hide
@assert H01(q, pq) ≈ pq[1] * sin(q[3]) - pq[2] * cos(q[3])             # hide
@assert H001(q, pq) ≈ -pq[2] * sin(q[3])                              # hide
@assert H101(q, pq) ≈ pq[1] * cos(q[3]) + pq[2] * sin(q[3])            # hide
nothing                                                                # hide
```

The example page integrates the extremal with this control and checks it against the direct
solution.

## Vector fields are not Hamiltonians

`Poisson` rejects a `VectorField`: lift it first, or use `ad` for the Lie bracket.

```@repl main
XV = VectorField(x -> [x[2], -x[1]]);
try # hide
Poisson(XV, x -> x[1])
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## See also

- [Lie derivative and Lie bracket](@ref geometry-ad): the brackets of vector fields, and `∂ₜ`.
- [The `@Lie` macro](@ref geometry-lie-macro): the notation `@Lie {H, G}`.
- [Singular control](@ref examples-singular-control): the singular arc above, solved.
