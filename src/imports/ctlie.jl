# CTLie reexports
#
# CTLie is new in v2.1.0-beta. It took over the differential-geometry API that
# used to live in CTFlows: `Lift`, `Poisson`, `∂ₜ`, `@Lie`, and `ad` — the
# latter being the former `CTFlows.Lie`. The `⋅` operator has no replacement.
#
# ⚠️ CTLie's AD is extension-gated: `Lift`, `ad`, `Poisson` and `∂ₜ` need
# CTBase's `CTBaseDifferentiationInterface` extension to be *armed*.
# That is what `imports/ad.jl` is for.

# The module name `CTLie` is not exported: since CTLie 0.3 the expansion of `@Lie` holds the
# modules themselves, not their names, so it works from any caller (#966).

# Differential geometry
@reexport import CTLie: ad, Lift, Poisson, ∂ₜ, @Lie

# AD backend control (global)
@reexport import CTLie: dg_ad_backend, dg_ad_backend!

# Types — `LiftedHamiltonianFunction` is the former `CTFlows.HamiltonianLift`.
# It is `<: Function`, *not* `<: CTBase.Data.AbstractHamiltonian` any more.
import CTLie: LiftedHamiltonianFunction
