#--------------------------------------------------------------------------------------------------
# Solver of an prob by unconstrained direct simple shooting
function solve_by_udss(
    prob::UncFreeXfProblem,
    method::Description;
    init::Union{Nothing,Controls,Tuple{TimesDisc,Controls},Function,UncFreeXfSolution}=nothing,
    grid::Union{Nothing,TimesDisc}=nothing,
    penalty_constraint::Real=__penalty_constraint(),
    display::Bool=__display(),
    callbacks::ControlToolboxCallbacks=__callbacks(),
    init_interpolation::Function=__init_interpolation(),
    kwargs...
)

    # --------------------------------------------------------------------------------------------------
    # print chosen method
    display ? println("\nMethod = ", method) : nothing

    # --------------------------------------------------------------------------------------------------
    # transcription from optimal control to CTOptimization problem and init
    opti_init, grid = make_udss_init(prob, init, grid, init_interpolation)
    opti_prob = make_udss_problem(prob, grid, penalty_constraint)

    # --------------------------------------------------------------------------------------------------
    # resolution of the problem
    #
    # callbacks
    cbs_print = get_priority_print_callbacks((PrintCallback(printOCPDescent, priority=0), callbacks...))
    cbs_stop = get_priority_stop_callbacks(callbacks)
    #
    opti_sol = CTOptimization.solve(
        opti_prob,
        clean_description(method),
        init=opti_init,
        iterations=__iterations(),
        absoluteTolerance=__absoluteTolerance(),
        optimalityTolerance=__optimalityTolerance(),
        stagnationTolerance=__stagnationTolerance(),
        display=display,
        callbacks=(cbs_print..., cbs_stop...);
        kwargs...
    )

    # --------------------------------------------------------------------------------------------------
    # transcription of the solution, from descent to prob
    sol = make_udss_solution(opti_sol, prob, grid, penalty_constraint)

    # --------------------------------------------------------------------------------------------------
    # print convergence result ?

    return sol

end

function solve_by_udss(prob::UncFixedXfProblem, args...; 
    init::Union{Nothing,Controls,Tuple{TimesDisc,Controls},Function,UncFixedXfSolution}=nothing, 
    kwargs...)
    new_prob = convert(prob, UncFreeXfProblem)
    if typeof(init) == UncFixedXfSolution
        new_init = convert(init, UncFreeXfSolution)
    else
        new_init = init
    end
    sol = solve_by_udss(new_prob, args...; init=new_init, kwargs...)
    new_sol = convert(sol, UncFixedXfSolution)
    return new_sol
end

function solve_by_udss(prob::AbstractOptimalControlProblem, args...; kwargs...)
    throw(InconsistentArgument("this problem can not be solved by direct simple shooting."))
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