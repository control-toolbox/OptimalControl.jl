# Rosenbrock benchmark problem definition used by CTSolvers tests.
function rosenbrock_objective(x)
    return (x[1] - 1.0)^2 + 100*(x[2] - x[1]^2)^2
end
function rosenbrock_constraint(x)
    return x[1]
end
function rosenbrock_is_minimize()
    return true
end

function Rosenbrock()
    # define common functions
    F(x) = rosenbrock_objective(x)
    c(x) = rosenbrock_constraint(x)
    lcon = [-Inf]
    ucon = [10.0]
    minimize = rosenbrock_is_minimize()

    # define ADNLPModels builder
    function build_adnlp_model(
        initial_guess::AbstractVector; kwargs...
    )::ADNLPModels.ADNLPModel
        return ADNLPModels.ADNLPModel(
            F, initial_guess, c, lcon, ucon; minimize=minimize, kwargs...
        )
    end

    # define ExaModels builder
    function build_exa_model(
        ::Type{BaseType}, initial_guess::AbstractVector; kwargs...
    )::ExaModels.ExaModel where {BaseType<:AbstractFloat}
        m = ExaModels.ExaCore(BaseType; minimize=minimize, kwargs...)
        x = ExaModels.variable(m, length(initial_guess); start=initial_guess)
        ExaModels.objective(m, F(x))
        ExaModels.constraint(m, c(x); lcon=lcon, ucon=ucon)
        return ExaModels.ExaModel(m)
    end

    prob = OptimizationProblem(
        CTSolvers.ADNLPModelBuilder(build_adnlp_model),
        CTSolvers.ExaModelBuilder(build_exa_model),
        ADNLPSolutionBuilder(),
        ExaSolutionBuilder(),
    )
    init = [-1.2; 1.0]
    sol = [1.0; 1.0]

    return (prob=prob, init=init, sol=sol)
end
