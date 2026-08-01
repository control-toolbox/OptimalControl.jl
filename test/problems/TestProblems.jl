# ============================================================================
# TestProblems — the shared problem library
# ============================================================================
# Every problem is available in two front-end forms, `:abstract` (the `@def`
# DSL) and `:functional` (the `CTModels.Building` API), and returns a
# `TestProblem` rather than an ad-hoc NamedTuple. See `common.jl` for the
# shape and `registry.jl` for the name-indexed entry point.
#
# ⚠️ Each test file `include`s this module independently — TestRunner runs
# files in separate processes, so each must stand alone. That is also why the
# memo in `common.jl` is per-module rather than global.

module TestProblems

using OptimalControl
using CTModels: CTModels

# Shape first: the problem files all build `TestProblem`s.
include("common.jl")

include("beam.jl")
include("goddard.jl")
include("double_integrator.jl")
include("quadrotor.jl")
include("transfer.jl")
include("control_free.jl")

# Registry last: it indexes the constructors defined above.
include("registry.jl")

export TestProblem, FORMS, PROBLEMS
export Beam, Goddard
export DoubleIntegratorTime, DoubleIntegratorEnergy, DoubleIntegratorEnergyConstrained
export Quadrotor, Transfer
export ExponentialGrowth, HarmonicOscillator

end
