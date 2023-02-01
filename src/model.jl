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
function time!(ocp::OptimalControlModel, type::Symbol, time::Time)
    type_ = Symbol(type, :_time)
    if type_ == :initial_time || type_ == :final_time
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
    if type == :initial || type == :final
        ocp.constraints[label] = (type, :eq, x->x-val)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    ll = Symbol(label, :_lower)
    lu = Symbol(label, :_upper)
    if type == :initial || type == :final
        lb > -Inf ? ocp.constraints[ll] = (type, :ineq, x->x-lb) : nothing
        ub <  Inf ? ocp.constraints[lu] = (type, :ineq, x->ub-x) : nothing
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function)
    if type == :dynamics || type == :dynamics!
        setproperty!(ocp, type, f)
    else
        error("this constraint is not valid")
    end
end

function constraint!(ocp::OptimalControlModel, type::Symbol, f::Function, lb::Real, ub::Real, label::Symbol=gensym(:anonymous))
    ll = Symbol(label, :_lower)
    lu = Symbol(label, :_upper)
    if type == :control
        lb > -Inf ? ocp.constraints[ll] = (type, :ineq, u->f(u)-lb) : nothing
        ub <  Inf ? ocp.constraints[lu] = (type, :ineq, u->ub-f(u)) : nothing
    elseif type == :state
        lb > -Inf ? ocp.constraints[ll] = (type, :ineq, (x,u)->f(x,u)-lb) : nothing
        ub <  Inf ? ocp.constraints[lu] = (type, :ineq, (x,u)->ub-f(x,u)) : nothing
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
    return ocp.constraints[label][3]
end

#
function NLPConstraints(ocp::OptimalControlModel)
    constraints = ocp.constraints
    
    ξf = Vector{Any}(); ξl = Vector{Any}(); ξu = Vector{Any}()
    ψf = Vector{Any}(); ψl = Vector{Any}(); ψu = Vector{Any}()
    ϕf = Vector{Any}(); ϕl = Vector{Any}(); ϕu = Vector{Any}()

    for (key, c) ∈ constraints
        if c[1] == :control
            push!(ξf, c[3])
            push!(ξl, 0.)
            c[2] == :eq ? push!(ξu, 0.) : push!(ξu, Inf)
        elseif c[1] == :state
            push!(ψf, c[3])
            push!(ψl, 0.)
            c[2] == :eq ? push!(ψu, 0.) : push!(ψu, Inf)
        elseif c[1] == :initial
            push!(ϕf, (t0, x0, tf, xf) -> c[3](x0))
            append!(ϕl, zeros(Float64, ocp.state_dimension)) # todo: 
            c[2] == :eq ? append!(ϕu, zeros(Float64, ocp.state_dimension)) : push!(ϕu, Inf)
        elseif c[1] == :final
            push!(ϕf, (t0, x0, tf, xf) -> c[3](xf))
            append!(ϕl, zeros(Float64, ocp.state_dimension)) # todo:
            c[2] == :eq ? append!(ϕu, zeros(Float64, ocp.state_dimension)) : push!(ϕu, Inf)
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
    if criterion == :min || criterion == :max
        ocp.criterion = criterion
    else
        error("this criterion is not valid")
    end
    if type == :lagrangian || type == :mayer
        setproperty!(ocp, type, f)
    else
        error("this objective is not valid")
    end
end