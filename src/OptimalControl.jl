module OptimalControl

using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using LinearAlgebra # for the norm for instance
using Printf # to print iterations results
using Interpolations: linear_interpolation, Line, Interpolations
using Reexport
using Parameters # @with_kw

using NLPModelsIpopt, ADNLPModels    # for direct methods

# todo: use RecipesBase instead of plot
using Plots
import Plots: plot, plot!, Plots # import instead of using to overload the plot and plot! functions, to plot ocp solution

#
# control-toolbox ecosystem packages
# nlp solvers
using CTOptimization
import CTOptimization: solve, CTOptimizationProblem, CTOptimization
# tools: callbacks, exceptions, functions and more
@reexport using ControlToolboxTools
const ControlToolboxCallbacks = Tuple{Vararg{ControlToolboxCallback}}
# flows
@reexport using HamiltonianFlows
import HamiltonianFlows: Flow, HamiltonianFlows
#

# todo: the two following methods should be in ControlToolboxTools
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

# general
include("main/algorithms.jl")
include("main/utils.jl")
include("main/default.jl")
include("main/model.jl")
include("main/solve.jl")
include("main/flows.jl")
include("main/solution.jl")
#include("main/print.jl")

# direct shooting
include("direct-shooting/solution.jl")
include("direct-shooting/init.jl")
include("direct-shooting/utils.jl")
include("direct-shooting/problem.jl")
include("direct-shooting/solve.jl")
include("direct-shooting/plot.jl")

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

# getters for solutions
export state_dimension, control_dimension, time_steps, steps_dimension, state
export control, adjoint, objective, iterations, success, message, stopping
export constraints_violation

# plots
export plot, plot!

# extras
export Ad, Poisson

end
