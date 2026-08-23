# Geometry — specification

**PR**: 9 · **Depends on**: PR 8 · **Status**: specification
**Scope**: `docs/src/geometry/*`

## Objective

The differential-geometry toolkit, which now lives in **CTLie**. The user's framing: *"dans
certains cas, pour définir le flot, comme dans un des exemples avec la singulière, il a besoin
d'outils de la géométrie différentielle pour calculer le contrôle singulier — il faut donc lui
expliquer les outils qu'il a à disposition, sachant que les choses ont bien changé, maintenant
c'est dans CTLie (et `ad` remplace `Lie` par exemple)."*

**This is the most broken section of the old site.** `attic/manual-differential-geometry.md`
is 634 lines built on `Lie`, `⋅` and `HamiltonianLift` — none of which exist. It is a rewrite,
not an audit.

Profile: **Geometric**.

## Pages

| id | title | path | source |
| --- | --- | --- | --- |
| `geometry-overview` | Differential geometry tools | `geometry/overview.md` | **new** |
| `geometry-lift` | Lifting a vector field | `geometry/lift.md` | `attic/manual-differential-geometry.md` §"Hamiltonian lift" |
| `geometry-ad` | Lie derivative and Lie bracket | `geometry/ad.md` | **rewrite** of §"Lie derivative" + §"Lie bracket" |
| `geometry-poisson` | Poisson bracket | `geometry/poisson.md` | `attic/…` §"Poisson bracket" |
| `geometry-lie-macro` | The `@Lie` macro | `geometry/lie-macro.md` | `attic/…` §"The `@Lie` macro" |
| `geometry-ad-backend` | Choosing an AD backend | `geometry/ad-backend.md` | **new** |

`∂ₜ` (partial time derivative) folds into `geometry/ad.md` §"Non-autonomous fields" rather
than getting its own page — it is one function with one job.

---

## Reference: the whole surface

Verified against **CTLie 0.1.5-beta** (`~/.julia/packages/CTLie/cHxPr/`), the version
OptimalControl resolves. `src/CTLie.jl:50-56` exports exactly:

```
ad · Lift · LiftedHamiltonianFunction · Poisson · ∂ₜ · @Lie
dg_ad_backend · dg_ad_backend!
```

OptimalControl re-exports all of them **except `LiftedHamiltonianFunction`**, which is
imported only (`src/imports/ctlie.jl`) — so it must be written
`OptimalControl.LiftedHamiltonianFunction`.

Signatures (from the resolved source):

```julia
ad(X::Function, foo::Function;
   ad_backend = dg_ad_backend(),
   is_autonomous::Bool = true,
   is_variable::Bool  = false)                      # src/ad.jl:40
ad(X::Function, foo::Function, ::Type{TD}, ::Type{VD}; ad_backend)   # src/ad.jl:92
ad(X::AbstractVectorField, Y::AbstractVectorField; ad_backend)  → VectorField
ad(X::AbstractVectorField, f::Function; ad_backend)             → Function

Lift(f::Function; is_autonomous, is_variable)  → LiftedHamiltonianFunction  # src/lift.jl:68
Lift(f::Function, ::Type{TD}, ::Type{VD})      → LiftedHamiltonianFunction  # :107
Lift(X::AbstractVectorField)                   → Hamiltonian                # :144

Poisson(H::Function, G::Function; ad_backend, is_autonomous, is_variable)   # src/poisson.jl:37
Poisson(H::Function, G::Function, ::Type{TD}, ::Type{VD}; ad_backend)       # :82
Poisson(H::AbstractHamiltonian, G::AbstractHamiltonian; ad_backend) → Hamiltonian

∂ₜ(f::Function; ad_backend)
∂ₜ(X::AbstractVectorField; ad_backend)             → VectorField{NonAutonomous,…}
∂ₜ(X::AbstractHamiltonianVectorField; ad_backend)  → HamiltonianVectorField{NonAutonomous,…}
∂ₜ(H::AbstractHamiltonian; ad_backend)             → Hamiltonian{NonAutonomous,…}

@Lie expr [is_autonomous=…] [is_variable=…] [ad_backend=…]   # src/lie_macro.jl:510

dg_ad_backend()                     → Differentiation.AbstractADBackend
dg_ad_backend!(backend)             → nothing
```

Conventions to state once, on `geometry/overview.md`:

- Lie bracket: $[X, Y](x) = J_Y(x)\,X(x) - J_X(x)\,Y(x)$.
- Poisson bracket: $\{H, G\} = \nabla_p H \cdot \nabla_x G - \nabla_x H \cdot \nabla_p G$.
- The identity that ties them: $\{H_X, H_Y\} = H_{[X,Y]}$ — i.e.
  `Poisson(Lift(X), Lift(Y)) ≈ Lift(ad(X, Y))`. Show it as an executed check; it is the best
  single demonstration that the two halves of the toolkit agree.

Errors, all worth showing once because they are good errors:

| Situation | Exception |
| --- | --- |
| `ad` given an `AbstractHamiltonian` | `IncorrectArgument` — "use `Poisson`" |
| `Poisson` given an `AbstractVectorField` | `IncorrectArgument` — "use `ad`" |
| time/variable dependence mismatch between operands | `PreconditionError` |
| an `InPlace` operand, or a `HamiltonianVectorField` to `ad` | `NotImplemented` |
| `Lift(::HamiltonianVectorField)` | `NotImplemented` |
| `@Lie … autonomous=false` (old keyword) | `IncorrectArgument` at macro-expansion, listing `is_autonomous, is_variable, ad_backend` |

---

## Page details

### `geometry/overview.md` — new

- **Purpose** — what the toolkit is for, and the map.
- **Outline**
  - `## What this is for` — computing a singular control, checking controllability, building
    Hamiltonians from vector fields
  - `## The four operations` — `Lift`, `ad`, `Poisson`, `∂ₜ`, one line each
  - `## Two vocabularies` — vector fields on the state space vs Hamiltonians on the cotangent
    space; `Lift` is the bridge
  - `## The bridge identity` — `Poisson(Lift(X), Lift(Y)) ≈ Lift(ad(X, Y))`, executed
  - `## Autonomous, non-autonomous, variable` — the `is_autonomous` / `is_variable` keywords
    and why operands must agree
  - `## Automatic differentiation` — everything except `Lift` is AD-backed; link
    `@ref geometry-ad-backend`
  - `## Coming from v2.0` — a short table: `Lie` → `ad`, `⋅` → `ad`,
    `HamiltonianLift` → `LiftedHamiltonianFunction`; link `@ref migration`
- **API covered** — all of it, by name.
- **API traps** — `attic/manual-differential-geometry.md:7` claims `Hamiltonian`,
  `VectorField`, `HamiltonianVectorField` are **not exported** and must be qualified. They are
  exported. Delete the admonition and every `OptimalControl.` prefix on them.

### `geometry/lift.md`

- **Purpose** — turn a vector field into a Hamiltonian: $H(x,p) = p \cdot X(x)$.
- **Outline**
  - `## The lift` — the definition and the one-liner
  - `## From a plain function` — `Lift(f)` → a `LiftedHamiltonianFunction`
  - `## From a typed vector field` — `Lift(VectorField(f))` → a `Hamiltonian`
  - `## Non-autonomous and variable forms` — `is_autonomous=`, `is_variable=`; the call
    signatures `h(x,p)`, `h(t,x,p)`, `h(x,p,v)`, `h(t,x,p,v)`
  - `## Which one do I get` — a two-row table
  - `## What you can do with it` — feed it to `Poisson`, or to `Flow`; link
    `@ref flows-from-hamiltonians`
- **API covered** — `Lift`, `OptimalControl.LiftedHamiltonianFunction`, `VectorField`,
  `Hamiltonian`.
- **Source** — `attic/manual-differential-geometry.md` §"Hamiltonian lift" is structurally
  fine; `Lift` did not change. Only the surrounding vocabulary did.
- **API traps** — one, and it is a **silent** failure, so it gets a `!!! warning`:

  ```julia
  H = Lift(F)                 # F::Function
  H isa AbstractHamiltonian   # false in v2.1, true in v2.0
  ```

  `LiftedHamiltonianFunction <: Function`, no longer `<: AbstractHamiltonian`. Any `isa` or
  `<:` test against the old hierarchy is now quietly wrong. Note also that `Lift` is
  **overloaded on its input**: `Lift(X::AbstractVectorField)` still returns a `Hamiltonian`.
  Only the plain-`Function` overload changed.

### `geometry/ad.md` — rewrite

- **Purpose** — `ad`: the Lie derivative when the second argument is a scalar function, the
  Lie bracket when it is a vector field.
- **Outline**
  - `## One function, two meanings`
  - `## Lie derivative` — `ad(X, f)` where `f` is scalar-valued; $(\mathcal{L}_X f)(x)$
  - `## Lie bracket` — `ad(X, Y)` where `Y` is a vector field; the convention
  - `## Typed operands` — `ad(VectorField(X), VectorField(Y))` returns a `VectorField`, so it
    **nests**: `ad(ad(X, Y), Y)`
  - `## Non-autonomous and variable fields` — `is_autonomous=`, `is_variable=`; operands must
    agree or you get a `PreconditionError`
  - `## Partial time derivative` — `∂ₜ`, and the rule that its result is **always**
    `NonAutonomous`
  - `## Errors you will meet` — the table above
  - `## Coming from v2.0` — `Lie(X, f)` → `ad(X, f)`; `X ⋅ f` → `ad(X, f)`, **removed with no
    operator replacement**
- **API covered** — `ad`, `∂ₜ`, `VectorField`, `is_autonomous=`, `is_variable=`.
- **Source** — the structure of `attic/manual-differential-geometry.md` §"Lie derivative"
  (lines 84–192) and §"Lie bracket" (325–377) survives; **every code block is dead** and must
  be rewritten. The `⋅` sections and the summary table (622–628) are deleted outright.
- **API traps** — this page *is* the trap. Grep the finished page for `Lie(`, ` ⋅ `,
  `autonomous=` and `HamiltonianLift` before merging.

### `geometry/poisson.md`

- **Purpose** — the Poisson bracket of two Hamiltonians.
- **Outline**
  - `## Definition` — $\{H, G\} = \nabla_p H \cdot \nabla_x G - \nabla_x H \cdot \nabla_p G$
  - `## On plain functions` — `Poisson(H, G)`
  - `## On typed Hamiltonians` — returns a `Hamiltonian`, so it **nests**
  - `## The bridge to Lie brackets` — `Poisson(Lift(X), Lift(Y)) ≈ Lift(ad(X, Y))`, executed
  - `## Non-autonomous and variable forms`
  - `## Application: singular controls` — the standard chain $H_{01}$, $H_{001}$, $H_{101}$,
    and $u_{\text{sing}} = -H_{001}/H_{101}$; forward-link
    `@ref examples-singular-control`
- **API covered** — `Poisson`, `Hamiltonian`, `Lift`, `ad`.
- **Source** — `attic/manual-differential-geometry.md` §"Poisson bracket"; the code survives
  because `Poisson` did not change.
- **API traps** — passing an `AbstractVectorField` gives `IncorrectArgument` pointing at `ad`.
  Show it.

### `geometry/lie-macro.md`

- **Purpose** — `@Lie`, the bracket notation that makes the singular-control computation
  readable.
- **Outline**
  - `## Why a macro` — `@Lie [X, Y]` and `@Lie {H, K}` read like the mathematics
  - `## Lie brackets` — `[a, b]` expands to `ad`
  - `## Poisson brackets` — `{c, d}` expands to `Poisson`
  - `## Nesting` — `@Lie [[X, Y], Y]`, `@Lie {{H, K}, L}`
  - `## Arithmetic and evaluation points` — `@Lie [F0, F1](x) + 4 * [F1, F2](x)`
  - `## Keywords` — `is_autonomous=`, `is_variable=`, `ad_backend=`; **parenthesise** when you
    evaluate, because trailing keywords bind to `@Lie`:
    `(@Lie [F, G](x))`, not `@Lie [F, G](x) atol=1e-6`
  - `## What it needs in scope` — the expansion emits fully qualified `CTLie._lie_mac` /
    `CTLie._poisson_mac` and `CTBase.Traits.*`, so **both `CTLie` and `CTBase` must be
    resolvable at the call site**. `using OptimalControl` re-exports both module names, so
    this is automatic — but it explains why they are re-exported at all
- **API covered** — `@Lie`, `CTLie`, `CTBase`.
- **Source** — `attic/manual-differential-geometry.md` §"The `@Lie` macro`".
- **API traps**
  - `@Lie [X, Y] autonomous=false` → `IncorrectArgument` at expansion time, naming the three
    accepted keywords. Show it; it is a well-designed error.
  - **Do not break the VitePress escaping.** The `{{`/`}}` plugin
    (`docs/src/.vitepress/config.mts:61-71`) exists so `` `@Lie {{H, K}, L}` `` in inline code
    is not parsed as a Vue template expression. Nested Poisson brackets are this page's bread
    and butter — verify the rendered output, not just the build exit code.

### `geometry/ad-backend.md` — new

- **Purpose** — choose how the derivatives are computed. Currently undocumented.
- **Outline**
  - `## Everything here is AD-backed` — except `Lift`
  - `## The default` — `DifferentiationInterface` over ForwardDiff
  - `## Reading the current backend` — `dg_ad_backend()`
  - `## Changing it globally` — `dg_ad_backend!(...)`
  - `## Changing it for one call` — the `ad_backend=` keyword on `ad`, `Poisson`, `∂ₜ`, `@Lie`
  - `## GPU` — `Differentiation.DifferentiationInterface{CTBase.Strategies.GPU}()`
  - `## Introspection` — `describe(:di)`
  - `## If nothing works` — the symptom when `DifferentiationInterface` is not loaded
- **API covered** — `dg_ad_backend`, `dg_ad_backend!`, `ad_backend=`, `describe(:di)`,
  `CPU`, `GPU`.
- **API traps**
  - The backend is a **`CTBase.Differentiation` object**, not a raw `ADTypes` backend.
    `dg_ad_backend!(AutoForwardDiff())` is the v2.0 spelling and is wrong; the current one is
    `dg_ad_backend!(CTBase.Differentiation.DifferentiationInterface())`. `ADTypes` is no
    longer even a CTLie dependency.
  - `CTBase.Differentiation` is reachable (the `CTBase` module name is re-exported) but
    `Differentiation` itself is not bound — write the full path.

---

## Outgoing links

| From | To |
| --- | --- |
| `overview.md` | every page in the section, `@ref flows-overview`, `@ref migration` |
| `lift.md` | `@ref flows-from-hamiltonians`, `@ref geometry-poisson` |
| `ad.md` | `@ref geometry-poisson`, `@ref geometry-lie-macro`, `@ref migration` |
| `poisson.md` | `@ref geometry-lie-macro`, `@ref examples-singular-control` |
| `lie-macro.md` | `@ref geometry-ad`, `@ref geometry-poisson`, `@ref examples-singular-control` |
| `ad-backend.md` | `@ref solve-gpu`, `@ref flows-overview` |

## Acceptance criteria

- [x] `grep -rn 'Lie(\| ⋅ \|HamiltonianLift\|autonomous=\|OptimalControl\.VectorField' docs/src/geometry/`
      returns nothing (`@Lie` and `is_autonomous=` excepted — refine the pattern). Verified: the
      only hits are the "Coming from v2.0" migration tables (`overview.md`, `ad.md`) and the
      deliberate `@Lie [...] autonomous=false` rejection demo on `lie-macro.md` — all
      intentional mentions of the *old* API, not live usage of it.
- [x] The bridge identity `Poisson(Lift(X), Lift(Y)) ≈ Lift(ad(X, Y))` executes on
      `overview.md` and again on `poisson.md`. Both use the nonlinear pair
      `X(x)=[x[1]^2,x[2]^2]`, `Y(x)=[x[2],-x[1]]` (the attic's own linear pair gives an
      identically-zero bracket, too weak a check) — both sides evaluate to `12.0`.
- [x] The `H isa AbstractHamiltonian` → `false` trap has a `!!! warning` on `lift.md`.
- [x] `ad-backend.md` exists and `dg_ad_backend` / `dg_ad_backend!` appear nowhere else as
      undocumented names (grepped across `docs/src/`).
- [x] Nested Poisson notation renders correctly in the built VitePress site — checked the
      actual rendered HTML (`docs/build/1/geometry/lie-macro.html`), not just the build log; the
      `{{`/`}}` escape plugin isn't even triggered since these examples live in fenced
      ` ```@example ` blocks, not inline code spans.
- [x] Every error in the exceptions table is demonstrated at least once across the section,
      including the `InPlace`-operand-to-`ad` case, added explicitly to `ad.md` once noticed it
      was listed in the table but not actually shown anywhere.
- [x] `LiftedHamiltonianFunction` is always written with the `OptimalControl.` prefix. Caught and
      fixed three bare occurrences on `lift.md` during review (the type itself is import-only,
      not exported — a bare reference in an example would be a real footgun for a reader).

## Also found and fixed

- **A real bug in the first draft**, caught by the actual `make.jl` build, not by review: the
  "Arithmetic and evaluation points" example on `lie-macro.md` reused `F1`/`F2` (3-D vector
  fields, defined earlier on the page for the Lie-bracket examples) with a 2-D evaluation point
  — a `BoundsError`. Fixed by evaluating at a 3-D point instead of introducing new fields.
- **`@ref examples-singular-control` doesn't exist.** The spec's own outgoing-links table
  (`poisson.md`, `lie-macro.md`) points at this anchor, but PR 10 ("docs: examples") hasn't
  started and `docs/src/examples/gallery.md` only carries the page-level stub anchor
  `examples-gallery` — no sub-anchor for a specific worked example exists yet, unlike the
  page-level stubs PR 2 pre-created for every *page* in the sitemap. Linking to the
  not-yet-existing anchor would have been a genuine unresolved-`@ref` build warning, not a
  harmless forward reference like the ones used elsewhere in this series. Pointed both links at
  `@ref examples-gallery` instead; retarget to a more specific anchor once PR 10 creates one.
- **One nuance beyond the spec**: `Lift(::HamiltonianVectorField)` throws `NotImplemented`, as
  specced, but the underlying guard is shared with `ad` and its message says "ad" even when
  triggered through `Lift` (`ad_types.jl:59`'s `_check_not_hvf`, reused by both). Documented
  honestly on `lift.md` rather than silently editing the shown output to match expectations —
  it's a harmless upstream wart, not worth an issue against CTLie.
- **This PR needed no code change.** `src/imports/ctlie.jl` already re-exports the full surface
  the spec calls for (`ad`, `Lift`, `Poisson`, `∂ₜ`, `@Lie`, `dg_ad_backend`,
  `dg_ad_backend!`, plus the `CTLie`/`CTBase` module aliases), with `LiftedHamiltonianFunction`
  correctly import-only. Confirmed live (`Base.isexported`) before writing a single page, so no
  `src/`/`test/` changes and no re-export commit were needed for this PR — unlike PR 8.
- Verified against **CTLie 0.1.5-beta**, the version `docs/Manifest.toml` actually resolves
  (`~/.julia/packages/CTLie/cHxPr/`) — not the newer `../CTLie` sibling checkout (`0.2.0`), same
  situation as PR 8's CTFlows pin. Read the full source (`ad.jl`, `lift.jl`, `poisson.jl`,
  `lie_macro.jl`, `ad_types.jl`, `default.jl`) at that exact version rather than trusting the
  spec's own citations.
