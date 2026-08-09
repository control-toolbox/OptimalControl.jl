# Results — specification

**PR**: 7 · **Depends on**: PR 6 · **Status**: specification
**Scope**: `docs/src/results/*`

## Objective

Everything you do *after* something has been computed: read it, draw it, store it.

**This section is deliberately placed before Flows.** A trajectory returned by a flow is
inspected and plotted with exactly the same functions as a solution returned by `solve` —
`state`, `control`, `costate`, `objective`, `time_grid`, `plot`. Flows can then say "same as
Results" instead of repeating it, which is precisely the point the user made: *"il peut les
afficher, introspecter la solution, comme quand c'est une solution d'un problème de contrôle
optimal."*

## Pages

| id | title | path | source |
| --- | --- | --- | --- |
| `results-solution` | The solution object | `results/solution.md` | `attic/manual-solution.md` |
| `results-plot` | Plot a solution | `results/plot.md` | `attic/manual-plot.md` |
| `results-save-load` | Save and load | `results/save-load.md` | **new** — currently undocumented |

---

## Page details

### `results/solution.md`

- **Purpose** — read a computed result: trajectories, costate, duals, metadata.
- **Outline**
  - `## What you get back` — `solve` returns a `Solution`; a flow returns a trajectory; the
    accessors are the same generics
  - `## Trajectories` — `state`, `control`, `variable`, `costate`; **they are functions of
    time**, and `time_grid` gives the nodes
  - `## The objective`
  - `## Did it work` — `successful`, `status`, `message`, `iterations`,
    `constraints_violation`, `infos`
  - `## Dual variables` — `dual`, and the eight constraint-specific accessors
  - `## Back to the model` — `model(sol)`
  - `## Empty solutions` — `is_empty`, `is_empty_time_grid`
- **API covered** — `state`, `control`, `variable`, `costate`, `objective`, `time_grid`,
  `times`, `iterations`, `status`, `message`, `successful`, `constraints_violation`, `infos`,
  `model`, `is_empty`, `is_empty_time_grid`, `dual`,
  `path_constraints_dual`, `boundary_constraints_dual`,
  `state_constraints_lb_dual`, `state_constraints_ub_dual`,
  `control_constraints_lb_dual`, `control_constraints_ub_dual`,
  `variable_constraints_lb_dual`, `variable_constraints_ub_dual`,
  `dim_dual_state_constraints_box`, `dim_dual_control_constraints_box`,
  `dim_dual_variable_constraints_box`.
- **Source** — `attic/manual-solution.md` (437 lines). Drop the "solution struct" internals
  section; that is API-reference material.
- **API traps**
  - `success(sol)` never existed as a CTModels method and `success` is `Base.success`. The
    accessor is `successful(sol)`. PR 3 makes the old spelling throw with that message —
    cross-link `@ref migration`.
  - **1-D is a scalar**: for a scalar control, `control(sol)(t)` is a `Number`, not a
    length-1 vector. Show it explicitly; this is the most common shape surprise.
  - `Solution` and `AbstractSolution` are imported, not exported — do not write bare
    `Solution` in a type annotation in an example.
- **Symmetry** — this page mirrors `@ref modelling-inspect`. Say so and link both ways.

### `results/plot.md`

- **Purpose** — draw a solution or a trajectory, and control the layout.
- **Outline**
  - `## Getting started` — `using Plots`, then `plot(sol)`
  - `## What gets drawn by default`
  - `## Choosing what to draw` — positional `:state`, `:control`, `:costate`
  - `## Layout` — `layout=:split` vs `layout=:group`
  - `## The control` — `control=:components` / `:norm` / `:all`
  - `## Styling` — `state_style`, `costate_style`, `control_style`, `time_style`
    (NamedTuple, or `:none` to hide)
  - `## Normalised time`
  - `## Constraints`
  - `## Adding to an existing plot` — `plot!`
  - `## Custom subplots`
  - `## Plotting a flow trajectory` — the same call works; forward-link
    `@ref flows-simulation`
- **API covered** — `plot`, `plot!`, and every keyword above.
- **Source** — `attic/manual-plot.md` (454 lines) is thorough and current. Audit, do not
  rewrite. Its §"plotting from `Flow`" (`@id manual-plot-flow`) becomes the last section here
  and must gain `using OrdinaryDiffEqTsit5` in the preamble.
- **API traps**
  - `plot` on a solution without `using Plots` throws `ExtensionError(:Plots)`
    (`CTModels.jl/src/Display/Display.jl:69`). Show the error once; it is the most common
    "why is nothing happening".
  - The flow section's examples must be re-checked against the current `Flow` API
    ([`05-flows-indirect.md`](05-flows-indirect.md) §"Constructor catalogue").

### `results/save-load.md` — **new page**

- **Purpose** — persist a solution and read it back. Currently documented nowhere on the site
  even though the API is exported.
- **Outline**
  - `## Why` — expensive solves, warm starts, sharing results
  - `## JLD2` — `using JLD2`; `export_ocp_solution(sol; format=:JLD, filename="solution")`,
    `import_ocp_solution(ocp; format=:JLD, filename="solution")`
  - `## JSON3` — `using JSON3`; same calls with `format=:JSON`
  - `## Which format` — JLD2 round-trips Julia values exactly; JSON3 is portable and readable
  - `## Reloading as an initial guess` — feed the imported solution straight to `solve` as a
    warm start; link `@ref solve-initial-guess`
  - `## Without the extension` — the `ExtensionError` you get
- **API covered** — `export_ocp_solution`, `import_ocp_solution`.
- **Source** — new. The backends are weak-dependency extensions `CTModelsJLD` / `CTModelsJSON`.
- **The user-facing signatures** (verified in the resolved CTModels 0.15.3-beta,
  `src/Serialization/export_import.jl:49,91`):

  ```julia
  export_ocp_solution(sol; format::Symbol=:JLD, filename::String="solution")
  import_ocp_solution(ocp; format::Symbol=:JLD, filename::String="solution")
  ```

  `format` is a **`Symbol`**, `:JLD` or `:JSON`; anything else is an `IncorrectArgument`
  that names both valid values. `filename` is a **base name — the extension is added
  automatically**, which is why the same name works for both formats.

- **API traps**
  - The tag types `JLD2Tag`, `JSON3Tag`, `AbstractTag`
    (`CTModels.jl/src/Serialization/types.jl`) are an **internal dispatch mechanism**. They
    are not re-exported and the user never touches them — the `format` symbol is the API.
    Do not mention them on the page.
  - `import_ocp_solution` takes the **model**, not a filename, as its positional argument:
    the model is what the solution is reconstructed against.
  - `filename` has no extension. Writing `filename="sol.jld2"` produces `sol.jld2.jld2`.

---

## Outgoing links

| From | To |
| --- | --- |
| `solution.md` | `@ref modelling-inspect`, `@ref results-plot`, `@ref results-save-load`, `@ref migration` |
| `plot.md` | `@ref results-solution`, `@ref flows-simulation` |
| `save-load.md` | `@ref solve-initial-guess`, `@ref results-solution` |

## Acceptance criteria

- [ ] Every accessor in the `solution.md` list appears and executes.
- [ ] The scalar-control shape is demonstrated explicitly, not merely asserted.
- [ ] `save-load.md` exists, runs a real round-trip in both formats, and states how the format
      is chosen.
- [ ] `plot.md`'s flow section has `using OrdinaryDiffEqTsit5` and current `Flow` calls.
- [ ] The `success` → `successful` note is present and links to the migration page.
- [ ] Nothing in the section writes bare `Solution` as a type name.
