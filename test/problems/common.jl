# ============================================================================
# TestProblem — the shared shape of every test problem
# ============================================================================
# The nine problems used to return bare NamedTuples with **no common schema**:
# some carried `F0`/`F1`, some `x0`/`xf`/`t0`/`tf`, some `p_expected`. Anything
# generic over them — a form-equivalence check, a shooting helper — had to
# guess.
#
# `TestProblem` promotes the four fields every problem has and keeps the rest
# in `data`, verbatim. That is the escape hatch: no information was dropped in
# the migration, it just moved one level down.
#
# The `form` field is the other half. Each problem can be built two ways:
#
#   `:abstract`   — the `@def` DSL (what the nine were)
#   `:functional` — the `CTModels.Building` API (`state!`, `dynamics!`, …)
#
# They must produce equivalent models; `suite/problems/test_forms_equivalent.jl`
# is what holds them to it.

"""
    TestProblem

A test problem in one of its two front-end forms.

# Fields
- `name::Symbol`: problem identifier, e.g. `:goddard`
- `form::Symbol`: `:abstract` (the `@def` DSL) or `:functional` (the
  `CTModels.Building` API)
- `ocp`: the optimal control problem itself
- `objective::Union{Float64,Nothing}`: reference optimal value, `nothing` when
  no reference is available
- `init`: initial guess, or `nothing`
- `data::NamedTuple`: everything else the problem carries — `F0`/`F1`,
  `x0`/`xf`/`t0`/`tf`, expected parameters, switching times, …
- `methods::Tuple{Vararg{Symbol}}`: which solution methods this problem is a
  fixture for — see [`METHODS`](@ref)
- `shoot_builder::Union{Function,Nothing}`: `nothing`, or a function of
  signature `(; hamiltonian_type::Symbol=:total) -> (shoot!, ξ_exact, ξ_guess)`
  — see below

# `shoot_builder`

The indirect fixture's shooting derivation, kept next to the problem rather
than re-derived in every test file that needs it. `shoot!` has the flat-vector
signature [`test_shooting`](@ref) expects — `shoot!(s, ξ) → nothing` — and
`ξ_exact`/`ξ_guess` are the reference solution and a perturbed starting guess,
both in that same flattened shape (typically `[p0; switching_times...; tf]`,
whichever subset the problem's own structure actually has unknowns for).

`hamiltonian_type` is a keyword rather than baked in because the same
derivation is the vehicle for `suite/problems/test_hamiltonian_type.jl`, which
needs both `:total` and `:partial` from the identical control laws — hence a
function returning `(shoot!, ξ_exact, ξ_guess)` rather than a precomputed
triple.

`nothing` when the problem has no exploitable extremal structure — the
quadrotor, for one.

# Why `methods` exists

Not every problem can be attacked both ways. The quadrotor has no exploitable
extremal structure and no reference costate, so it is a *direct* fixture only;
running a shooting sweep over the whole library would either skip it by name —
a list that rots — or fail on it.

Declaring the capability keeps generic loops honest:

```julia
for pb in problems_for(:indirect)
    # every one of these has the shooting data it needs
end
```

The precondition for `:indirect` is concrete: the problem must carry enough in
`data` to build and check a shooting function (a reference `p0`, plus
switching times and dynamics fields where the structure needs them).
"""
struct TestProblem
    name::Symbol
    form::Symbol
    ocp::Any
    objective::Union{Float64,Nothing}
    init::Any
    data::NamedTuple
    methods::Tuple{Vararg{Symbol}}
    shoot_builder::Union{Function,Nothing}
end

"""
    METHODS

The solution methods a problem can declare itself a fixture for.

- `:direct`   — discretise, then solve the NLP. Every problem supports this.
- `:indirect` — Pontryagin + shooting. Requires reference shooting data in
  `data`; see [`TestProblem`](@ref).
"""
const METHODS = (:direct, :indirect)

# Default: direct only, no shooting derivation. A problem opts into
# `:indirect` explicitly, at the point where it also supplies `shoot_builder`.
function TestProblem(
    name::Symbol,
    form::Symbol,
    ocp,
    objective::Union{Float64,Nothing},
    init,
    data::NamedTuple;
    methods::Tuple{Vararg{Symbol}}=(:direct,),
    shoot_builder::Union{Function,Nothing}=nothing,
)
    for m in methods
        m in METHODS ||
            throw(ArgumentError("unknown method $(repr(m)); expected one of $(METHODS)"))
    end
    # Make the claim self-enforcing rather than a comment: a problem that says
    # it is an indirect fixture must actually carry a shooting derivation, or
    # a generic shooting sweep would pick it up and then fail on `nothing`.
    if :indirect in methods && shoot_builder === nothing
        throw(
            ArgumentError(
                "problem $(repr(name)) declares :indirect but carries no `shoot_builder`; " *
                "an indirect fixture needs a shooting derivation to shoot from",
            ),
        )
    end
    return TestProblem(name, form, ocp, objective, init, data, methods, shoot_builder)
end

"""
    supports(pb::TestProblem, method::Symbol) -> Bool

Whether `pb` is a fixture for `method` (`:direct` or `:indirect`).
"""
supports(pb::TestProblem, method::Symbol) = method in pb.methods

"""
    FORMS

The two front ends every problem must support. Iterate over this rather than
hard-coding `(:abstract, :functional)`, so a third form would be picked up
everywhere at once.
"""
const FORMS = (:abstract, :functional)

"""
    check_form(form)

Throw a readable `ArgumentError` on an unknown form rather than letting it
fall through to a `MethodError` three frames down.
"""
function check_form(form::Symbol)
    form in FORMS ||
        throw(ArgumentError("unknown form $(repr(form)); expected one of $(FORMS)"))
    return form
end

# ----------------------------------------------------------------------------
# Memoisation
# ----------------------------------------------------------------------------
# `@def` expansion is not cheap and the suite re-requests the same problem many
# times over (`test_descriptive.jl` alone calls `Beam()` six times). The cache
# key is (name, form, hash of the keyword arguments), so parameterised variants
# stay distinct.
#
# ⚠️ Per-module, deliberately: TestRunner runs each test file in its own
# process, so this is a within-file cache, not shared state between files.

const _CACHE = Dict{Tuple{Symbol,Symbol,UInt},TestProblem}()

"""
    cached(build, name, form, kwargs)

Return the memoised `TestProblem` for `(name, form, kwargs)`, calling `build()`
on a miss.
"""
function cached(build, name::Symbol, form::Symbol, kwargs)
    key = (name, form, hash(kwargs))
    return get!(build, _CACHE, key)
end

"""
    clear_cache!()

Empty the problem cache. Only useful in a test that measures build cost.
"""
clear_cache!() = (empty!(_CACHE); nothing)
