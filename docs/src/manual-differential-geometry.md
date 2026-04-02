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
x = [1, 2]
p = [3, 4]
H(x, p)
```

The result is $H(x, p) = p_1 x_2 + p_2 (-x_1) = 3 \times 2 + 4 \times (-1) = 2$.

### From VectorField type

You can also use the `OptimalControl.VectorField` type, which allows more control over the function's properties:

```@example main-1
using OptimalControl # hide
# Wrap in VectorField (autonomous, non-variable by default)
X = OptimalControl.VectorField(x -> [x[2], -x[1]])
H = Lift(X)

# This returns a HamiltonianLift object
H([1, 2], [3, 4])
```

### Non-autonomous case

For time-dependent vector fields, use `autonomous=false`:

```@example main-2
using OptimalControl # hide
# Non-autonomous vector field: X(t, x) = [t*x[2], -x[1]]
X(t, x) = [t * x[2], -x[1]]
H = Lift(X; autonomous=false)

# Signature is now H(t, x, p)
H(2, [1, 2], [3, 4])
```

### Variable case

For vector fields depending on an additional parameter $v$, use `variable=true`:

```@example main-3
using OptimalControl # hide
# Variable vector field: X(x, v) = [x[2] + v, -x[1]]
X(x, v) = [x[2] + v, -x[1]]
H = Lift(X; variable=true)

# Signature is now H(x, p, v)
H([1, 2], [3, 4], 1)
```

## Lie derivative

The **Lie derivative** of a function $f: \mathbb{R}^n \to \mathbb{R}$ along a vector field $X$ is defined by

```math
(X \cdot f)(x) = f'(x) \cdot X(x) = \sum_{i=1}^n \frac{\partial f}{\partial x_i}(x) X_i(x).
```

This represents the directional derivative of $f$ along $X$.

### [From plain Julia functions](@id lie-from-functions)

When using plain Julia functions, they are treated as autonomous and non-variable:

```@example main-4
using OptimalControl # hide
# Vector field and scalar function
X(x) = [x[2], -x[1]]
f(x) = x[1]^2 + x[2]^2

# Lie derivative (using dot operator)
Xf = X ⋅ f

# Evaluate at a point
Xf([1, 2])
```

For the harmonic oscillator with $X(x) = (x_2, -x_1)$ and energy $f(x) = x_1^2 + x_2^2$:

```math
(X \cdot f)(x) = 2x_1 x_2 + 2x_2(-x_1) = 0,
```

which confirms that energy is conserved along trajectories.

### [From VectorField type](@id lie-from-vectorfield)

```@example main-5
using OptimalControl # hide
# Using VectorField type
X = OptimalControl.VectorField(x -> [x[2], -x[1]])
g(x) = x[1]^2 + x[2]^2

# Lie derivative
Xg = X ⋅ g
Xg([1, 2])
```

### Alternative syntax

The `Lie` function is equivalent to the `⋅` operator:

```@example main-5
# These are equivalent
Xg1 = X ⋅ g
Xg2 = Lie(X, g)

Xg1([1, 2]) == Xg2([1, 2])
```

### With keyword arguments

For non-autonomous or variable cases, use the `Lie` function with keyword arguments:

```@example main-6
using OptimalControl # hide
# Non-autonomous case
X(t, x) = [t + x[2], -x[1]]
f(t, x) = t + x[1]^2 + x[2]^2

Xf = Lie(X, f; autonomous=false)
Xf(1, [1, 2])
```

```@example main-7
using OptimalControl # hide
# Variable case
X(x, v) = [x[2] + v, -x[1]]
f(x, v) = x[1]^2 + x[2]^2 + v

Xf = Lie(X, f; variable=true)
Xf([1, 2], 1)
```

### With VectorField type

You can also create the VectorField explicitly with the keywords, then use it without keywords in the Lie function:

```@example main-7a
using OptimalControl # hide
# Non-autonomous VectorField created with keywords
X = OptimalControl.VectorField((t, x) -> [t + x[2], -x[1]]; autonomous=false)
f(t, x) = t + x[1]^2 + x[2]^2

# No keywords needed here - the VectorField already knows its properties
Xf = Lie(X, f)
Xf(1, [1, 2])
```

```@example main-7b
using OptimalControl # hide
# Variable VectorField created with keywords
X = OptimalControl.VectorField((x, v) -> [x[2] + v, -x[1]]; variable=true)
f(x, v) = x[1]^2 + x[2]^2 + v

# No keywords needed here
Xf = Lie(X, f)
Xf([1, 2], 1)
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

### [From plain Julia functions](@id poisson-from-functions)

```@example main-8
using OptimalControl # hide
# Define two Hamiltonian functions
f(x, p) = p[1] * x[2] + p[2] * x[1]
g(x, p) = x[1]^2 + p[2]^2

# Compute the Poisson bracket
H = Poisson(f, g)

# Evaluate at a point
x = [1, 2]
p = [3, 4]
H(x, p)
```

### Verify antisymmetry

```@example main-8
Hfg = Poisson(f, g)
Hgf = Poisson(g, f)

println("Poisson(f, g) = ", Hfg(x, p))
println("Poisson(g, f) = ", Hgf(x, p))
println("Sum = ", Hfg(x, p) + Hgf(x, p))
```

### From Hamiltonian type

```@example main-8
# Wrap in Hamiltonian type
F = OptimalControl.Hamiltonian(f)
G = OptimalControl.Hamiltonian(g)

H = Poisson(F, G)
H(x, p)
```

### [With keyword arguments](@id poisson-kwargs)

```@example main-9
using OptimalControl # hide
# Non-autonomous case
f(t, x, p) = t + p[1] * x[2] + p[2] * x[1]
g(t, x, p) = t^2 + x[1]^2 + p[2]^2

H = Poisson(f, g; autonomous=false)
H(1, [1, 2], [3, 4])
```

### With Hamiltonian type and keywords

You can also create Hamiltonian objects explicitly with keywords, then use them without keywords in the Poisson function. **Important**: both Hamiltonians must have the same time and variable dependencies:

```@example main-9a
using OptimalControl # hide
# Non-autonomous Hamiltonians created with keywords
f(t, x, p) = t + p[1] * x[2] + p[2] * x[1]
g(t, x, p) = t^2 + x[1]^2 + p[2]^2

F = OptimalControl.Hamiltonian(f; autonomous=false)
G = OptimalControl.Hamiltonian(g; autonomous=false)

# No keywords needed here - both Hamiltonians are already non-autonomous
H = Poisson(F, G)
H(1, [1, 2], [3, 4])
```

```@example main-9b
using OptimalControl # hide
# Variable Hamiltonians created with keywords
f(x, p, v) = x[1]^2 + p[2]^2 + v
g(x, p, v) = x[2]^2 + p[1]^2 + 2*v

F = OptimalControl.Hamiltonian(f; variable=true)
G = OptimalControl.Hamiltonian(g; variable=true)

# Both are variable, so the Poisson bracket is also variable
H = Poisson(F, G)
H([1, 2], [3, 4], 1)
```

### Relation to Hamiltonian vector fields

The Poisson bracket is closely related to the Lie derivative. If $\vec{H} = (\nabla_p H, -\nabla_x H)$ denotes the Hamiltonian vector field associated to $H$, then

```math
\{H, G\} = \vec{H} \cdot G.
```

This means the Poisson bracket of $H$ and $G$ equals the Lie derivative of $G$ along the Hamiltonian vector field of $H$.

### Poisson bracket of Hamiltonian lifts

When computing the Poisson bracket of two Hamiltonian lifts, the result is the Hamiltonian lift of the Lie bracket of the underlying vector fields:

```@example main-10
using OptimalControl # hide
# Two vector fields
X(x) = [x[1]^2, x[2]^2]
Y(x) = [x[2], -x[1]]

# Their Hamiltonian lifts
HX = Lift(X)
HY = Lift(Y)

# Poisson bracket of lifts
H = Poisson(HX, HY)
H([1, 2], [3, 4])
```

This satisfies: $\{H_X, H_Y\} = H_{[X,Y]}$ where $[X,Y]$ is the Lie bracket of vector fields (see next section).

## Lie bracket of vector fields

For two vector fields $X, Y: \mathbb{R}^n \to \mathbb{R}^n$, the **Lie bracket** is the vector field $[X, Y]$ defined by

```math
[X, Y](x) = Y'(x) \cdot X(x) - X'(x) \cdot Y(x),
```

where $X'(x)$ denotes the Jacobian matrix of $X$ at $x$.

### [From VectorField type](@id bracket-from-vectorfield)

```@example main-11
using OptimalControl # hide
# Define two vector fields
X = OptimalControl.VectorField(x -> [x[2], -x[1]])
Y = OptimalControl.VectorField(x -> [x[1], x[2]])

# Compute the Lie bracket
Z = Lie(X, Y)

# Evaluate at a point
Z([1, 2])
```

### Relation to Poisson brackets

If $H_X = \text{Lift}(X)$ and $H_Y = \text{Lift}(Y)$ are the Hamiltonian lifts, then:

```math
\{H_X, H_Y\} = H_{[X,Y]}.
```

Let's verify this numerically:

```@example main-11
# Hamiltonian lifts
HX = Lift(x -> X(x))
HY = Lift(x -> Y(x))

# Poisson bracket of the lifts
HXY = Poisson(HX, HY)

# Lift of the Lie bracket
HZ = Lift(x -> Z(x))

# Compare at a point
x = [1, 2]
p = [3, 4]

println("Poisson bracket: ", HXY(x, p))
println("Lift of Lie bracket: ", HZ(x, p))
```

## The `@Lie` macro

The `@Lie` macro provides a convenient syntax for computing Lie brackets (for vector fields) and Poisson brackets (for Hamiltonians).

!!! warning "Important distinction"

    - **Square brackets `[...]`** denote **Lie brackets** and work with:
        - `VectorField` objects
        - Plain Julia functions (automatically wrapped as `VectorField`)
    - **Curly braces `{...}`** denote **Poisson brackets** and work with:
        - Plain Julia functions (automatically wrapped as `Hamiltonian`)
        - `Hamiltonian` objects

    When using **only plain functions** (no `VectorField` or `Hamiltonian` objects), specify `autonomous` and/or `variable` keywords as needed to match your function signature. Keywords are optional - if not specified, they use the default values (`autonomous=true`, `variable=false`). If you mix plain functions with `VectorField` or `Hamiltonian` objects, the keywords are inferred from the `VectorField` or `Hamiltonian` objects.

### Lie brackets with VectorField

```@example main-12
using OptimalControl # hide
# Define vector fields
F1 = OptimalControl.VectorField(x -> [0, -x[3], x[2]])
F2 = OptimalControl.VectorField(x -> [x[3], 0, -x[1]])

# Compute Lie bracket using macro
F12 = @Lie [F1, F2]

# Evaluate
F12([1, 2, 3])
```

### Nested Lie brackets

```@example main-12
F3 = OptimalControl.VectorField(x -> [x[1], x[2], x[3]])
F123 = @Lie [[F1, F2], F3]
F123([1, 2, 3])
```

### Lie brackets with plain Julia functions

You can also use plain Julia functions directly with the `@Lie` macro. The functions will be automatically wrapped in `VectorField` objects:

```@example main-12a
using OptimalControl # hide
# Define plain Julia functions
X(x) = [x[2], -x[1]]
Y(x) = [x[1], x[2]]

# Compute Lie bracket using macro with plain functions
Z = @Lie [X, Y]

# Evaluate
Z([1, 2])
```

### With keyword arguments for plain functions

For non-autonomous or variable cases, specify the keywords:

```@example main-12b
using OptimalControl # hide
# Non-autonomous plain functions
X(t, x) = [t + x[2], -x[1]]
Y(t, x) = [x[1], t*x[2]]

# Use autonomous=false keyword
Z = @Lie [X, Y] autonomous=false
Z(1, [1, 2])
```

```@example main-12c
using OptimalControl # hide
# Variable plain functions
X(x, v) = [x[2] + v, -x[1]]
Y(x, v) = [x[1], x[2] + v]

# Use variable=true keyword
Z = @Lie [X, Y] variable=true
Z([1, 2], 1)
```

### Nested brackets with plain functions

```@example main-12d
using OptimalControl # hide
X(x) = [0, -x[3], x[2]]
Y(x) = [x[3], 0, -x[1]]
Z(x) = [x[1], x[2], x[3]]

# Nested Lie brackets
nested = @Lie [[X, Y], Z]
nested([1, 2, 3])
```

!!! tip "Plain functions vs VectorField"

    Using plain functions with `@Lie [X, Y]` is convenient for quick computations. However, if you need to reuse the same vector field multiple times or want explicit control over the autonomy/variability, consider creating `VectorField` objects explicitly:

    ```julia
    # Explicit VectorField (keywords at creation)
    X = OptimalControl.VectorField((t, x) -> [t + x[2], -x[1]]; autonomous=false)
    Y = OptimalControl.VectorField((t, x) -> [x[1], t*x[2]]; autonomous=false)
    Z = @Lie [X, Y]  # No keywords needed

    # Plain functions (keywords at macro call)
    X(t, x) = [t + x[2], -x[1]]
    Y(t, x) = [x[1], t*x[2]]
    Z = @Lie [X, Y] autonomous=false
    ```

### Poisson brackets from plain functions

For Hamiltonian functions (plain Julia functions), use curly braces `{_, _}`:

```@example main-13
using OptimalControl # hide
# Define Hamiltonian functions
H0(x, p) = p[1] * x[2] + p[2] * (-x[1])
H1(x, p) = p[2]

# Compute Poisson bracket
H01 = @Lie {H0, H1}

# Evaluate
H01([1, 2], [3, 4])
```

### Iterated Poisson brackets

The macro is particularly useful for computing iterated brackets, which appear in singular control analysis:

```@example main-13
# First-order bracket
H01 = @Lie {H0, H1}

# Second-order brackets
H001 = @Lie {H0, H01}
H101 = @Lie {H1, H01}

# Evaluate
x = [1, 2]
p = [3, 4]

println("H01(x, p) = ", H01(x, p))
println("H001(x, p) = ", H001(x, p))
println("H101(x, p) = ", H101(x, p))
```

These iterated brackets are used to compute singular controls. For a pseudo-Hamiltonian of the form $H = H_0 + u H_1$, if the switching function $H_1$ vanishes on an interval (singular arc), the control is given by

```math
u_s = -\frac{H_{001}}{H_{101}},
```

provided $H_{101} \neq 0$. See the [singular control example](@ref example-singular-control) for a complete application.

### [With keyword arguments](@id macro-kwargs)

For non-autonomous functions, specify `autonomous=false`:

```@example main-14
using OptimalControl # hide
# Non-autonomous Hamiltonians
H0(t, x, p) = t + p[1] * x[2] + p[2] * (-x[1])
H1(t, x, p) = p[2]

# Poisson bracket with keyword
H01 = @Lie {H0, H1} autonomous=false

# Evaluate
H01(1, [1, 2], [3, 4])
```

### Poisson brackets from Hamiltonian type

```@example main-15
using OptimalControl # hide
# Using Hamiltonian type
H1 = OptimalControl.Hamiltonian((x, p) -> x[1]^2 + p[2]^2)
H2 = OptimalControl.Hamiltonian((x, p) -> x[2]^2 + p[1]^2)

# Macro works with Hamiltonian objects too
H12 = @Lie {H1, H2}
H12([1, 1], [3, 2])
```

## Partial time derivative

For non-autonomous functions $f(t, x, \ldots)$, the **partial derivative with respect to time** is computed using the `∂ₜ` operator:

```math
(\partial_t f)(t, x, \ldots) = \frac{\partial f}{\partial t}(t, x, \ldots).
```

### Basic usage

```@example main-16
using OptimalControl # hide
# Define a time-dependent function
f(t, x) = t * x

# Compute partial time derivative
df = ∂ₜ(f)

# Evaluate
df(0, 8)
```

```@example main-16
df(2, 3)
```

### More complex example

```@example main-17
using OptimalControl # hide
# Function with multiple arguments
g(t, x, p) = t^2 + x[1] * p[1] + x[2] * p[2]

# Partial derivative
dg = ∂ₜ(g)

# At t=3, ∂g/∂t = 2t = 6
dg(3, [1, 2], [4, 5])
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
| ----------------- | --------------------- | ------------ |
| Hamiltonian lift | $H_X(x,p) = \langle p, X(x) \rangle$ | `H = Lift(X)` |
| Lie derivative | $(X \cdot f)(x) = f'(x) \cdot X(x)$ | `X ⋅ f` or `Lie(X, f)` |
| Poisson bracket | $\{f,g\}(x,p) = \langle \nabla_p f, \nabla_x g \rangle - \langle \nabla_x f, \nabla_p g \rangle$ | `Poisson(f, g)` or `@Lie {f, g}` |
| Lie bracket | $[X,Y](x) = Y'(x) X(x) - X'(x) Y(x)$ | `Lie(X, Y)` or `@Lie [X, Y]` |
| Partial time derivative | $\partial_t f(t, x, \ldots)$ | `∂ₜ(f)` |

## See also

- [Compute flows from Hamiltonians and others](@ref manual-flow-others) — Using flows with Hamiltonian vector fields
- [Singular control example](@ref example-singular-control) — Application to computing singular controls
- [Goddard tutorial](@extref Tutorials tutorial-goddard) — Complex example with bang, singular, and boundary arcs
