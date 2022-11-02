# --------------------------------------------------------------------------------------------------
# Aliases for types
const Times = Union{Vector{<:Number},StepRangeLen}
const States = Vector{<:Vector{<:Number}}
const Adjoints = Vector{<:Vector{<:Number}} #Union{Vector{<:Number}, Vector{<:Vector{<:Number}}, Matrix{<:Vector{<:Number}}}
const Controls = Vector{<:Vector{<:Number}} #Union{Vector{<:Number}, Vector{<:Vector{<:Number}}}
const Time = Number
const State = Vector{<:Number}
const Adjoint = Vector{<:Number}
const Dimension = Integer

# --------------------------------------------------------------------------------------------------
# Optimal control problems
abstract type OptimalControlProblem end

# Regular OCP with final constrainst
struct RegularOCPFinalConstraint <: OptimalControlProblem
    description::Description
    state_dimension::Union{Dimension,Nothing}
    control_dimension::Union{Dimension,Nothing}
    final_constraint_dimension::Union{Dimension,Nothing}
    Lagrange_cost::Function
    dynamics::Function
    initial_time::Time
    initial_condition::State
    final_time::Time
    final_constraint::Function
end

# Regular OCP with final condition
struct RegularOCPFinalCondition <: OptimalControlProblem
    description::Description
    state_dimension::Union{Dimension,Nothing}
    control_dimension::Union{Dimension,Nothing}
    Lagrange_cost::Function
    dynamics::Function
    initial_time::Time
    initial_condition::State
    final_time::Time
    final_condition::State
end

# Creation of a regular OCP with final constrainst
"""
	OCP(Lagrange_cost      :: Function, 
	dynamics                    :: Function, 
	initial_time                :: Time,
	initial_condition           :: State,
	final_time                  :: Time,
	final_constraint            :: Function,
	state_dimension             :: Dimension,
	control_dimension           :: Dimension,
	final_constraint_dimension  :: Dimension,
	description...)

TBW
"""
function OCP(
    Lagrange_cost::Function,
    dynamics::Function,
    initial_time::Time,
    initial_condition::State,
    final_time::Time,
    final_constraint::Function,
    state_dimension::Dimension,
    control_dimension::Dimension,
    final_constraint_dimension::Dimension,
    description...,
)
    ocp = RegularOCPFinalConstraint(makeDescription(description...), state_dimension, control_dimension, final_constraint_dimension, Lagrange_cost, dynamics, initial_time, initial_condition, final_time, final_constraint)
    return ocp
end

# Creation of a regular OCP with final condition
"""
	OCP(Lagrange_cost      :: Function, 
	dynamics                    :: Function, 
	initial_time                :: Time,
	initial_condition           :: State,
	final_time                  :: Time,
	final_condition             :: State,
	state_dimension             :: Dimension,
	control_dimension           :: Dimension,
	description...)

TBW
"""
function OCP(Lagrange_cost::Function, dynamics::Function, initial_time::Time, initial_condition::State, final_time::Time, final_condition::State, state_dimension::Dimension, control_dimension::Dimension, description...)
    ocp = RegularOCPFinalCondition(makeDescription(description...), state_dimension, control_dimension, Lagrange_cost, dynamics, initial_time, initial_condition, final_time, final_condition)
    return ocp
end

#= # instantiation of the ocp: choose the right type depending upon the inputs
# todo : à voir de ce que l'on fait de cette méthode avec des arguments en keywords
function OCP(   description...; # keyword arguments from here
				control_dimension           :: Dimension,
				Lagrange_cost               :: Function, 
				dynamics                    :: Function, 
				initial_condition           :: State, 
				final_time                  :: Time, 
				final_constraint            :: Function, # optional from here
				final_constraint_dimension  :: Union{Dimension, Nothing}=nothing,
				state_dimension             :: Union{Dimension, Nothing}=nothing,
				initial_time                :: Time=0.0)

	# create the right ocp type depending on inputs
	state_dimension = state_dimension===nothing ? length(initial_condition) : state_dimension 
	ocp = RegularOCPFinalConstraint(makeDescription(description...), state_dimension, control_dimension, 
				final_constraint_dimension, Lagrange_cost, dynamics, initial_time, initial_condition, 
				final_time, final_constraint)
	return ocp
end =#

# --------------------------------------------------------------------------------------------------
# Initialization
abstract type OptimalControlInit end

# --------------------------------------------------------------------------------------------------
# Solution
abstract type OptimalControlSolution end

# --------------------------------------------------------------------------------------------------
# Resolution
"""
	solve(ocp::OptimalControlProblem, description...; kwargs...)

TBW
"""
function solve(ocp::OptimalControlProblem, description...; kwargs...)
    method = getCompleteSolverDescription(makeDescription(description...))
    # if no error before, then the method is correct: no need of else
    if :descent in method
        return solve_by_descent(ocp, method; kwargs...)
    end
end

# --------------------------------------------------------------------------------------------------
# Description of the methods
#
#methods_desc = Dict(
#    :descent => "Descent method for optimal control problem"
#)

# --------------------------------------------------------------------------------------------------
# Display: text/html ?  
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
"""
	Base.show(io::IO, ocp::RegularOCPFinalConstraint)

TBW
"""
function Base.show(io::IO, ocp::RegularOCPFinalConstraint)

    dimx = ocp.state_dimension === nothing ? "n" : ocp.state_dimension
    dimu = ocp.control_dimension === nothing ? "m" : ocp.control_dimension
    dimc = ocp.final_constraint_dimension === nothing ? "p" : ocp.final_constraint_dimension

    desc = ocp.description

    println(io, "Optimal control problem of the form:")
    println(io, "")
    print(io, "    minimize  J(x, u) = ")
    isnonautonomous(desc) ? println(io, '\u222B', " L(t, x(t), u(t)) dt, over [t0, tf]") : println(io, '\u222B', " L(x(t), u(t)) dt, over [t0, tf]")
    println(io, "")
    println(io, "    subject to")
    println(io, "")
    isnonautonomous(desc) ? println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")
    println(io, "        x(t0) = x0, c(x(tf)) = 0,")
    println(io, "")
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx), ", u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), " and c(x) ", '\u2208', " R", dimc == 1 ? "" : Base.string("^", dimc), ".")
    #println(io, "")
    println(io, " Besides, t0, tf and x0 are fixed. ")
    #println(io, "")

end

"""
	Base.show(io::IO, ocp::RegularOCPFinalCondition)

TBW
"""
function Base.show(io::IO, ocp::RegularOCPFinalCondition)

    dimx = ocp.state_dimension === nothing ? "n" : ocp.state_dimension
    dimu = ocp.control_dimension === nothing ? "m" : ocp.control_dimension

    desc = ocp.description

    println(io, "Optimal control problem of the form:")
    println(io, "")
    print(io, "    minimize  J(x, u) = ")
    isnonautonomous(desc) ? println(io, '\u222B', " L(t, x(t), u(t)) dt, over [t0, tf]") : println(io, '\u222B', " L(x(t), u(t)) dt, over [t0, tf]")
    println(io, "")
    println(io, "    subject to")
    println(io, "")
    isnonautonomous(desc) ? println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")
    println(io, "        x(t0) = x0, x(tf) = xf,")
    println(io, "")
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx), " and u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), ".")
    #println(io, "")
    println(io, " Besides, t0, tf, x0 and xf are fixed. ")
    #println(io, "")

end
