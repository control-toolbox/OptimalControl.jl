module ControlToolbox

    using ForwardDiff: jacobian, gradient, ForwardDiff
    #using LinearAlgebra

    import Plots: plot, plot!, Plots

    include("utils.jl")
    include("Flows.jl"); using .Flows
    include("ocp.jl")
    include("steepest.jl")

    export OptimalControlProblem
    export SimpleRegularOCP

    export OCP

    export OptimalControlSolution
    export SteepestOCPSol

    export OptimalControlInit
    export SteepestOCPInit

    #export plot, plot! # pas besoin semble-t-il car je rédéfinis Plots.plot et Plots.plot!

    export solve

end
