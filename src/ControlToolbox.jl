module ControlToolbox

    using ForwardDiff: jacobian, gradient, ForwardDiff
    #using LinearAlgebra

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
