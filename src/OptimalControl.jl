module OptimalControl

using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using LinearAlgebra # for the norm for instance
using Printf # to print iterations results
using Interpolations: linear_interpolation, Line, Interpolations
using Reexport
using Parameters # @with_kw

using NLPModelsIpopt, ADNLPModels    # for direct methods

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
@reexport using HamiltonianFlows
import HamiltonianFlows: Flow, HamiltonianFlows
#

isnonautonomous(time_dependence::Symbol) = :nonautonomous == time_dependence
isautonomous(time_dependence::Symbol) = !isnonautonomous(time_dependence)

# --------------------------------------------------------------------------------------------------
# Aliases for types
# const AbstractVector{T} = AbstractArray{T,1}.
const MyNumber = Real
const MyVector = AbstractVector{<:MyNumber}

const Time = MyNumber
const Times = MyVector
const TimesDisc = Union{MyVector,StepRangeLen}

const States = Vector{<:MyVector}
const Adjoints = Vector{<:MyVector}
const Controls = Vector{<:MyVector}

const State = MyVector
const Adjoint = MyVector # todo: ajouter type adjoint pour faire par exemple p*f(x, u) au lieu de p'*f(x,u)
const Dimension = Integer

#
include("main/utils.jl")
include("main/default.jl")

# general
include("main/model.jl")
include("main/problem.jl")
include("main/solve.jl")
include("main/flows.jl")

# direct shooting
##include("direct-shooting/init.jl")
##include("direct-shooting/utils.jl")
##include("direct-shooting/problem.jl")
##include("direct-shooting/solve.jl")
##include("direct-shooting/solution.jl")
##include("direct-shooting/plot.jl")

# direct ipopt methods
include("direct/utils.jl")
include("direct/problem.jl")
include("direct/solve.jl")
include("direct/solution.jl")
include("direct/plot.jl")

# solve
export solve

# model
export AbstractOptimalControlModel, OptimalControlModel
export Model, time!, constraint!, objective!, state!, control!
export remove_constraint!
export constraint

# problems
##export AbstractOptimalControlProblem, AbstractOptimalControlSolution, AbstractOptimalControlInit
##export UncFreeXfProblem, UncFreeXfInit, UncFreeXfSolution
##export UncFixedXfProblem, UncFixedXfInit, UncFixedXfSolution
##export OptimalControlProblem

# plots
export plot, plot!

# extras
export Ad, Poisson

end
