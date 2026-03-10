module TestProblems

    using OptimalControl

    include("beam.jl")
    include("goddard.jl")
    include("quadrotor.jl")
    include("transfer.jl")

    export Beam, Goddard, Quadrotor, Transfer

end
