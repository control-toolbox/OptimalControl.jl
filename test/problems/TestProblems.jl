module TestProblems

using OptimalControl

include("beam.jl")
include("goddard.jl")
include("double_integrator.jl")

export Beam, Goddard
export DoubleIntegratorTime, DoubleIntegratorEnergy, DoubleIntegratorEnergyConstrained

end
