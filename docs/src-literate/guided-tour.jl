# # [OptimalControl.jl — a guided tour](@id getting-started-guided-tour)
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
#src   Documenter build), `#nb` emits plain https URLs (for the downloadable notebook). External
#src   homepages (jso.dev, juliaplots, control-toolbox.org root) stay as single plain URLs.
#src ============================================================================
#
# This tutorial is a guided tour of [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl), part of the [control-toolbox](https://control-toolbox.org) ecosystem. We follow two problems end to end: a simple **double integrator** for modelling, initialisation and the **indirect** (Pontryagin) method, and the **Goddard rocket** for the **direct** method in depth, grid continuation and GPU solving. Advanced topics are linked at the end.
#
# It is written for readers with a background in optimal control, ODEs or optimisation. By the end you will be able to define an optimal control problem, solve it by both the direct and indirect methods, and visualise the result — all in a few lines of code.
#
#src The download links are raw HTML on purpose: Documenter rewrites a Markdown link
#src `../assets/…` to `assets/…`, which VitePress then resolves under `getting-started/`.
#md # ```@raw html
#md # <div class="tip custom-block">
#md # <p class="custom-block-title">Run it yourself</p>
#md # <p>This page is generated from a single script. Download it as a <a href="../assets/guided-tour.ipynb" download>Jupyter notebook</a> or as a <a href="../assets/guided-tour.jl" download>Julia script</a> and run it on your machine. Besides <code>OptimalControl</code>, it uses <code>NLPModelsIpopt</code>, <code>Plots</code>, <code>MadNLP</code>, <code>OrdinaryDiffEqTsit5</code> and <code>NonlinearSolve</code>, plus <code>MadNLPGPU</code>, <code>CUDA</code> and <code>CUDSS</code> for the GPU section.</p>
#md # </div>
#md # ```

#src ============================================================================
# ## The problem, and installing the tools
#src ============================================================================
#
# We model and solve **optimal control problems** (OCP): minimise a cost, made of a function of the end points and an integral along the trajectory, subject to controlled dynamics $\dot{x}(t) = f(t, x(t), u(t))$ and constraints.
#md # The general problem, with free times and optimisation variables, and the notation used throughout the documentation are on [Formulation](@ref modelling-formulation).
#nb # The general problem, with free times and optimisation variables, and the notation used throughout the documentation are on [Formulation](https://control-toolbox.org/OptimalControl.jl/dev/modelling/formulation).
#
# OptimalControl.jl is the core of the [control-toolbox](https://control-toolbox.org) ecosystem, a modular suite of Julia packages — CTBase (base types & exceptions), CTParser (DSL parsing), CTModels (problem data structures), CTDirect (discretisation & NLP transcription), CTFlows (Hamiltonian flows for indirect methods), CTLie (Lie and Poisson brackets), and CTSolvers (solver orchestration) — that can also be used individually.
#
# Installation is a single package:
#
# ```julia
# import Pkg
# Pkg.add("OptimalControl")
# ```
#
#md # The solvers, plotting and ODE integrators are separate packages, loaded only when needed: see [Installation](@ref getting-started-installation).
#nb # The solvers, plotting and ODE integrators are separate packages, loaded only when needed: see [Installation](https://control-toolbox.org/OptimalControl.jl/dev/getting-started/installation).
#
# We load OptimalControl.jl to model the problem; the other packages are loaded where they are first used.

using OptimalControl

#src ============================================================================
# ## Defining a problem: `@def` vs macro-free
#src ============================================================================
#
# Our running example: a wagon of unit mass on a frictionless rail, state $x = (q, v)$ (position, velocity), acceleration controlled by a force $u$. We start at $(-1, 0)$, must reach $(0, 0)$ at $t_f = 1$, and minimise the transfer energy
#
# ```math
# \frac{1}{2}\int_0^1 u^2(t)\,\mathrm{d}t,
# ```
#
# subject to the dynamics
#
# ```math
# \dot{q}(t) = v(t), \qquad \dot{v}(t) = u(t).
# ```
#
# The data of the problem: the time interval and the end points.

t0 = 0
tf = 1
x0 = [-1, 0]
xf = [0, 0]
#md nothing # hide

# ### The `@def` macro
#
#md # The [`@def`](@ref modelling-abstract-syntax) macro lets us write the problem almost exactly as the mathematics.
#nb # The [`@def`](https://control-toolbox.org/OptimalControl.jl/dev/modelling/abstract-syntax) macro lets us write the problem almost exactly as the mathematics.
# Each line of the block mirrors a piece of the formulation — time, state, control, boundary conditions, dynamics, then cost — in the order one would write them on paper. Unicode symbols (`∈`, `R²`, `ẋ`, `∫`, `→`) make the code read like the maths; plain ASCII alternatives (`R^2`, `derivative`, `integral`, `=>`) are available for keyboards or workflows that prefer them:

ocp = @def begin
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == [v(t), u(t)]

    0.5∫(u(t)^2) → min
end
#md nothing # hide

# ### The same problem with the macro-free (functional) API
#
#md # The [functional API](@ref modelling-functional-api) builds the *same* model step by step with plain functions — useful for programmatic problem generation or macro-free library code.
#nb # The [functional API](https://control-toolbox.org/OptimalControl.jl/dev/modelling/functional-api) builds the *same* model step by step with plain functions — useful for programmatic problem generation or macro-free library code.
#
# First, the functions of the problem: the dynamics, the boundary conditions and the integrand of the cost. The last argument of each is the optimisation variable, none here.

function f_energy!(dx, t, x, u, var)
    dx[1] = x[2]
    dx[2] = u          # scalar control: `u`, not `u[1]`
    return nothing
end

function boundary_energy!(b, x0_, xf_, var)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end

lagrange_energy(t, x, u, var) = 0.5 * u^2
#md nothing # hide

# Then the model, built one component at a time:

pre = OptimalControl.PreModel()
time!(pre; t0=t0, tf=tf)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)
dynamics!(pre, f_energy!)
constraint!(pre, :boundary; f=boundary_energy!, lb=zeros(4), ub=zeros(4), label=:endpoint)
objective!(pre, :min; lagrange=lagrange_energy)
time_dependence!(pre; autonomous=true)
ocp_func = build(pre)
#md nothing # hide

# ### What the macro actually does
#
# `@def` *translates the expression* into the very same functional calls, and **additionally records the symbolic definition**. We can see the difference directly: the macro keeps the DSL expression, whereas the functional API stores an empty definition.

definition(ocp)          # the macro records the full DSL expression

#-

has_abstract_definition(ocp_func)   # false: no symbolic definition

#md # !!! warning "Two things to keep in mind"
#md #     - A dimension-1 `x`, `u` or `v` reaches a callback as a **scalar** — write `u`, not `u[1]` — exactly as on a solution and in `@def`. The one exception is the in-place output buffer (`dx` here, `val` for constraints): always a vector, written by index. See [Shapes in callbacks](@ref modelling-functional-api-shapes).
#md #     - The functional API currently works only with the `:adnlp` modeler; it does **not** support the `:exa` modeler needed for GPU solving — one more reason to prefer `@def` when GPU execution is contemplated (more in the GPU section).
#nb # **Two things to keep in mind:** (1) a dimension-1 `x`, `u` or `v` reaches a callback as a scalar — write `u`, not `u[1]` — while the in-place output buffer (`dx`, `val`) is always a vector written by index; (2) the functional API currently works only with the `:adnlp` modeler, **not** `:exa` (needed for GPU solving) — one more reason to prefer `@def` when GPU execution is contemplated (more in the GPU section).

#src ============================================================================
# ## First solve, initial guess, and the costate
#src ============================================================================
#
# Solving is one call, plotting another. Solving needs a solver backend, [NLPModelsIpopt.jl](https://jso.dev/NLPModelsIpopt.jl) for the default solver Ipopt, and plotting needs [Plots.jl](https://docs.juliaplots.org):

using NLPModelsIpopt
using Plots

direct_sol = solve(ocp)
#md nothing # hide

#md #-
#md direct_sol # hide

#-

plot(direct_sol; size=(800, 710))

#-
#md @assert isapprox(objective(direct_sol), 6; rtol=1e-3)   # hide
#md nothing                                                  # hide

# ### The default initial guess
#
# With no initial guess, every variable is initialised to `0.1`. We can *see* the initial guess without optimising, by stopping the solver immediately with `max_iter=0`:

sol_init = solve(ocp; init=nothing, max_iter=0, display=false)
plot(sol_init; size=(800, 710))

#md # !!! note "Notice the right-hand column: the costate is already there"
#md #     Even though we only ever provide the state, control and (optional) variable, the solution carries a costate: the multipliers of the discretised dynamics. It approximates the **adjoint $p$ of Pontryagin's Maximum Principle**, up to the step of the grid — the $p$ we will reuse to start the indirect method in the indirect section. This closes the loop between the direct and indirect methods.
#nb # **Notice the right-hand column: the costate is already there.** Even though we only ever provide the state, control and (optional) variable, the solution carries a costate: the multipliers of the discretised dynamics. It approximates the **adjoint $p$ of Pontryagin's Maximum Principle**, up to the step of the grid — the $p$ we will reuse to start the indirect method in the indirect section. This closes the loop between the direct and indirect methods.

# ### Providing our own initial guess
#
# The recommended way to provide an initial guess is the `@init` macro, using the labels from the `@def` block (`q`, `v`, `u` here):

ig = @init ocp begin
    q(t) := -1 + t
    v(t) := 0
    u(t) := 0
end

sol = solve(ocp; init=ig, display=false)
println("iterations, default guess: ", iterations(direct_sol))
println("iterations, @init guess:   ", iterations(sol))

# In this case both guesses give **1 iteration**: the double integrator is a *linear-quadratic* problem, so the NLP is quadratic and Ipopt solves it in a single step regardless of the starting point. Warm-starting only pays off on genuinely nonlinear problems — we will see this with the **Goddard rocket** in the next section.

#md # For all the ways to specify an initial guess, see [Initial guess](@ref solve-initial-guess).
#nb # For all the ways to specify an initial guess, see [Initial guess](https://control-toolbox.org/OptimalControl.jl/dev/solve/initial-guess).
#md # !!! note
#md #     An initial guess gives the state, the control and the variable, not the costate: it can neither be set in `@init` nor taken from a previous solution with `init=sol`. The costate drawn above with `max_iter=0` is the solver's own initial estimate of the multipliers. See [#1083](https://github.com/control-toolbox/OptimalControl.jl/issues/1083).
#nb # **Note:** an initial guess gives the state, the control and the variable, not the costate: it can neither be set in `@init` nor taken from a previous solution with `init=sol`. The costate drawn above with `max_iter=0` is the solver's own initial estimate of the multipliers. See [#1083](https://github.com/control-toolbox/OptimalControl.jl/issues/1083).

#src ============================================================================
# ## Direct method in depth: Goddard
#src ============================================================================
#
# The **direct** method turns the infinite-dimensional OCP into a finite-dimensional nonlinear program (NLP) by discretising time on a grid, then hands the NLP to a solver such as [Ipopt](https://coin-or.github.io/Ipopt). It is robust and easy to use.
#md # How a scheme turns the dynamics and the cost into the equations of the NLP is on [The direct method, briefly](@ref solve-overview-direct-method).
#nb # How a scheme turns the dynamics and the cost into the equations of the NLP is on [The direct method, briefly](https://control-toolbox.org/OptimalControl.jl/dev/solve/overview#the-direct-method-briefly).
#
# ### The Goddard rocket problem
#
# To demonstrate convergence behaviour and warm-starting, we need a genuinely nonlinear problem. The **Goddard rocket** — maximise the final altitude, with free final time and a singular arc — is a classic test case.

## Goddard data and dynamics (F0: drift, F1: thrust)
const r0 = 1
const v0 = 0
const m0 = 1
const mf = 0.6
const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2

F0(x) = begin
    r, v, m = x
    D = Cd * v^2 * exp(-β * (r - 1))
    [v, -D / m - 1 / r^2, 0]
end
F1(x) = begin
    r, v, m = x
    [0, Tmax / m, -b * Tmax]
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

    ẋ(t) == F0(x(t)) + u(t) * F1(x(t))

    r(tf) → max
end
#md nothing # hide

# ### Changing the solver
#
#md # `solve` uses the defaults (collocation, ADNLP modeler, Ipopt, CPU). Switching solver is just loading a package and passing a token (see [Choosing a method](@ref solve-choosing-a-method)):
#nb # `solve` uses the defaults (collocation, ADNLP modeler, Ipopt, CPU). Switching solver is just loading a package and passing a token (see [Choosing a method](https://control-toolbox.org/OptimalControl.jl/dev/solve/choosing-a-method)):

using MadNLP

sol_ipopt = solve(goddard; grid_size=250, display=false)
sol_madnlp = solve(goddard, :madnlp; grid_size=250, display=false)

println("Ipopt  : r(tf) = ", objective(sol_ipopt), ", ", iterations(sol_ipopt), " iters")
println("MadNLP : r(tf) = ", objective(sol_madnlp), ", ", iterations(sol_madnlp), " iters")

# Both solvers reach the same final altitude, to about six digits; only the number of iterations differs.

#-
#md @assert isapprox(objective(sol_ipopt), 1.012837; atol=1e-5)                  # hide
#md @assert isapprox(objective(sol_madnlp), objective(sol_ipopt); rtol=1e-6)     # hide
#md nothing                                                                      # hide

# The available methods and their options can be inspected with `methods()` and `describe(:collocation)`; we will not dwell on them here.

# ### Grid continuation by warm-starting
#
# A solution can be passed **directly** as the initial guess of another solve — it is interpolated onto the new grid. This makes discrete continuation trivial and ties back to the initialisation above. On this nonlinear problem it genuinely **pays**: we compare reaching a fine grid of 1000 two ways — a **cold start** (solve `grid_size=1000` directly) versus a **cascade** (solve `grid_size=50` first, then `grid_size=1000` warm-started with that solution).

## cold start: grid 1000 directly (reused below, for the comparison with a bang-bang strategy)
sol_cold = solve(goddard; grid_size=1000, display=false)

## warm cascade: grid 50 first, then grid 1000 initialised from it
s50 = solve(goddard; grid_size=50, display=false)
s1000 = solve(goddard; grid_size=1000, init=s50, display=false)

println("cold    grid 1000        : ", iterations(sol_cold), " iters")
println("cascade grid 50 (warm-up): ", iterations(s50), " iters")
println("cascade grid 1000 (warm) : ", iterations(s1000), " iters")

# Warm-started from the coarse solution, the fine solve needs only a handful of iterations. Even counting the warm-up on grid 50, the cascade uses fewer iterations in total than the cold start, and each grid-50 iteration is much cheaper than a grid-1000 one.

#-
#md @assert iterations(s50) + iterations(s1000) < iterations(sol_cold)   # hide
#md nothing                                                              # hide

# Overlay the two solutions to see that the coarse grid already captures the structure:

plt = plot(s50; label="50", size=(800, 1340), legend=false)
plot!(plt, s1000; label="1000")
plot!(plt; subplot=1, legend=:best)   # one legend, on the first subplot

#md # This is grid-refinement warm-starting. The very same mechanism drives **parametric** continuation (homotopy on a physical parameter, e.g. maximum thrust): [Discrete continuation](@extref Tutorials tutorial-continuation).
#nb # This is grid-refinement warm-starting. The very same mechanism drives **parametric** continuation (homotopy on a physical parameter, e.g. maximum thrust): <https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html>.

# ### Comparison with a bang-bang strategy

#md # How much better is the optimal solution compared to a naive strategy? We simulate **full thrust until fuel depletion, then coast to apogee** — a bang-bang profile with no optimisation, just two ODE integrations using [`Flow`](@ref flows-overview) (see also [Simulation](@ref flows-simulation)) with [OrdinaryDiffEq callbacks](https://docs.sciml.ai/DiffEqDocs/stable/features/callback_functions/) (`ContinuousCallback` and `terminate!` come from `OrdinaryDiffEqTsit5`).
#nb # How much better is the optimal solution compared to a naive strategy? We simulate **full thrust until fuel depletion, then coast to apogee** — a bang-bang profile with no optimisation, just two ODE integrations using [`Flow`](https://control-toolbox.org/OptimalControl.jl/dev/flows/overview) (see also [Simulation](https://control-toolbox.org/OptimalControl.jl/dev/flows/simulation)) with [OrdinaryDiffEq callbacks](https://docs.sciml.ai/DiffEqDocs/stable/features/callback_functions/) (`ContinuousCallback` and `terminate!` come from `OrdinaryDiffEqTsit5`).

using OrdinaryDiffEqTsit5   # ODE solver + callbacks (ContinuousCallback, terminate!)

## Phase 1: u = 1, stop when m = mf (fuel depleted)
cb_fuel = ContinuousCallback((u, t, int) -> u[3] - mf, terminate!)
flow_bang1 = Flow(VectorField(x -> F0(x) + F1(x)); callback=cb_fuel)
traj_bang1 = flow_bang1((t0, 1.0), [r0, v0, m0]; grid=nothing)
t1_bang = time_grid(traj_bang1)[end]
x1_bang = state(traj_bang1)(t1_bang)

## Phase 2: u = 0, stop when v = 0 (apogee)
cb_apogee = ContinuousCallback((u, t, int) -> u[2], terminate!)
flow_bang2 = Flow(VectorField(F0); callback=cb_apogee)
traj_bang2 = flow_bang2((t1_bang, 1.0), x1_bang; grid=nothing)
tf_bang = time_grid(traj_bang2)[end]
rf_bang = state(traj_bang2)(tf_bang)[1]

r_opt_f = objective(sol_cold)
println("Bang-bang: r(tf) = ", round(rf_bang; digits=6), ", tf = ", round(tf_bang; digits=4))
println("Optimal:   r(tf) = ", round(r_opt_f; digits=6), ", tf = ", round(variable(sol_cold); digits=4))

gain = 100 * (r_opt_f - rf_bang) / (rf_bang - r0)   # gain above r0, in %
println("Extra altitude gain of the optimal strategy: ", round(gain; digits=1), " %")

#md # !!! warning "Pass `grid=nothing` with terminating callbacks"
#md #     When calling a `Flow` on a time span `(t0, tmax)`, `CTFlows` regrids the trajectory on `[t0, tmax]` by default — even if a `terminate!` callback stopped the integration earlier. Passing `grid=nothing` preserves the solver's actual time grid up to the callback event.
#nb # **Warning:** when calling a `Flow` on a time span `(t0, tmax)`, `CTFlows` regrids the trajectory on `[t0, tmax]` by default — even if a `terminate!` callback stopped the integration earlier. Passing `grid=nothing` preserves the solver's actual time grid up to the callback event.

# The optimal strategy climbs about 2.7 % higher above $r_0$ than the naive one. It does not simply push at the maximum: after a full-thrust phase it throttles along a **singular arc**, where pushing harder would mostly be lost to drag, then coasts. Overlaying the altitude of both strategies against time makes the difference visible:

#md # ::: details The plotting code
#-
#md @assert isapprox(rf_bang, 1.012505; atol=1e-5)          # hide
#md @assert objective(sol_cold) > rf_bang                    # hide
#md nothing                                                  # hide

## assemble the bang-bang altitude as (t, r) for plotting
t1_grid, t2_grid = time_grid(traj_bang1), time_grid(traj_bang2)
t_bang = [t1_grid; t2_grid]
r_bang = [[state(traj_bang1)(t)[1] for t in t1_grid]; [state(traj_bang2)(t)[1] for t in t2_grid]]

## the optimal altitude, read from the solution on its time grid
t_opt = time_grid(sol_cold)
r_opt = [state(sol_cold)(t)[1] for t in t_opt]

tf_opt = t_opt[end]

plt = plot(
    t_opt,
    r_opt;
    label="optimal",
    linewidth=2,
    xlabel="time",
    ylabel="altitude",
    legend=:topleft,
    size=(800, 400),
    left_margin=5Plots.mm,
)
plot!(plt, t_bang, r_bang; label="bang-bang", linestyle=:dash, linewidth=2)
hline!(plt, [r0]; color=:gray, linewidth=0.8, label="")
plot!(plt, [tf_opt, tf_opt], [r0, r_opt_f]; color=1, linestyle=:dot, linewidth=1.2, label="")
plot!(plt, [tf_bang, tf_bang], [r0, rf_bang]; color=2, linestyle=:dot, linewidth=1.2, label="")
scatter!(plt, [tf_opt], [r_opt_f]; color=1, markersize=5, label="")
scatter!(plt, [tf_bang], [rf_bang]; color=2, markersize=5, label="")

## Inset zoom around the two apogees
plot!(
    plt,
    t_opt,
    r_opt;
    inset=(1, bbox(0.40, 0.40, 0.46, 0.45)),
    subplot=2,
    xlims=(0.178, 0.210),
    ylims=(1.01238, 1.01292),
    linewidth=2,
    color=1,
    legend=false,
    title="apogee zoom",
    titlefontsize=9,
    tickfontsize=7,
    framestyle=:box,
)
plot!(plt[2], t_bang, r_bang; linestyle=:dash, linewidth=2, color=2)
scatter!(plt[2], [tf_opt], [r_opt_f]; color=1, markersize=4)
scatter!(plt[2], [tf_bang], [rf_bang]; color=2, markersize=4)
t_ref = 0.203
plot!(plt[2], [tf_opt, t_ref], [r_opt_f, r_opt_f]; color=:gray, linestyle=:dot, linewidth=1)
plot!(plt[2], [tf_bang, t_ref], [rf_bang, rf_bang]; color=:gray, linestyle=:dot, linewidth=1)
plot!(plt[2], [t_ref, t_ref], [rf_bang, r_opt_f]; color=:black, linewidth=1.5)
annotate!(plt[2], t_ref + 0.0008, (rf_bang + r_opt_f) / 2, text("+$(round(gain; digits=1)) %", 8, :left))
#nb plt
#md nothing # hide

#md # :::
#md plt # hide

# The bang-bang rocket climbs faster at first, but it burns all its fuel at full speed in the densest air. The optimal one holds back, keeps fuel for later, and ends higher.

#src The rocket animation (HTML only): the template is docs/src-literate/goddard-animation.html,
#src filled in by `Main.goddard_animation` (docs/make.jl), shown as the `text/html` output.
#md struct TourRawHTML                                                                      # hide
#md     raw::String                                                                          # hide
#md end                                                                                      # hide
#md Base.show(io::IO, ::MIME"text/html", h::TourRawHTML) = print(io, h.raw)                 # hide
#md let                                                                                      # hide
#md     X_opt = state(sol_cold).(t_opt)                                                      # hide
#md     X_bang = [[state(traj_bang1)(t) for t in t1_grid]; [state(traj_bang2)(t) for t in t2_grid]] # hide
#md     col(X, i) = [x[i] for x in X]                                                        # hide
#md     TourRawHTML(Main.goddard_animation(;                                                 # hide
#md         t1=t_opt, r1=col(X_opt, 1), v1=col(X_opt, 2), m1=col(X_opt, 3),                  # hide
#md         u1=control(sol_cold).(t_opt),                                                    # hide
#md         t2=t_bang, r2=col(X_bang, 1), v2=col(X_bang, 2), m2=col(X_bang, 3),              # hide
#md         u2=[fill(1.0, length(t1_grid)); fill(0.0, length(t2_grid))],                     # hide
#md         t_max=max(t_opt[end], t_bang[end]), m0=m0, mf=mf, r0=r0,                         # hide
#md         rf_opt=r_opt_f, rf_bang=rf_bang, tf_opt=t_opt[end], tf_bang=tf_bang,             # hide
#md         color_opt=palette(:default)[1], color_bang=palette(:default)[2]))                # hide
#md end                                                                                      # hide

#src ============================================================================
# ## Solving on a GPU
#src ============================================================================
#
# Moving to the GPU is a single token, `:gpu`, which auto-completes to `(:collocation, :exa, :madnlp, :gpu)`. It requires the `:exa` modeler (hence `@def`, not the macro-free API — cf. the definition section) plus an NVIDIA GPU.
#
# The GPU stack needs **three** packages: `MadNLPGPU`, `CUDA` and `CUDSS`. Whether the solve then runs depends on the machine: without a functional GPU (a laptop, a CI runner without a GPU), it fails. We wrap the call in a `try/catch` so that the tour keeps running either way, and print what happened.

#md Base.CoreLogging.disable_logging(Base.CoreLogging.Warn)   # hide
using MadNLPGPU
using CUDA
using CUDSS

println("CUDA.functional() = ", CUDA.functional())
try
    global sol_gpu = solve(goddard, :gpu; grid_size=1000, display=false)
    println("GPU solve succeeded: r(tf) = ", objective(sol_gpu))
catch e
    println("GPU solve failed: ", first(sprint(showerror, e), 400))
end
#md Base.CoreLogging.disable_logging(Base.CoreLogging.BelowMinLevel)   # hide
#md nothing                                                             # hide

# The output above tells which case the machine that built this page was in.

#md # For the full GPU setup, see [GPU](@ref solve-gpu).
#nb # For the full GPU setup, see [GPU](https://control-toolbox.org/OptimalControl.jl/dev/solve/gpu).

#src ============================================================================
# ## The indirect method
#src ============================================================================
#
# We now return to the **double integrator** `ocp` from the earlier sections. Its shooting has just two unknowns and is initialised by the direct costate above, which makes it ideal to *see* the indirect method. (The Goddard shooting is a *structured multi-arc* problem — see the links in the last section.)
#
# In control-toolbox we systematically pair the direct method with the **indirect** one, based on Pontryagin's Maximum Principle (PMP). With the pseudo-Hamiltonian
#
# ```math
# H(x,p,u) = p\,f(x,u) + p^0 f^0(x,u) \qquad (\text{normal case } p^0 = -1),
# ```
#
# the indirect method proceeds in three steps.
#
# **Step 1 — Maximising control.** The PMP yields the control in feedback form $u(x, p) = \arg\max_u H(x, p, u)$. Substituting back gives the maximised Hamiltonian
#
# ```math
# \mathbf{H}(x, p) = H(x, p, u(x, p)).
# ```
#
# **Step 2 — Boundary value problem.** The optimal trajectory satisfies the Hamiltonian system
#
# ```math
# \dot{x} = \nabla_p \mathbf{H}, \qquad \dot{p} = -\nabla_x \mathbf{H},
# ```
#
# with boundary conditions $x(t_0) = x_0$, $x(t_f) = x_f$.
#
# **Step 3 — Shooting function.** Let $\varphi_{t_0, x_0, p_0}(\cdot)$ denote the flow of the Hamiltonian vector field from $(x_0, p_0)$. The shooting function
#
# ```math
# S(p_0) = \pi(\varphi_{t_0, x_0, p_0}(t_f)) - x_f, \qquad \pi(x, p) = x,
# ```
#
# measures the miss at $t_f$: solving the BVP reduces to finding $p_0$ such that $S(p_0) = 0$.
#
#md # To picture what each iteration does, here is an analogy: a player throws a ball. The two unknowns are the **angle** and the **speed** of the throw, as $p_0$ has two components, and the ball must be in the hoop at a fixed time $T$, as $x(t_f) = x_f$ must hold at the fixed time $t_f$. Each throw is one trial value of $p_0$.

#src The basketball animation (HTML only): the template is
#src docs/src-literate/shooting-animation.html, filled in by `Main.shooting_animation`
#src (docs/make.jl), shown as the `text/html` output. Nothing appears in the notebook.
#md using LinearAlgebra                                                                     # hide
#md let                                                                                      # hide
#md     g_b, T_b, h_b, x_t, y_t = 9.81, 1.1, 2.0, 4.6, 3.05                                  # hide
#md     ball(u, t) = [u[2]*cos(u[1])*t, h_b + u[2]*sin(u[1])*t - g_b*t^2/2]                  # hide
#md     S_b(u) = ball(u, T_b) - [x_t, y_t]                                                   # hide
#md     J_b(u) = [-u[2]*sin(u[1])*T_b  cos(u[1])*T_b; u[2]*cos(u[1])*T_b  sin(u[1])*T_b]     # hide
#md     tol_b = 1e-3                                                                         # hide
#md     shots = [[deg2rad(34), 6.5]]                                                         # hide
#md     while norm(S_b(shots[end])) > tol_b && length(shots) < 10                            # hide
#md         push!(shots, shots[end] - J_b(shots[end]) \ S_b(shots[end]))                    # hide
#md     end                                                                                  # hide
#md     TourRawHTML(Main.shooting_animation(;                                                # hide
#md         shots=shots, residuals=[norm(S_b(u)) for u in shots],                            # hide
#md         xt=x_t, yt=y_t, h0=h_b, g=g_b, T=T_b, tol=tol_b, color=palette(:default)[1]))    # hide
#md end                                                                                      # hide

#md # !!! note "Reading the animation"
#md #     - The **residual** is what the shooting function $S(p_0)$ measures: the gap between the ball and the hoop at time $T$. The dashed arrow draws it, and the table gives its length in metres.
#md #     - Newton's method uses how this gap changes with the angle and the speed to correct them. Close to the solution the residual falls very fast, as the last column shows.
#md #     - The ball seems to be in the hoop one correction before the end: the table tells how much accuracy is still gained.

# For the energy problem, $H = p_1 v + p_2 u - u^2/2$, so the maximiser is $u = p_2$.

using NonlinearSolve   # nonlinear equations (shooting); the ODE solver is already loaded

## maximising control in feedback form
u_feedback(x, p) = p[2]

## Hamiltonian flow of the OCP
φ = Flow(ocp, u_feedback)

## state projection π(x, p) = x
proj((x, p)) = x

## shooting function
S(p0) = proj(φ(t0, x0, p0, tf)) - xf
#md nothing # hide

# **The shooting is initialised with the costate of the direct solution** — the very adjoint we highlighted above:

nle!(s, p0, _) = (s[:] = S(p0))

p_of_t = costate(direct_sol)     # costate as a function of time
p0_guess = p_of_t(t0)              # initial costate from the direct method

prob = NonlinearProblem(nle!, p0_guess)
shooting_sol = NonlinearSolve.solve(prob; show_trace=Val(true))
p0_sol = shooting_sol.u

println("costate p0 = ", p0_sol)
println("shoot S(p0) = ", S(p0_sol))

# The shooting converges to $p_0 = (12, 6)$, the exact initial costate: the costate of the direct solution was already very close to it. The shooting of the double integrator is linear in $p_0$, so a single Newton step suffices, as the trace above shows; the basketball is not linear, which is why it took several corrections.

#-
#md @assert isapprox(p0_sol, [12, 6]; atol=1e-8)   # hide
#md nothing                                         # hide

# Reconstruct the indirect solution from the flow and overlay it with the direct solution:

indirect_sol = φ((t0, tf), x0, p0_sol)

plt_compare = plot(direct_sol; label="direct", size=(800, 710), legend=false)
plot!(plt_compare, indirect_sol; label="indirect")
plot!(plt_compare; subplot=1, legend=:best)   # one legend, on the first subplot

#md # See [From an OCP](@ref flows-from-ocp) for the flow construction, and the [indirect simple shooting tutorial](@extref Tutorials tutorial-indirect-simple-shooting).
#nb # See [From an OCP](https://control-toolbox.org/OptimalControl.jl/dev/flows/from-ocp) for the flow construction, and the [indirect simple shooting tutorial](https://control-toolbox.org/Tutorials.jl/stable/tutorial-iss.html).

#src ============================================================================
# ## Going further
#src ============================================================================
#
# **Variables & parameters.** Beyond the control, one can optimise **parameters** naturally, both in an OCP (the `variable` keyword of the DSL) and in a differential-constraint optimisation problem **without any control** (a *control-free* problem).
#md # See [control-free problems](@ref examples-control-free).
#nb # See [control-free problems](https://control-toolbox.org/OptimalControl.jl/dev/examples/control-free).
#src NOTE(v1): parameter estimation is only *mentioned* here. The worked example is an
#src   extension (out of v1) — see .reports/tutorial-brainstorming.md "Extensions futures".
#
# **Advanced examples** (each does both direct and indirect):
#
#md # - Singular control (control-affine systems) — [singular control](@ref examples-singular-control)
#md # - State constraint — [state constraint](@ref examples-state-constraint)
#md # - Goddard problem — free final time, a singular arc, a state constraint and a structured shooting all at once — [Goddard tutorial](@extref Tutorials tutorial-goddard)
#nb # - Singular control (control-affine systems) — <https://control-toolbox.org/OptimalControl.jl/dev/examples/singular-control>
#nb # - State constraint — <https://control-toolbox.org/OptimalControl.jl/dev/examples/state-constraint>
#nb # - Goddard problem — free final time, a singular arc, a state constraint and a structured shooting all at once — <https://control-toolbox.org/Tutorials.jl/stable/tutorial-goddard.html>
#
#md # **Discrete continuation** — warm-starting across a family of problems (homotopy on a physical parameter), the grown-up version of the grid continuation above: [Discrete continuation](@extref Tutorials tutorial-continuation).
#nb # **Discrete continuation** — warm-starting across a family of problems (homotopy on a physical parameter), the grown-up version of the grid continuation above: <https://control-toolbox.org/Tutorials.jl/stable/tutorial-continuation.html>.
#
#src ============================================================================
#src END OF SOCLE (v1). Extensions (parameter estimation worked out, singular, state
#src constraint, Goddard) go below in later versions — see brainstorming doc.
#src ============================================================================
