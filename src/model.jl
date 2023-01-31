# --------------------------------------------------------------------------------------------------
# Abstract Optimal control model
abstract type AbstractOptimalControlModel end

@with_kw mutable struct OptimalControlModel <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    initial_condition::Union{State,Nothing}=nothing
    final_condition::Union{State,Nothing}=nothing
    lagrange::Union{Function,Nothing}=nothing
    dynamics::Union{Function,Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    control_dimension::Union{Dimension,Nothing}=nothing
end

function Model()
    return OptimalControlModel()
end

function state!(ocp::OptimalControlModel, n::Dimension)
    ocp.state_dimension = n
end

function control!(ocp::OptimalControlModel, m::Dimension)
    ocp.control_dimension = m
end

function time!(ocp::OptimalControlModel, times::Times)
    if length(times) != 2
        error("times must be of dimension 2")
    end
    ocp.initial_time=times[1]
    ocp.final_time=times[2]
end

function constraint!(ocp::OptimalControlModel, c::Symbol, x::State)
    if c == :initial
        ocp.initial_condition = x
    elseif c == :final
        ocp.final_condition = x
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, c::Symbol, f::Function)
    if c == :dynamics
        ocp.dynamics = f
    else
        error("this constraint is not valid")
    end
end

function objective!(ocp::OptimalControlModel, o::Symbol, f::Function)
    if o == :lagrangian
        ocp.lagrange = f
    else
        error("this objective is not valid")
    end
end