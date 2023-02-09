# --------------------------------------------------------------------------------------------------
# defaults values for direct shooting
__grid_size_direct_shooting() = 201
__penalty_constraint() = 1e4 # the penalty term in front of final constraints
__iterations() = 100 # number of maximal iterations
__absoluteTolerance() = 10 * eps() # absolute tolerance for the stopping criterion
__optimalityTolerance() = 1e-8 # optimality relative tolerance for the CN1
__stagnationTolerance() = 1e-8 # step stagnation relative tolerance
__display() = true # print output during resolution
__callbacks() = ()

# default for interpolation of the initialization
__init_interpolation() = (T, U) -> Interpolations.linear_interpolation(T, U, extrapolation_bc = Interpolations.Line())

# direct method
__grid_size_direct() = 100
__print_level_ipopt() = 5
__mu_strategy_ipopt() = "adaptive"