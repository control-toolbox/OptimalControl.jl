# [Differential geometry tools](@id manual-differential-geometry)

Optimal control theory relies on differential geometry tools to analyze Hamiltonian systems, compute singular controls, study controllability, and more. This page introduces the main operators available in OptimalControl.jl: Hamiltonian lift, Lie derivatives, Poisson brackets, Lie brackets, and partial time derivatives.

!!! note "Type qualification"
    
    Types like `Hamiltonian`, `HamiltonianLift`, `VectorField`, and `HamiltonianVectorField` are **not exported** by OptimalControl.jl. You must qualify them with `OptimalControl.` when using them (e.g., `OptimalControl.VectorField`). Functions and operators (`Lift`, `⋅`, `Lie`, `Poisson`, `@Lie`, `∂ₜ`) are exported and can be used directly.

First, import the package:

```@example main
using OptimalControl
```

## Hamiltonian lift

Given a vector field $X: \mathbb{R}^n \to \mathbb{R}^n$, its **Hamiltonian lift** is the function $H_X: \mathbb{R}^n \times (\mathbb{R}^n)^* \to \mathbb{R}$ defined by

```math
H_X(x, p) = \langle p, X(x) \rangle = \sum_{i=1}^n p_i X_i(x).
```

### From plain Julia functions

The simplest way to compute a Hamiltonian lift is from a plain Julia function. By default, the function is treated as **autonomous** (time-independent) and **non-variable** (no extra parameter):

```@example main
# Define a vector field as a Julia function
X(x) = [x[2], -x[1]]

# Compute its Hamiltonian lift
H = Lift(X)

# Evaluate at a point (x, p)
x = [1.0, 2.0]
p = [3.0, 4.0]
H(x, p)
```

The result is $H(x, p) = p_1 x_2 + p_2 (-x_1) = 3 \times 2 + 4 \times (-1) = 2$.

### From VectorField type

You can also use the `OptimalControl.VectorField` type, which allows more control over the function's properties:

```@example main
# Wrap in VectorField (autonomous, non-variable by default)
X_vf = OptimalControl.VectorField(x -> [x[2], -x[1]])
H_vf = Lift(X_vf)

# This returns a HamiltonianLift object
H_vf([1.0, 2.0], [3.0, 4.0])
```

### Non-autonomous case

For time-dependent vector fields, use `autonomous=false`:

```@example main
# Non-autonomous vector field: X(t, x) = [t*x[2], -x[1]]
X_na(t, x) = [t * x[2], -x[1]]
H_na = Lift(X_na; autonomous=false)

# Signature is now H(t, x, p)
H_na(2.0, [1.0, 2.0], [3.0, 4.0])
```

### Variable case

For vector fields depending on an additional parameter $v$, use `variable=true`:

```@example main
# Variable vector field: X(x, v) = [x[2] + v, -x[1]]
X_var(x, v) = [x[2] + v, -x[1]]
H_var = Lift(X_var; variable=true)

# Signature is now H(x, p, v)
H_var([1.0, 2.0], [3.0, 4.0], 1.0)
```

## Lie derivative

The **Lie derivative** of a function $f: \mathbb{R}^n \to \mathbb{R}$ along a vector field $X$ is defined by

```math
(X \cdot f)(x) = f'(x) \cdot X(x) = \sum_{i=1}^n \frac{\partial f}{\partial x_i}(x) X_i(x).
```

This represents the directional derivative of $f$ along $X$.

### From plain Julia functions

When using plain Julia functions, they are treated as autonomous and non-variable:

```@example main
# Vector field and scalar function
φ(x) = [x[2], -x[1]]
f(x) = x[1]^2 + x[2]^2

# Lie derivative (using dot operator)
Xf = φ ⋅ f

# Evaluate at a point
Xf([1.0, 2.0])
```

For the harmonic oscillator with $X(x) = (x_2, -x_1)$ and energy $f(x) = x_1^2 + x_2^2$:

```math
(X \cdot f)(x) = 2x_1 x_2 + 2x_2(-x_1) = 0,
```

which confirms that energy is conserved along trajectories.

### From VectorField type

```@example main
# Using VectorField type
X = OptimalControl.VectorField(x -> [x[2], -x[1]])
g(x) = x[1]^2 + x[2]^2

# Lie derivative
Xg = X ⋅ g
Xg([1.0, 2.0])
```

### Alternative syntax

The `Lie` function is equivalent to the `⋅` operator:

```@example main
# These are equivalent
result1 = X ⋅ g
result2 = Lie(X, g)

result1([1.0, 2.0]) == result2([1.0, 2.0])
```

### With keyword arguments

For non-autonomous or variable cases, use the `Lie` function with keyword arguments:

```@example main
# Non-autonomous case
φ_na(t, x) = [t + x[2], -x[1]]
f_na(t, x) = t + x[1]^2 + x[2]^2

Xf_na = Lie(φ_na, f_na; autonomous=false)
Xf_na(1.0, [1.0, 2.0])
```

```@example main
# Variable case
φ_var(x, v) = [x[2] + v, -x[1]]
f_var(x, v) = x[1]^2 + x[2]^2 + v

Xf_var = Lie(φ_var, f_var; variable=true)
Xf_var([1.0, 2.0], 1.0)
```

## Poisson bracket

For two functions $f, g: \mathbb{R}^n \times (\mathbb{R}^n)^* \to \mathbb{R}$, the **Poisson bracket** is defined by

```math
\{f, g\}(x, p) = \sum_{i=1}^n \left( \frac{\partial f}{\partial p_i} \frac{\partial g}{\partial x_i} - \frac{\partial f}{\partial x_i} \frac{\partial g}{\partial p_i} \right).
```

### Properties

The Poisson bracket satisfies:

- **Bilinearity**: $\{af + bg, h\} = a\{f, h\} + b\{g, h\}$ for scalars $a, b$
- **Antisymmetry**: $\{f, g\} = -\{g, f\}$
- **Leibniz rule**: $\{fg, h\} = f\{g, h\} + g\{f, h\}$
- **Jacobi identity**: $\{\{f, g\}, h\} + \{\{h, f\}, g\} + \{\{g, h\}, f\} = 0$

### From plain Julia functions

```@example main
# Define two Hamiltonian functions
f(x, p) = p[1] * x[2] + p[2] * x[1]
g(x, p) = x[1]^2 + p[2]^2

# Compute the Poisson bracket
bracket = Poisson(f, g)

# Evaluate at a point
x = [1.0, 2.0]
p = [3.0, 4.0]
bracket(x, p)
```

### Verify antisymmetry

```@example main
bracket_fg = Poisson(f, g)
bracket_gf = Poisson(g, f)

println("Poisson(f, g) = ", bracket_fg(x, p))
println("Poisson(g, f) = ", bracket_gf(x, p))
println("Sum = ", bracket_fg(x, p) + bracket_gf(x, p))
```

### From Hamiltonian type

```@example main
# Wrap in Hamiltonian type
F = OptimalControl.Hamiltonian(f)
G = OptimalControl.Hamiltonian(g)

bracket_HH = Poisson(F, G)
bracket_HH(x, p)
```

### With keyword arguments

```@example main
# Non-autonomous case
f_na(t, x, p) = t + p[1] * x[2] + p[2] * x[1]
g_na(t, x, p) = t^2 + x[1]^2 + p[2]^2

bracket_na = Poisson(f_na, g_na; autonomous=false)
bracket_na(1.0, [1.0, 2.0], [3.0, 4.0])
```

### Relation to Hamiltonian vector fields

The Poisson bracket is closely related to the Lie derivative. If $\vec{H} = (\nabla_p H, -\nabla_x H)$ denotes the Hamiltonian vector field associated to $H$, then

```math
\{H, G\} = \vec{H} \cdot G.
```

This means the Poisson bracket of $H$ and $G$ equals the Lie derivative of $G$ along the Hamiltonian vector field of $H$.

### Poisson bracket of Hamiltonian lifts

When computing the Poisson bracket of two Hamiltonian lifts, the result is the Hamiltonian lift of the Lie bracket of the underlying vector fields:

```@example main
# Two vector fields
X(x) = [x[1]^2, x[2]^2]
Y(x) = [x[2], -x[1]]

# Their Hamiltonian lifts
HX = Lift(X)
HY = Lift(Y)

# Poisson bracket of lifts
bracket_lifts = Poisson(HX, HY)
bracket_lifts([1.0, 2.0], [3.0, 4.0])
```

This satisfies: $\{H_X, H_Y\} = H_{[X,Y]}$ where $[X,Y]$ is the Lie bracket of vector fields (see next section).

## Lie bracket of vector fields

For two vector fields $X, Y: \mathbb{R}^n \to \mathbb{R}^n$, the **Lie bracket** is the vector field $[X, Y]$ defined by

```math
[X, Y](x) = Y'(x) \cdot X(x) - X'(x) \cdot Y(x),
```

where $X'(x)$ denotes the Jacobian matrix of $X$ at $x$.

### From VectorField type

```@example main
# Define two vector fields
X = OptimalControl.VectorField(x -> [x[2], -x[1]])
Y = OptimalControl.VectorField(x -> [x[1], x[2]])

# Compute the Lie bracket
Z = Lie(X, Y)

# Evaluate at a point
Z([1.0, 2.0])
```

### Relation to Poisson brackets

If $H_X = \text{Lift}(X)$ and $H_Y = \text{Lift}(Y)$ are the Hamiltonian lifts, then:

```math
\{H_X, H_Y\} = H_{[X,Y]}.
```

Let's verify this numerically:

```@example main
# Hamiltonian lifts
HX = Lift(x -> X(x))
HY = Lift(x -> Y(x))

# Poisson bracket of the lifts
bracket_XY = Poisson(HX, HY)

# Lift of the Lie bracket
HZ = Lift(x -> Z(x))

# Compare at a point
x = [1.0, 2.0]
p = [3.0, 4.0]

println("Poisson bracket: ", bracket_XY(x, p))
println("Lift of Lie bracket: ", HZ(x, p))
```

## The `@Lie` macro

The `@Lie` macro provides a convenient syntax for computing Lie brackets (for vector fields) and Poisson brackets (for Hamiltonians).

### Lie brackets with VectorField

```@example main
# Define vector fields
F1 = OptimalControl.VectorField(x -> [0, -x[3], x[2]])
F2 = OptimalControl.VectorField(x -> [x[3], 0, -x[1]])

# Compute Lie bracket using macro
L = @Lie [F1, F2]

# Evaluate
L([1.0, 2.0, 3.0])
```

### Nested Lie brackets

```@example main
F3 = OptimalControl.VectorField(x -> [x[1], x[2], x[3]])
nested = @Lie [[F1, F2], F3]
nested([1.0, 2.0, 3.0])
```

### Poisson brackets from plain functions

For Hamiltonian functions (plain Julia functions), use curly braces `{_, _}`:

```@example main
# Define Hamiltonian functions
H0(x, p) = p[1] * x[2] + p[2] * (-x[1])
H1(x, p) = p[2]

# Compute Poisson bracket
H01 = @Lie {H0, H1}

# Evaluate
H01([1.0, 2.0], [3.0, 4.0])
```

### Iterated Poisson brackets

The macro is particularly useful for computing iterated brackets, which appear in singular control analysis:

```@example main
# First-order bracket
H01 = @Lie {H0, H1}

# Second-order brackets
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}

# Evaluate
x = [1.0, 2.0]
p = [3.0, 4.0]

println("H01(x, p) = ", H01(x, p))
println("H001(x, p) = ", H001(x, p))
println("H101(x, p) = ", H101(x, p))
```

These iterated brackets are used to compute singular controls. For a pseudo-Hamiltonian of the form $H = H_0 + u H_1$, if the switching function $H_1$ vanishes on an interval (singular arc), the control is given by

```math
u_s = -\frac{H_{001}}{H_{101}},
```

provided $H_{101} \neq 0$. See the [singular control example](@ref example-singular-control) for a complete application.

### With keyword arguments

For non-autonomous functions, specify `autonomous=false`:

```@example main
# Non-autonomous Hamiltonians
H0_na(t, x, p) = t + p[1] * x[2] + p[2] * (-x[1])
H1_na(t, x, p) = p[2]

# Poisson bracket with keyword
H01_na = @Lie {H0_na, H1_na} autonomous=false

# Evaluate
H01_na(1.0, [1.0, 2.0], [3.0, 4.0])
```

### Poisson brackets from Hamiltonian type

```@example main
# Using Hamiltonian type
H1_ham = OptimalControl.Hamiltonian((x, p) -> x[1]^2 + p[2]^2)
H2_ham = OptimalControl.Hamiltonian((x, p) -> x[2]^2 + p[1]^2)

# Macro works with Hamiltonian objects too
P = @Lie {H1_ham, H2_ham}
P([1.0, 1.0], [3.0, 2.0])
```

## Partial time derivative

For non-autonomous functions $f(t, x, \ldots)$, the **partial derivative with respect to time** is computed using the `∂ₜ` operator:

```math
(\partial_t f)(t, x, \ldots) = \frac{\partial f}{\partial t}(t, x, \ldots).
```

### Basic usage

```@example main
# Define a time-dependent function
f(t, x) = t * x

# Compute partial time derivative
df = ∂ₜ(f)

# Evaluate
df(0, 8)
```

```@example main
df(2, 3)
```

### More complex example

```@example main
# Function with multiple arguments
g(t, x, p) = t^2 + x[1] * p[1] + x[2] * p[2]

# Partial derivative
dg = ∂ₜ(g)

# At t=3, ∂g/∂t = 2t = 6
dg(3, [1.0, 2.0], [4.0, 5.0])
```

### Relation to total time derivative

For a non-autonomous Hamiltonian $H(t, x, p)$ and a function $G(t, x, p)$, the **total time derivative** along the Hamiltonian flow is:

```math
\frac{d}{dt} G(t, x(t), p(t)) = \partial_t G + \{H, G\}.
```

This is the sum of:
- The **partial time derivative** $\partial_t G$ (explicit time dependence)
- The **Poisson bracket** $\{H, G\}$ (evolution along the flow)

This relation is fundamental in non-autonomous optimal control theory.

## Summary

| Function/Operator | Mathematical notation | Julia syntax |
|-------------------|----------------------|--------------|
| Hamiltonian lift | $H_X(x,p) = \langle p, X(x) \rangle$ | `H = Lift(X)` |
| Lie derivative | $(X \cdot f)(x) = f'(x) \cdot X(x)$ | `X ⋅ f` or `Lie(X, f)` |
| Poisson bracket | $\{f,g\}(x,p) = \langle \nabla_p f, \nabla_x g \rangle - \langle \nabla_x f, \nabla_p g \rangle$ | `Poisson(f, g)` or `@Lie {f, g}` |
| Lie bracket | $[X,Y](x) = Y'(x) X(x) - X'(x) Y(x)$ | `Lie(X, Y)` or `@Lie [X, Y]` |
| Partial time derivative | $\partial_t f(t, x, \ldots)$ | `∂ₜ(f)` |

## See also

- [Compute flows from Hamiltonians and others](@ref manual-flow-others) — Using flows with Hamiltonian vector fields
- [Singular control example](@ref example-singular-control) — Application to computing singular controls
- [Goddard tutorial](@extref Tutorials tutorial-goddard) — Complex example with bang, singular, and boundary arcs
