# [Lift](@id geometry-lift)

Given a vector field $X : \mathbb{R}^n \to \mathbb{R}^n$, its **Hamiltonian lift** is the
function $H_X : \mathbb{R}^n \times (\mathbb{R}^n)^* \to \mathbb{R}$ defined by

```math
H_X(x, p) = \langle p, X(x) \rangle = \sum_{i=1}^n p_i X_i(x).
```

It is an algebraic construction: no derivative is computed.

```@example main
using OptimalControl
using OrdinaryDiffEqTsit5
```

## From a plain function

```@example main
X(x) = [x[2], -x[1]]
H = Lift(X)

x, p = [1.0, 2.0], [3.0, 4.0]
H(x, p)   # 3 × 2 + 4 × (-1)
```

The lift of a plain function is a function, not a `Hamiltonian`:

```@example main
H isa Function, H isa AbstractHamiltonian
```

## From a typed vector field

The lift of a `VectorField` is a `Hamiltonian`, with the same dependence on time and on the
variable as the vector field:

```@example main
XV = VectorField(x -> [x[2], -x[1]])
HV = Lift(XV)
HV isa AbstractHamiltonian, HV(x, p)
```

## Time and variable

For a vector field $X(t, x)$, pass `is_autonomous=false`, and the lift is called as
$H(t, x, p)$. With $X(t, x) = (t x_2, -x_1)$, $H(2, x, p) = 3 \times 4 + 4 \times (-1) = 8$:

```@example main
Ht = Lift((t, x) -> [t * x[2], -x[1]]; is_autonomous=false)
Ht(2.0, x, p)
```

For a vector field $X(x, v)$, pass `is_variable=true`, and the lift is called as
$H(x, p, v)$. With $X(x, v) = (x_2 + v, -x_1)$, $H(x, p, 1) = 3 \times 3 + 4 \times (-1) = 5$:

```@example main
Hv = Lift((x, v) -> [x[2] + v, -x[1]]; is_variable=true)
Hv(x, p, 1.0)
```

```@example main
@assert H(x, p) == 2 && HV(x, p) == 2 && Ht(2.0, x, p) == 8 && Hv(x, p, 1.0) == 5   # hide
@assert H isa Function && !(H isa AbstractHamiltonian) && HV isa AbstractHamiltonian  # hide
nothing                                                                              # hide
```

| You lift | You get | Called as |
| --- | --- | --- |
| a function `X` | a function (`OptimalControl.LiftedHamiltonianFunction`) | `H(x, p)`, `H(t, x, p)`, `H(x, p, v)` or `H(t, x, p, v)`, from the keywords |
| a `VectorField` | a `Hamiltonian` | the same, from the traits of the vector field |

## The flow of a lift

The Hamiltonian flow of $H_X$ integrates $\dot x = X(x)$ together with the adjoint equation
$\dot p = -X'(x)^{\top} p$. For $X(x) = -x$, this gives $x(t) = e^{-t} x_0$ and
$p(t) = e^{t} p_0$. A `Hamiltonian` is needed to build the flow (see
[From Hamiltonians](@ref flows-from-hamiltonians)), so lift a `VectorField`, or wrap the
lift of a function in `Hamiltonian`:

```@example main
f = Flow(Lift(VectorField(x -> -x)))
xf, pf = f(0, x, p, 1)
```

```@example main
@assert isapprox(xf, exp(-1) * x; rtol=1e-6) && isapprox(pf, exp(1) * p; rtol=1e-6)   # hide
@assert all(Flow(Hamiltonian(Lift(x -> -x)))(0, x, p, 1) .≈ (xf, pf))                 # hide
nothing                                                                               # hide
```

The lift is also the bridge between the two brackets:
$\{H_X, H_Y\} = H_{[X, Y]}$ (see [The bridge identity](@ref geometry-overview-bridge)).

## A Hamiltonian vector field cannot be lifted

A `HamiltonianVectorField` already lives on the cotangent space, so `Lift` rejects it. The
message names `ad` instead of `Lift`
([CTLie#41](https://github.com/control-toolbox/CTLie.jl/issues/41)):

```@repl main
try # hide
Lift(HamiltonianVectorField((x, p) -> (p, -x)))
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

## See also

- [Geometry overview](@ref geometry-overview): the summary of the operations.
- [Poisson bracket](@ref geometry-poisson): the brackets of lifts.
- [From Hamiltonians](@ref flows-from-hamiltonians): flows built from a Hamiltonian.
