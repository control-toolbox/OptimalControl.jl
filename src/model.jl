# --------------------------------------------------------------------------------------------------
# Abstract Optimal control model
abstract type AbstractOptimalControlModel end

@with_kw mutable struct OptimalControlModel <: AbstractOptimalControlModel
    initial_time::Union{Time,Nothing}=nothing
    final_time::Union{Time,Nothing}=nothing
    lagrangian::Union{Function,Nothing}=nothing
    mayer::Union{Function,Nothing}=nothing
    criterion::Union{Symbol,Nothing}=nothing
    dynamics::Union{Function,Nothing}=nothing
    dynamics!::Union{Function,Nothing}=nothing
    state_dimension::Union{Dimension,Nothing}=nothing
    control_dimension::Union{Dimension,Nothing}=nothing
    constraints::Dict{Symbol, Tuple{Vararg{Any}}}=Dict{Symbol, Tuple{Vararg{Any}}}()
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
function time!(ocp::OptimalControlModel, type::Symbol, time::Time)
    type_ = Symbol(type, :_time)
    if type_ in [ :initial_time, :final_time ]
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
    if type in [ :initial, :final ]
        ocp.constraints[label] = (type, :eq, x -> x, val)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type in [ :initial, :final ]
        ocp.constraints[label] = (type, :ineq, x -> x, ub, lb)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function)
    if type in [ :dynamics, :dynamics! ]
        setproperty!(ocp, type, f)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, val::Real, label::Symbol=gensym(:anonymous))
    if type in [ :control, :state, :boundary ]
        ocp.constraints[label] = (type, :eq, f, val)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    if type in [ :control, :state, :boundary ]
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
function constraint(ocp::OptimalControlModel, label::Symbol)
    con = ocp.constraints[label]
    if length(con) != 4
        nothing
    else
        error("this constraint is not valid")
    end
    type, _, f, val = con
    if type in [ :initial, :final ]
        return x -> f(x) - val
    elseif type == :boundary
        return (t0, x0, tf, xf) -> f(t0, x0, tf, xf) - val
    elseif type == :control
        return u -> f(u) - val
    elseif type == :state
        return (x, u) -> f(x, u) - val
    else
        error("this constraint is not valid")
    end
    return nothing
end

#
function constraint(ocp::OptimalControlModel, label::Symbol, bound::Symbol)
    # constraints are all >= 0
    type, _, f, lb, ub = ocp.constraints[label]
    if !( bound in [ :lower, :upper ] )
        error("this constraint is not valid")
    end
    if (bound == :lower && lb == -Inf) || (bound == :upper && ub == Inf)
        error("this constraint is not valid")
    end 
    if type in [ :initial, :final ]
        return bound == :lower ? x -> f(x) - lb : x -> ub - f(x)
    elseif type == :boundary
        return bound == :lower ? (t0, x0, tf, xf) -> f(t0, x0, tf, xf) - lb : (t0, x0, tf, xf) -> ub - f(t0, x0, tf, xf)
    elseif type == :control
        return bound == :lower ? u -> f(u) - lb : u -> ub - f(u)
    elseif type == :state
        return bound == :lower ? (x, u) -> f(x, u) - lb : (x, u) -> ub - f(x,u) 
    else
        error("this constraint is not valid")
    end
    return nothing
end

#
function nlp_constraints(ocp::OptimalControlModel)
    #
    constraints = ocp.constraints
    n = ocp.state_dimension
    
    ξf = Vector{Any}(); ξl = Vector{Any}(); ξu = Vector{Any}()
    ψf = Vector{Any}(); ψl = Vector{Any}(); ψu = Vector{Any}()
    ϕf = Vector{Any}(); ϕl = Vector{Any}(); ϕu = Vector{Any}()

    for (_, c) ∈ constraints
        if c[1] == :control
            push!(ξf, c[3])
            append!(ξl, c[4])
            append!(ξu, c[2] == :eq ? c[4] : c[5])
        elseif c[1] == :state
            push!(ψf, c[3])
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

    ξ!(val, u) = [ val[i] = ξf[i](u) for i in 1:length(ξf) ]
    ψ!(val, x, u) = [ val[i] = ψf[i](x, u) for i in 1:length(ψf) ]
    ϕ!(val, t0, x0, tf, xf) = [ val[i] = ϕf[i](t0, x0, tf, xf) for i in 1:length(ϕf) ]

    return (ξ!, ξl, ξu), (ψ!, ψl, ψu), (ϕ!, ϕl, ϕu)

end

# -------------------------------------------------------------------------------------------
# 
function objective!(ocp::OptimalControlModel, type::Symbol, f::Function, criterion::Symbol=:min)
    if criterion in [ :min, :max ]
        ocp.criterion = criterion
    else
        error("this criterion is not valid")
    end
    if type in [ :lagrangian, :mayer ]
        setproperty!(ocp, type, f)
    else
        error("this objective is not valid")
    end
end
