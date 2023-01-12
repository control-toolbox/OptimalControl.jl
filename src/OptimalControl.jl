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
using CommonSolveOptimisation
using ControlToolboxTools
using HamiltonianFlows
#
#
include("common/callbacks.jl")
include("common/exceptions.jl")
include("common/utils.jl")
include("common/default.jl")
#
include("optim-old/descent.jl")
#
include("OptimalControlProblem.jl")
include("OptimalControlSolve.jl")
#
include("common/convert.jl")
#
include("descent/structs.jl")
include("descent/interface.jl")

export solve
export OptimalControlProblem, OptimalControlSolution, OptimalControlInit
export RegularOCPFinalConstraint, RegularOCPFinalCondition
#export DescentOCPSol, DescentOCPInit
export CTCallback, PrintCallback, StopCallback
export CTException, IncorrectMethod, InconsistentArgument
export plot, plot!

end
