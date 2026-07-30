# ============================================================================
# Problem registry
# ============================================================================
# Lets a test iterate over problems and forms without naming constructors:
#
#     for form in FORMS, name in PROBLEMS
#         pb = build(name, form)
#         ...
#     end
#
# `suite/problems/test_forms_equivalent.jl` is the main consumer.

"""
    PROBLEMS

Every problem name the registry can build, in both forms.
"""
const PROBLEMS = (
    :beam,
    :goddard,
    :double_integrator_time,
    :double_integrator_energy,
    :double_integrator_energy_constrained,
    :quadrotor,
    :transfer,
    :exponential_growth,
    :harmonic_oscillator,
)

const _CONSTRUCTORS = Dict{Symbol,Function}(
    :beam => Beam,
    :goddard => Goddard,
    :double_integrator_time => DoubleIntegratorTime,
    :double_integrator_energy => DoubleIntegratorEnergy,
    :double_integrator_energy_constrained => DoubleIntegratorEnergyConstrained,
    :quadrotor => Quadrotor,
    :transfer => Transfer,
    :exponential_growth => ExponentialGrowth,
    :harmonic_oscillator => HarmonicOscillator,
)

"""
    build(name::Symbol, form::Symbol=:abstract; kwargs...) -> TestProblem

Build problem `name` in `form`. Keyword arguments are forwarded to the
problem's own constructor.

Throws an `ArgumentError` naming the available problems on an unknown `name`,
rather than a `KeyError`.
"""
function build(name::Symbol, form::Symbol=:abstract; kwargs...)
    check_form(form)
    haskey(_CONSTRUCTORS, name) || throw(
        ArgumentError("unknown problem $(repr(name)); expected one of $(PROBLEMS)")
    )
    return _CONSTRUCTORS[name](form; kwargs...)
end

"""
    problems_for(method::Symbol, form::Symbol=:abstract) -> Vector{TestProblem}

Every problem that is a fixture for `method` (`:direct` or `:indirect`), built
in `form`.

This is how a generic sweep should select its problems. Hard-coding a list of
names instead means the list silently rots the moment a problem gains or loses
the reference data that makes it usable — the quadrotor, for one, has no
exploitable extremal structure and is a direct fixture only.

```julia
for pb in problems_for(:indirect)
    # every one of these carries a reference `p0`
end
```
"""
function problems_for(method::Symbol, form::Symbol=:abstract)
    method in METHODS ||
        throw(ArgumentError("unknown method $(repr(method)); expected one of $(METHODS)"))
    return [pb for pb in (build(n, form) for n in PROBLEMS) if supports(pb, method)]
end

"""
    problem_names_for(method::Symbol) -> Vector{Symbol}

Names only — cheaper than [`problems_for`](@ref) when the problems themselves
are not needed (building them expands `@def`).
"""
problem_names_for(method::Symbol) =
    [pb.name for pb in problems_for(method)]
