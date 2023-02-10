module CTDirectShooting

# using
#
# ici CTBase est vu comme un sous-module déjà inclus dans un module parent (OptimalControl)
# du coup, on fait du ..CTBase 
using ..CTBase
import ..CTBase: DirectShootingSolution

#
using LinearAlgebra # for the norm for instance
using Printf # to print iterations results for instance

# todo: use RecipesBase instead of plot
using Plots
import Plots: plot, plot! # import instead of using to overload the plot and plot! functions

# tools: Descriptions, callbacks, exceptions, functions and more
using ControlToolboxTools
const ControlToolboxCallbacks = Tuple{Vararg{ControlToolboxCallback}} # todo: handle this better

# flows
using HamiltonianFlows

# nlp solvers
using CTOptimization
import CTOptimization: solve, CTOptimizationProblem

# Types
const MyNumber, MyVector, Time, Times, TimesDisc, States, Adjoints, Controls, State, Adjoint, Dimension = CTBase.types()

# Other declarations
const nlp_constraints = CTBase.nlp_constraints
const __grid_size_direct_shooting = CTBase.__grid_size_direct_shooting
const __display = CTBase.__display
const __penalty_constraint = CTBase.__penalty_constraint
const __callbacks = CTBase.__callbacks
const __init_interpolation = CTBase.__init_interpolation
const __iterations = CTBase.__iterations 
const __absoluteTolerance = CTBase.__absoluteTolerance
const __optimalityTolerance = CTBase.__optimalityTolerance
const __stagnationTolerance = CTBase.__stagnationTolerance
const ctgradient = CTBase.ctgradient
const ctjacobian = CTBase.ctjacobian
const expand = CTBase.expand
const vec2vec = CTBase.vec2vec

# includes
include("init.jl")
include("utils.jl")
include("problem.jl")
include("solve.jl")
include("solution.jl")
include("plot.jl")

# export functions only for user
export direct_shooting_solve
export plot, plot!

end