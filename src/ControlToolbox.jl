module ControlToolbox

using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using LinearAlgebra # for the norm for instance
using Printf # to print iterations results
using Interpolations: linear_interpolation, Line, Interpolations

import Plots: plot, plot!, Plots # import instead of using to overload the plot and plot! functions, to plot ocp solution

#
include("Flows.jl")
using .Flows
#
include("utils.jl")
include("description.jl")
include("callbacks.jl")
include("exceptions.jl")
include("ocp.jl")
include("convert.jl")
include("Optim.jl")
include("optim/descent.jl")
include("ocp-descent.jl")

export OCP # method to construct an ocp
export solve # solver of optimal control problems

export OptimalControlProblem # definition of an ocp (abstract)
export OptimalControlSolution # solution of an ocp (abstract)
export OptimalControlInit # initialization of an ocp (abstract)

export RegularOCPFinalConstraint # interface of a regular ocp with final constraint
export RegularOCPFinalCondition

export DescentOCPSol # solution of an ocp from the descent method
export DescentOCPInit # initialization of an ocp for the descent method

export CTCallback
export PrintCallback
export StopCallback

export CTException
export AmbiguousDescription
export IncorrectMethod
export InconsistentArgument

export plot, plot!

end
