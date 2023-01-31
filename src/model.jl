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
end

function Model()
    return OptimalControlModel()
end

function time!(ocp::OptimalControlModel, times::Tuple{Time,Time})
    ocp.initial_time=times[1]
    ocp.final_time=times[2]
end

function constraint!(ocp::OptimalControlModel, c::Symbol, x::State)
    if c == :initial || c == :Initial
        ocp.initial_condition = x
    elseif c == :final || c == :Final
        ocp.final_condition = x
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, c::Symbol, f::Function)
    if c == :dynamics || c == :Dynamics
        ocp.dynamics = f
    else
        error("this constraint is not valid")
    end
end

function objective!(ocp::OptimalControlModel, o::Symbol, f::Function)
    if o == :lagrangian || o == :Lagrangian
        ocp.lagrange = f
    else
        error("this objective is not valid")
    end
end