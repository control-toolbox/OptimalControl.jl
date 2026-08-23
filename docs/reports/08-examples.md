# Examples — specification

**PR**: 10 · **Depends on**: PRs 8, 9 · **Status**: specification
**Scope**: `docs/src/examples/*`

## Objective

Complete, self-contained problems worked end to end. A guide answers *"how do I do X"*; an
example answers *"what does a real problem look like"*. Each one is a story with a result,
not a feature demonstration.

Also the section's second job: **be the entry point for the Geometric profile**, who arrives
looking for a singular arc or a state constraint, not for a tutorial.

## Pages

Six existing, plus one new. Ordered by difficulty — the sidebar order is the reading order.

| id | title | path | source |
| --- | --- | --- | --- |
| `examples-double-integrator-energy` | Energy minimisation | `examples/double-integrator-energy.md` | `attic/example-double-integrator-energy.md` |
| `examples-double-integrator-time` | Time minimisation (bang–bang) | `examples/double-integrator-time.md` | `attic/example-double-integrator-time.md` |
| `examples-control-free` | Parameter estimation without a control | `examples/control-free.md` | `attic/example-control-free.md` |
| `examples-control-and-variable` | Control and variable together | `examples/control-and-variable.md` | `attic/example-control-and-variable.md` |
| `examples-singular-control` | Singular control | `examples/singular-control.md` | `attic/example-singular-control.md` |
| `examples-state-constraint` | State constraint | `examples/state-constraint.md` | `attic/example-state-constraint.md` |
| `examples-simulation` | Simulating a controlled system | `examples/simulation.md` | **new** (optional — see §"Scope decision") |

### Scope decision

`examples-simulation` is the only genuinely new example, and it exists because the Simulator
profile has no story of its own: every current example is an optimisation. **Recommendation**:
write it if `flows/simulation.md` turns out to need more than a snippet to be convincing;
otherwise drop it and let the guide carry the load. Decide when PR 8 is done, not before.

---

## Common structure

Every example page follows the same skeleton. Consistency is what makes a gallery usable.

```markdown
# [Title](@id examples-<slug>)

## The problem
Physical setting, then the mathematics.

## Definition
`@def`, executed.

## Direct solution
`solve`, `plot`.

## Indirect solution           ← where applicable
PMP by hand, the flow, the shooting function, the check against the direct solution.

## Comparison                  ← where both exist
Same picture, both methods.

## See also
Guides this example exercises.
```

The "See also" is not decoration: it is how a reader who arrived from a search engine finds
the guide that explains what they just read.

---

## Page details

### `examples/double-integrator-energy.md`

- **Story** — the canonical first problem: $\ddot q = u$, minimise $\int \tfrac12 u^2$.
- **Covers** — `@def`, `solve`, `plot`, `time_grid`, `costate`, `Flow`.
- **Source** — `attic/example-double-integrator-energy.md` (169 lines).
- **API traps** — the indirect section builds a Hamiltonian flow; audit the preamble
  (`using OrdinaryDiffEqTsit5`) and every flow call.
- **Note** — this problem also appears in `index.md` and
  `getting-started/first-problem.md`. That repetition is deliberate; keep the three
  definitions **character-identical** so the reader recognises it.

### `examples/double-integrator-time.md`

- **Story** — time-optimal double integrator; bang–bang control with one switching.
- **Covers** — `@def`, `solve`, `plot`, `plot!`, `time_grid`, `costate`, `variable`, `Flow`,
  flow concatenation `*`, in-place shooting, switching-time detection, NLE resolution.
- **Source** — `attic/example-double-integrator-time.md` (204 lines).
- **Role** — this is the **reference example for `flows/multi-phase.md` and
  `flows/shooting.md`**. Those two guides harvest from it; keep it the canonical version and
  have the guides link here rather than duplicate.
- **API traps** — free final time means a `NonFixed` problem: `variable=` is mandatory on
  every flow call, and the transversality condition may want `variable_costate=true`. Audit
  every call.

### `examples/control-free.md`

- **Story** — two parameter-estimation problems with no control: exponential growth rate
  ($p = 0.5$) and harmonic-oscillator pulsation ($\omega = \pi/2$). Solved directly, then
  indirectly with a Hamiltonian flow and the augmented costate.
- **Covers** — `@def` without a control, `solve`, `plot`, `plot!`, `time_grid`, `costate`,
  `variable`, `model`, `objective`, `Flow(ocp)`.
- **Source** — `attic/example-control-free.md` (378 lines).
- **Relation to the guide** — `modelling/without-control.md` (PR 5) is the *guide*; this is
  the *example*. The guide harvests the intro and both fixtures; this page keeps the full
  worked story including the indirect part. Cross-link both ways.
- **API traps** — the augmented-costate section used `augment=true`; it is now
  `variable_costate=true`. `Flow(ocp)` with no law is correct **here and only here** (the
  control-free case).

### `examples/control-and-variable.md`

- **Story** — the same two systems, now with a control input and a quadratic control cost:
  simultaneous parameter *and* control estimation.
- **Covers** — same list as `control-free.md`.
- **Source** — `attic/example-control-and-variable.md` (381 lines).
- **Note** — this pair (`control-free` → `control-and-variable`) is the site's clearest
  illustration of what adding a control does to a problem. Keep them adjacent in the sidebar
  and cross-link them explicitly.

### `examples/singular-control.md` — the Geometry payoff

- **Story** — a problem whose optimal control has a singular arc; the singular control is
  computed by hand, then again with Poisson brackets, then the whole thing is solved by
  shooting.
- **Covers** — `@def`, `solve`, `plot`, `plot!`, `state`, `costate`, `variable`, `time_grid`,
  `Flow`, **`Lift`**, **`@Lie`** in its `{}` Poisson form.
- **The computation** — this is the passage the whole Geometry section exists to support:

  ```julia
  H0 = Lift(F0)
  H1 = Lift(F1)
  H01  = @Lie {H0, H1}
  H001 = @Lie {H0, H01}
  H101 = @Lie {H1, H01}
  us(x, p) = -H001(x, p) / H101(x, p)
  ```

- **Source** — `attic/example-singular-control.md` (351 lines).
- **API traps** — good news: `Lift` and the `@Lie {}` form both survive unchanged, so the
  geometry code is **already correct**. What needs auditing is the flow half (preamble,
  positional variable, `augment=`) and any `OptimalControl.` qualification on now-exported
  types.
- **Role** — `geometry/poisson.md` and `geometry/lie-macro.md` both forward-link here as the
  worked application. Do not duplicate the derivation in the guides.

### `examples/state-constraint.md`

- **Story** — first-order and second-order state constraints: boundary arcs, the multiplier
  $\mu$, costate jumps, multi-arc concatenation.
- **Covers** — `@def`, `solve`, `plot`, `plot!`, `state`, `costate`, `time_grid`, `Flow`
  (five of them, including the constrained-arc form), flow concatenation with jumps.
- **Source** — `attic/example-state-constraint.md` (518 lines — the longest page on the site).
- **API traps** — the biggest concentration on the site:
  - `Flow(ocp, u, c, μ)` → `Flow(ocp, u; constraint=c, multiplier=μ)`.
  - Consider showing the `Symbol` spelling (`constraint=:label`) at least once — the problem
    already declares its constraints in the `@def`, so this is exactly the case the feature
    was built for.
  - The concatenation syntax `f1 * (t1, f2) * (t2, f3)` and the jump forms need re-checking
    against the current `MultiPhase` API.
- **Role** — reference example for `flows/constrained-arcs.md`.

### `examples/simulation.md` — new, conditional

- **Story** — a controlled system, an open-loop control, a trajectory; then the same system
  under feedback. No optimisation anywhere.
- **Covers** — `Flow(ControlledVectorField(f), OpenLoop(u))`,
  `Flow(ControlledVectorField(f), ClosedLoop(k))`, `state`, `control`, `objective`,
  `time_grid`, `plot`.
- **Why it might be worth it** — it is the only page on a hypothetical site that would tell
  the Simulator profile "yes, this package is for you too". Everything else here is an
  optimisation.
- **Decide after PR 8.**

---

## Cross-cutting work for this PR

1. **Preamble audit** — every example gains `using OrdinaryDiffEqTsit5` before its first
   `Flow`. Six pages, six preambles.
2. **Flow-call audit** — grep all six for a positional variable (`, tf, ` followed by a fifth
   argument), `augment=`, `Flow(ocp, u, `, `Flow(` on a bare function, and
   `OptimalControl.Hamiltonian`.
3. **Shape audit** — 1-D states and controls must be scalars.
4. **Anchor rename** — all six ids change (`example-*` → `examples-*` and the path moves
   under `examples/`). `index.md` links to the first one; the guides will link to several.
5. **Sidebar order** — energy → time → control-free → control-and-variable → singular →
   state-constraint. Increasing difficulty, and each one uses something the previous
   introduced.

## Outgoing links

| From | To |
| --- | --- |
| every example | the guides it exercises |
| `double-integrator-time.md` | `@ref flows-multi-phase`, `@ref flows-shooting` |
| `control-free.md` | `@ref modelling-without-control`, `@ref examples-control-and-variable` |
| `control-and-variable.md` | `@ref examples-control-free` |
| `singular-control.md` | `@ref geometry-poisson`, `@ref geometry-lie-macro`, `@ref geometry-lift`, `@ref flows-shooting` |
| `state-constraint.md` | `@ref flows-constrained-arcs`, `@ref flows-multi-phase` |

## Acceptance criteria

- [x] All six pages execute with `Draft = false`. Confirmed via a full
      `julia --project=docs docs/make.jl` build (0 execution failures) plus a standalone
      block-by-block re-run of each page's extracted `@example` code.
- [x] Every page follows the common skeleton and ends with a "See also".
- [x] No positional variable, no `augment=`, no `Flow(f::Function)`, no
      `Flow(ocp, u, g, μ)`, no `OptimalControl.`-qualified exported type. Grepped precisely
      (not just for the substrings) — zero hits; see "Also found and fixed" for the three
      positional-`variable` bugs this caught that the spec's own file notes didn't flag.
- [x] Every page that calls `Flow` loads `OrdinaryDiffEqTsit5`. All six do.
- [x] The double-integrator definition is character-identical across `index.md` and
      `examples/double-integrator-energy.md` — confirmed, reused verbatim
      (`t0=0,tf=1,x0=[-1,0],xf=[0,0]`, dynamics `[v(t),u(t)]`, cost `0.5∫(u(t)^2)`).
      `getting-started/first-problem.md` is still a PR-11 stub (not yet written) — flagged for
      PR 11 to reuse this exact block when it lands; nothing further to do here.
- [x] `singular-control.md` reproduces the same numerical result as before the rewrite: the
      free final time from the indirect (shooting) solve, `tf_sol ≈ 1.149730885756096`, matches
      the direct solve's own `tf ≈ 1.149732813941868` to 6 significant figures, and the
      `Lift`/`@Lie` bracket formula `us_bracket(q,p)` agrees with the hand-derived
      `u_indirect(x)=sin(x[3])^2` along the extremal to ~1e-9 — both confirm the untouched
      geometry code and the fixed flow half agree.
- [x] The `examples-simulation` decision is recorded: **dropped**. `flows/simulation.md` (PR 8)
      already carries 10 executed `@example` blocks — open loop, closed loop, an
      OCP-with-`OpenLoop` trajectory carrying a real objective, plotting, and every relevant
      error path — and reads as a complete story without a dedicated example page.

## Also found and fixed

- **Three positional-`variable` bugs, not flagged by the spec's own file-by-file notes**:
  `double-integrator-time.md`, `control-free.md`/`control-and-variable.md`, and
  `singular-control.md` all called a `NonFixed` flow with the variable value as a bare
  positional argument (or omitted it) instead of the mandatory `variable=` keyword — inherited
  unchanged from the attic. Confirmed against `test/problems/double_integrator.jl`'s
  `_di_time_shoot_builder`, which threads `variable=τf` correctly; fixed all three pages to
  match, re-verified live (residuals ~1e-13 to ~1e-15 throughout).
- **A real bug caught only by live execution**: `state-constraint.md`'s boundary-arc case built
  `fs_arc` and `fc_bd` from two *separate* calls to `make_ocp(a_arc)` — each call constructs a
  fresh OCP instance, and multi-phase concatenation requires every phase to share the exact same
  one. Threw `IncorrectArgument` ("cannot reconstruct a multi-phase solution from flows of
  different OCPs") at the final `f_arc = fs_arc * (...) * fc_bd * (...)` step. Fixed by building
  `ocp_arc = make_ocp(a_arc)` once and reusing it for `solve`, `fs_arc`, and `fc_bd`.
- **A broken `[Home](@ref)` link**: `index.md`'s top heading has no `@id`, so there is no `Home`
  anchor to reference — caught by the full `make.jl` build (`Cannot resolve @ref`), fixed by
  rewording to plain prose.
- **Two `plot!` calls with the wrong first argument**: wrote `plot!(sol1, sol2, ...)` (two
  solutions) instead of `plot!(plt, sol2, ...)` (a stored plot handle, then the solution to
  overlay) in `state-constraint.md`'s two comparison plots — a `RecipesPipeline` error, fixed by
  storing the first `plot(...)` call's return value.
- **The recurring CTModels.jl#392 VBox bug** hits every bare `plot(sol)` call under this
  environment's pinned CTModels, same as every prior PR in this series — every plot on this page
  uses the `plot(sol, :state, :control)` selector workaround.
- **`v(t) ≤ v_max` first-order constraint reuses `flows/constrained-arcs.md`'s exact fixture**
  (`VMAX=1.2`, `t0=0.0,tf=1.0,x0=[-1.0,0.0]`, labeled `(vmax)`) rather than re-deriving new
  numbers, and demonstrates the `constraint=:vmax` Symbol form per the spec's own suggestion —
  the multiplier signature is `μ(x, p) = p[1]` (2-arg), not the attic's 1-arg `μ(p) = p[1]`.
- **The `model` naming collision**: `control-free.md`/`control-and-variable.md`'s local
  synthetic-data function was renamed from `model(t)` to `x_true(t)` to stop shadowing the real,
  exported `model(sol)` accessor; added one real `model(direct_sol) === ocp_growth` call so the
  accessor the spec's own "Covers" list asks for is actually demonstrated, not just avoided.
- **`control-and-variable.md`'s harmonic oscillator no longer converges to `ω=π/2`** — confirmed
  correct, not a bug: with a control now sharing the work of steering `q` to `0`, the
  cost-minimising `|ω|` genuinely changes (confirmed direct and indirect solves agree with each
  other, `ω≈-0.654` both ways); `ω=π/2` was only ever forced by the control-free version's rigid
  boundary conditions. Added a note in the page so this isn't read as a discrepancy.
- **`docs/src/examples/gallery.md` isn't in the spec's own page table** — kept as the section's
  landing/index page (the "Examples" analogue of every other section's "Overview"), since PR 2
  already built it as a stub with a live anchor (`examples-gallery`) that 8 already-written
  guide pages forward-link to. `docs/make.jl`'s "Examples" nav entry converted from a bare
  string to a nested vector (`"Gallery"` first, then the six story pages), matching every other
  section's shape.
- **Sharpened 4 pre-existing forward links** that only ever pointed at the generic
  `examples-gallery` stub for lack of anything better, now that the specific anchors exist:
  `flows/multi-phase.md` and `flows/shooting.md` gained a real "See also" link to
  `examples-double-integrator-time` (PR 8 predates this section, had none before);
  `geometry/poisson.md` and `geometry/lie-macro.md` retargeted to `examples-singular-control`
  (both already flagged as a TODO in PR 9's own report); `modelling/without-control.md`
  retargeted to `examples-control-free`; `docs/src-literate/tutorial.jl`'s three `#md`-only
  mentions retargeted to the three specific example anchors (its `#nb` notebook-export variants
  left untouched — those are literal URLs into the stable, deployed old site, out of scope
  here). `modelling/functional-api.md`'s "worked both ways" mention was deliberately **not**
  retargeted — nothing in `examples/` actually shows the same problem worked in both `@def` and
  functional-API form side by side, so forcing a specific anchor there would misrepresent the
  content; left pointing at the generic gallery.
