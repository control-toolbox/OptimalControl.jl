```@meta
Draft = false
```

```@meta
EditURL = "../src-literate/tutorial.jl"
```

# OptimalControl.jl — a guided tour

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/control-toolbox/OptimalControl.jl/paderborn?urlpath=%2Fdoc%2Ftree%2Fdocs%2Fsrc%2Fnotebooks%2Ftutorial.ipynb)


This tutorial is a guided tour of [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl),
part of the [control-toolbox](https://control-toolbox.org) ecosystem. We take a **single
running example** — the double integrator — and follow it end to end: modelling, solving by
the **direct** method, initialisation, grid continuation, GPU, and finally the **indirect**
(Pontryagin) method. Advanced topics are linked at the end.

## 0. The problem, and installing the tools

An **optimal control problem** (OCP) in Bolza form reads

```math
J(x, u) = g(x(t_0), x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))\,\mathrm{d}t \;\to\; \min,
```

subject to the dynamics $\dot{x}(t) = f(t, x(t), u(t))$ and, possibly, box / path / boundary
constraints. When $g = 0$ the cost is of **Lagrange** form; when $f^0 = 0$, of **Mayer** form.


Installation is a single package:

```julia
import Pkg
Pkg.add("OptimalControl")
```

We load OptimalControl.jl to model the problem, a solver backend
([NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl)), and [Plots.jl](https://docs.juliaplots.org).

````@example tutorial
using OptimalControl
using NLPModelsIpopt
using Plots
````

## 1. Defining a problem: `@def` and the macro-free API

Our running example: a wagon of unit mass on a frictionless rail, state $x = (q, v)$
(position, velocity), acceleration controlled by a force $u$. We start at $(-1, 0)$, must
reach $(0, 0)$ at $t_f = 1$, and minimise the transfer energy $\tfrac12\int_0^1 u^2$.

````@example tutorial
t0 = 0; tf = 1; x0 = [-1, 0]; xf = [0, 0]
````

### The `@def` macro

The [`@def`](@ref manual-abstract-syntax) macro lets us write the problem almost exactly
as the mathematics:

````@example tutorial
ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end
````

### The same problem with the macro-free (functional) API

The [functional API](@ref manual-macro-free) builds the *same* model step by step with
plain functions — useful for programmatic problem generation or macro-free library code.

````@example tutorial
pre = OptimalControl.PreModel()

time!(pre; t0=t0, tf=tf)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_energy!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u[1]
    return nothing
end
dynamics!(pre, f_energy!)

function boundary_energy!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre, :boundary; f=boundary_energy!, lb=zeros(4), ub=zeros(4), label=:endpoint)

lagrange_energy(t, x, u, v) = 0.5 * u[1]^2
objective!(pre, :min; lagrange=lagrange_energy)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
````

### What the macro actually does

**Key message:** `@def` *translates the expression* into the very same functional calls, and
**additionally records the symbolic definition**. We can see the difference directly: the
macro keeps the DSL expression, whereas the functional API stores an empty definition.

````@example tutorial
definition(ocp)          # the macro records the full DSL expression
````

````@example tutorial
has_abstract_definition(ocp_func)   # false: functional API stores no abstract definition
````

## 2. First solve, initial guess, and the costate

Solving is one call, plotting another.

````@example tutorial
direct_sol = solve(ocp)
````

````@example tutorial
plot(direct_sol)
````

### The default initial guess

With no initial guess, every variable is initialised to `0.1`. We can *see* the initial guess
without optimising, by stopping the solver immediately with `max_iter=0`:

````@example tutorial
sol_init = solve(ocp; init=nothing, max_iter=0, display=false)
plot(sol_init; size=(600, 450))
````

**Notice the right-hand column: the costate is already there.** Even though we only ever
provide the state, control and (optional) variable, the solver initialises the **adjoint**
internally. After optimisation, this right-column costate is exactly the **adjoint $p$ of
Pontryagin's Maximum Principle** — the same $p$ we will reuse to start the indirect method
in §5. This closes the loop between the direct and indirect methods.

### Providing our own initial guess

A better guess reduces the iteration count. The recommended way is the `@init` macro, using
the labels from the `@def` block (`q`, `v`, `u` here):

````@example tutorial
ig = @init ocp begin
    q(t) := -1 + t
    v(t) := 0
    u(t) := 0
end

sol = solve(ocp; init=ig, display=false)
println("iterations, default guess: ", iterations(direct_sol))
println("iterations, @init guess:   ", iterations(sol))
````

For all the ways to specify an initial guess, see [Set an initial guess](@ref manual-initial-guess).

## 3. The direct method in depth: the Goddard problem

The **direct** method turns the infinite-dimensional OCP into a finite-dimensional nonlinear
program (NLP) by discretising time (Runge–Kutta / collocation) on a grid, then hands the NLP
to a solver. It is robust and easy to use.


The double integrator is *linear-quadratic*: the solver nails it in a **single iteration**, so
there is nothing to show about convergence or warm-starting. We switch to a genuinely
nonlinear problem — the **Goddard rocket**: maximise the final altitude, with free final time,
a velocity state constraint and a singular arc.

````@example tutorial
# Goddard data and dynamics (F0: drift, F1: thrust)
const r0 = 1; v0 = 0; m0 = 1; vmax = 0.1; mf = 0.6
Cd = 310; Tmax = 3.5; β = 500; b = 2

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β * (r - 1))
    [v, -D/m - 1/r^2, 0]
end
F1(x) = begin
    r, v, m = x
    [0, Tmax/m, -b*Tmax]
end

goddard = @def begin
    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (r, v, m) ∈ R³, state
    u ∈ R, control

    x(t0) == [r0, v0, m0]
    m(tf) == mf
    0 ≤ u(t) ≤ 1
    r(t) ≥ r0
    0 ≤ v(t) ≤ vmax

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

    -r(tf) → min
end
````

### Choosing a solver is trivial

`solve` uses the defaults (collocation, ADNLP modeler, Ipopt, CPU). Switching solver is
just loading a package and passing a token (see [Solve a problem](@ref manual-solve)):

````@example tutorial
using MadNLP
sol_ipopt  = solve(goddard;          grid_size=250, display=false)
sol_madnlp = solve(goddard, :madnlp; grid_size=250, display=false)
println("Ipopt  : r(tf) = ", -objective(sol_ipopt),  ", ", iterations(sol_ipopt),  " iters")
println("MadNLP : r(tf) = ", -objective(sol_madnlp), ", ", iterations(sol_madnlp), " iters")
````

### Options: grid size and scheme

The main knob is `grid_size`; the integration `scheme` is another
(`:trapeze`, `:midpoint`, `:gauss_legendre_2`, ...).

````@example tutorial
sol_gl2 = solve(goddard; grid_size=250, scheme=:gauss_legendre_2, display=false)
nothing #hide
````

### Grid continuation by warm-starting

A solution can be passed **directly** as the initial guess of another solve — it is
interpolated onto the new grid. This makes discrete continuation trivial and ties back to the
initialisation of §2. On this nonlinear problem it genuinely **pays**: we compare reaching a
fine grid of 1000 two ways —

1. **cold start** — solve `grid_size=1000` directly;
2. **cascade** — solve `250 → 500 → 1000`, warm-starting each step with the previous solution.

````@example tutorial
using BenchmarkTools

# solutions computed once, reused for iteration counts and the overlay plot
sol_cold = solve(goddard; grid_size=1000, display=false)
s50  = solve(goddard; grid_size=50, display=false)
s1000 = solve(goddard; grid_size=1000, init=s50, display=false)

iter_cold    = iterations(sol_cold)
iter_cascade = iterations(s50) + iterations(s1000)

# timings — BenchmarkTools handles JIT warm-up and reports the minimum
t_cold = @belapsed solve($goddard; grid_size=1000, display=false) samples=3 seconds=10
t_cascade = @belapsed begin
    a = solve($goddard; grid_size=50, display=false)
    solve($goddard; grid_size=1000, init=a, display=false)
end samples=3 seconds=10

println("cold 1000       : ", iter_cold,    " iters, ", round(t_cold;    digits=3), " s")
println("cascade 50→1000 : ", iter_cascade, " iters, ", round(t_cascade; digits=3), " s")
````

**Message:** the grid size trades accuracy against cost, and warm-starting cuts the iteration
count. Overlay the successive solutions to watch convergence:

````@example tutorial
plt = plot(s50;  label="50")
plot!(plt, s1000; label="1000")
````

This is grid-refinement warm-starting. The very same mechanism drives **parametric**
continuation (homotopy on a physical parameter, e.g. maximum thrust):
<https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html>.

## 4. Solving on a GPU (optional in live — expected error here)

Moving to the GPU is a single token, `:gpu`, which auto-completes to
`(:collocation, :exa, :madnlp, :gpu)`. It requires the `:exa` modeler (hence `@def`, not the
macro-free API — cf. §1) plus a CUDA-capable GPU.

In a seminar or on Binder there is usually **no functional GPU**, so the call is *expected to
fail* — that is the pedagogical point: the `:gpu` token needs a specific setup. We wrap it in
a `try/catch` so the tour keeps running and shows the raised exception.

````@example tutorial
using MadNLPGPU
using CUDA

try
    global sol_gpu = solve(goddard, :gpu; grid_size=1000)
    println("GPU solve succeeded — a functional GPU is available.")
catch e
    println("GPU solve failed, as expected without a functional GPU.")
    println("CUDA.functional() = ", CUDA.functional())
    println("Exception: ", first(sprint(showerror, e), 400))
end
````

For the full GPU setup, see [Solve on GPU](@ref manual-solve-gpu).

## 5. The indirect method — back to the simple problem

We now return to the **double integrator** `ocp` of §§1–2. Its shooting has just two unknowns
and is initialised by the direct costate of §2, which makes it ideal to *see* the indirect
method. (The Goddard shooting is a *structured multi-arc* problem — see the links in §6.)

In control-toolbox we systematically pair the direct method with the **indirect** one, based
on Pontryagin's Maximum Principle (PMP). With pseudo-Hamiltonian
$H(x,p,u) = p\,f(x,u) + p^0 f^0(x,u)$ (normal case $p^0 = -1$), the PMP gives the maximising
control in feedback form $u(x,p) = \arg\max_u H$, and the optimal trajectory solves a
boundary value problem that we recast as a **shooting equation** $S(p_0) = 0$.


For the energy problem, $H = p_1 v + p_2 u - u^2/2$, so the maximiser is $u = p_2$.

````@example tutorial
using OrdinaryDiffEq   # ODE solver (Hamiltonian flow)
using NonlinearSolve   # nonlinear equations (shooting)

# maximising control in feedback form
u_max(x, p) = p[2]

# Hamiltonian flow of the OCP
φ = Flow(ocp, u_max);

# state projection π(x, p) = x
proj((x, p)) = x

# shooting function
S(p0) = proj(φ(t0, x0, p0, tf)) - xf
````

**The shooting is initialised with the costate of the direct solution** — the very adjoint we
highlighted in §2:

````@example tutorial
nle!(s, p0, _) = (s[:] = S(p0))

p_of_t   = costate(direct_sol)     # costate as a function of time
p0_guess = p_of_t(t0)              # initial costate from the direct method

prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = solve(prob; show_trace=Val(true))
p0_sol = shooting_sol.u

println("costate p0 = ", p0_sol)
println("shoot S(p0) = ", S(p0_sol))
````

Reconstruct and plot the indirect solution from the flow:

````@example tutorial
indirect_sol = φ((t0, tf), x0, p0_sol; saveat=range(t0, tf, 100))
plot(indirect_sol)
````

See [Compute flows from optimal control problems](@ref manual-flow-ocp) for the flow
construction, and the [indirect simple shooting tutorial](@extref tutorial-indirect-simple-shooting).

## 6. Going further (end of the socle)

This is the natural stopping point. From here, the tour branches out — we point to the
detailed pages rather than coding them live.

**Variables & parameters.** Beyond the control, one can optimise **parameters** naturally,
both in an OCP (the `variable` keyword of the DSL) and in a differential-constraint
optimisation problem **without any control** (a *control-free* problem).
See [control-free problems](@ref example-control-free).

**Advanced examples** (each does both direct and indirect):

- Singular control (control-affine systems) — [singular control](@ref example-singular-control)
- State constraint — [state constraint](@ref example-state-constraint)
- Goddard problem — free final time, a singular arc, a state constraint and a structured
  shooting all at once — [Goddard tutorial](@extref Tutorials tutorial-goddard)

**Discrete continuation** — warm-starting across a family of problems (homotopy on a physical
parameter), the grown-up version of the grid continuation of §3:
<https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html>.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

