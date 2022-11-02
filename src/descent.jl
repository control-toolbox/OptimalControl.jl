# --------------------------------------------------------------------------------------------------
# Definition of a general descent problem
mutable struct DescentProblem
    ∇f::Function # gradient of the function
    f::Function # function to minimize
end

# --------------------------------------------------------------------------------------------------
# Definition of an initialization for the descent method
mutable struct DescentOCPInit <: OptimalControlInit
    U::Controls # the optimization variable U of the ocp for the descent method
end

mutable struct DescentInit
    x::Vector{<:Number} # the optimization variable x of the descent method
    """
      	DescentInit(x::Vector{<:Number})

      TBW
    """
    function DescentInit(x::Vector{<:Number}) # to transcribe U in x
        new(x)
    end
    """
      	DescentInit(U::Controls)

      TBW
    """
    function DescentInit(U::Controls) # to transcribe U in x
        new(vec2vec(U))
    end
end

# --------------------------------------------------------------------------------------------------
# Definition of a solution for the descent method
mutable struct DescentOCPSol <: OptimalControlSolution
    T::Times # the times
    X::States # the states at the times T
    U::Controls # the controls at T
    P::Adjoints # the adjoint at T
    state_dimension::Dimension # the dimension of the state
    control_dimension::Dimension # the dimension of the control
    stopping::Symbol # the stopping criterion at the end of the descent method
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

mutable struct DescentSol
    x::Vector{<:Number} # the optimization variable solution
    stopping::Symbol # the stopping criterion at the end of the descent method
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

# --------------------------------------------------------------------------------------------------
# read the description to get the chosen methods
# we assume the description is complete
update_method(e::Union{Nothing, Symbol}, s::Symbol, d::Description) = s ∈ d ? s : e
"""
	read(method::Description)

TBW
"""
function read(method::Description)
    #
    direction = nothing
    direction = update_method(direction, :gradient, method)
    direction = update_method(direction, :bfgs, method)
    #
    line_search = nothing
    line_search = update_method(line_search, :fixedstep, method)
    line_search = update_method(line_search, :backtracking, method)
    line_search = update_method(line_search, :bissection, method)
    #
    return direction, line_search
end

# --------------------------------------------------------------------------------------------------
# defaults values
__penalty_constraint() = 1e4 # the penalty term in front of final constraints
__iterations() = 100 # number of maximal iterations
__step_length() = nothing # the step length of the line search method
function __step_length(line_search::Symbol, step_length::Union{Number,Nothing})
    if step_length == __step_length() && line_search == :fixedstep
        return 1e-1 # fixed step length, small enough
    elseif step_length == __step_length() #&& line_search==:backtracking
        return 1e0 # initial step length for backtracking
    else
        return step_length
    end
end
__absoluteTolerance() = 10 * eps() # absolute tolerance for the stopping criterion
__optimalityTolerance() = 1e-8 # optimality relative tolerance for the CN1
__stagnationTolerance() = 1e-8 # step stagnation relative tolerance
__display() = true # print output during resolution
__callbacks() = ()

# default for interpolation of the initialization
#__init_interpolation() = (T, U) -> extrapolate(scale(interpolate(U, BSpline(Linear())), T), Line())
__init_interpolation() = (T, U) -> linear_interpolation(T, U, extrapolation_bc = Line())
#extrapolate(interpolate(T, U, BSpline(Linear())), Line())

# default for descent_solver
__line_search() = :bissection
__direction() = :bfgs

# callback for ocp resolution by descent method
"""
	printOCPDescent(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)

TBW
"""
function printOCPDescent(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)
    if i == 0
        println("\n     Calls  ‖∇F(U)‖         ‖U‖             Stagnation      \n")
    end
    @printf("%10d", i) # Iterations
    @printf("%16.8e", norm(gᵢ)) # ‖∇F(U)‖
    @printf("%16.8e", norm(Uᵢ)) # ‖U‖
    @printf("%16.8e", norm(Uᵢ) > 1e-14 ? norm(sᵢ * dᵢ) / norm(Uᵢ) : norm(sᵢ * dᵢ)) # Stagnation
end

# --------------------------------------------------------------------------------------------------
# Solver of an ocp by descent method
function solve_by_descent(
    ocp::RegularOCPFinalConstraint,
    method::Description;
    init::Union{Nothing,Controls,Tuple{Times,Controls},DescentOCPSol,Function}=nothing,
    grid::Union{Nothing,Times}=nothing,
    penalty_constraint::Number=__penalty_constraint(),
    iterations::Integer=__iterations(),
    step_length::Union{Number,Nothing}=__step_length(),
    absoluteTolerance::Number=__absoluteTolerance(),
    optimalityTolerance::Number=__optimalityTolerance(),
    stagnationTolerance::Number=__stagnationTolerance(),
    display::Bool=__display(),
    callbacks::CTCallbacks=__callbacks(),
    init_interpolation::Function=__init_interpolation()
)

    # --------------------------------------------------------------------------------------------------
    # print chosen method
    display ? println("\nMethod = ", method) : nothing

    # we suppose the description of the method is complete
    # we get the direction search and line search methods
    direction, line_search = read(method)

    # --------------------------------------------------------------------------------------------------
    # get the default options for those which depend on the method
    step_length = __step_length(line_search, step_length)

    # --------------------------------------------------------------------------------------------------
    # step 1: transcription from ocp to descent problem and init
    #
    descent_init, grid = ocp2descent_init(ocp, init, grid, init_interpolation)
    descent_problem = ocp2descent_problem(ocp, grid, penalty_constraint)

    # --------------------------------------------------------------------------------------------------
    # step 2: resolution of the problem
    cbs_print = get_priority_print_callbacks((PrintCallback(printOCPDescent, priority=0), callbacks...))
    cbs_stop = get_priority_stop_callbacks(callbacks)
    descent_sol = descent_solver(
        descent_problem,
        descent_init,
        direction=direction,
        line_search=line_search,
        iterations=iterations,
        step_length=step_length,
        absoluteTolerance=absoluteTolerance,
        optimalityTolerance=optimalityTolerance,
        stagnationTolerance=stagnationTolerance,
        display=display,
        callbacks=(cbs_print..., cbs_stop...),
    )

    # --------------------------------------------------------------------------------------------------
    # step 3: transcription of the solution, from descent to ocp
    ocp_sol = descent2ocp_solution(descent_sol, ocp, grid, penalty_constraint)

    # --------------------------------------------------------------------------------------------------
    # step 4: print convergence result
    display ? print_convergence(ocp_sol) : nothing

    return ocp_sol

end

"""
	solve_by_descent(ocp::RegularOCPFinalCondition, args...; kwargs...)

TBW
"""
solve_by_descent(ocp::RegularOCPFinalCondition, args...; kwargs...) = solve_by_descent(convert(ocp, RegularOCPFinalConstraint), args...; kwargs...)

# --------------------------------------------------------------------------------------------------
# 
# some texts related to results...
textsStopping = Dict(:optimality => "optimality necessary conditions reached up to numerical tolerances", :stagnation => "the step length became too small", :iterations => "maximal number of iterations reached")

# final print after resolution
"""
	print_convergence(ocp_sol::DescentOCPSol)

TBW
"""
function print_convergence(ocp_sol::DescentOCPSol)
    println("")
    println("Descent solver result:")
    println("   iterations: ", ocp_sol.iterations)
    println("   stopping: ", ocp_sol.message)
    println("   success: ", ocp_sol.success)
end

# --------------------------------------------------------------------------------------------------
# step 1: transcription of the initialization

function __check_grid_validity(ocp::RegularOCPFinalConstraint, T::Times)
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

# default values
__grid_size() = 201
function __grid(ocp::RegularOCPFinalConstraint, N::Integer=__grid_size()) 
    t0 = ocp.initial_time
    tf = ocp.final_time
    return range(t0, tf, N)
end
function __init(ocp::RegularOCPFinalConstraint, N::Integer=__grid_size())
    m = ocp.control_dimension
    return [zeros(m) for i in 1:N-1]
end

#
function my_interpolation(interp::Function, T::Times, U::Controls, T_::Times)
    u_lin = interp(T, U)
    return u_lin.(T_)
end

# init=nothing, grid=nothing => init=default, grid=range(t0, tf, N), with N=__grid_size()
function ocp2descent_init(ocp::RegularOCPFinalConstraint, init::Nothing, grid::Nothing, args...)
    return DescentInit(__init(ocp)), __grid(ocp)
end

# init=nothing, grid=T => init=zeros(m, N-1), grid=T, with N=length(T) (check validity)
function ocp2descent_init(ocp::RegularOCPFinalConstraint, init::Nothing, grid::Times, args...)
    if !__check_grid_validity(ocp, grid)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    return DescentInit(__init(ocp, length(grid))), grid
end

# init=U, grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size()
function ocp2descent_init(ocp::RegularOCPFinalConstraint, U::Controls, grid::Nothing, interp::Function)
    T  = __grid(ocp, length(U)+1)
    T_ = __grid(ocp)
    U_ = my_interpolation(interp, T[1:end-1], U, T_)
    return DescentInit(U_[1:end-1]), T_
end

# init=U, grid=T => init=U, grid=T (check validity with ocp and with init)
function ocp2descent_init(ocp::RegularOCPFinalConstraint, init::Controls, grid::Times, args...)
    if !__check_grid_validity(ocp, grid)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    if !__check_grid_validity(init, grid)
        throw(InconsistentArgument("grid argument is inconsistent with init argument"))
    end
    return DescentInit(init), grid
end

# init=(T,U), grid=nothing => init=U, grid=range(t0, tf, N), with N=__grid_size() (check validity with ocp and with U)
function ocp2descent_init(ocp::RegularOCPFinalConstraint, init::Tuple{Times,Controls}, grid::Nothing, interp::Function)
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
    return DescentInit(U_[1:end-1]), T_
end

# init=(T1,U), grid=T2 => init=U, grid=T2 (check validity with ocp (T1, T2) and with U (T1))
function ocp2descent_init(ocp::RegularOCPFinalConstraint, init::Tuple{Times,Controls}, grid::Times, interp::Function)
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
    return DescentInit(U_[1:end-1]), T2
end

# init=S, grid=nothing => init=S.U, grid=range(t0, tf, N), with N=__grid_size()
function ocp2descent_init(ocp::RegularOCPFinalConstraint, S::DescentOCPSol, grid::Nothing, interp::Function)
    T_ = __grid(ocp) # default grid
    U_ = my_interpolation(interp, S.T[1:end-1], S.U, T_)
    return DescentInit(U_[1:end-1]), T_
end

# init=S, grid=T => init=S.U, grid=T (check validity with ocp)
function ocp2descent_init(ocp::RegularOCPFinalConstraint, S::DescentOCPSol, T::Times, interp::Function)
    if !__check_grid_validity(ocp, T)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    U_ = my_interpolation(interp, S.T[1:end-1], S.U, T)
    return DescentInit(U_[1:end-1]), T
end

# init=u, grid=nothing => init=u(T), grid=T=range(t0, tf, N), with N=__grid_size()
function ocp2descent_init(ocp::RegularOCPFinalConstraint, u::Function, grid::Nothing, args...)
    T = __grid(ocp) # default grid
    U = u.(T)
    return DescentInit(U[1:end-1]), T
end

# init=u, grid=T => init=u(T), grid=T (check validity with ocp)
function ocp2descent_init(ocp::RegularOCPFinalConstraint, u::Function, T::Times, args...)
    if !__check_grid_validity(ocp, T)
        throw(InconsistentArgument("grid argument is inconsistent with ocp argument"))
    end
    U = u.(T)
    return DescentInit(U[1:end-1]), T
end

# --------------------------------------------------------------------------------------------------
# Utils for the transcription from ocp to descent problem

# forward integration of the state
"""
	model(x0, T, U, f)

TBW
"""
function model(x0, T, U, f)
    xₙ = x0
    X = [xₙ]
    for n in range(1, length(T) - 1)
        xₙ = f(T[n], xₙ, T[n+1], U[n])
        X = vcat(X, [xₙ]) # vcat gives a vector of vector
    end
    return xₙ, X
end

# backward integration of state and costate
"""
	adjoint(xₙ, pₙ, T, U, f)

TBW
"""
function adjoint(xₙ, pₙ, T, U, f)
    X = [xₙ]
    P = [pₙ]
    for n in range(length(T), 2, step=-1)
        xₙ, pₙ = f(T[n], xₙ, pₙ, T[n-1], U[n-1])
        X = vcat([xₙ], X)
        P = vcat([pₙ], P)
    end
    return xₙ, pₙ, X, P
end

# --------------------------------------------------------------------------------------------------
# step 1: transcription of the problem, from ocp to descent
function ocp2descent_problem(ocp::RegularOCPFinalConstraint, grid::Times, penalty_constraint::Number)

    # ocp data
    dy = ocp.dynamics
    co = ocp.Lagrange_cost
    cf = ocp.final_constraint
    x0 = ocp.initial_condition
    desc = ocp.description

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for the final constraints
    αₚ = penalty_constraint

    # state flow
    vf(t, x, u) = isnonautonomous(desc) ? dy(t, x, u) : dy(x, u)
    f = Flow(VectorField(vf), :nonautonomous) # we always give a non autonomous Vector Field

    # augmented state flow
    vfa(t, x, u) = isnonautonomous(desc) ? [dy(t, x[1:end-1], u)[:]; co(t, x[1:end-1], u)] : [dy(x[1:end-1], u)[:]; co(x[1:end-1], u)]
    fa = Flow(VectorField(vfa), :nonautonomous) # we always give a non autonomous Vector Field

    # state-costate flow
    p⁰ = -1.0
    H(t, x, p, u) = isnonautonomous(desc) ? p⁰ * co(t, x, u) + p' * dy(t, x, u) : p⁰ * co(x, u) + p' * dy(x, u)
    fh = Flow(Hamiltonian(H), :nonautonomous) # we always give a non autonomous Hamiltonian

    # to compute the gradient of the function by the adjoint method,
    # we need the partial derivative of the Hamiltonian wrt to the control
    Hu(t, x, p, u) = ∇(u -> H(t, x, p, u), u)

    # discretization grid
    T = grid

    # gradient of the function J
    function ∇J(U::Controls)
        xₙ, _ = model(x0, T, U, f)
        pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
        _, _, X, P = adjoint(xₙ, pₙ, T, U, fh)
        g = [-Hu(T[i], X[i], P[i], U[i]) .* (T[i+1] - T[i]) for i in 1:length(T)-1]
        return g
    end
    # vec2vec permet de passer d'un vecteur de vecteur à simplement un vecteur
    ∇J(x::Vector{<:Number}) = vec2vec(∇J(vec2vec(x, ocp.control_dimension))) # for desent solver

    # function J, that we minimize
    L(t, x, u) = isnonautonomous(desc) ? co(t, x, u) : co(x, u)
    function J(U::Controls)
        # via augmented system
        xₙ, X = model([x0[:]; 0.0], T, U, fa)
        cost = xₙ[end] + 0.5 * αₚ * norm(cf(xₙ[1:end-1]))^2
        return cost
    end
    J(x::Vector{<:Number}) = J(vec2vec(x, ocp.control_dimension)) # for descent solver

    # descent problem
    sdp = DescentProblem(∇J, J)

    return sdp

end

# Print callback during descent solver
"""
	printDescent(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)

TBW
"""
function printDescent(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    if i == 0
        println("\n     Calls  ‖∇f(x)‖         ‖x‖             Stagnation      \n")
    end
    @printf("%10d", i) # Iterations
    @printf("%16.8e", norm(gᵢ)) # ‖∇f(x)‖
    @printf("%16.8e", norm(xᵢ)) # ‖x‖
    @printf("%16.8e", norm(xᵢ) > 1e-14 ? norm(sᵢ * dᵢ) / norm(xᵢ) : norm(sᵢ * dᵢ)) # Stagnation
end

"""
	stop_optimality(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, 
	ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

TBW
"""
function stop_optimality(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

    stop = false
    stopping = nothing
    success = nothing
    message = nothing

    if norm(gᵢ) ≤ max(optimalityTolerance * ng₀, absoluteTolerance) # CN1
        stopping = :optimality
        message = textsStopping[stopping]
        success = true
        stop = true
    end

    return stop, stopping, message, success

end

"""
	stop_stagnation(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, 
	ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

TBW
"""
function stop_stagnation(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

    stop = false
    stopping = nothing
    success = nothing
    message = nothing

    if norm(sᵢ * dᵢ) ≤ max(stagnationTolerance * norm(xᵢ), absoluteTolerance) # step stagnation
        stopping = :stagnation
        message = textsStopping[stopping]
        success = true
        stop = true
    end

    return stop, stopping, message, success

end

"""
	stop_iterations(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, 
	ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

TBW
"""
function stop_iterations(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

    stop = false
    stopping = nothing
    success = nothing
    message = nothing

    if i ≥ iterations # iterations max
        stopping = :iterations
        message = textsStopping[stopping]
        success = false
        stop = true
    end

    return stop, stopping, message, success

end

# --------------------------------------------------------------------------------------------------
# step 2: solver
"""
	descent_solver(sdp::DescentProblem, 
	init::DescentInit; 
	direction::Symbol=__direction(), 
	line_search::Symbol=__line_search(),
	iterations::Integer=__iterations(), 
	step_length::Union{Number, Nothing}=__step_length(),
	absoluteTolerance::Number=__absoluteTolerance(), 
	optimalityTolerance::Number=__optimalityTolerance(), 
	stagnationTolerance::Number=__stagnationTolerance(),
	display::Bool=__display(),
	callbacks::CTCallbacks=__callbacks())

TBW
"""
function descent_solver(
    sdp::DescentProblem,
    init::DescentInit;
    direction::Symbol=__direction(),
    line_search::Symbol=__line_search(),
    iterations::Integer=__iterations(),
    step_length::Union{Number,Nothing}=__step_length(),
    absoluteTolerance::Number=__absoluteTolerance(),
    optimalityTolerance::Number=__optimalityTolerance(),
    stagnationTolerance::Number=__stagnationTolerance(),
    display::Bool=__display(),
    callbacks::CTCallbacks=__callbacks()
)

    # print callbacks
    cbs_print = get_priority_print_callbacks((PrintCallback(printDescent, priority=-1), callbacks...))
    myprint(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ) = [cb(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ) for cb in cbs_print]

    # stop callbacks
    cbs_stop = ()
    cbs_stop = (StopCallback(stop_optimality, priority=0), cbs_stop...)
    cbs_stop = (StopCallback(stop_stagnation, priority=0), cbs_stop...)
    cbs_stop = (StopCallback(stop_iterations, priority=0), cbs_stop...)
    cbs_stop = get_priority_stop_callbacks((cbs_stop..., callbacks...))
    function mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)
        stop = false; stopping = nothing; success = nothing; message = nothing
        for cb in cbs_stop
            if !stop
                stop, stopping, message, success = cb(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)
            end
        end
        return stop, stopping, message, success
    end

    # update step_length according to line_search method if step_length has default value
    step_length = __step_length(line_search, step_length)

    # test if the chosen method are correct
    if line_search ∉ (:backtracking, :fixedstep, :bissection)
        throw(IncorrectMethod(line_search))
    end
    if direction ∉ (:gradient, :bfgs)
        throw(IncorrectMethod(direction))
    end

    # general descent solver data
    ∇f = sdp.∇f
    f = sdp.f
    xᵢ = init.x
    s₀ = step_length
    sᵢ = s₀
    fᵢ = f(xᵢ)

    # for BFGS and steepest descent (ie gradient method)
    n = length(xᵢ)
    Iₙ = Matrix{Float64}(I, n, n)
    Hᵢ = Iₙ
    gᵢ = ∇f(xᵢ)
    ng₀ = norm(gᵢ)
    dᵢ = -Hᵢ * gᵢ

    # init print
    i = 0
    display ? (myprint(i, 0.0, dᵢ, xᵢ, gᵢ, fᵢ), println()) : nothing
    
    # stopping criteria
    stop = false; stopping = nothing; success = nothing; message = nothing
    stop, stopping, message, success = mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)
    if !stop
        i += 1
    end

    #
    while !stop

        # step length computation
        if line_search == :backtracking
            sᵢ = backtracking(xᵢ, dᵢ, gᵢ, f, s₀)
        elseif line_search == :fixedstep
            sᵢ = s₀
        elseif line_search == :bissection
            sᵢ = bissection(xᵢ, dᵢ, gᵢ, f, ∇f, s₀)
            #else # plus tard, on pourra peut-être changer de line search en cours d'algo
            #     # donc je laisse ceci malgré le test déjà fait. Idem pour la direction.
            #    throw(IncorrectMethod(line_search))
        end

        # iterate update 
        xᵢ = xᵢ + sᵢ * dᵢ # xᵢ₊₁

        # new gradient
        gᵢ₊₁ = ∇f(xᵢ) # ∇f(xᵢ₊₁)

        # direction computation
        if direction == :bfgs
            dᵢ, Hᵢ = BFGS(sᵢ, dᵢ, gᵢ, gᵢ₊₁, Hᵢ, Iₙ)
            # todo: trouver un exemple qui rentre dans le if
            #if dᵢ'*gᵢ₊₁ > 0 # this is not a descent direction
            #    Hᵢ = Iₙ #/ norm(gᵢ₊₁)
            #    dᵢ = -Hᵢ*gᵢ₊₁
            #end
        elseif direction == :gradient
            dᵢ = -gᵢ₊₁
            #else
            #    throw(IncorrectMethod(direction))
        end

        # update of the current gradient
        gᵢ = gᵢ₊₁  # ∇f(xᵢ₊₁)
        fᵢ = f(xᵢ) # f(xᵢ₊₁)

        # print
        display ? (myprint(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ), println()) : nothing

        # stopping criteria
        stop, stopping, message, success = mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)
        if !stop
            i += 1
        end

    end

    return DescentSol(xᵢ, stopping, message, success, i)

end

# todo: improve memory consumption by updating inputs - add !, ie BFGS!
"""
	BFGS(sᵢ, dᵢ, gᵢ, gᵢ₊₁, Hᵢ, Iₙ)

TBW
"""
function BFGS(sᵢ, dᵢ, gᵢ, gᵢ₊₁, Hᵢ, Iₙ)
    #
    yᵢ = gᵢ₊₁ - gᵢ  # ∇f(xᵢ₊₁) - ∇f(xᵢ)
    nᵢ = dᵢ' * yᵢ
    Aᵢ = dᵢ * yᵢ'
    Hᵢ₊₁ = (Iₙ - Aᵢ / nᵢ) * Hᵢ * (Iₙ - Aᵢ' / nᵢ) + sᵢ * dᵢ * dᵢ' / nᵢ # Hᵢ₊₁ - BFGS update - approx of the inverse of ∇²f(xᵢ₊₁)
    dᵢ₊₁ = -Hᵢ₊₁ * gᵢ₊₁ # new direction
    #
    return dᵢ₊₁, Hᵢ₊₁
end

"""
	backtracking(x, d, g, f, s₀)

TBW
"""
function backtracking(x, d, g, f, s₀)

    # parameters
    ρ = 0.5
    c₁ = 1e-4
    smin = 1e-8
    iₘₐₓ = 20

    #
    φ(s) = f(x + s * d)
    dTg = d' * g
    wolfe1(s) = f(x) + c₁ * s * dTg
    s = s₀
    k = 1
    while φ(s) > wolfe1(s) && s > smin && k < iₘₐₓ  # Weak first Wolfe condition
        s = ρ * s
        k = k + 1
    end

    #if s ≤ smin
    #    s = s₀
    #end

    return s
end

"""
	bissection(x, d, g, f, ∇f, s₀)

TBW
"""
function bissection(x, d, g, f, ∇f, s₀)

    # parameters
    ρ = 0.5
    c₁ = 1e-4
    c₂ = 0.9
    smin = 1e-8
    α = 0
    β = Inf
    iₘₐₓ = 20

    #
    φ(s) = f(x + s * d)
    dTg = d' * g
    wolfe1(s) = f(x) + c₁ * s * dTg
    ∂φ(s) = d' * ∇f(x + s * d)
    wolfe20 = c₂ * d' * g #c₂*∂φ(0)
    s = s₀
    k = 1
    stop = false
    while !stop && s > smin && k < iₘₐₓ

        if φ(s) > wolfe1(s) # Weak first Wolfe condition not satisfied
            β = s
            s = ρ * (α + β)
        elseif ∂φ(s) < wolfe20 # second Wolfe condition not satisfied
            α = s
            β == Inf ? s = α / ρ : s = ρ * (α + β)
        else # first and second ok
            stop = true
        end
        k = k + 1

    end

    #if s ≤ smin
    #    s = s₀
    #end

    return s

end

# --------------------------------------------------------------------------------------------------
# step 3: transcription of the solution, from descent to ocp
"""
	descent2ocp_solution(sd_sol::DescentSol, ocp::RegularOCPFinalConstraint, grid_size::Integer, penalty_constraint::Number)

TBW
"""
function descent2ocp_solution(sd_sol::DescentSol, ocp::RegularOCPFinalConstraint, grid::Times, penalty_constraint::Number)

    # ocp data
    dy = ocp.dynamics
    co = ocp.Lagrange_cost
    cf = ocp.final_constraint
    x0 = ocp.initial_condition
    desc = ocp.description

    # control solution
    U⁺ = vec2vec(sd_sol.x, ocp.control_dimension)

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for final constraints
    αₚ = penalty_constraint

    # flow for state
    vf(t, x, u) = isnonautonomous(desc) ? dy(t, x, u) : dy(x, u)
    f = Flow(VectorField(vf), :nonautonomous) # we always give a non autonomous Vector Field

    # flow for state-adjoint
    p⁰ = -1.0
    H(t, x, p, u) = isnonautonomous(desc) ? p⁰ * co(t, x, u) + p' * dy(t, x, u) : p⁰ * co(x, u) + p' * dy(x, u)
    fh = Flow(Hamiltonian(H), :nonautonomous) # we always give a non autonomous Hamiltonian

    # get state and adjoint
    T = grid
    xₙ, _ = model(x0, T, U⁺, f)
    pₙ = p⁰ * αₚ * transpose(Jcf(xₙ)) * cf(xₙ)
    _, _, X⁺, P⁺ = adjoint(xₙ, pₙ, T, U⁺, fh)

    return DescentOCPSol(T, X⁺, U⁺, P⁺, ocp.state_dimension, ocp.control_dimension, sd_sol.stopping, sd_sol.message, sd_sol.success, sd_sol.iterations)

end

# --------------------------------------------------------------------------------------------------
# Plot solution
# print("x", '\u2080'+9) : x₉ 
#

# General plot
"""
	Plots.plot(ocp_sol::DescentOCPSol, args...; 
	state_style=(), 
	control_style=(), 
	adjoint_style=(), kwargs...)

TBW
"""
function Plots.plot(ocp_sol::DescentOCPSol, args...; state_style=(), control_style=(), adjoint_style=(), kwargs...)

    # todo : gérer le cas dans les labels où m, n > 9

    n = ocp_sol.state_dimension
    m = ocp_sol.control_dimension

    px = Plots.plot(; xlabel="time", title="state", state_style...)
    if n == 1
        Plots.plot!(px, ocp_sol, :time, (:state, i); label="x", state_style...)
    else
        for i in range(1, n)
            Plots.plot!(px, ocp_sol, :time, (:state, i); label="x" * ('\u2080' + i), state_style...)
        end
    end

    pu = Plots.plot(; xlabel="time", title="control", control_style...)
    if m == 1
        Plots.plot!(pu, ocp_sol, :time, (:control, 1); label="u", control_style...)
    else
        for i in range(1, m)
            Plots.plot!(pu, ocp_sol, :time, (:control, i); label="u" * ('\u2080' + i), control_style...)
        end
    end

    pp = Plots.plot(; xlabel="time", title="adjoint", adjoint_style...)
    if n == 1
        Plots.plot!(pp, ocp_sol, :time, (:adjoint, i); label="p", adjoint_style...)
    else
        for i in range(1, n)
            Plots.plot!(pp, ocp_sol, :time, (:adjoint, i); label="p" * ('\u2080' + i), adjoint_style...)
        end
    end

    ps = Plots.plot(px, pu, pp, args..., layout=(1, 3); kwargs...)

    return ps

end

# specific plot
"""
	Plots.plot(ocp_sol::DescentOCPSol, 
	xx::Union{Symbol, Tuple{Symbol, Integer}}, 
	yy::Union{Symbol, Tuple{Symbol, Integer}}, args...; kwargs...)

TBW
"""
function Plots.plot(ocp_sol::DescentOCPSol, xx::Union{Symbol,Tuple{Symbol,Integer}}, yy::Union{Symbol,Tuple{Symbol,Integer}}, args...; kwargs...)

    x = get(ocp_sol, xx)
    y = get(ocp_sol, yy)

    return Plots.plot(x, y, args...; kwargs...)

end

"""
	Plots.plot!(p::Plots.Plot{<:Plots.AbstractBackend}, ocp_sol::DescentOCPSol, 
	xx::Union{Symbol, Tuple{Symbol, Integer}}, 
	yy::Union{Symbol, Tuple{Symbol, Integer}}, args...; kwargs...)

TBW
"""
function Plots.plot!(p::Plots.Plot{<:Plots.AbstractBackend}, ocp_sol::DescentOCPSol, xx::Union{Symbol,Tuple{Symbol,Integer}}, yy::Union{Symbol,Tuple{Symbol,Integer}}, args...; kwargs...)

    x = get(ocp_sol, xx)
    y = get(ocp_sol, yy)

    Plots.plot!(p, x, y, args...; kwargs...)

end
#plot!(p, x, y, args...; kwargs...) = Plots.plot!(p, x, y, args...; kwargs...)

"""
	get(ocp_sol::DescentOCPSol, xx::Union{Symbol, Tuple{Symbol, Integer}})

TBW
"""
function get(ocp_sol::DescentOCPSol, xx::Union{Symbol,Tuple{Symbol,Integer}})

    T = ocp_sol.T
    X = ocp_sol.X
    U = ocp_sol.U
    P = ocp_sol.P

    m = length(T)

    if typeof(xx) == Symbol
        vv = xx
        if vv == :time
            x = T
        elseif vv == :state
            x = [X[i][1] for i in 1:m]
        elseif vv == :adjoint || vv == :costate
            x = [P[i][1] for i in 1:m]
        else
            x = vcat([U[i][1] for i in 1:m-1], U[m-1][1])
        end
    else
        vv = xx[1]
        ii = xx[2]
        if vv == :time
            x = T
        elseif vv == :state
            x = [X[i][ii] for i in 1:m]
        elseif vv == :adjoint || vv == :costate
            x = [P[i][ii] for i in 1:m]
        else
            x = vcat([U[i][ii] for i in 1:m-1], U[m-1][ii])
        end
    end

    return x

end
