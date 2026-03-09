module TestProblems

    using OptimalControl

    include("beam.jl")
    include("goddard.jl")
    include("quadrotor.jl")

    export Beam, Goddard, Quadrotor

end
