module ControlToolbox

    using ForwardDiff
    using OrdinaryDiffEq #: ODEProblem, solve
    using LinearAlgebra #: norm

    import Plots: plot, plot!

    include("utils.jl")
    include("Flows.jl"); using .Flows
    include("ocp.jl")
    include("steepest.jl")

    export OptimalControlProblem
    export RegularOptimalControlProblem

    export OptimalControlSolution
    export SteepestOCPSol

    export OptimalControlInit
    export SteepestOCPInit

    export plot, plot!

    export solve

end
