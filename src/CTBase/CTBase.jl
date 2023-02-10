module CTBase

# this should be in ControlToolboxTools, which should be renamed CTBase

# using
using ForwardDiff: jacobian, gradient, ForwardDiff # automatic differentiation
using Parameters # @with_kw: permit to have default values in struct
using Interpolations: linear_interpolation, Line, Interpolations # for default interpolation
#import Base: show # to print an OptimalControlModel
using Printf # to print a OptimalControlModel
using ControlToolboxTools # tools: callbacks, exceptions, functions and more

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
types() = MyNumber, MyVector, Time, Times, TimesDisc, States, Adjoints, Controls, State, Adjoint, Dimension

#
include("utils.jl")
#include("algorithms.jl")
include("model.jl")
include("print.jl")
include("solutions.jl")
include("default.jl")

#function solve(ocp::OptimalControlModel, algo::AbstractControlAlgorithm, method::Description; kwargs...)
#    error("solve not implemented")
#end

#
# export only for users

# utils
export Ad, Poisson

# model
export Model, time!, constraint!, objective!, state!, control!, remove_constraint!, constraint
export ismin, dynamics, lagrange, criterion, initial_time, final_time
export control_dimension, state_dimension, constraints, initial_condition, final_constraint

# solution
export time_steps_length, state_dimension, control_dimension
export time_steps, state, control, adjoint, objective
export iterations, success, message, stopping
export constraints_violation

# export structs
export AbstractOptimalControlModel, OptimalControlModel
export AbstractOptimalControlSolution, DirectSolution, DirectShootingSolution
#export AbstractControlAlgorithm, DirectAlgorithm, DirectShootingAlgorithm

# solve
#export solve

end