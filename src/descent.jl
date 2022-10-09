# --------------------------------------------------------------------------------------------------
# Definition of a general descent problem
mutable struct DescentProblem
    ∇f::Function
    f::Function
end

# --------------------------------------------------------------------------------------------------
# Definition of an initialization for the descent method
mutable struct DescentOCPInit <: OptimalControlInit
    U::Controls
end

mutable struct DescentInit
    x::Union{Vector{<:Number}, Controls}
    function DescentInit(U::Controls)
        new(vec2vec(U))
    end
end

# --------------------------------------------------------------------------------------------------
# Definition of a solution for the descent method
mutable struct DescentOCPSol <: OptimalControlSolution
    T::Times
    X::States
    U::Controls
    P::Adjoints
    state_dimension   :: Dimension
    control_dimension :: Dimension
end

mutable struct DescentSol
    x::Union{Vector{<:Number}, Controls}
end

# --------------------------------------------------------------------------------------------------
# Default options
__grid_size() = 200
__penalty_constraint() = 1e2
__iterations() = 100
__step_length() = nothing
function __step_length(step_search::Symbol, step_length::Union{Number, Nothing})
    if step_length == __step_length() && step_search==:fixedstep
        return 1e-1
    elseif step_length == __step_length() && step_search==:backtracking
        return 1e0
    else
        return step_length
    end
end

# --------------------------------------------------------------------------------------------------
# Solver of an ocp by descent method
function solve_by_descent(ocp::SimpleRegularOCP, method::Description; 
    init::Union{Nothing, Controls, DescentOCPInit, DescentOCPSol}=nothing, 
    grid_size::Integer=__grid_size(), 
    penalty_constraint::Number=__penalty_constraint(), 
    iterations::Integer=__iterations(), 
    step_length::Union{Number, Nothing}=__step_length())

    # print chosen method
    println("Method = ", method)

    # we suppose the description of the method is complete
    direction, step_search = read(method)

    # get default options depending on the method
    step_length = __step_length(step_search, step_length)

    # step 1: transcription from ocp to sd problem and init
    descent_init    = ocp2descent_init(init, grid_size, ocp.control_dimension)
    descent_problem = ocp2descent_problem(ocp, grid_size, penalty_constraint)

    # step 2: resolution of the problem
    descent_sol = descent_solver(descent_problem, descent_init, direction, step_search,
        iterations, step_length)

    # step 3: transcription of the solution
    ocp_sol = descent2ocp_solution(descent_sol, ocp, grid_size, penalty_constraint)

    return ocp_sol

end

function read(method::Description)
    #
    direction = nothing
    direction = :gradient ∈ method ? :gradient : direction
    direction = :bfgs ∈ method ? :bfgs : direction
    #
    step_search = nothing
    step_search = :fixedstep ∈ method ? :fixedstep : step_search
    step_search = :backtracking ∈ method ? :backtracking : step_search
    #
    return direction, step_search
end

# --------------------------------------------------------------------------------------------------
# step 1: transcription of the initialization
ocp2descent_init(init::Nothing,  grid_size::Integer, control_dimension::Dimension) = 
    DescentInit([ zeros(control_dimension) for i in 1:grid_size-1])
ocp2descent_init(init::Controls, args...) = DescentInit(init)
ocp2descent_init(init::DescentOCPInit, args...) = DescentInit(init.U)
ocp2descent_init(init::DescentOCPSol,  args...) = DescentInit(init.U)

# --------------------------------------------------------------------------------------------------
# Utils for the transcription from ocp to sd
function model(x0, T, U, f)
    xₙ = x0
    X = [xₙ]
    for n ∈ range(1, length(T)-1)
        xₙ = f(T[n], xₙ, T[n+1], U[n]); X = vcat(X, [xₙ]) # vcat gives a vector of vector
    end
    return xₙ, X
end

function adjoint(xₙ, pₙ, T, U, f)
    X = [xₙ]; P = [pₙ]
    for n ∈ range(length(T), 2, step=-1)
        xₙ, pₙ = f(T[n], xₙ, pₙ, T[n-1], U[n-1]); X = vcat([xₙ], X); P = vcat([pₙ], P)
    end
    return xₙ, pₙ, X, P
end

# --------------------------------------------------------------------------------------------------
function ocp2descent_problem(ocp::SimpleRegularOCP, grid_size::Integer, penalty_constraint::Number)

    # ocp data
    dy = ocp.dynamics
    co = ocp.Lagrange_cost
    cf = ocp.final_constraint
    t0 = ocp.initial_time
    x0 = ocp.initial_condition
    tf = ocp.final_time
    desc = ocp.description

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for final condition
    αₚ = penalty_constraint

    # flows
    vf(t, x, u) = isnonautonomous(desc) ? dy(t, x, u) : dy(x, u)
    f  = Flow(VectorField(vf), :nonautonomous); # we always give a non autonomous Vector Field

    p⁰ = -1.0;
    H(t, x, p, u) = isnonautonomous(desc) ? p⁰*co(t, x, u) + p'*dy(t, x, u) : p⁰*co(x, u) + p'*dy(x, u)
    fh = Flow(Hamiltonian(H), :nonautonomous); # we always give a non autonomous Hamiltonian

    # for the adjoint method
    Hu(t, x, p, u) = ∇(u -> H(t, x, p, u), u)

    # discretization grid
    T = range(t0, tf, grid_size)

    # gradient function
    function ∇J(U::Controls)
        xₙ, _ = model(x0, T, U, f)
        pₙ = p⁰*αₚ*transpose(Jcf(xₙ))*cf(xₙ)
        _, _, X, P = adjoint(xₙ, pₙ, T, U, fh)
        g = [ -Hu(T[i], X[i], P[i], U[i]).*(T[i+1]-T[i]) for i=1:length(T)-1 ]
        return g
    end
    ∇J(x::Vector{<:Number}) = vec2vec(∇J(vec2vec(x, ocp.control_dimension)))

    L(t, x, u) = isnonautonomous(desc) ? co(t, x, u) : co(x, u)
    function J(U::Controls)
        xₙ, X = model(x0, T, U, f)
        y = 0.0
        for i ∈ range(1, length(U))
            y = y + L(T[i], X[i], U[i])*(T[i+1]-T[i])
        end
        y = y + 0.5*αₚ*norm(cf(xₙ))^2
        return y
    end
    J(x::Vector{<:Number}) = J(vec2vec(x, ocp.control_dimension))

    # descent problem
    # vec2vec permet de passer d'un vecteur de vecteur à simplement un vecteur
    sdp = DescentProblem(∇J, J)

    return sdp

end

# --------------------------------------------------------------------------------------------------
function descent_solver(sdp::DescentProblem, init::DescentInit, 
    direction::Symbol, step_search::Symbol,
    iterations::Integer, step_length::Number)

    # general descent solver data
    ∇f = sdp.∇f
    f  = sdp.f
    xᵢ = init.x
    s₀ = step_length

    # for BFGS and steepest descent (ie gradient method)
    n  = length(xᵢ)
    Iₙ = Matrix{Float64}(I, n, n)
    Hᵢ = Iₙ
    gᵢ = ∇f(xᵢ); 
    dᵢ = -Hᵢ*gᵢ

    # init print
    println("\n     Calls  ‖∇f(x)‖         ‖x‖             Stagnation      \n")

    #
    for i ∈ range(1, iterations)
        # step length computation - inputs: xᵢ, dᵢ, gᵢ, f - outputs: sᵢ
        if step_search == :backtracking
            sᵢ = backtracking(xᵢ, dᵢ, gᵢ, f, s₀)
        elseif step_search == :fixedstep
            sᵢ = s₀
        else
            error("No such step search method.")
        end

        # iterate update 
        xᵢ = xᵢ + sᵢ*dᵢ  # xᵢ₊₁

        # new gradient
        gᵢ₊₁ = ∇f(xᵢ)      # ∇f(xᵢ₊₁)

        # direction computation - inputs: sᵢ, dᵢ, gᵢ, gᵢ₊₁, Hᵢ - outputs: dᵢ₊₁, Hᵢ₊₁
        if direction == :bfgs
            dᵢ, Hᵢ = BFGS(sᵢ, dᵢ, gᵢ, gᵢ₊₁, Hᵢ, Iₙ)
        elseif direction == :gradient
            dᵢ = -gᵢ₊₁
        else
            error("No such direction method.")
        end

        # update of the current gradient
        gᵢ = gᵢ₊₁          # ∇f(xᵢ₊₁)

        # print
        @printf("%10d", i) # Iterations or calls
        @printf("%16.8e", norm(gᵢ)) # ‖∇f(x)‖
        @printf("%16.8e", norm(xᵢ)) # ‖x‖
        @printf("%16.8e", norm(sᵢ*dᵢ)/norm(xᵢ)) # Stagnation
        println()

    end
    return DescentSol(xᵢ)
end

# todo: improve memory consumption by updating inputs - add !, ie BFGS!
function BFGS(sᵢ, dᵢ, gᵢ, gᵢ₊₁, Hᵢ, Iₙ)
    #
    yᵢ = gᵢ₊₁ - gᵢ  # ∇f(xᵢ₊₁) - ∇f(xᵢ)
    nᵢ = dᵢ'*yᵢ
    Aᵢ = dᵢ*yᵢ'
    Hᵢ₊₁ = (Iₙ-Aᵢ/nᵢ)*Hᵢ*(Iₙ-Aᵢ'/nᵢ)+sᵢ*dᵢ*dᵢ'/nᵢ # Hᵢ₊₁ - BFGS update - approx of the inverse of ∇²f(xᵢ₊₁)
    dᵢ₊₁ = -Hᵢ₊₁*gᵢ₊₁        # new direction
    #
    return dᵢ₊₁, Hᵢ₊₁
end

function backtracking(x, d, g, f, s₀)

    # parameters
    ρ  = 0.5 # for backtraking
    c₁ = 1e-4
    smin = 1e-8

    #
    φ(s) = f(x+s*d); dTg = d'*g; wolfe1(s) = f(x)+c₁*s*dTg
    s = s₀
    k = 1
    while φ(s)>wolfe1(s) && s>smin && k<10  # Weak first Wolfe condition
        s = ρ*s
        k = k+1
    end

    return s
end

function descent2ocp_solution(sd_sol::DescentSol, ocp::SimpleRegularOCP, grid_size::Integer, penalty_constraint::Number)

    # ocp data
    dy = ocp.dynamics
    co = ocp.Lagrange_cost
    cf = ocp.final_constraint
    t0 = ocp.initial_time
    x0 = ocp.initial_condition
    tf = ocp.final_time
    desc = ocp.description
    
    # control solution
    U⁺ = vec2vec(sd_sol.x, ocp.control_dimension)

    # Jacobian of the constraints
    Jcf(x) = Jac(cf, x)

    # penalty term for final condition
    αₚ = penalty_constraint

    # flow for state
    vf(t, x, u) = isnonautonomous(desc) ? dy(t, x, u) : dy(x, u)
    f  = Flow(VectorField(vf), :nonautonomous); # we always give a non autonomous Vector Field

    # flow for adjoint
    p⁰ = -1.0;
    H(t, x, p, u) = isnonautonomous(desc) ? p⁰*co(t, x, u) + p'*dy(t, x, u) : p⁰*co(x, u) + p'*dy(x, u)
    fh = Flow(Hamiltonian(H), :nonautonomous); # we always give a non autonomous Hamiltonian

    # get state and adjoint
    T = range(t0, tf, grid_size)
    xₙ, _ = model(x0, T, U⁺, f)
    pₙ = p⁰*αₚ*transpose(Jcf(xₙ))*cf(xₙ)
    _, _, X⁺, P⁺ = adjoint(xₙ, pₙ, T, U⁺, fh)

    return DescentOCPSol(T, X⁺, U⁺, P⁺, ocp.state_dimension, ocp.control_dimension)

end

# --------------------------------------------------------------------------------------------------
# Plot solution
# print("x", '\u2080'+9) : x₉ 
#
function Plots.plot(ocp_sol::DescentOCPSol, args...; 
    state_style=(), 
    control_style=(), 
    adjoint_style=(), kwargs...)

    # todo : gérer le cas dans les labels où m, n > 9

    n = ocp_sol.state_dimension
    m = ocp_sol.control_dimension

    px = Plots.plot(; xlabel="time", title="state", state_style...)
    if n==1
        Plots.plot!(px, ocp_sol, :time, (:state, i); label="x", state_style...)
    else
        for i ∈ range(1, n)
            Plots.plot!(px, ocp_sol, :time, (:state, i); label="x"*('\u2080'+i), state_style...)
        end
    end

    pu = Plots.plot(; xlabel="time", title="control", control_style...)
    if m==1
        Plots.plot!(pu, ocp_sol, :time, (:control, 1); label="u", control_style...)
    else
        for i ∈ range(1, m)
            Plots.plot!(pu, ocp_sol, :time, (:control, i); label="u"*('\u2080'+i), control_style...)
        end
    end

    pp = Plots.plot(; xlabel="time", title="adjoint", adjoint_style...)
    if n==1
        Plots.plot!(pp, ocp_sol, :time, (:adjoint, i); label="p", adjoint_style...)
    else
        for i ∈ range(1, n)
            Plots.plot!(pp, ocp_sol, :time, (:adjoint, i); label="p"*('\u2080'+i), adjoint_style...)
        end
    end

    ps = Plots.plot(px, pu, pp, args..., layout=(1,3); kwargs...)

    return ps

end

function Plots.plot(ocp_sol::DescentOCPSol, 
    xx::Union{Symbol, Tuple{Symbol, Integer}}, 
    yy::Union{Symbol, Tuple{Symbol, Integer}}, args...; kwargs...)

    x = get(ocp_sol, xx)
    y = get(ocp_sol, yy)

    return Plots.plot(x, y, args...; kwargs...)

end

function Plots.plot!(p::Plots.Plot{<:Plots.AbstractBackend}, ocp_sol::DescentOCPSol, 
    xx::Union{Symbol, Tuple{Symbol, Integer}}, 
    yy::Union{Symbol, Tuple{Symbol, Integer}}, args...; kwargs...)

    x = get(ocp_sol, xx)
    y = get(ocp_sol, yy)

    Plots.plot!(p, x, y, args...; kwargs...)

end
#plot!(p, x, y, args...; kwargs...) = Plots.plot!(p, x, y, args...; kwargs...)

function get(ocp_sol::DescentOCPSol, xx::Union{Symbol, Tuple{Symbol, Integer}})

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
            x = [ X[i][1] for i=1:m ]
        elseif vv == :adjoint || vv == :costate
            x = [ P[i][1] for i=1:m ]
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
        elseif vv == :adjoint || vv == :costate
            x = [ P[i][ii] for i=1:m ]
        else
            x = vcat([ U[i][ii] for i=1:m-1 ], U[m-1][ii])
        end
    end

    return x

end
