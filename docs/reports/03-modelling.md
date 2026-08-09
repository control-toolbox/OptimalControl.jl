# Modelling — specification

**PR**: 5 · **Depends on**: PR 2 · **Status**: specification
**Scope**: `docs/src/modelling/*`

## Objective

Everything about *describing* a problem, before anything is solved: the two front ends
(`@def` and the functional API), the control-free case, and how to read a model back.

This is the first content PR because every later section's examples start with a model.

## Pages

| id | title | path | source |
| --- | --- | --- | --- |
| `modelling-formulation` | Mathematical formulation | `modelling/formulation.md` | `docs/src/index.md` §`math-formulation` (moved) |
| `modelling-abstract-syntax` | Abstract syntax (`@def`) | `modelling/abstract-syntax.md` | `attic/manual-abstract.md` (survives well) |
| `modelling-functional-api` | Functional API | `modelling/functional-api.md` | `attic/manual-macro-free.md` (trim heavily) |
| `modelling-without-control` | Problems without a control | `modelling/without-control.md` | **new** — harvest `attic/example-control-free.md` §intro |
| `modelling-inspect` | Inspect a problem | `modelling/inspect.md` | `attic/manual-model.md` (survives well) |
| `modelling-with-ai` | Write a problem with AI | `modelling/with-ai.md` | `attic/manual-ai-llm.md` |

---

## Page details

### `modelling/formulation.md`

- **Purpose** — the mathematics the rest of the site refers back to. One page, no code.
- **Outline**
  - `## Bolza problem` — $J(x,u) = g(x(t_0),x(t_f)) + \int_{t_0}^{t_f} f^0$
  - `## Dynamics`
  - `## Constraints` — the four families: state box, control box, nonlinear path, boundary
  - `## Mayer, Lagrange, Bolza`
  - `## Free times and extra variables` — $J(x,u,t_0,t_f)$, then $v \in \mathbb{R}^k$
  - `## The control-free case` — degenerate $m = 0$; forward-link `@ref modelling-without-control`
- **API covered** — none. Deliberately.
- **Source** — lift `index.md` §`math-formulation` verbatim. **Keep the `@id math-formulation`
  anchor alive** — `manual-macro-free.md` links to it today and other pages will.
- **Why it moves out of `index.md`**: the landing page should be an orientation, not a
  mathematics section. `index.md` keeps a two-line summary and links here.

### `modelling/abstract-syntax.md`

- **Purpose** — the complete `@def` reference. The most-visited page on the site.
- **Outline** (the existing structure is good; keep it)
  - `## variable` · `## time` · `## state` · `## control` · `## no control`
  - `## dynamics` — including the coordinatewise form `∂(x)(t)`
  - `## constraints` — box, nonlinear path, boundary, labelled
  - `## cost` — Mayer, Lagrange, Bolza, `→ min` / `→ max`
  - `## aliases`
  - `## Known issues`
- **API covered** — `@def` (and `@def` with an explicit target). Note that `@def_exa`
  (`CTParser.jl/src/onepass.jl:1361`) is **not** re-exported — either surface it or say
  nothing; do not mention it as available.
- **Executed examples** — every syntax fragment should build a real model.
- **Source** — `attic/manual-abstract.md` (646 lines) is largely correct; it documents the
  parser, which did not change. Audit rather than rewrite.
- **API traps** — the "no control" section must forward-link to
  `@ref modelling-without-control`, and must state the rule explicitly: **a zero-dimensional
  control is expressed by never declaring one.** `control!(pre, 0)` is *rejected*
  (`CTModels.jl/src/Building/control.jl:77`).

### `modelling/functional-api.md`

- **Purpose** — build the same model without macros, for programmatic construction.
- **Outline**
  - `## When you want this` — generated problems, loops over families, no parser
  - `## The canvas` — the maths-to-builder mapping table
  - `## A worked example` — the same double integrator as `@def`, side by side
  - `## Shapes in callbacks` — **the new section that replaces the deleted one**, see below
  - `## Order and preconditions` — what must be called before what
  - `## Equivalence` — the two front ends produce equivalent models
- **API covered** — `PreModel`, `time!`, `state!`, `control!`, `variable!`, `dynamics!`,
  `objective!`, `constraint!`, `time_dependence!`, `build`.
- **Source** — `attic/manual-macro-free.md` is 898 lines, the largest page on the site, and
  it ends with an inline API-reference section of `@docs; canonical=false` blocks.
  **Delete that inline section** — PR 4 generates it. Target ≈ 350 lines.

- **⚠️ API trap #1 — the biggest factual error on the whole old site.**

  `attic/manual-macro-free.md:252-279`, *"Scalar vs vector: a subtlety of the functional
  API"*, is **entirely false now**. Verbatim from the current page:

  > *"the functional API callbacks always receive `x`, `u`, and `v` as **vectors**,
  > regardless of their dimension"* (line 256)
  >
  > *"inside callbacks, dimension-1 components must always be indexed"* (line 254)
  >
  > *"This asymmetry is intentional"* (line 278)

  The ecosystem's "1-D is a scalar" rule was created to **remove** exactly that asymmetry,
  and it is now implemented and tested — `test/suite/shape/test_shape_contract.jl` asserts
  `x isa Number` and `u isa Number` for `n=1, m=1` through the full `solve` stack, again
  through `Flow`, and a third testset asserts the two paths agree.

  **Delete the section. Do not correct it.** Replace it with `## Shapes in callbacks`:

  - 1-D state, control and variable arrive as **scalars**; dimension ≥ 2 as vectors.
  - The **in-place buffer is the exception**: `r` (and `dx`, `val`, `b`) is always a
    length-`n` vector written by index, *even for `n = 1`*, because a scalar cannot be
    mutated. `f!(r, t, x, u, v) = (r[1] = -x + u; nothing)`.
  - This is the one place on the site where that asymmetry is explained. Every other page
    just follows it.

  Consequence for the rest of the page: **rewrite every callback that indexes a
  dimension-1 quantity into scalar style.** `lagrange_energy(t, x, u, v) = 0.5 * u[1]^2`
  (line 213) becomes `0.5 * u^2`; `dx[2] = u[1]` (line 194) becomes `dx[2] = u`;
  `v[1]` for a scalar variable becomes `v` (lines 330-332, 367, 449-474, 558-568).
  `dx[1] = …` and `b[1] = …` stay — those are buffers.

  `x[1]` still evaluates to the scalar, so nothing *breaks*; but a guide that writes `u[1]`
  for a scalar control is teaching the pre-rule mental model. Mention the compatibility
  once on `@ref migration`, not here.

- **API trap #2** — `PreModel` and `Model` are **imported, not exported**: write
  `OptimalControl.PreModel()`.
- **API trap #3** — the equivalence claim is a real, tested contract:
  `test/suite/problems/test_forms_equivalent.jl` asserts it for every library problem. Say
  so; it is the reason to trust the page.

### `modelling/without-control.md` — **new page, currently invisible on the site**

- **Purpose** — model an ODE with parameters and no control: parameter estimation, fitting,
  and the "optimise a constant" family. Serves the **Simulator** profile.
- **Outline**
  - `## What this is for` — fitting a dynamical system to data; optimising a constant
  - `## How to declare it` — declare a `variable`, a time, a state, dynamics, a cost; **omit
    the control line entirely**
  - `## Worked example: exponential growth` — fit $\dot x = p\,x$, $x(0)=2$ to
    $2e^{t/2}$ by minimising $\int_0^{10} (x - x_{\text{obs}})^2$; expect $p = 0.5$
  - `## Worked example: harmonic oscillator` — $\ddot q = -\omega^2 q$, analytic
    $\omega = \pi/2$
  - `## How the package knows` — `is_control_free(ocp)` / `has_control(ocp)`; the trait
    `_control_dependence(::EmptyControlModel) = Traits.ControlFree`
    (`CTModels.jl/src/Models/model.jl:160`)
  - `## Solving it directly` — plain `solve`
  - `## Solving it indirectly` — `Flow(ocp)` takes **no** control law in this case; forward-link
    `@ref flows-from-ocp`
  - `## Adding a control back` — one paragraph + link to
    `@ref examples-control-and-variable`
- **API covered** — `@def` without a control, `is_control_free`, `has_control`, `variable`,
  `Flow(ocp)`, `solve`.
- **Source** — new page. Harvest the intro and both problems from
  `attic/example-control-free.md`; that file becomes the *example* (see
  [`08-examples.md`](08-examples.md)) while this one is the *guide*.
- **API traps** — three, all sharp:
  1. `control!(ocp, 0)` is an error, not a way to say "no control".
  2. `Flow(ocp)` with **no** law works only in the control-free case
     (`CTFlows.jl/src/Flows/building.jl:157` → `_flow_from_ocp(::Type{Traits.ControlFree}, …)`).
     With a control it throws a `PreconditionError` telling you to use `Flow(ocp, law)`.
  3. `constraint=` / `multiplier=` on a control-free `Flow(ocp)` are **rejected** — there is
     no pseudo-Hamiltonian to carry $\mu \cdot g$.

Fixtures already exist and are tested: `test/problems/control_free.jl` (`ExponentialGrowth`,
`HarmonicOscillator`), both built in the abstract *and* functional forms.

### `modelling/inspect.md`

- **Purpose** — read a model back: dimensions, names, dynamics, costs, constraints, traits.
  Also the "is this model what I think it is" workflow.
- **Outline**
  - `## Times` · `## State` · `## Control` · `## Variable`
  - `## Dynamics` · `## Cost` · `## Constraints`
  - `## Traits` — autonomous? variable? control-free? abstractly defined?
  - `## The original definition` — `definition`, `has_abstract_definition`
- **API covered** — the full getter surface:
  `initial_time`, `final_time`, `times`, `time_name`, `initial_time_name`, `final_time_name`,
  `has_fixed_initial_time`, `has_free_initial_time`, `has_fixed_final_time`,
  `has_free_final_time`, `is_initial_time_fixed`, `is_initial_time_free`,
  `is_final_time_fixed`, `is_final_time_free`;
  `state_dimension`, `state_name`, `state_components`, `control_dimension`, `control_name`,
  `control_components`, `variable_dimension`, `variable_name`, `variable_components`;
  `components`, `dimension`, `name`, `index`, `expression`;
  `dynamics`, `objective`, `mayer`, `lagrange`, `criterion`, `has_mayer_cost`,
  `has_lagrange_cost`, `is_mayer_cost_defined`, `is_lagrange_cost_defined`;
  `constraint`, `constraints`, `path_constraints_nl`, `boundary_constraints_nl`,
  `state_constraints_box`, `control_constraints_box`, `variable_constraints_box`,
  `dim_path_constraints_nl`, `dim_boundary_constraints_nl`, `dim_state_constraints_box`,
  `dim_control_constraints_box`, `dim_variable_constraints_box`;
  `is_autonomous`, `is_nonautonomous`, `is_variable`, `is_nonvariable`, `has_variable`,
  `has_control`, `is_control_free`;
  `definition`, `has_abstract_definition`, `is_abstractly_defined`.
- **Source** — `attic/manual-model.md` (721 lines) is accurate and well organised. Audit,
  reorganise into the outline above, drop the "model struct" internals section — that is
  API-reference material now.
- **API traps** — `time(ocp)` is gone (it is `Base.time`); the accessor is `times(ocp)`.
  PR 3 makes the old spelling throw with that message.

### `modelling/with-ai.md`

- **Purpose** — get an LLM to write the `@def` for you, including from a photograph of a
  problem statement.
- **Outline** — unchanged: the prompt template, the `@raw html` provider buttons, three
  transcripts (double integrator, coordinatewise/ExaModels-compatible form, Goddard from
  `assets/rocket-def.png`).
- **Source** — `attic/manual-ai-llm.md`, near-verbatim.
- **API traps** — the prompt template points the model at the DSL page. **Update the URL** to
  `modelling/abstract-syntax`. Everything else is inert ```` ```julia ```` fences and needs no
  execution.
- **Note** — this page is the only one whose code blocks are deliberately *not* executed
  (they are model output, quoted). Say so at the top so a reviewer does not "fix" it.

---

## Outgoing links

| From | To |
| --- | --- |
| `formulation.md` | `@ref modelling-abstract-syntax`, `@ref modelling-without-control` |
| `abstract-syntax.md` | `@ref modelling-functional-api`, `@ref modelling-without-control`, `@ref solve-overview`, `@ref modelling-with-ai` |
| `functional-api.md` | `@ref math-formulation`, `@ref modelling-abstract-syntax` |
| `without-control.md` | `@ref flows-from-ocp`, `@ref examples-control-free`, `@ref examples-control-and-variable` |
| `inspect.md` | `@ref results-solution` (the symmetric page), API reference |
| `with-ai.md` | `@ref modelling-abstract-syntax` |

## Acceptance criteria

- [ ] Every symbol in the `inspect.md` list appears on the page and executes.
- [ ] `without-control.md` exists and both fixtures run, reproducing $p = 0.5$ and
      $\omega = \pi/2$.
- [ ] `functional-api.md` no longer contains an inline `@docs` block, and is under ~400 lines.
- [ ] No page writes `OptimalControl.VectorField`-style qualification for an exported symbol;
      `PreModel` and `Model` *are* qualified, correctly.
- [ ] The `@id math-formulation` anchor still resolves after the move.
- [ ] `with-ai.md`'s prompt template points at the new DSL page URL.
