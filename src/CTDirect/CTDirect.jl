module CTDirect

# using
#
#include("../CTBase/CTBase.jl"); 
using ..CTBase
import ..CTBase: DirectSolution

# todo: use RecipesBase instead of plot
using Plots
import Plots: plot, plot! # import instead of using to overload the plot and plot! functions

# nlp modeling and resolution
using NLPModelsIpopt, ADNLPModels

# tools: Descriptions, callbacks, exceptions, functions and more
using ControlToolboxTools

# Types
const MyNumber, MyVector, Time, Times, TimesDisc, States, Adjoints, Controls, State, Adjoint, Dimension = CTBase.types()

# Other declarations
const nlp_constraints = CTBase.nlp_constraints
const __grid_size_direct = CTBase.__grid_size_direct
const __print_level_ipopt = CTBase.__print_level_ipopt
const __mu_strategy_ipopt = CTBase.__mu_strategy_ipopt
const __display = CTBase.__display

# includes
include("utils.jl")
include("problem.jl")
include("solve.jl")
include("solution.jl")
include("plot.jl")

# export functions only for user
export direct_solve
export plot

end