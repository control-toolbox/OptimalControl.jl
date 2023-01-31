# --------------------------------------------------------------------------------------------------
# Abstract Optimal control model
abstract type AbstractOptimalControlModel end

@with_kw mutable struct OptimalControlModel <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    lagrange::Union{Function,Nothing}=nothing
    dynamics::Union{Function,Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    control_dimension::Union{Dimension,Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Symbol, Symbol, Function}}=Dict{Symbol, Tuple{Symbol, Symbol, Function}}()
end

#
function Model()
    return OptimalControlModel()
end

# -------------------------------------------------------------------------------------------
# 
function state!(ocp::OptimalControlModel, n::Dimension)
    ocp.state_dimension = n
end

function control!(ocp::OptimalControlModel, m::Dimension)
    ocp.control_dimension = m
end

# -------------------------------------------------------------------------------------------
# 
function time!(ocp::OptimalControlModel, t::Symbol, time::Time)
    if t == :initial
        ocp.initial_time=time
    elseif t == :final
        ocp.final_time=time
    else
        error("this time choice is not valid")
    end
end

function time!(ocp::OptimalControlModel, times::Times)
    if length(times) != 2
        error("times must be of dimension 2")
    end
    ocp.initial_time=times[1]
    ocp.final_time=times[2]
end

# -------------------------------------------------------------------------------------------
#
function constraint!(ocp::OptimalControlModel, type::Symbol, val::State, label::Symbol=gensym(:anonymous))
    if type == :initial
        ocp.constraints[label] = (type, :eq, x->x-val)
    elseif type == :final
        ocp.constraints[label] = (type, :eq, x->x-val)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function)
    if type == :dynamics
        ocp.dynamics = f
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type == :control
        if lb > -Inf
            ocp.constraints[Symbol(label, :_lower)] = (type, :ineq, u->f(u)-lb)
        end
        if ub < Inf
            ocp.constraints[Symbol(label, :_lower)] = (type, :ineq, u->ub-f(u))
        end
    elseif type == :state
        if lb > -Inf
            ocp.constraints[Symbol(label, :_lower)] = (type, :ineq, (x,u)->f(x,u)-lb)
        end
        if ub < Inf
            ocp.constraints[Symbol(label, :_lower)] = (type, :ineq, (x,u)->ub-f(x,u))
        end
    else
        error("this constraint is not valid")
    end
end

function constraint(ocp::OptimalControlModel, label::Symbol)
    return ocp.constraints[label][3]
end

# -------------------------------------------------------------------------------------------
# 
function objective!(ocp::OptimalControlModel, o::Symbol, f::Function)
    if o == :lagrangian
        ocp.lagrange = f
    else
        error("this objective is not valid")
    end
end