# Elec benchmark problem definition used by CTSolvers tests.
using Random

function elec_objective(x, y, z, i, j)
    1.0 / sqrt((x[i] - x[j])^2 + (y[i] - y[j])^2 + (z[i] - z[j])^2)
end
elec_constraint(x, y, z, i) = x[i]^2 + y[i]^2 + z[i]^2 - 1.0
function elec_objective(x, y, z)
    np = length(x)
    obj = 0.0
    for i in 1:(np - 1)
        for j in (i + 1):np
            obj += elec_objective(x, y, z, i, j)
        end
    end
    return obj
end
function elec_constraint(x, y, z)
    np = length(x)
    return [elec_constraint(x, y, z, i) for i in 1:np]
end
elec_is_minimize() = true

function Elec(; np::Int=5, seed::Int=2713)
    # Set the starting point to a quasi-uniform distribution of electrons on a unit sphere
    Random.seed!(seed)

    # Objective: minimize Coulomb potential
    function F(vars)
        x = vars[1:np]
        y = vars[(np + 1):2np]
        z = vars[(2np + 1):end]
        return elec_objective(x, y, z)
    end

    # Constraints: unit-ball constraint for each electron
    function c(vars)
        x = vars[1:np]
        y = vars[(np + 1):2np]
        z = vars[(2np + 1):end]
        return elec_constraint(x, y, z)
    end

    lcon = zeros(np)
    ucon = zeros(np)
    minimize = elec_is_minimize()

    # Define ADNLPModels builder
    function build_adnlp_model(guess::NamedTuple; kwargs...)::ADNLPModels.ADNLPModel
        # Convert tuple to flat vector for ADNLPModels
        guess_vec = vcat(guess.x, guess.y, guess.z)
        return ADNLPModels.ADNLPModel(
            F, guess_vec, c, lcon, ucon; minimize=minimize, kwargs...
        )
    end

    # Define ExaModels builder
    function build_exa_model(
        ::Type{BaseType}, guess::NamedTuple; kwargs...
    )::ExaModels.ExaModel where {BaseType<:AbstractFloat}
        m = ExaModels.ExaCore(BaseType; minimize=minimize, kwargs...)

        x = ExaModels.variable(m, 1:np; start=guess.x)
        y = ExaModels.variable(m, 1:np; start=guess.y)
        z = ExaModels.variable(m, 1:np; start=guess.z)

        # Coulomb potential objective
        itr = [(i, j) for i in 1:(np - 1) for j in (i + 1):np]
        ExaModels.objective(m, sum(elec_objective(x, y, z, i, j) for (i, j) in itr))

        # Unit-ball constraints
        ExaModels.constraint(m, elec_constraint(x, y, z, i) for i in 1:np)

        return ExaModels.ExaModel(m)
    end

    prob = OptimizationProblem(
        CTSolvers.ADNLPModelBuilder(build_adnlp_model),
        CTSolvers.ExaModelBuilder(build_exa_model),
        ADNLPSolutionBuilder(),
        ExaSolutionBuilder(),
    )

    theta = (2π) .* rand(np)
    phi = π .* rand(np)
    x_init = [cos(theta[i]) * sin(phi[i]) for i in 1:np]
    y_init = [sin(theta[i]) * sin(phi[i]) for i in 1:np]
    z_init = [cos(phi[i]) for i in 1:np]
    init = (x=x_init, y=y_init, z=z_init)

    sol = missing

    return (prob=prob, init=init, sol=sol)
end
