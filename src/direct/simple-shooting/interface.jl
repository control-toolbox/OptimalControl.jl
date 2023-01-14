#    iterations::Integer=__iterations(),
#    step_length::Union{Number,Nothing}=__step_length(),
#    absoluteTolerance::Number=__absoluteTolerance(),
#    optimalityTolerance::Number=__optimalityTolerance(),
#    stagnationTolerance::Number=__stagnationTolerance(),
#    callbacks::CTCallbacks=__callbacks(),

#--------------------------------------------------------------------------------------------------
# Solver of an ocp by unconstrained direct simple shooting
function solve_by_udss(
    prob::UncFreeXfProblem,
    method::Description;
    init::Union{Nothing,Controls,Tuple{Times,Controls},Function,UncFreeXfSolution}=nothing,
    grid::Union{Nothing,Times}=nothing,
    penalty_constraint::Number=__penalty_constraint(),
    display::Bool=__display(),
    callbacks::CTCallbacks=__callbacks(),
    init_interpolation::Function=__init_interpolation(),
    kwargs...
)

    # --------------------------------------------------------------------------------------------------
    # print chosen method
    display ? println("\nMethod = ", method) : nothing

    # --------------------------------------------------------------------------------------------------
    # transcription from ocp to optimisation problem and init
    opti_init, grid = make_udss_init(ocp, init, grid, init_interpolation)
    opti_prob = make_udss_problem(ocp, grid, penalty_constraint)

    # --------------------------------------------------------------------------------------------------
    # resolution of the problem
    #
    # callbacks
    cbs_print = get_priority_print_callbacks((PrintCallback(printOCPDescent, priority=0), callbacks...))
    cbs_stop = get_priority_stop_callbacks(callbacks)
    #
    opti_sol = CommonSolveOptimisation.solve(
        opti_prob,
        init=opti_init,
        iterations=__iterations(),
        absoluteTolerance=__absoluteTolerance(),
        optimalityTolerance=__optimalityTolerance(),
        stagnationTolerance=__stagnationTolerance(),
        display=display,
        callbacks=(cbs_print..., cbs_stop...),
        kwargs...
    )

    # --------------------------------------------------------------------------------------------------
    # transcription of the solution, from descent to ocp
    sol = make_udss_solution(descent_sol, ocp, grid, penalty_constraint)

    # --------------------------------------------------------------------------------------------------
    # print convergence result ?

    return sol

end

function solve_by_udss(ocp::UncFixedXfProblem, args...; kwargs...)
    return convert(solve_by_udss(convert(ocp, UncFreeXfProblem), args...; kwargs...), UncFixedXfSolution)
end

#--------------------------------------------------------------------------------------------------
# print callback for ocp resolution by descent method
function printOCPDescent(i, sᵢ, dᵢ, Uᵢ, gᵢ, fᵢ)
    if i == 0
        println("\n     Calls  ‖∇F(U)‖         ‖U‖             Stagnation      \n")
    end
    @printf("%10d", i) # Iterations
    @printf("%16.8e", norm(gᵢ)) # ‖∇F(U)‖
    @printf("%16.8e", norm(Uᵢ)) # ‖U‖
    @printf("%16.8e", norm(Uᵢ) > 1e-14 ? norm(sᵢ * dᵢ) / norm(Uᵢ) : norm(sᵢ * dᵢ)) # Stagnation
end