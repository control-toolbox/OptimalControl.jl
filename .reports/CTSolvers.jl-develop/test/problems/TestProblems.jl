module TestProblems
    using CTModels
    using CTSolvers
    using SolverCore
    using ADNLPModels
    using ExaModels

    include("problems_definition.jl")
    include("rosenbrock.jl")     
    include("max1minusx2.jl")
    include("elec.jl")

    # From problems_definition.jl
    export OptimizationProblem, DummyProblem

    # From rosenbrock.jl
    export Rosenbrock, rosenbrock_objective, rosenbrock_constraint

    # From max1minusx2.jl
    export Max1MinusX2

    # From elec.jl
    export Elec
end
