module TestProblems

using OptimalControl

include("beam.jl")
include("goddard.jl")

export Beam, Goddard

end
