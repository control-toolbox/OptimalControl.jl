module OptimalControl

using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using LinearAlgebra # for the norm for instance
using Printf # to print iterations results
using Interpolations: linear_interpolation, Line, Interpolations
using Reexport
using Parameters

# todo: use RecipesBase instead of plot
import Plots: plot, plot!, Plots # import instead of using to overload the plot and plot! functions, to plot ocp solution

#
# method to compute gradient and Jacobian
∇(f::Function, x) = ForwardDiff.gradient(f, x)
Jac(f::Function, x) = ForwardDiff.jacobian(f, x)

#
# dev packages
using CTOptimization
import CTOptimization: solve, CTOptimization
@reexport using ControlToolboxTools
const ControlToolboxCallbacks = Tuple{Vararg{ControlToolboxCallback}}
using HamiltonianFlows
#

# --------------------------------------------------------------------------------------------------
# Aliases for types
const Times = Union{Vector{<:Real},StepRangeLen}
const States = Vector{<:Vector{<:Real}}
const Adjoints = Vector{<:Vector{<:Real}} #Union{Vector{<:Real}, Vector{<:Vector{<:Real}}, Matrix{<:Vector{<:Real}}}
const Controls = Vector{<:Vector{<:Real}} #Union{Vector{<:Real}, Vector{<:Vector{<:Real}}}
const Time = Real
const State = Vector{<:Real}
const Adjoint = Vector{<:Real} # todo: ajouter type adjoint pour faire par exemple p*f(x, u) au lieu de p'*f(x,u)
const Dimension = Integer

#
include("./utils.jl")
include("./default.jl")
#
include("model.jl")
include("problem.jl")
include("solve.jl")
#
include("direct/simple-shooting/init.jl")
include("direct/simple-shooting/utils.jl")
include("direct/simple-shooting/problem.jl")
include("direct/simple-shooting/solution.jl")
include("direct/simple-shooting/interface.jl")
include("direct/simple-shooting/plot.jl")

export solve

# model
export AbstractOptimalControlModel, OptimalControlModel
export Model, time!, constraint!, objective!

# problems
export AbstractOptimalControlProblem, AbstractOptimalControlSolution, AbstractOptimalControlInit
export UncFreeXfProblem, UncFreeXfInit, UncFreeXfSolution
export UncFixedXfProblem, UncFixedXfInit, UncFixedXfSolution
#
export OptimalControlProblem

#
export plot, plot!

end
