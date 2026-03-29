module TestProblems

using OptimalControl

include("beam.jl")
include("goddard.jl")
include("double_integrator.jl")
include("quadrotor.jl")
include("transfer.jl")

export Beam, Goddard
export DoubleIntegratorTime, DoubleIntegratorEnergy, DoubleIntegratorEnergyConstrained
export Quadrotor, Transfer

end
