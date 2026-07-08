# # OptimalControl.jl — a guided tour
#
# [![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/control-toolbox/OptimalControl.jl/paderborn?urlpath=%2Fdoc%2Ftree%2Fdocs%2Fsrc%2Fnotebooks%2Ftutorial.ipynb)
#
#src ============================================================================
#src SKELETON — v1 "socle" (~45 min). See .reports/tutorial-brainstorming.md.
#src Sections form the self-contained socle. Extensions are out of v1.
#src
#src Literate conventions used here:
#src   `# text`   → markdown line (rendered in .md and .ipynb)
#src   plain code → executed Julia
#src   `## text`  → stays a code comment inside a code block
#src   `#src ...`  → source-only note, stripped from BOTH .md and .ipynb (TODOs live here)
#src   `#md ...`   → markdown output only     `#nb ...` → notebook output only
#src
#src LINKS: doc-internal links are split — `#md` emits `@ref`/`@extref` (cross-refs for the
#src   Documenter build), `#nb` emits plain https URLs (for the Binder notebook). External
#src   homepages (jso.dev, juliaplots, control-toolbox.org root) stay as single plain URLs.
#src ============================================================================
#
# This tutorial is a guided tour of [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl),
# part of the [control-toolbox](https://control-toolbox.org) ecosystem. We take a **single
# running example** — the double integrator — and follow it end to end: modelling, solving by
# the **direct** method, initialisation, grid continuation, GPU, and finally the **indirect**
# (Pontryagin) method. Advanced topics are linked at the end.
#
#src TODO(prose): 2–3 sentence hook. Who it is for (control/ODE/optim background, not Julia
#src   experts). What they will be able to do after (define + solve + plot in a few lines).

#src ============================================================================
# ## The problem, and installing the tools
#src ============================================================================
#
# An **optimal control problem** (OCP) in Bolza form reads
#
# ```math
# J(x, u) = g(x(t_0), x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))\,\mathrm{d}t \;\to\; \min,
# ```
#
# subject to the dynamics $\dot{x}(t) = f(t, x(t), u(t))$ and, possibly, box / path / boundary
# constraints. When $g = 0$ the cost is of **Lagrange** form; when $f^0 = 0$, of **Mayer** form.
#
#src TODO(prose): recall constraints block + free-time / extra-variable v (copy the math from
#src   the brainstorming "Formulation mathématique"). Keep it short: 1 slide of math.
#src TODO(prose): one sentence + (optional) one figure on the modular ecosystem
#src   (CTBase / CTParser / CTModels / CTDirect / CTFlows / CTSolvers).
#
# Installation is a single package:
#
# ```julia
# import Pkg
# Pkg.add("OptimalControl")
# ```
#
# We load OptimalControl.jl to model the problem, a solver backend
# ([NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl)), and [Plots.jl](https://docs.juliaplots.org).

using OptimalControl
using NLPModelsIpopt
using Plots

#src ============================================================================
# ## Defining a problem: `@def` and the macro-free API
#src ============================================================================
#
# Our running example: a wagon of unit mass on a frictionless rail, state $x = (q, v)$
# (position, velocity), acceleration controlled by a force $u$. We start at $(-1, 0)$, must
# reach $(0, 0)$ at $t_f = 1$, and minimise the transfer energy $\tfrac12\int_0^1 u^2$.

t0 = 0; tf = 1; x0 = [-1, 0]; xf = [0, 0]

# ### The `@def` macro
#
#md # The [`@def`](@ref manual-abstract-syntax) macro lets us write the problem almost exactly
#nb # The [`@def`](https://control-toolbox.org/OptimalControl.jl/stable/manual-abstract.html) macro lets us write the problem almost exactly
# as the mathematics:

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫( u(t)^2 ) → min
end

#src TODO(prose): optionally build it piece by piece (time → state → control → dynamics →
#src   boundary → cost) to show proximity with the math. Mention non-Unicode alternatives.
#src TODO(optional): show 1 pedagogical error (incomplete def / undeclared variable) → CTBase
#src   exception. Do NOT execute an erroring block in the built doc; guard with try/catch or
#src   present it as a non-run ```julia fenced block.

# ### The same problem with the macro-free (functional) API
#
#md # The [functional API](@ref manual-macro-free) builds the *same* model step by step with
#nb # The [functional API](https://control-toolbox.org/OptimalControl.jl/stable/manual-macro-free.html) builds the *same* model step by step with
# plain functions — useful for programmatic problem generation or macro-free library code.

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

# ### What the macro actually does
#
# **Key message:** `@def` *translates the expression* into the very same functional calls, and
# **additionally records the symbolic definition**. We can see the difference directly: the
# macro keeps the DSL expression, whereas the functional API stores an empty definition.

definition(ocp)          # the macro records the full DSL expression

#-

has_abstract_definition(ocp_func)   # false: functional API stores no abstract definition

#src TODO(prose): remarks to drop here —
#src   (a) scalar vs vector in callbacks: `u[1]` even in dim 1 (see manual-macro-free).
#src   (b) the functional API only works with the `:adnlp` modeler, NOT `:exa`/GPU — this
#src       motivates the GPU section. Forward-reference it.

#src ============================================================================
# ## First solve, initial guess, and the costate
#src ============================================================================
#
# Solving is one call, plotting another.

direct_sol = solve(ocp)

#-

plot(direct_sol)

# ### The default initial guess
#
# With no initial guess, every variable is initialised to `0.1`. We can *see* the initial guess
# without optimising, by stopping the solver immediately with `max_iter=0`:

sol_init = solve(ocp; init=nothing, max_iter=0, display=false)
plot(sol_init; size=(600, 450))

# **Notice the right-hand column: the costate is already there.** Even though we only ever
# provide the state, control and (optional) variable, the solver initialises the **adjoint**
# internally. After optimisation, this right-column costate is exactly the **adjoint $p$ of
# Pontryagin's Maximum Principle** — the same $p$ we will reuse to start the indirect method
# in the indirect section. This closes the loop between the direct and indirect methods.

# ### Providing our own initial guess
#
# A better guess reduces the iteration count. The recommended way is the `@init` macro, using
# the labels from the `@def` block (`q`, `v`, `u` here):

ig = @init ocp begin
    q(t) := -1 + t
    v(t) := 0
    u(t) := 0
end

sol = solve(ocp; init=ig, display=false)
println("iterations, default guess: ", iterations(direct_sol))
println("iterations, @init guess:   ", iterations(sol))

#md # For all the ways to specify an initial guess, see [Set an initial guess](@ref manual-initial-guess).
#nb # For all the ways to specify an initial guess, see [Set an initial guess](https://control-toolbox.org/OptimalControl.jl/stable/manual-initial-guess.html).
#src TODO(prose): note there is no costate init yet (documented limitation).

#src ============================================================================
# ## The direct method in depth: the Goddard problem
#src ============================================================================
#
# The **direct** method turns the infinite-dimensional OCP into a finite-dimensional nonlinear
# program (NLP) by discretising time (Runge–Kutta / collocation) on a grid, then hands the NLP
# to a solver. It is robust and easy to use.
#
#src TODO(prose): recall the trapezoidal discretisation → NLP (copy from brainstorming
#src   "Principe de la méthode directe"). Keep to one slide.
#
# The double integrator is *linear-quadratic*: the solver nails it in a **single iteration**, so
# there is nothing to show about convergence or warm-starting. We switch to a genuinely
# nonlinear problem — the **Goddard rocket**: maximise the final altitude, with free final time,
# a velocity state constraint and a singular arc.

## Goddard data and dynamics (F0: drift, F1: thrust)
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

# ### Choosing a solver is trivial
#
#md # `solve` uses the defaults (collocation, ADNLP modeler, Ipopt, CPU). Switching solver is
#md # just loading a package and passing a token (see [Solve a problem](@ref manual-solve)):
#nb # `solve` uses the defaults (collocation, ADNLP modeler, Ipopt, CPU). Switching solver is
#nb # just loading a package and passing a token (see [Solve a problem](https://control-toolbox.org/OptimalControl.jl/stable/manual-solve.html)):

using MadNLP
sol_ipopt  = solve(goddard;          grid_size=250, display=false)
sol_madnlp = solve(goddard, :madnlp; grid_size=250, display=false)
println("Ipopt  : r(tf) = ", -objective(sol_ipopt),  ", ", iterations(sol_ipopt),  " iters")
println("MadNLP : r(tf) = ", -objective(sol_madnlp), ", ", iterations(sol_madnlp), " iters")

#src TODO(prose): briefly mention `methods()` and `describe(:collocation)`. Do not dwell.

# ### Options: grid size and scheme
#
# The main knob is `grid_size`; the integration `scheme` is another
# (`:trapeze`, `:midpoint`, `:gauss_legendre_2`, ...).

sol_gl2 = solve(goddard; grid_size=250, scheme=:gauss_legendre_2, display=false)
nothing #hide

# ### Grid continuation by warm-starting
#
# A solution can be passed **directly** as the initial guess of another solve — it is
# interpolated onto the new grid. This makes discrete continuation trivial and ties back to the
# initialisation above. On this nonlinear problem it genuinely **pays**: we compare reaching a
# fine grid of 1000 two ways —
#
# 1. **cold start** — solve `grid_size=1000` directly;
# 2. **cascade** — solve `250 → 500 → 1000`, warm-starting each step with the previous solution.

using BenchmarkTools

## solutions computed once, reused for iteration counts and the overlay plot
sol_cold = solve(goddard; grid_size=1000, display=false)
s50  = solve(goddard; grid_size=50, display=false)
s1000 = solve(goddard; grid_size=1000, init=s50, display=false)

iter_cold    = iterations(sol_cold)
iter_cascade = iterations(s50) + iterations(s1000)

#src TODO(build-time): @belapsed runs several samples; capped here to keep the doc build fast.
## timings — BenchmarkTools handles JIT warm-up and reports the minimum
t_cold = @belapsed solve($goddard; grid_size=1000, display=false) samples=3 seconds=10
t_cascade = @belapsed begin
    a = solve($goddard; grid_size=50, display=false)
    solve($goddard; grid_size=1000, init=a, display=false)
end samples=3 seconds=10

println("cold 1000       : ", iter_cold,    " iters, ", round(t_cold;    digits=3), " s")
println("cascade 50→1000 : ", iter_cascade, " iters, ", round(t_cascade; digits=3), " s")

# **Message:** the grid size trades accuracy against cost, and warm-starting cuts the iteration
# count. Overlay the successive solutions to watch convergence:

plt = plot(s50;  label="50")
plot!(plt, s1000; label="1000")

# This is grid-refinement warm-starting. The very same mechanism drives **parametric**
# continuation (homotopy on a physical parameter, e.g. maximum thrust):
# <https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html>.
#src TODO(links): convert the continuation link to @extref once the Documenter anchor is known.

#src ============================================================================
# ## Solving on a GPU (optional in live — expected error here)
#src ============================================================================
#
# Moving to the GPU is a single token, `:gpu`, which auto-completes to
# `(:collocation, :exa, :madnlp, :gpu)`. It requires the `:exa` modeler (hence `@def`, not the
# macro-free API — cf. the definition section) plus a CUDA-capable GPU.
#
# In a seminar or on Binder there is usually **no functional GPU**, so the call is *expected to
# fail* — that is the pedagogical point: the `:gpu` token needs a specific setup. We wrap it in
# a `try/catch` so the tour keeps running and shows the raised exception.

using MadNLPGPU
using CUDA

#src TODO(exec): if the :exa modeler cannot build Goddard's F0/F1 dynamics, this errors at
#src   model-build time (still caught below). If that happens, either inline the dynamics
#src   coordinate-wise, or demo the :gpu token on the simple `ocp` — the "expected error"
#src   lesson holds either way.
try
    global sol_gpu = solve(goddard, :gpu; grid_size=1000)
    println("GPU solve succeeded — a functional GPU is available.")
catch e
    println("GPU solve failed, as expected without a functional GPU.")
    println("CUDA.functional() = ", CUDA.functional())
    println("Exception: ", first(sprint(showerror, e), 400))
end

#md # For the full GPU setup, see [Solve on GPU](@ref manual-solve-gpu).
#nb # For the full GPU setup, see [Solve on GPU](https://control-toolbox.org/OptimalControl.jl/stable/manual-solve-gpu.html).

#src ============================================================================
# ## The indirect method — back to the simple problem
#src ============================================================================
#
# We now return to the **double integrator** `ocp` from the earlier sections. Its shooting has just two unknowns
# and is initialised by the direct costate above, which makes it ideal to *see* the indirect
# method. (The Goddard shooting is a *structured multi-arc* problem — see the links in the last section.)
#
# In control-toolbox we systematically pair the direct method with the **indirect** one, based
# on Pontryagin's Maximum Principle (PMP). With pseudo-Hamiltonian
# $H(x,p,u) = p\,f(x,u) + p^0 f^0(x,u)$ (normal case $p^0 = -1$), the PMP gives the maximising
# control in feedback form $u(x,p) = \arg\max_u H$, and the optimal trajectory solves a
# boundary value problem that we recast as a **shooting equation** $S(p_0) = 0$.
#
#src TODO(prose): recall the 3 steps (maximising control → BVP → shooting function) from the
#src   brainstorming "Principe de la méthode indirecte". One slide of math.
#
# For the energy problem, $H = p_1 v + p_2 u - u^2/2$, so the maximiser is $u = p_2$.

using OrdinaryDiffEq   # ODE solver (Hamiltonian flow)
using NonlinearSolve   # nonlinear equations (shooting)

## maximising control in feedback form
u_max(x, p) = p[2]

## Hamiltonian flow of the OCP
φ = Flow(ocp, u_max);

## state projection π(x, p) = x
proj((x, p)) = x

## shooting function
S(p0) = proj(φ(t0, x0, p0, tf)) - xf

# **The shooting is initialised with the costate of the direct solution** — the very adjoint we
# highlighted in §2:

nle!(s, p0, _) = (s[:] = S(p0))

p_of_t   = costate(direct_sol)     # costate as a function of time
p0_guess = p_of_t(t0)              # initial costate from the direct method

prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = solve(prob; show_trace=Val(true))
p0_sol = shooting_sol.u

println("costate p0 = ", p0_sol)
println("shoot S(p0) = ", S(p0_sol))

# Reconstruct and plot the indirect solution from the flow:

indirect_sol = φ((t0, tf), x0, p0_sol; saveat=range(t0, tf, 100))
plot(indirect_sol)

#src TODO(prose): overlay direct vs indirect on one plot to show they match.
#md # See [Compute flows from optimal control problems](@ref manual-flow-ocp) for the flow
#md # construction, and the [indirect simple shooting tutorial](@extref tutorial-indirect-simple-shooting).
#nb # See [Compute flows from optimal control problems](https://control-toolbox.org/OptimalControl.jl/stable/manual-flow-ocp.html)
#nb # for the flow construction, and the [indirect simple shooting tutorial](https://control-toolbox.org/Tutorials.jl/stable/).

#src ============================================================================
# ## Going further (end of the socle)
#src ============================================================================
#
# This is the natural stopping point. From here, the tour branches out — we point to the
# detailed pages rather than coding them live.
#
# **Variables & parameters.** Beyond the control, one can optimise **parameters** naturally,
# both in an OCP (the `variable` keyword of the DSL) and in a differential-constraint
# optimisation problem **without any control** (a *control-free* problem).
#md # See [control-free problems](@ref example-control-free).
#nb # See [control-free problems](https://control-toolbox.org/OptimalControl.jl/stable/example-control-free.html).
#src NOTE(v1): parameter estimation is only *mentioned* here. The worked example is an
#src   extension (out of v1) — see .reports/tutorial-brainstorming.md "Extensions futures".
#
# **Advanced examples** (each does both direct and indirect):
#
#md # - Singular control (control-affine systems) — [singular control](@ref example-singular-control)
#md # - State constraint — [state constraint](@ref example-state-constraint)
#md # - Goddard problem — free final time, a singular arc, a state constraint and a structured
#md #   shooting all at once — [Goddard tutorial](@extref Tutorials tutorial-goddard)
#nb # - Singular control (control-affine systems) — <https://control-toolbox.org/OptimalControl.jl/stable/example-singular-control.html>
#nb # - State constraint — <https://control-toolbox.org/OptimalControl.jl/stable/example-state-constraint.html>
#nb # - Goddard problem — free final time, a singular arc, a state constraint and a structured
#nb #   shooting all at once — <https://control-toolbox.org/Tutorials.jl/stable/tutorial-goddard.html>
#
# **Discrete continuation** — warm-starting across a family of problems (homotopy on a physical
# parameter), the grown-up version of the grid continuation above:
# <https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html>.
#
#src ============================================================================
#src END OF SOCLE (v1). Extensions (parameter estimation worked out, singular, state
#src constraint, Goddard) go below in later versions — see brainstorming doc.
#src ============================================================================
