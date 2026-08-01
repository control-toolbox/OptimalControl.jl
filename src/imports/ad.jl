# Automatic differentiation
#
# ⚠️ Same rule as imports/adnlpmodels.jl: a `[deps]` entry arms nothing.
#
# - `DifferentiationInterface` arms `CTBaseDifferentiationInterface`, without
#   which the whole differential-geometry API (`ad`, `Lift`, `Poisson`, `∂ₜ`,
#   `@Lie`) is inert.
# - `ForwardDiff` arms `CTSolversForwardDiff`. Do NOT rely on ADNLPModels
#   dragging it in transitively: that is an implementation detail of a package
#   we do not control.
#
# Guarded by test/suite/extensions/test_extensions_armed.jl.

import DifferentiationInterface: DifferentiationInterface # arms CTBaseDifferentiationInterface
import ForwardDiff: ForwardDiff                           # arms CTSolversForwardDiff
