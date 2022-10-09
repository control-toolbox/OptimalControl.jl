module ControlToolbox

    using ForwardDiff: jacobian, gradient, ForwardDiff
    using LinearAlgebra
    using Printf    

    import Plots: plot, plot!, Plots

    include("utils.jl")
    include("Flows.jl"); using .Flows
    include("description.jl")
    include("ocp.jl")
    include("descent.jl")

    export OptimalControlProblem
    export OptimalControlSolution
    export OptimalControlInit

    export SimpleRegularOCP

    export OCP # method to construct an ocp

    export DescentOCPSol
    export DescentOCPInit

    #export plot, plot! # pas besoin semble-t-il car je rédéfinis Plots.plot et Plots.plot!

    export solve

end
