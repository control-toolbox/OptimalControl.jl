# --------------------------------------------------------------------------------------------------
# definition of a general descent problem
mutable struct DescentProblem
    f::Function # function to minimize
    ∇f::Function # gradient of the function
end

# --------------------------------------------------------------------------------------------------
# definition of an initialization for the descent method
mutable struct DescentInit
    x::Vector{<:Number} # the optimization variable x of the descent method
    function DescentInit(x::Vector{<:Number})
        new(x)
    end
    function DescentInit(x::Vector{<:Vector{<:Number}})
        new(vec2vec(x))
    end
end

# --------------------------------------------------------------------------------------------------
# definition of a solution for the descent method
mutable struct DescentSol
    x::Vector{<:Number} # the optimization variable solution
    stopping::Symbol # the stopping criterion at the end of the descent method
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

# --------------------------------------------------------------------------------------------------
# 
# some texts related to results...
textsStopping = Dict(
    :optimality => "optimality necessary conditions reached up to numerical tolerances", 
    :stagnation => "the step length became too small", 
    :iterations => "maximal number of iterations reached")

# --------------------------------------------------------------------------------------------------
# defaults values
__line_search() = :bissection
__direction() = :bfgs
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

# --------------------------------------------------------------------------------------------------
# callbacks
#
# print iterations
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

# stopping criteria
"""
	stop_optimality(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, 
	ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

TBW
"""
function stop_optimality(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, optimalityTolerance, absoluteTolerance, stagnationTolerance, iterations)

    stop = false; stopping = nothing; success = nothing; message = nothing
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

    stop = false; stopping = nothing; success = nothing; message = nothing
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

    stop = false; stopping = nothing; success = nothing; message = nothing
    if i ≥ iterations # iterations max
        stopping = :iterations
        message = textsStopping[stopping]
        success = false
        stop = true
    end
    return stop, stopping, message, success

end

# final print after resolution
"""
	print_convergence(ocp_sol::DescentOCPSol)

TBW
"""
function print_convergence(sol::DescentSol)
    println("")
    println("Descent solver result:")
    println("   iterations: ", sol.iterations)
    println("   stopping: ", sol.message)
    println("   success: ", sol.success)
end

# --------------------------------------------------------------------------------------------------
# solver
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
    f  = sdp.f
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

    sol = DescentSol(xᵢ, stopping, message, success, i)

    display ? print_convergence(sol) : nothing

    return sol

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