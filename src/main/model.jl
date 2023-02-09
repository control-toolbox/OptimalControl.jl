# --------------------------------------------------------------------------------------------------
# Abstract Optimal control model
abstract type AbstractOptimalControlModel end

@with_kw mutable struct OptimalControlModel{time_dependence} <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    lagrange::Union{LagrangeFunction{time_dependence},Nothing}=nothing
    mayer::Union{Function,Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{DynamicsFunction{time_dependence},Nothing}=nothing
    dynamics!::Union{Function,Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    control_dimension::Union{Dimension,Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
end

# Constructors
abstract type Model{td} end # c'est un peu du bricolage ça
function Model{time_dependence}() where {time_dependence}
    return OptimalControlModel{time_dependence}()
end
Model() = Model{:autonomous}() # default value

# -------------------------------------------------------------------------------------------
# getters
dynamics(ocp::OptimalControlModel) = ocp.dynamics
lagrange(ocp::OptimalControlModel) = ocp.lagrange
criterion(ocp::OptimalControlModel) = ocp.criterion
ismin(ocp::OptimalControlModel) = criterion(ocp) == :min
initial_time(ocp::OptimalControlModel) = ocp.initial_time
final_time(ocp::OptimalControlModel) = ocp.final_time
control_dimension(ocp::OptimalControlModel) = ocp.control_dimension
state_dimension(ocp::OptimalControlModel) = ocp.state_dimension
constraints(ocp::OptimalControlModel) = ocp.constraints
function initial_condition(ocp::OptimalControlModel) 
    cs = constraints(ocp)
    n = state_dimension(ocp)
    x0 = nothing
    for (_, c) ∈ cs
        type, _, _, val = c
        if type == :initial
             x0 = val
        end
    end
    return x0
end
function final_constraint(ocp::OptimalControlModel) 
    cs = constraints(ocp)
    cf = nothing
    for (_, c) ∈ cs
        type, _, f, val = c
        if type == :final
            cf = x -> f(x) - val
        end
    end
    return cf
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
function time!(ocp::OptimalControlModel, type::Symbol, time::Time)
    type_ = Symbol(type, :_time)
    if type_ ∈ [ :initial_time, :final_time ]
        setproperty!(ocp, type_, time)
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
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :eq, x -> x, val)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type ∈ [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x, ub, lb)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel{time_dependence}, type::Symbol, f::Function) where {time_dependence}
    if type ∈ [ :dynamics, :dynamics! ]
        setproperty!(ocp, type, DynamicsFunction{time_dependence}(f))
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val::Real, label::Symbol=gensym(:anonymous))
    if type ∈ [ :control, :state, :boundary ]
        ocp.constraints[label] = (type, :eq, f, val)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type ∈ [ :control, :state, :boundary ]
        ocp.constraints[label] = (type, :ineq, f, lb, ub)
    else
        error("this constraint is not valid")
    end
end

#
function remove_constraint!(ocp::OptimalControlModel, label::Symbol)
    delete!(ocp.constraints, label)
end

#
function constraint(ocp::OptimalControlModel{time_dependence}, label::Symbol) where {time_dependence}
    con = ocp.constraints[label]
    if length(con) != 4
        error("this constraint is not valid")
    end
    type, _, f, val = con
    if type ∈ [ :initial, :final ]
        return x -> f(x) - val
    elseif type == :boundary
        return (t0, x0, tf, xf) -> f(t0, x0, tf, xf) - val
    elseif type == :control
        return isautonomous(time_dependence) ? u -> f(u) - val : (t, u) -> f(t, u) - val
    elseif type == :state
        return isautonomous(time_dependence) ? (x, u) -> f(x, u) - val : (t, x, u) -> f(t, x, u) - val
    else
        error("this constraint is not valid")
    end
    return nothing
end

#
function constraint(ocp::OptimalControlModel{time_dependence}, label::Symbol, bound::Symbol) where {time_dependence}
    # constraints are all >= 0
    con = ocp.constraints[label]
    if length(con) != 5
        error("this constraint is not valid")
    end
    type, _, f, lb, ub = con
    if !( bound ∈ [ :lower, :upper ] )
        error("this constraint is not valid")
    end
    if (bound == :lower && lb == -Inf) || (bound == :upper && ub == Inf)
        error("this constraint is not valid")
    end
    if type ∈ [ :initial, :final ]
        return bound == :lower ? x -> f(x) - lb : x -> ub - f(x)
    elseif type == :boundary
        return bound == :lower ? (t0, x0, tf, xf) -> f(t0, x0, tf, xf) - lb : (t0, x0, tf, xf) -> ub - f(t0, x0, tf, xf)
    elseif type == :control
        if isautonomous(time_dependence)
            return bound == :lower ? u -> f(u) - lb : u -> ub - f(u)
        else
            return bound == :lower ? (t, u) -> f(t, u) - lb : (t, u) -> ub - f(t, u)
        end
    elseif type == :state
        if isautonomous(time_dependence)
            return bound == :lower ? (x, u) -> f(x, u) - lb : (x, u) -> ub - f(x, u) 
        else
            return bound == :lower ? (t, x, u) -> f(t, x, u) - lb : (t, x, u) -> ub - f(t, x, u) 
        end
    else
        error("this constraint is not valid")
    end
    return nothing
end

#
function nlp_constraints(ocp::OptimalControlModel{time_dependence}) where {time_dependence}
    #
    constraints = ocp.constraints
    n = ocp.state_dimension
    
    ξf = Vector{ControlFunction}(); ξl = Vector{MyNumber}(); ξu = Vector{MyNumber}()
    ψf = Vector{StateConstraintFunction}(); ψl = Vector{MyNumber}(); ψu = Vector{MyNumber}()
    ϕf = Vector{Function}(); ϕl = Vector{MyNumber}(); ϕu = Vector{MyNumber}()

    for (_, c) ∈ constraints
        if c[1] == :control
            push!(ξf, ControlFunction{time_dependence}(c[3]))
            append!(ξl, c[4])
            append!(ξu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :state
            push!(ψf, StateConstraintFunction{time_dependence}(c[3]))
            append!(ψl, c[4])
            append!(ψu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :initial
            push!(ϕf, (t0, x0, tf, xf) -> c[3](x0))
            append!(ϕl, c[4])
            append!(ϕu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :final
            push!(ϕf, (t0, x0, tf, xf) -> c[3](xf))
            append!(ϕl, c[4])
            append!(ϕu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :boundary
            push!(ϕf, (t0, x0, tf, xf) -> c[3](t0, x0, tf, xf))
            append!(ϕl, c[4])
            append!(ϕu, c[2] == :eq ? c[4] : c[5])
        end
    end

#    ξ!(val, u) = [ val[i] = ξf[i](u) for i ∈ 1:length(ξf) ]
#    ψ!(val, x, u) = [ val[i] = ψf[i](x, u) for i ∈ 1:length(ψf) ]
#    ϕ!(val, t0, x0, tf, xf) = [ val[i] = ϕf[i](t0, x0, tf, xf) for i ∈ 1:length(ϕf) ]

    function ξ(t, u)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ξf) append!(val, ξf[i](t, u)) end
    return val
    end 

    function ψ(t, x, u)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ψf) append!(val, ψf[i](t, x, u)) end
    return val
    end 

    function ϕ(t0, x0, tf, xf)
        val = Vector{MyNumber}()
        for i ∈ 1:length(ϕf) append!(val, ϕf[i](t0, x0, tf, xf)) end
    return val
    end 

    return (ξl, ξ, ξu), (ψl, ψ, ψu), (ϕl, ϕ, ϕu)

end

# -------------------------------------------------------------------------------------------
# 
function objective!(ocp::OptimalControlModel{time_dependence}, type::Symbol, f::Function, criterion::Symbol=:min) where {time_dependence}
    setproperty!(ocp, :mayer, nothing)
    setproperty!(ocp, :lagrange, nothing)
    if criterion ∈ [ :min, :max ]
        ocp.criterion = criterion
    else
        error("this criterion is not valid")
    end
    if type == :mayer
        setproperty!(ocp, :mayer, f)
    elseif type == :lagrange
        setproperty!(ocp, :lagrange, LagrangeFunction{time_dependence}(f))
    else
        error("this objective is not valid")
    end
end
