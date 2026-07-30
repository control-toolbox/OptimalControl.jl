# CTLie reexports
#
# CTLie is new in v2.1.0-beta. It took over the differential-geometry API that
# used to live in CTFlows: `Lift`, `Poisson`, `∂ₜ`, `@Lie`, and `ad` — the
# latter being the former `CTFlows.Lie`. The `⋅` operator has no replacement.
#
# ⚠️ CTLie's AD is extension-gated: `Lift`, `ad`, `Poisson` and `∂ₜ` need
# CTBase's `CTBaseDifferentiationInterface` extension to be *armed*.
# That is what `imports/ad.jl` is for.

# Generated code — the `@Lie` macro emits `CTLie.*` and `CTBase.Traits.*`
# prefixes in its expansion, so both modules must be in scope at the call site.
@reexport import CTLie: CTLie # for generated code (prefix)

# Differential geometry
@reexport import CTLie: ad, Lift, Poisson, ∂ₜ, @Lie

# AD backend control (global)
@reexport import CTLie: dg_ad_backend, dg_ad_backend!

# Types — `LiftedHamiltonianFunction` is the former `CTFlows.HamiltonianLift`.
# It is `<: Function`, *not* `<: CTBase.Data.AbstractHamiltonian` any more.
import CTLie: LiftedHamiltonianFunction
