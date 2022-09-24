# --------------------------------------------------------------------------------------------------
# Aliases for types
#
const Times = Union{Vector{<:Number}, StepRangeLen}
const States = Union{Vector{<:Number}, Vector{<:Vector{<:Number}}, Matrix{<:Vector{<:Number}}}
const Controls = Union{Vector{<:Number}, Vector{<:Vector{<:Number}}}

const Time = Number
const State = Vector{<:Number}

# --------------------------------------------------------------------------------------------------
# Optimal control problems
#
abstract type OptimalControlProblem end

# TODO : améliorer constructeur
# ajouter pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
mutable struct RegularOptimalControlProblem <: OptimalControlProblem
    integrand_cost::Function 
    dynamics::Function
    initial_time::Time
    initial_condition::State
    final_time::Time
    final_constraints::Function
end

const OCP = OptimalControlProblem
const ROCP = RegularOptimalControlProblem

# --------------------------------------------------------------------------------------------------
# Initialization
#
abstract type OptimalControlInit end

mutable struct SteepestOCPInit <: OptimalControlInit
    U::Controls
end

const SOCPInit = SteepestOCPInit

# --------------------------------------------------------------------------------------------------
# Solution
#
abstract type OptimalControlSolution end

mutable struct SteepestOCPSol <: OptimalControlSolution
    T::Times
    X::States
    U::Controls
end

const SOCPSol = SteepestOCPSol

# --------------------------------------------------------------------------------------------------
# Description of the methods
#
methods_desc = Dict(
    :steepest_descent => "Steepest descent method for optimal control problem"
)

# --------------------------------------------------------------------------------------------------
# Resolution
#
function solve(ocp::OCP, method::Symbol=:steepest_descent; kwargs...)
    if method==:steepest_descent
        return steepest_descent_ocp(ocp; kwargs...)
    else
        nothing
    end  
end

# --------------------------------------------------------------------------------------------------
# Plot solution
#
function get(ocp_sol::SteepestOCPSol, xx::Union{Symbol, Tuple{Symbol, Integer}})

    T = ocp_sol.T
    X = ocp_sol.X
    U = ocp_sol.U

    m = length(T)

    if typeof(xx) == Symbol
        if xx == :time
            x = T
        elseif xx == :state
            x = [ X[i][1] for i=1:m ]
        else
            x = vcat([ U[i][1] for i=1:m-1 ], U[m-1][1])
        end
    else
        vv = xx[1]
        ii = xx[2]
        if vv == :time
            x = T
        elseif vv == :state
            x = [ X[i][ii] for i=1:m ]
        else
            x = vcat([ U[i][ii] for i=1:m-1 ], U[m-1][ii])
        end
    end

    return x

end

function plot(ocp_sol::SteepestOCPSol, 
    xx::Union{Symbol, Tuple{Symbol, Integer}}, 
    yy::Union{Symbol, Tuple{Symbol, Integer}}, args...; kwargs...)

    x = get(ocp_sol, xx)
    y = get(ocp_sol, yy)

    return plot(x, y, args...; kwargs...)

end

function plot!(p, ocp_sol::SteepestOCPSol, 
    xx::Union{Symbol, Tuple{Symbol, Integer}}, 
    yy::Union{Symbol, Tuple{Symbol, Integer}}, args...; kwargs...)

    x = get(ocp_sol, xx)
    y = get(ocp_sol, yy)

    plot!(p, x, y, args...; kwargs...)

end

#println(methods_desc[:steepest_descent])