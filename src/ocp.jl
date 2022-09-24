abstract type OptimalControlProblem end

# TODO : améliorer constructeur
# ajouter pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
mutable struct ROCP <: OptimalControlProblem
    integrand_cost::Function 
    dynamics::Function
    initial_time::Number
    initial_condition::Vector{<:Number}
    final_time::Number
    final_constraints::Function
end

methods_desc = Dict(
    :steepest_descent => "Steepest descent method for optimal control problem"
)

function osolve(ocp::OptimalControlProblem, method::Symbol=:steepest_descent; kwargs...)
    if method==:steepest_descent
        return steepest_descent_ocp(ocp; kwargs...)
    else
        nothing
    end  
end

#println(methods_desc[:steepest_descent])