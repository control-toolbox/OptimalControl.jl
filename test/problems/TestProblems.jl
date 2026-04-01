module TestProblems

using OptimalControl

include("beam.jl")
include("goddard.jl")
include("double_integrator.jl")
include("quadrotor.jl")
include("transfer.jl")
include("control_free.jl")

export Beam, Goddard
export DoubleIntegratorTime, DoubleIntegratorEnergy, DoubleIntegratorEnergyConstrained
export Quadrotor, Transfer
export ExponentialGrowth, HarmonicOscillator

end
