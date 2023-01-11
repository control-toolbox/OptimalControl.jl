module OptimalControl

using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using LinearAlgebra # for the norm for instance
using Printf # to print iterations results
using Interpolations: linear_interpolation, Line, Interpolations

# todo: use RecipesBase instead of plot
import Plots: plot, plot!, Plots # import instead of using to overload the plot and plot! functions, to plot ocp solution

#
# method to compute gradient and Jacobian
∇(f::Function, x) = ForwardDiff.gradient(f, x)
Jac(f::Function, x) = ForwardDiff.jacobian(f, x)

#
# dev packages
using HamiltonianFlows
using ControlToolboxTools
#
#
include("common/callbacks.jl")
include("common/exceptions.jl")
include("common/utils.jl")
#
include("optim/descent.jl")
#
include("ocp/ocp.jl")
include("ocp/convert.jl")
include("ocp/descent.jl")

export OCP, solve
export OptimalControlProblem, OptimalControlSolution, OptimalControlInit
export RegularOCPFinalConstraint, RegularOCPFinalCondition
export DescentOCPSol, DescentOCPInit
export CTCallback, PrintCallback, StopCallback
export CTException, IncorrectMethod, InconsistentArgument
export plot, plot!

end
