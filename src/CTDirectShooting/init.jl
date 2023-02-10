# --------------------------------------------------------------------------------------------------
# make a CTOptimizationInit (Unconstrained)
# direct shooting

# --------------------------------------------------------------------------------------------------
# check if the given grid (to the interface to the solver) is valid
function check_grid_validity(t0::Time, tf::Time, T::TimesDisc)
    # T: t0 ≤ t1 ≤ ... ≤ tf
    valid = true
    valid = (t0==T[1]) & valid
    valid = (tf==T[end]) & valid
    valid = (T==sort(T)) & valid
    return valid
end

function check_grid_validity(U::Vector{<:MyVector}, T::TimesDisc)
    return length(U) == (length(T) - 1) || length(U) == length(T)
end

# --------------------------------------------------------------------------------------------------
#
function my_interpolation(interp::Function, T::TimesDisc, U::Controls, T_::TimesDisc)
    u_lin = interp(T, U)
    return u_lin.(T_)
end

# --------------------------------------------------------------------------------------------------
# default values
function __grid(t0::Time, tf::Time, N::Integer=__grid_size_direct_shooting()) 
    return range(t0, tf, N)
end
function __init(m::Dimension, N::Integer=__grid_size_direct_shooting())
    return expand([zeros(m) for i in 1:N-1])
end

# --------------------------------------------------------------------------------------------------
#
function reduce_one_if_necessary(U::Controls, T::TimesDisc)
    if length(U) == length(T)
        return U[1:end-1]
    else
        return U
    end
end

# convert to get a Vector of numbers for the CTOptimization solver
function convert_init(U::Controls)
    return expand(U)
end

# 
function finalize_init(U::Controls, T::TimesDisc)
    return convert_init(reduce_one_if_necessary(U, T)), T
end

# --------------------------------------------------------------------------------------------------
# matrix
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, init::Tuple{TimesDisc, Matrix{<:MyNumber}}, grid, interp::Function)
    T = init[1]
    U = init[2]
    return CTOptimizationInit(t0, tf, m, (T, matrix2vec(U)), grid, interp)
end

function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, U::Matrix{<:MyNumber}, grid, interp::Function)
    return CTOptimizationInit(t0, tf, m, matrix2vec(U), grid, interp)
end

# init=nothing, grid=nothing => init=default, grid=range(t0, tf, N), with N=__grid_size_direct_shooting()
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, init::Nothing, grid::Nothing, args...)
    return __init(m), __grid(t0, tf)
end

# init=nothing, grid=T => init=zeros(m, N-1), grid=T, with N=length(T) (check validity)
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, init::Nothing, grid::TimesDisc, args...)
    if !check_grid_validity(t0, tf, grid)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    return __init(m, length(grid)), grid
end

# init=U, grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size_direct_shooting()
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, U::Controls, grid::Nothing, interp::Function)
    T  = __grid(t0, tf, length(U)+1)
    T_ = __grid(t0, tf)
    U_ = my_interpolation(interp, T[1:end-1], U, T_)
    return finalize_init(U_, T_)
end

# init=U, grid=T => init=U, grid=T (check validity with ocp and with init)
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, init::Controls, grid::TimesDisc, args...)
    if !check_grid_validity(t0, tf, grid)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    if !check_grid_validity(init, grid)
        throw(InconsistentArgument("grid argument is inconsistent with init argument"))
    end
    return finalize_init(init, grid)
end

# init=(T,U), grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size_direct_shooting() (check validity with ocp and with U)
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, init::Tuple{TimesDisc,Controls}, grid::Nothing, interp::Function)
    T_ = __grid(t0, tf) # default grid
    return CTOptimizationInit(t0, tf, m, init, T_, interp)
end

# init=(T1,U), grid=T2 => init=U, grid=T2 (check validity with ocp (T1, T2) and with U (T1))
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, init::Tuple{TimesDisc,Controls}, grid::TimesDisc, interp::Function)
    T1 = init[1]
    U  = init[2]
    T2 = grid
    if !check_grid_validity(t0, tf, T2)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    if !check_grid_validity(t0, tf, T1)
        throw(InconsistentArgument("init[1] argument is inconsistent with ocp argument"))
    end
    if !check_grid_validity(U, T1)
        throw(InconsistentArgument("init[1] argument is inconsistent with init[2] argument"))
    end
    U_ = my_interpolation(interp, T1[1:length(U)], U, T2)
    return finalize_init(U_, T2)
end

# 
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, S::DirectShootingSolution, grid, interp::Function)
    return CTOptimizationInit(t0, tf, m, (time_steps(S), control(S)), grid, interp)
end

# 
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, S::DirectSolution, grid, interp::Function)
    return CTOptimizationInit(t0, tf, m, (time_steps(S), control(S)), grid, interp)
end

#
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, u::Function, T::TimesDisc, interp::Function)
    return CTOptimizationInit(t0, tf, m, u.(T), T, interp)
end

#
function CTOptimizationInit(t0::Time, tf::Time, m::Dimension, u::Function, grid::Nothing, interp::Function)
    return CTOptimizationInit(t0, tf, m, u, __grid(t0, tf), interp)
end