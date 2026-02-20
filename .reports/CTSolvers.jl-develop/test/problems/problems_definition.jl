# Helper optimization problem and solution-builder types used by benchmark test problems.
# Helper types
abstract type AbstractNLPSolutionBuilder <: CTSolvers.AbstractSolutionBuilder end
struct ADNLPSolutionBuilder <: AbstractNLPSolutionBuilder end
struct ExaSolutionBuilder <: AbstractNLPSolutionBuilder end

#
struct OptimizationProblem <: CTSolvers.AbstractOptimizationProblem
    build_adnlp_model::CTSolvers.ADNLPModelBuilder
    build_exa_model::CTSolvers.ExaModelBuilder
    adnlp_solution_builder::ADNLPSolutionBuilder
    exa_solution_builder::ExaSolutionBuilder
end

function CTSolvers.get_adnlp_model_builder(prob::OptimizationProblem)
    return prob.build_adnlp_model
end

function CTSolvers.get_exa_model_builder(prob::OptimizationProblem)
    return prob.build_exa_model
end

function (builder::ADNLPSolutionBuilder)(nlp_solution::SolverCore.AbstractExecutionStats)
    return nlp_solution
end

function (builder::ExaSolutionBuilder)(nlp_solution::SolverCore.AbstractExecutionStats)
    return nlp_solution
end

function CTSolvers.get_adnlp_solution_builder(prob::OptimizationProblem)
    return prob.adnlp_solution_builder
end

function CTSolvers.get_exa_solution_builder(prob::OptimizationProblem)
    return prob.exa_solution_builder
end

#
struct DummyProblem <: CTSolvers.AbstractOptimizationProblem end
