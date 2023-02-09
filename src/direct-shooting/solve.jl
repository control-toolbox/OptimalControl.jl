#--------------------------------------------------------------------------------------------------
# Solver of an prob by unconstrained direct simple shooting
function solve(
    ocp::OptimalControlModel,
    algo::DirectShooting,
    method::Description;
    init::Union{Nothing,Controls,Tuple{TimesDisc,Controls},Function,DirectShootingSolution,DirectSolution}=nothing,
    grid::Union{Nothing,TimesDisc}=nothing,
    penalty_constraint::Real=__penalty_constraint(),
    display::Bool=__display(),
    callbacks::ControlToolboxCallbacks=__callbacks(),
    init_interpolation::Function=__init_interpolation(),
    kwargs...
)

    # check if we can solve this kind of problems, that is there must be no constraints
    #
    # parse prob
    # make CTOptimizationInit: Vector{<:Real}
    # make CTOptimizationProblem: CTOptimizationProblem(f; gradient, dimension)
    # resolution with CTOptimization
    # make DirectShootingSolution
    # 
    # struct UnconstrainedSolution <: CTOptimizationSolution
    #    x::Primal
    #    stopping::Symbol
    #    message::String
    #    success::Bool
    #    iterations::Integer
    #end    

    # check validity
    ξ, ψ, ϕ = nlp_constraints(ocp)
    dim_ξ = length(ξ[1])      # dimension of the boundary constraints
    dim_ψ = length(ψ[1])
    if dim_ξ != 0 && dim_ψ != 0
        error("direct shooting is implemented for problems without constraints")
    end

    # Init - need some parsing
    t0 = initial_time(ocp)
    tf = final_time(ocp)
    m  = control_dimension(ocp)
    opti_init, grid = CTOptimizationInit(t0, tf, m, init, grid, init_interpolation)

    # Problem
    nlp = CTOptimizationProblem(ocp, grid, penalty_constraint)

    # Resolution
    # callbacks
    cbs_print = get_priority_print_callbacks((PrintCallback(printOCPDescent, priority=0), callbacks...))
    cbs_stop = get_priority_stop_callbacks(callbacks)
    #
    nlp_sol = CTOptimization.solve(
        nlp,
        method,
        init=opti_init,
        iterations=__iterations(),
        absoluteTolerance=__absoluteTolerance(),
        optimalityTolerance=__optimalityTolerance(),
        stagnationTolerance=__stagnationTolerance(),
        display=display,
        callbacks=(cbs_print..., cbs_stop...);
        kwargs...
    )

    # transcription of the solution, from descent to prob
    sol = DirectShootingSolution(nlp_sol, ocp, grid, penalty_constraint)

    return sol

end

#--------------------------------------------------------------------------------------------------
# print callback for prob resolution by descent method
function printOCPDescent(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)
    if i == 0
        println("\n     Calls  ‖∇F(U)‖         ‖U‖             Stagnation      \n")
    end
    @printf("%10d", i) # Iterations
    @printf("%16.8e", norm(gᵢ)) # ‖∇F(U)‖
    @printf("%16.8e", norm(Uᵢ)) # ‖U‖
    @printf("%16.8e", norm(Uᵢ) > 1e-14 ? norm(sᵢ * dᵢ) / norm(Uᵢ) : norm(sᵢ * dᵢ)) # Stagnation
end