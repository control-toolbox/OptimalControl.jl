# Flows (indirect) — specification

**PR**: 8 · **Depends on**: PR 6 (and reads from PR 7) · **Status**: specification
**Scope**: `docs/src/flows/*`, plus one re-export decision in `src/imports/ctflows.jl`

## Objective

The largest and most-changed section. It covers three distinct jobs that share one
constructor:

1. **Indirect optimal control** — build the Hamiltonian flow of the PMP, write a shooting
   function, solve it.
2. **Simulation** — integrate a controlled system under an open-loop or feedback control, and
   inspect the result exactly like an optimal control solution.
3. **Inspection** — pull the Hamiltonian, the Hamiltonian vector field, the pseudo-Hamiltonian
   or the control law back out of a flow you built.

Profiles: **Geometric** (1, 3) and **Simulator** (2). Job 2 is currently invisible on the
site; job 3 is documented nowhere.

> **Every page in this section opens with `using OrdinaryDiffEqTsit5`.** SciML is not a hard
> dependency; without an integrator, `Flow` fails with a bare `MethodError`. No exceptions.

## Pages

| id | title | path | source |
| --- | --- | --- | --- |
| `flows-overview` | Flows and indirect methods | `flows/overview.md` | **new** |
| `flows-from-ocp` | Flows from an optimal control problem | `flows/from-ocp.md` | `attic/manual-flow-ocp.md` (heavy rework) |
| `flows-from-hamiltonians` | Flows from Hamiltonians and vector fields | `flows/from-hamiltonians.md` | `attic/manual-flow-others.md` (108 lines → full page) |
| `flows-simulation` | Simulating a controlled system | `flows/simulation.md` | **new** |
| `flows-accessors` | What you can get back from a flow | `flows/accessors.md` | **new** |
| `flows-multi-phase` | Multi-phase flows | `flows/multi-phase.md` | **new** — split out of `attic/manual-flow-ocp.md` §concatenation |
| `flows-constrained-arcs` | Constrained arcs | `flows/constrained-arcs.md` | `attic/manual-flow-ocp.md` §state constraints |
| `flows-shooting` | Writing a shooting function | `flows/shooting.md` | **new** — harvest `attic/example-double-integrator-time.md` |

---

## Reference: the constructor catalogue

Every page in this section must agree with this table. Verified against **CTFlows 0.16.3-beta**
(`~/.julia/packages/CTFlows/PsDmR/src/Flows/building.jl`), which is what OptimalControl
resolves — not the `../CTFlows.jl` checkout.

| # | Call | Line | Returns |
| --- | --- | --- | --- |
| 1 | `Flow(VectorField(f))` | 33 | `StateFlow` |
| 2 | `Flow(HamiltonianVectorField(hvf))` | 66 | `HamiltonianFlow` |
| 3 | `Flow(Hamiltonian(h))` | 118 | `HamiltonianFlow` (AD) |
| 4 | `Flow(ocp)` — **control-free only** | 157 | `OptimalControlFlow` |
| 5 | `Flow(PseudoHamiltonian(h̃), law)` | 269 | `HamiltonianFlow` |
| 6 | `Flow(PseudoHamiltonianVectorField(h̃vf), law)` | 406 | `HamiltonianFlow` |
| 7 | `Flow(ControlledVectorField(fc), law)` | 478 | `ControlledFlow` |
| 8 | `Flow(ocp, law::ControlLaw)` | 557 | `OptimalControlFlow` or `ControlledFlow` |
| 9 | `Flow(ocp, u::Function)` | 792 | `OptimalControlFlow` (auto-wrapped `DynClosedLoop`) |
| — | `Flow(ocp, ::Any, args...)` | 1019 | **always throws** `PreconditionError` |
| 10 | `Flow(::SciMLBase.AbstractODEFunction)` / `(::AbstractODEProblem)` | SciML ext | `StateFlow` / `SciMLProblemFlow` |

**There is no `Flow(f::Function)`.** A bare function must be wrapped in the `CTBase.Data` type
that says what it is. PR 3 makes the old spelling throw with that message.

Which law type selects which behaviour:

| Law | With an OCP | With a `ControlledVectorField` | With a `PseudoHamiltonian` |
| --- | --- | --- | --- |
| `DynClosedLoop((x,p) -> …)` | `OptimalControlFlow` (Hamiltonian) | `PreconditionError` | ✅ the only accepted law |
| `ClosedLoop(x -> …)` | `ControlledFlow` (state) | ✅ | `PreconditionError` |
| `OpenLoop(t -> …)` | `ControlledFlow` (state) | ✅ | `PreconditionError` |

Call signatures:

```julia
(f::AbstractStateFlow)(t0, x0, tf; variable, unsafe)
(f::AbstractStateFlow)(tspan, x0; variable, unsafe)
(f::AbstractHamiltonianFlow)(t0, x0, p0, tf; variable, unsafe, variable_costate)
(f::AbstractHamiltonianFlow)(tspan, x0, p0; variable, unsafe, variable_costate)
```

Three keywords that must be explained somewhere in the section:

- **`variable=v`** — mandatory on a `NonFixed` problem. Omitting it raises a
  `PreconditionError` whose suggestion is literally *"Pass `variable=v` when calling the
  flow"*. There is **no positional slot** any more.
- **`variable_costate=true`** — integrates $\dot p_v = -\partial H/\partial v$ and returns
  `(xf, pf, pvf)`. This replaced `augment=true`.
- **`unsafe=true`** — do not check the ODE retcode, do not throw on failure. **Essential
  inside a shooting loop**, where an intermediate failure should surface through the residual
  rather than abort the solve. Document it on `flows/shooting.md`.

---

## Page details

### `flows/overview.md` — new

- **Purpose** — the map of the section, and the PMP recap that makes the rest make sense.
- **Outline**
  - `## Why flows` — direct discretises, indirect integrates; when each wins
  - `## The Pontryagin Maximum Principle, briefly` — pseudo-Hamiltonian
    $H(t,x,p,u,v) = p \cdot f + p^0 f^0$, the maximisation condition, the control law
    $u^*(x,p)$, the boundary/transversality conditions
  - `## From the PMP to a flow` — you supply $u^*$, `Flow` gives you $\exp(t\vec H)$
  - `## Three things this section does` — indirect solving, simulation, inspection
  - `## Before you start` — `using OrdinaryDiffEqTsit5`, and what happens without it
  - `## Choosing an integrator and its options` — `describe(:sciml)`, `describe(:di)`;
    `alg=`, `reltol=`, `abstol=`, `saveat=`, `dense=`; the AD family routes to `:di`,
    the integrator family to `:sciml`
  - `## CPU and GPU` — `method=:cpu` / `:gpu`, the same tokens as `solve`
  - `## Where to go`
- **API covered** — `Flow` (named, not detailed), `describe(:sciml)`, `describe(:di)`,
  `SciML`, `AbstractIntegrator`.
- **API traps** — `describe` covering the *indirect* strategies (`:di`, `:sciml`) is a real
  capability nobody documents. `OptimalControl.get_full_strategy_registry()` merges the solve
  registry with `CTFlows.Flows.flow_registry()`; mention it as the introspection entry point.

### `flows/from-ocp.md`

- **Purpose** — the main path: an OCP plus a control law gives you the PMP flow.
- **Outline**
  - `## The idea` — you did the PMP by hand, you have $u^*(x,p)$
  - `## The simplest form` — `Flow(ocp, (x, p) -> p[2])`
  - `## Passing a typed law` — `Flow(ocp, DynClosedLoop((x,p) -> …))`, and why you would
  - `## Non-autonomous problems` — `u(t, x, p)`
  - `## Problems with a variable` — `u(x, p, v)` / `u(t, x, p, v)`; **`variable=` is
    mandatory at call time**
  - `## Free final time and the augmented costate` — `variable_costate=true`
  - `## Control-free problems` — `Flow(ocp)` with no law; link `@ref modelling-without-control`
  - `## Total or partial Hamiltonian` — `hamiltonian_type=:total` (default; composes a
    `ComposedHamiltonian`, differentiates through the law) vs `:partial`
    (`PseudoHamiltonianSystem`, partials at frozen feedback). Tested by
    `test/suite/problems/test_hamiltonian_type.jl`
  - `## What comes back` — an `OptimalControlFlow`; a trajectory call returns a
    `CTModels.Solution`, so everything in `@ref results-solution` applies
- **API covered** — `Flow`, `DynClosedLoop`, `ControlLaw`, `variable=`, `variable_costate=`,
  `unsafe=`, `hamiltonian_type=`, `method=`.
- **Source** — `attic/manual-flow-ocp.md` (685 lines, 23 `Flow` calls). Split: concatenation
  → `multi-phase.md`, state constraints → `constrained-arcs.md`, bare-vector-field →
  `from-hamiltonians.md`. What is left is this page.
- **API traps** — the whole page. Specifically:
  - `Flow(x -> x)` at `attic/manual-flow-ocp.md:504-505` no longer exists.
  - `Flow(ocp, u, g, μ)` at `attic/manual-flow-ocp.md:594` is now keywords.
  - `augment=true` → `variable_costate=true`.
  - `OptimalControl.Hamiltonian(...)` → bare `Hamiltonian(...)`.
  - `u`'s arity is **validated** against the OCP's time/variable dependence; a mismatch is an
    `IncorrectArgument`. Show the error once — it is a good error.

### `flows/from-hamiltonians.md`

- **Purpose** — build a flow when you do *not* start from an OCP. Currently 108 lines; this is
  a full page.
- **Outline** — one section per constructor, each with a runnable snippet:
  - `## From a vector field` — `Flow(VectorField(f))`; the plain ODE case
  - `## From a Hamiltonian` — `Flow(Hamiltonian(h))`; $\vec H$ obtained by AD
  - `## From a Hamiltonian vector field` — `Flow(HamiltonianVectorField(hvf))`; no AD
  - `## From a pseudo-Hamiltonian and a control law` —
    `Flow(PseudoHamiltonian(h̃), DynClosedLoop(u))`; `hamiltonian_type=`
  - `## From a pseudo-Hamiltonian vector field and a control law` —
    `Flow(PseudoHamiltonianVectorField(h̃vf), DynClosedLoop(u))`; no `hamiltonian_type` here
  - `## From a SciML problem` — `Flow(ODEFunction(...))`, `Flow(ODEProblem(...))`
  - `## Non-autonomous and variable-dependent forms` — `is_autonomous=`, `is_variable=`
  - `## Summary table` — which constructor uses AD, which returns what
- **API covered** — `Flow`, `VectorField`, `Hamiltonian`, `HamiltonianVectorField`,
  `PseudoHamiltonian`, `PseudoHamiltonianVectorField`, `ControlledVectorField`,
  `ComposedHamiltonian`, `ComposedVectorField`, `DynClosedLoop`, `is_autonomous=`,
  `is_variable=`, `is_inplace=`.
- **Source** — `attic/manual-flow-others.md` gives the skeleton; everything else is new.
- **API traps** — `attic/manual-flow-others.md:98` writes
  `Flow((t,x) -> …; autonomous=false)`. Both halves are wrong now: no `Flow(::Function)`, and
  the keyword is `is_autonomous`. Correct: `Flow(VectorField(f; is_autonomous=false))`.

### `flows/simulation.md` — new, serves the Simulator profile

- **Purpose** — *"construire des flots à partir de contrôles en boucle ouverte pour calculer
  des solutions particulières du système contrôlé"*, and the closed-loop counterpart.
- **Outline**
  - `## The idea` — you have a controlled system and a control; you want the trajectory, not
    an optimum
  - `## Open loop` — `Flow(ControlledVectorField(fc), OpenLoop(t -> …))`
  - `## Closed loop (feedback)` — `Flow(ControlledVectorField(fc), ClosedLoop(x -> …))`
  - `## From an optimal control problem` — `Flow(ocp, OpenLoop(u))` returns a `ControlledFlow`
    that also carries the **objective**, so you can evaluate a candidate control's cost
  - `## Inspecting the trajectory` — `state`, `control`, `objective`, `time_grid` — the same
    accessors as a solution; link `@ref results-solution`
  - `## Plotting it` — `plot(traj)`; link `@ref results-plot`
  - `## Point vs trajectory` — `f(t0, x0, tf)` returns the endpoint;
    `f((t0, tf), x0)` returns a trajectory
- **API covered** — `Flow`, `ControlledVectorField`, `OpenLoop`, `ClosedLoop`, `state`,
  `control`, `objective`, `time_grid`, `plot`.
- **API traps**
  - **`OpenLoop` is now unconditionally non-autonomous**: the law is `u(t)` or `u(t, v)`.
    `OpenLoop(() -> 1.0)` is gone. This is a semantic change that will not announce itself as
    an import error — give it a `!!! warning`.
  - `DynClosedLoop` with a `ControlledVectorField` is a `PreconditionError`.
  - `Flow(ControlledVectorField, law)` returns a trajectory with **no objective** (there is no
    OCP); `Flow(ocp, OpenLoop(u))` does have one. Say which is which.
  - The trajectory type is `StateFlowTrajectory` (renamed from `ControlledTrajectory`, no
    alias) — but it is **not re-exported**, so never name it in an example.

### `flows/accessors.md` — new; the user asked for this explicitly

- **Purpose** — *"quand il construit un flot il a accès à des accesseurs. Par exemple depuis
  un ocp et une loi de commande, il peut récupérer le hamiltonien, ou le champ de vecteurs
  hamiltoniens."*
- **Outline**
  - `## What a flow remembers`
  - `## The Hamiltonian` — `hamiltonian(f)` → callable `H(t,x,p,v)`
  - `## The Hamiltonian vector field` — `hamiltonian_vector_field(f)` →
    `HamiltonianVectorField` $= (\partial_p H, -\partial_x H)$
  - `## The pseudo-Hamiltonian and the control law` — `pseudo_hamiltonian(f)` →
    $\tilde H(t,x,p,u,v)$, `control_law(f)` → the law you passed
  - `## Gradients` — `get_hamiltonian_gradient(f)`, `get_variable_gradient(f)`,
    `get_pseudo_hamiltonian_gradient(f)`, `get_pseudo_variable_gradient(f)`
  - `## Building $\vec H$ from a Hamiltonian without a flow` —
    `hamiltonian_vector_field(h::AbstractHamiltonian)`
  - `## What is available on which flow` — a table
  - `## The underlying system and integrator` — `system(f)`, `integrator(f)`; escape hatch
- **Availability table** (must be in the page, it is the whole point):

| Built from | `hamiltonian` | `hamiltonian_vector_field` | `pseudo_hamiltonian` | `control_law` |
| --- | --- | --- | --- | --- |
| `Hamiltonian(h)` | ✅ | ✅ | ✗ | ✗ |
| `HamiltonianVectorField(hvf)` | ✗ | ✅ | ✗ | ✗ |
| `PseudoHamiltonian(h̃), law` | ✅ | ✅ | ✅ | ✅ |
| `PseudoHamiltonianVectorField(h̃vf), law` | ✗ | ✅ | ✗ | ✗ |
| `ocp, law` | ✅ | ✅ | ✅ | ✅ |
| `VectorField(f)` | ✗ | `vector_field` | ✗ | ✗ |

Asking for an unavailable accessor raises `IncorrectArgument`.

- **✅ Re-export gap — decided 2026-08-09: close it.**

  `src/imports/ctflows.jl:16` re-exports `control_law` and `pseudo_hamiltonian` but **not**
  their siblings `hamiltonian`, `hamiltonian_vector_field`, `vector_field`, `system`,
  `integrator`, or the four `get_*_gradient` functions — even though all are exported by
  `CTFlows.Flows` / `CTFlows.Systems`. As it stands the page would write
  `CTFlows.Systems.hamiltonian(f)` for one accessor and bare `control_law(f)` for its
  sibling, which is indefensible.

  **PR 8 adds to `src/imports/ctflows.jl`:**

  ```julia
  @reexport import CTFlows.Systems:
      hamiltonian, hamiltonian_vector_field, vector_field,
      get_hamiltonian_gradient, get_variable_gradient,
      get_pseudo_hamiltonian_gradient, get_pseudo_variable_gradient
  ```

  Verified against the resolved environment: none of these names collides with anything
  CTBase, CTModels, CTSolvers or CTDirect exports. `system` and `integrator` stay
  **unexported** — too generic for a DSL surface — and the page qualifies them as
  `CTFlows.Flows.system(f)` in the escape-hatch section.

  `test/suite/reexport/test_ctflows.jl` must gain the matching `reexports(...)` assertions in
  the same PR, and [`99-api-coverage.md`](99-api-coverage.md) §8 must move these rows into
  the exported table.

### `flows/multi-phase.md` — new (split out)

- **Purpose** — concatenate arcs: bang–bang switchings, jumps, boundary arcs.
- **Outline**
  - `## Concatenating two flows` — `f1 * (t1, f2)`
  - `## Jumps` — `f1 * (t1, jump, f2)`; on a Hamiltonian flow,
    `h1 * (t, jump_x, jump_p, h2)`
  - `## Jumps as callables` — `x -> x'`, `(x,p) -> (x',p')`, or `nothing`
  - `## Calling a multi-phase flow`
  - `## Inspecting one` — `n_phases`, `get_flow`, `get_flows`, `get_switching_time`,
    `get_switching_times`, `get_jump`, `get_jumps`
  - `## Worked example` — the bang–bang time-optimal double integrator
- **API covered** — `Base.:*` on flows, `MultiPhaseFlow`, `MultiPhaseStateFlow`,
  `MultiPhaseHamiltonianFlow`, `AnyMultiPhaseFlow`, `n_phases`, `get_flow`, `get_flows`,
  `get_switching_time`, `get_switching_times`, `get_jump`, `get_jumps`.
- **Source** — `attic/manual-flow-ocp.md` §concatenation +
  `attic/example-double-integrator-time.md`.
- **API traps** — the multi-phase accessors are **all newly re-exported** and appear on no
  current page. This page is their only home.

### `flows/constrained-arcs.md`

- **Purpose** — flows on a boundary arc, with a path constraint and its multiplier.
- **Outline**
  - `## The setting` — a state constraint active on a sub-interval
  - `## Building the constrained flow` — `Flow(ocp, u; constraint=g, multiplier=μ)`
  - `## Three ways to give the constraint` — a plain `Function`, a `Data.StateConstraint` /
    `ControlConstraint` / `MixedConstraint` / `PathConstraint`, or **a `Symbol` naming a
    `:path` constraint already declared in the OCP**
  - `## Several constraints at once` — matched tuples
  - `## Assembling the arcs` — unconstrained → boundary → unconstrained, with the costate
    jump; link `@ref flows-multi-phase`
  - `## Partial Hamiltonian on a constrained arc` — now supported
- **API covered** — `Flow` with `constraint=`/`multiplier=`, `StateConstraint`,
  `ControlConstraint`, `MixedConstraint`, `PathConstraint`, `Multiplier`.
- **Source** — `attic/manual-flow-ocp.md` §state constraints, §jump on the costate;
  `attic/example-state-constraint.md` (518 lines) for the worked material.
- **API traps**
  - Positional `Flow(ocp, u, g, μ)` is gone; the keywords come **as a pair** — one without the
    other is an `IncorrectArgument`.
  - The `Symbol` spelling (`constraint=:vmax`) is a **capability gain**, not a rename. Lead
    with it; it is the nicest thing in this API.
  - `constraint=`/`multiplier=` on a **control-free** `Flow(ocp)` are rejected.

### `flows/shooting.md` — new

- **Purpose** — the payoff: turn a flow into a shooting function and solve it.
- **Outline**
  - `## The shooting equation` — unknown $p_0$ (and switching times, and $t_f$)
  - `## A simple shooting function` — out-of-place
  - `## In-place, for the solver`
  - `## Solving it` — `NonlinearSolve`
  - `## `unsafe=true` inside the loop` — why an intermediate integration failure should
    become a residual, not an exception
  - `## Free final time` — the extra transversality equation, and `variable_costate=true`
  - `## Multiple shooting and switching times` — unknowns include the $t_i$; link
    `@ref flows-multi-phase`
  - `## Getting a starting point from a direct solve` — take `costate(sol)(t0)` from a
    direct solution; this is the standard workflow and deserves a section of its own
  - `## Checking against the direct solution`
- **API covered** — `Flow`, `costate`, `state`, `control`, `variable`, `time_grid`,
  `unsafe=`, `variable_costate=`, plus `NonlinearSolve`.
- **Source** — new page assembled from `attic/example-double-integrator-time.md`
  (in-place shooting, switching-time detection, NLE resolution) and
  `attic/tutorial.md` §indirect.
- **API traps** — every flow call in the harvested material needs the positional variable and
  `augment=` audit.

---

## Outgoing links

| From | To |
| --- | --- |
| `overview.md` | every page in the section, `@ref solve-overview`, `@ref geometry-overview` |
| `from-ocp.md` | `@ref results-solution`, `@ref modelling-without-control`, `@ref flows-accessors`, `@ref flows-shooting` |
| `from-hamiltonians.md` | `@ref geometry-lift`, `@ref flows-accessors` |
| `simulation.md` | `@ref results-solution`, `@ref results-plot`, `@ref modelling-without-control` |
| `accessors.md` | `@ref flows-from-ocp`, `@ref geometry-overview` |
| `multi-phase.md` | `@ref flows-constrained-arcs`, `@ref examples-double-integrator-time` |
| `constrained-arcs.md` | `@ref flows-multi-phase`, `@ref examples-state-constraint` |
| `shooting.md` | `@ref solve-overview`, `@ref geometry-poisson`, `@ref examples-singular-control` |

## Acceptance criteria

- [x] Every page's preamble loads `OrdinaryDiffEqTsit5`.
- [x] All ten constructor forms of the catalogue appear, each with a runnable snippet —
      confirmed live across `from-hamiltonians.md` (6) and `from-ocp.md`/`simulation.md`
      (the 4 OCP/law forms).
- [x] The law/constructor compatibility table and the accessor availability table are on the
      site (`overview.md`/`from-ocp.md` state the law table piecewise; the accessor table is
      `accessors.md`'s own centrepiece, verified cell-by-cell, with one spec cell corrected —
      `hamiltonian(f)` on a `HamiltonianVectorField`-built flow genuinely throws
      `IncorrectArgument`).
- [x] `simulation.md` and `accessors.md` exist — neither has any predecessor.
- [x] The re-export decision on `hamiltonian` / `hamiltonian_vector_field` / `vector_field` /
      `get_*_gradient` is taken and implemented (`src/imports/ctflows.jl`), and
      `test/suite/reexport/test_ctflows.jl` has the matching testset (73/73 passing).
- [x] `OpenLoop`'s unconditional non-autonomy carries a `!!! warning` (`simulation.md`) —
      worded precisely after live verification: a zero-arg closure builds without error and
      only fails on first call, not at construction as one might assume.
- [x] No page contains a positional variable, `augment=`, `Flow(f::Function)`,
      `Flow(ocp,u,g,μ)`, `autonomous=`, or `OptimalControl.Hamiltonian` **as working syntax**.
      Three surviving matches on a grep, all deliberate: `from-hamiltonians.md` shows the
      stale `VectorField(g; autonomous=false)` failing (the point of that section), and
      `from-ocp.md` mentions `augment=true` once in prose, explaining it was renamed to
      `variable_costate=true` — neither presents the old spelling as something that works.
- [x] `unsafe=true` is explained where it matters — `shooting.md`, demonstrated with a
      synthetic finite-time-blowup ODE since the worked double-integrator example itself is
      too well-behaved to blow up even under a wild guess.

**Also found and fixed, beyond the checklist above:**
- A reproducible Documenter build quirk, isolated but not fully root-caused: `using
  OptimalControl` inside Documenter's `@example` sandbox (a `baremodule`) fails to bind
  `hamiltonian`/`hamiltonian_vector_field`/`vector_field`/the four `get_*_gradient` functions
  specifically, while `Flow`/`control_law`/`pseudo_hamiltonian` (re-exported the exact same way
  from the same `CTFlows.Systems` module) bind fine. Confirmed via extensive bisection that
  real, normal usage (`using OptimalControl` in an ordinary session or module) is unaffected —
  this is specific to the sandboxed `baremodule` Documenter's `@example`/`@repl` blocks run in.
  Worked around with a hidden (`# hide`), redundant direct import in `accessors.md`'s setup
  block; does not change what a reader sees or what a real user needs to do.
- The spec's own claim that a flow without an integrator loaded fails with a bare `MethodError`
  — corrected on `overview.md`: verified live it's actually a clean `ExtensionError`.
- `method=:cpu`/`:gpu` corrected to be a construction-time keyword (`Flow(...; method=:gpu)`),
  not a call-time one as the spec's `overview.md` outline could be read to imply.
