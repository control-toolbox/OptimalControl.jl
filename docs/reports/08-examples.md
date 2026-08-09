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

- [ ] All six pages execute with `draft = false`.
- [ ] Every page follows the common skeleton and ends with a "See also".
- [ ] No positional variable, no `augment=`, no `Flow(f::Function)`, no
      `Flow(ocp, u, g, μ)`, no `OptimalControl.`-qualified exported type.
- [ ] Every page that calls `Flow` loads `OrdinaryDiffEqTsit5`.
- [ ] The double-integrator definition is character-identical across `index.md`,
      `getting-started/first-problem.md` and `examples/double-integrator-energy.md`.
- [ ] `singular-control.md` reproduces the same numerical result as before the rewrite —
      the geometry code is unchanged, so any drift means the flow half was mis-migrated.
- [ ] The `examples-simulation` decision is recorded (written, or dropped with a reason).
