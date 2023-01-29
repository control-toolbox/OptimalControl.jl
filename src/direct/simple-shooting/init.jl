# --------------------------------------------------------------------------------------------------
# make an CTOptimizationInit (Unconstrained) from UncFreeXfInit and others
# direct simple shooting

# --------------------------------------------------------------------------------------------------
# check if the given grid (to the interface to the solver) is valid
function __check_grid_validity(ocp::UncFreeXfProblem, T::Times)
    # T: t0 ≤ t1 ≤ ... ≤ tf
    t0 = ocp.initial_time
    tf = ocp.final_time
    valid = true
    valid = (t0==T[1]) & valid
    valid = (tf==T[end]) & valid
    valid = (T==sort(T)) & valid
    return valid
end

function __check_grid_validity(U::Controls, T::Times)
    # length(U) == length(T) - 1
    return length(U) == (length(T) - 1)
end

# --------------------------------------------------------------------------------------------------
# default values
__grid_size() = 201
function __grid(ocp::UncFreeXfProblem, N::Integer=__grid_size()) 
    t0 = ocp.initial_time
    tf = ocp.final_time
    return range(t0, tf, N)
end
function __init(ocp::UncFreeXfProblem, N::Integer=__grid_size())
    m = ocp.control_dimension
    return expand([zeros(m) for i in 1:N-1])
end

#
function my_interpolation(interp::Function, T::Times, U::Controls, T_::Times)
    u_lin = interp(T, U)
    return u_lin.(T_)
end

# convert
function convert_init(U::Controls)
    return expand(U)
end

# --------------------------------------------------------------------------------------------------
# make

# init=nothing, grid=nothing => init=default, grid=range(t0, tf, N), with N=__grid_size()
function make_udss_init(ocp::UncFreeXfProblem, init::Nothing, grid::Nothing, args...)
    return __init(ocp), __grid(ocp)
end

# init=nothing, grid=T => init=zeros(m, N-1), grid=T, with N=length(T) (check validity)
function make_udss_init(ocp::UncFreeXfProblem, init::Nothing, grid::Times, args...)
    if !__check_grid_validity(ocp, grid)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    return __init(ocp, length(grid)), grid
end

# init=U, grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size()
function make_udss_init(ocp::UncFreeXfProblem, U::Controls, grid::Nothing, interp::Function)
    T  = __grid(ocp, length(U)+1)
    T_ = __grid(ocp)
    U_ = my_interpolation(interp, T[1:end-1], U, T_)
    return convert_init(U_[1:end-1]), T_
end

# init=U, grid=T => init=U, grid=T (check validity with ocp and with init)
function make_udss_init(ocp::UncFreeXfProblem, init::Controls, grid::Times, args...)
    if !__check_grid_validity(ocp, grid)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    if !__check_grid_validity(init, grid)
        throw(InconsistentArgument("grid argument is inconsistent with init argument"))
    end
    return convert_init(init), grid
end

# init=(T,U), grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size() (check validity with ocp and with U)
function make_udss_init(ocp::UncFreeXfProblem, init::Tuple{Times,Controls}, grid::Nothing, interp::Function)
    T = init[1]
    U = init[2]
    if !__check_grid_validity(ocp, T)
        throw(InconsistentArgument("init[1] argument is inconsistent with ocp argument"))
    end
    if !__check_grid_validity(U, T)
        throw(InconsistentArgument("init[1] argument is inconsistent with init[2] argument"))
    end
    T_ = __grid(ocp) # default grid
    U_ = my_interpolation(interp, T[1:end-1], U, T_)
    return convert_init(U_[1:end-1]), T_
end

# init=(T1,U), grid=T2 => init=U, grid=T2 (check validity with ocp (T1, T2) and with U (T1))
function make_udss_init(ocp::UncFreeXfProblem, init::Tuple{Times,Controls}, grid::Times, interp::Function)
    T1 = init[1]
    U  = init[2]
    T2 = grid
    if !__check_grid_validity(ocp, T2)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    if !__check_grid_validity(ocp, T1)
        throw(InconsistentArgument("init[1] argument is inconsistent with ocp argument"))
    end
    if !__check_grid_validity(U, T1)
        throw(InconsistentArgument("init[1] argument is inconsistent with init[2] argument"))
    end
    U_ = my_interpolation(interp, T1[1:end-1], U, T2)
    return convert_init(U_[1:end-1]), T2
end

# init=S, grid=nothing => init=S.U, grid=range(t0, tf, N), with N=__grid_size()
function make_udss_init(ocp::UncFreeXfProblem, S::UncFreeXfSolution, grid::Nothing, interp::Function)
    T_ = __grid(ocp) # default grid
    U_ = my_interpolation(interp, S.T[1:end-1], S.U, T_)
    return convert_init(U_[1:end-1]), T_
end

# init=S, grid=T => init=S.U, grid=T (check validity with ocp)
function make_udss_init(ocp::UncFreeXfProblem, S::UncFreeXfSolution, T::Times, interp::Function)
    if !__check_grid_validity(ocp, T)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    U_ = my_interpolation(interp, S.T[1:end-1], S.U, T)
    return convert_init(U_[1:end-1]), T
end

# init=u, grid=nothing => init=u(T), grid=T=range(t0, tf, N), with N=__grid_size()
function make_udss_init(ocp::UncFreeXfProblem, u::Function, grid::Nothing, args...)
    T = __grid(ocp) # default grid
    U = u.(T)
    return convert_init(U[1:end-1]), T
end

# init=u, grid=T => init=u(T), grid=T (check validity with ocp)
function make_udss_init(ocp::UncFreeXfProblem, u::Function, T::Times, args...)
    if !__check_grid_validity(ocp, T)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    U = u.(T)
    return convert_init(U[1:end-1]), T
end