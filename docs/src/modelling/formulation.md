# [Formulation](@id modelling-formulation)

This page fixes the mathematical setting and the notation used throughout the documentation.
The [`@def` syntax](@ref modelling-abstract-syntax) and the
[functional API](@ref modelling-functional-api) both transcribe it into code.

## The problem

An optimal control problem (OCP) with fixed initial and final times consists in minimising
the cost functional, written in **Bolza form**,

```math
J(x, u) = g(x(t_0), x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))\,\mathrm{d}t,
```

where the **state** $x(t) \in \mathbb{R}^n$ and the **control** $u(t) \in \mathbb{R}^m$ are
functions of time $t \in [t_0, t_f]$. They are subject to the differential constraint (the
**dynamics**)

```math
\dot{x}(t) = f(t, x(t), u(t))
```

and to other constraints such as

```math
\begin{array}{llcll}
x_{\mathrm{lower}} & \le & x(t)              & \le & x_{\mathrm{upper}}, \\
u_{\mathrm{lower}} & \le & u(t)              & \le & u_{\mathrm{upper}}, \\
c_{\mathrm{lower}} & \le & c(t, x(t), u(t))  & \le & c_{\mathrm{upper}}, \\
b_{\mathrm{lower}} & \le & b(x(t_0), x(t_f)) & \le & b_{\mathrm{upper}}.
\end{array}
```

The first two lines are **box constraints**, $c$ is a **path constraint**, and $b$ gathers the
**boundary conditions**. An equality constraint is the case where both bounds are equal.

If $g = 0$, the cost is said to be in **Lagrange form**; if $f^0 = 0$, it is in **Mayer form**.
Maximising $J$ is the same as minimising $-J$, so a cost can be written with `→ max` as well.

When $f^0$, $f$ and $c$ do not depend on $t$ explicitly, the problem is **autonomous**. See
[Time dependence](@ref modelling-inspect-time-dependence) for how to check it on a model.

## Free times and extra variables

The initial time $t_0$ and the final time $t_f$ may also be free, that is, part of the
optimisation variables:

```math
J(x, u, t_0, t_f) \to \min.
```

More generally, a vector $v \in \mathbb{R}^q$ of $q$ additional **variables** can be optimised
together with $x$ and $u$. It may contain $t_0$, $t_f$, or any other free parameter, and the
cost, the dynamics and the constraints may all depend on it:

```math
J(x, u, v) = g(x(t_0), x(t_f), v) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t), v)\,\mathrm{d}t \to \min,
```

```math
\dot{x}(t) = f(t, x(t), u(t), v),
```

with, in addition, box constraints on $v$:

```math
v_{\mathrm{lower}} \le v \le v_{\mathrm{upper}}.
```

## The control-free case

Nothing above requires a control: taking $m = 0$ (no $u$) is a legitimate degenerate case. It
is used to fit or optimise the parameters $v$ of a dynamical system rather than to steer it.
See [Control-free problems](@ref modelling-without-control) for how to declare and solve such problems.

## [Notation and conventions](@id modelling-formulation-conventions)

The pages on the indirect method ([Flows](@ref flows-overview), [Geometry](@ref geometry-overview)
and the [examples](@ref examples-gallery)) use the following conventions. They refer to this
section rather than redefine them.

**Dimensions.** $x(t) \in \mathbb{R}^n$, $u(t) \in \mathbb{R}^m$, $v \in \mathbb{R}^q$. A
dimension-one quantity is a scalar, in the mathematics as in the code.

**Pseudo-Hamiltonian.** With the costate $p(t) \in \mathbb{R}^n$ and the constant $p^0$,

```math
H(t, x, p, u, v) = p \cdot f(t, x, u, v) + p^0 f^0(t, x, u, v).
```

The sign of $p^0$ depends on the sense of the criterion: $p^0 \le 0$ for a minimisation and
$p^0 \ge 0$ for a maximisation. The normal case is $p^0 = -1$ for `→ min` and $p^0 = +1$ for
`→ max`; $p^0 = 0$ is the abnormal case. In the code, $H$ is a `PseudoHamiltonian`.

!!! info "Sign conventions"

    The pseudo-Hamiltonian is **always maximised**, for a minimisation as for a
    maximisation: only $p^0$ changes with the sense of the criterion. Since $p^0 f^0$ is the
    same for $\min \int f^0$ ($p^0 = -1$) and for $\max \int (-f^0)$ ($p^0 = +1$), the two
    problems have the same control, the same costate and the same multipliers: **the costate
    and the duals do not change sign with the sense of the criterion**. The other choice
    ($p^0 = -1$ always, with $H$ minimised for a maximisation) would flip them.

    The same convention holds for the constraints, whatever the method (direct or
    indirect): an inequality has a non-negative multiplier, however it is written, while an
    equality or a two-sided constraint has a signed multiplier (see *State constraints*
    below for how a constraint is normalised, and
    [Dual variables](@ref results-solution-duals) for the signs of the duals of a solution).

    These are the conventions of the control-toolbox ecosystem
    ([ct-conventions](https://github.com/control-toolbox/ct-conventions), rules `SGN1`–`SGN5`).

**Maximum principle.** Along an optimal trajectory, the control **maximises** $H$. When this
maximisation gives the control in feedback form $u(t, x, p, v)$, the **maximised Hamiltonian** is

```math
\mathbf{H}(t, x, p, v) = H(t, x, p, u(t, x, p, v), v),
```

a `Hamiltonian` in the code. The same notation is used for the Hamiltonian of any control law
$u(t, x, p, v)$, maximising or not (see [Hamiltonians of a problem](@ref modelling-hamiltonians)).
Its **Hamiltonian vector field**
$\vec{\mathbf{H}} = (\nabla_p \mathbf{H}, -\nabla_x \mathbf{H})$ gives the extremals:

```math
\dot{x}(t) = \nabla_p \mathbf{H}(t, x(t), p(t), v), \qquad
\dot{p}(t) = -\nabla_x \mathbf{H}(t, x(t), p(t), v).
```

**State constraints.** A state constraint is a path constraint that does not depend on the
control. For the maximum principle, it is put in the normalised form $c(x) \ge 0$: a
constraint declared as $c(x) \le 0$ or as an upper bound $x_i \le a$ becomes $-c(x) \ge 0$ or
$a - x_i \ge 0$, and a lower bound $x_i \ge a$ becomes $x_i - a \ge 0$. Along a boundary
arc, where $c(x(t)) = 0$, the pseudo-Hamiltonian gains the term $+\,\mu\, c(x)$, with a
multiplier $\mu \ge 0$:

```math
H(t, x, p, u, v) = p \cdot f(t, x, u, v) + p^0 f^0(t, x, u, v) + \mu\, c(x).
```

The sign of $\mu$ does not depend on how the constraint is written, nor on the sense of the
criterion. For a constraint with a single finite bound, $\mu$ is also the dual of the
solution. An equality, or a constraint with two finite bounds, is adjoined with the signed
multiplier $\mu_{\mathrm{ub}} - \mu_{\mathrm{lb}}$, which is also its dual: positive where the
upper bound is active, negative where the lower bound is.

**Minimal time.** A free final time to minimise is written as a Mayer cost, $t_f \to \min$.
Then $f^0 = 0$, so $H = p \cdot f$, and the transversality condition reads

```math
\mathbf{H}(t_f) = -p^0 = 1.
```

(In general, the transversality condition on a free final time is
$\mathbf{H}(t_f) = -p^0\, \partial_{t_f} g$, so it is the same for $\min t_f$ and for
$\max (-t_f)$.)

Writing the same cost in Lagrange form, $t_f = \int_{t_0}^{t_f} 1\,\mathrm{d}t$, gives instead
$H = p \cdot f - 1$ and $\mathbf{H} \equiv 0$ for an autonomous problem. Both are correct; the
documentation uses the Mayer form.

**The variable in the calls.** The functions of a problem, the dynamics, the costs, the
constraints, the Hamiltonians, the control laws and the multipliers, take the variable $v$ as
their **last positional argument**, as in the mathematics: `H(x, p, u, v)`, `u(t, x, p, v)`.
Their uniform call takes every argument, `H(t, x, p, u, v)`, with `v = nothing` for a problem
without a variable; arguments a function does not depend on are ignored. The calls of a
[flow](@ref flows-overview), whose positions are taken by the times, the state and the
costate, take it by **keyword**: `f(t0, x0, p0, tf; variable=v)`.

**Variable costate.** When the variable $v$ is optimised, the indirect method treats it as a
constant state ($\dot v = 0$) with its own costate $p_v$:

```math
\dot{p}_v(t) = -\nabla_v H, \qquad p_v(t_0) = 0, \qquad p_v(t_f) = p^0\, \nabla_v g,
```

for a Mayer term $g$ that depends on $v$ and no boundary condition that involves $v$. For
instance, with the cost term $\omega^2$ and $p^0 = -1$, $p_\omega(t_f) = -2\omega$ (the same
for $\max(-\omega^2)$, where $p^0 = +1$).

## See also

- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — write this formulation directly as Julia code.
- [Functional API](@ref modelling-functional-api) — build the same model without the macro.
- [Control-free problems](@ref modelling-without-control) — the $m = 0$ case.
- [Flows](@ref flows-overview) — build the Hamiltonian flows of the indirect method.
