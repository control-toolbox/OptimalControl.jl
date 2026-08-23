# ============================================================================
# v2.0 deprecation shims
# ============================================================================
# This file is a deliberate, temporary piracy layer. It extends functions and
# types owned by CTFlows, CTModels, Base and LinearAlgebra so that removed v2.0
# spellings fail with a CTBase.PreconditionError naming their v2.1.0-beta
# replacement, instead of a bare UndefVarError or MethodError.
#
# Not shimmed (Julia cannot dispatch on these cases or they are handled
# upstream):
#   - Flow(ocp, u, g, mu)     upstream PreconditionError in CTFlows/building.jl
#   - augment=true            keyword name, not a dispatch target
#   - autonomous=/variable=/inplace=  Data constructors keyword renames
#   - @Lie ... autonomous=    macro-time IncorrectArgument in CTLie
#
# Included after src/imports/ and before src/helpers/.
# ============================================================================

using Base: time, success
using LinearAlgebra: ⋅

export Lie, ⋅, HamiltonianLift

function _deprecated(old, new, ctx = nothing)
    return PreconditionError(
        "`$old` is deprecated";
        reason = "this spelling was removed in v2.1.0-beta",
        suggestion = "use $new",
        context = ctx,
    )
end

# Differential geometry -------------------------------------------------------

"""
$(TYPEDSIGNATURES)

Removed in v2.1.0-beta. Always throws — use [`ad`](@ref)`(X, f)` for a Lie derivative
or [`ad`](@ref)`(X, Y)` for a Lie bracket instead.
"""
function Lie(X, f)
    throw(_deprecated("Lie(X, f) / Lie(X, Y)", "ad(X, f) or ad(X, Y)"))
end

"""
$(TYPEDSIGNATURES)

The `X ⋅ f` Lie-derivative operator is removed in v2.1.0-beta, with no operator
replacement. Always throws — use [`ad`](@ref)`(X, f)` instead.
"""
LinearAlgebra.dot(X::AbstractVectorField, f::Function) =
    throw(_deprecated("X \\cdot f", "ad(X, f)"))

"""
$(TYPEDSIGNATURES)

Removed in v2.1.0-beta. Always throws — use [`Lift`](@ref)`(f)` for a plain function, or
`CTLie.LiftedHamiltonianFunction` directly, instead.
"""
function HamiltonianLift(args...)
    throw(_deprecated(
        "HamiltonianLift",
        "Lift(f) for a plain function, or CTLie.LiftedHamiltonianFunction",
    ))
end

# Removed accessors -----------------------------------------------------------

Base.time(m::Model) =
    throw(_deprecated("time(ocp)", "times(ocp)"))

Base.time(sol::AbstractSolution) =
    throw(_deprecated("time(sol)", "time_grid(sol)"))

Base.success(sol::AbstractSolution) =
    throw(_deprecated("success(sol)", "successful(sol)"))

# Flow constructor ------------------------------------------------------------

CTFlows.Flows.Flow(f::Function) =
    throw(_deprecated(
        "Flow(f::Function)",
        "Flow(VectorField(f)), Flow(Hamiltonian(f)), or Flow(HamiltonianVectorField(f))",
    ))

# Flow calling convention -----------------------------------------------------

function (f::CTFlows.Flows.AbstractHamiltonianFlow)(t0::Real, x0, p0, tf::Real, variable)
    throw(_deprecated(
        "f(t0, x0, p0, tf, lambda)",
        "f(t0, x0, p0, tf; variable=lambda)",
    ))
end

function (f::CTFlows.Flows.AbstractStateFlow)(t0::Real, x0, tf::Real, variable)
    throw(_deprecated(
        "f(t0, x0, tf, lambda)",
        "f(t0, x0, tf; variable=lambda)",
    ))
end
