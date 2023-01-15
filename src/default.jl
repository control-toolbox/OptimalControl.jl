# --------------------------------------------------------------------------------------------------
# defaults values
__penalty_constraint() = 1e4 # the penalty term in front of final constraints
__iterations() = 100 # number of maximal iterations
#__step_length() = nothing # the step length of the line search method
#function __step_length(line_search::Symbol, step_length::Union{Real,Nothing})
#    if step_length == __step_length() && line_search == :fixedstep
#        return 1e-1 # fixed step length, small enough
#    elseif step_length == __step_length() #&& line_search==:backtracking
#        return 1e0 # initial step length for backtracking
#    else
#        return step_length
#    end
#end
__absoluteTolerance() = 10 * eps() # absolute tolerance for the stopping criterion
__optimalityTolerance() = 1e-8 # optimality relative tolerance for the CN1
__stagnationTolerance() = 1e-8 # step stagnation relative tolerance
__display() = true # print output during resolution
__callbacks() = ()

# default for interpolation of the initialization
__init_interpolation() = (T, U) -> Interpolations.linear_interpolation(T, U, extrapolation_bc = Interpolations.Line())