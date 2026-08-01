# ============================================================================
# CTSolvers Reexports Tests
# ============================================================================
# The strategy/option layer this file used to cover left CTSolvers for CTBase
# in v2.1.0-beta — `AbstractStrategy`, `StrategyRegistry`, `describe`,
# `route_to`, `bypass`, `CPU`/`GPU`, … all moved. Those assertions now live in
# test_ctbase.jl.
#
# What is left here is CTSolvers' own: the DOCP layer (`AbstractDiscretizer`
# included — CTDirect only *implements* it now), modelers, solvers and
# integrators.

module TestCtsolvers

using Test: Test
using CTSolvers: CTSolvers
using OptimalControl # using is mandatory since we test exported symbols
using SolverCore: SolverCore # needed for ocp_solution signature check

include(joinpath(@__DIR__, "..", "..", "helpers", "reexport.jl"))
using .ReexportUtils: reexports, imports, is_exported

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtsolvers

function test_ctsolvers()
    Test.@testset "CTSolvers reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "DOCP Types" begin
            # Imported, not re-exported.
            for T in (:DiscretizedModel, :AbstractDiscretizer)
                Test.@testset "$T" begin
                    Test.@test imports(OptimalControl, T, CTSolvers.DOCP)
                    Test.@test !isdefined(CurrentModule, T)
                end
            end
        end

        Test.@testset "DOCP Functions" begin
            # ⚠️ `discretize` moved from CTDirect to CTSolvers.DOCP. The name
            # did not change, so only an ownership check catches a regression.
            for f in (:discretize, :ocp_model, :nlp_model, :ocp_solution)
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTSolvers.DOCP)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end
        end

        Test.@testset "Modeler Types" begin
            for T in (:AbstractNLPModeler, :ADNLP, :Exa)
                Test.@testset "$T" begin
                    Test.@test imports(OptimalControl, T, CTSolvers.Modelers)
                    Test.@test !isdefined(CurrentModule, T)
                    Test.@test getfield(OptimalControl, T) isa DataType ||
                        getfield(OptimalControl, T) isa UnionAll
                end
            end
        end

        Test.@testset "Solver Types" begin
            for T in (:AbstractNLPSolver, :Ipopt, :MadNLP, :Uno, :MadNCL, :Knitro)
                Test.@testset "$T" begin
                    Test.@test imports(OptimalControl, T, CTSolvers.Solvers)
                    Test.@test !isdefined(CurrentModule, T)
                end
            end
        end

        Test.@testset "Integrators" begin
            for f in (:final_state, :evaluate_at)
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTSolvers.Integrators)
                    Test.@test isdefined(CurrentModule, f)
                end
            end
            for T in (:AbstractIntegrator, :AbstractIntegrationResult, :SciML)
                Test.@testset "$T" begin
                    Test.@test reexports(OptimalControl, T, CTSolvers.Integrators)
                end
            end

            Test.@testset "deliberate omissions" begin
                # ⚠️ `times` must stay CTModels': it returns the `TimesModel`
                # *component*, not the integration grid (that one is
                # `time_grid`). Conflating them was the trap the explicit
                # import list in imports/ctsolvers.jl exists to avoid.
                Test.@test getfield(OptimalControl, :times) !==
                    getfield(CTSolvers.Integrators, :times)

                # `merge` must stay `Base.merge`.
                Test.@test getfield(OptimalControl, :merge) === Base.merge
                Test.@test getfield(OptimalControl, :merge) !==
                    getfield(CTSolvers.Integrators, :merge)
            end

            Test.@testset "shared generics" begin
                # `status` / `successful` are one object each, owned by
                # CTModels.Solutions and extended by CTSolvers.Integrators —
                # so a single import covers both sides.
                for f in (:status, :successful)
                    Test.@test getfield(OptimalControl, f) ===
                        getfield(CTSolvers.Integrators, f)
                end
            end
        end

        Test.@testset "Type Hierarchy" begin
            Test.@testset "Modelers" begin
                Test.@test OptimalControl.ADNLP <: OptimalControl.AbstractNLPModeler
                Test.@test OptimalControl.Exa <: OptimalControl.AbstractNLPModeler
            end
            Test.@testset "Solvers" begin
                for S in (
                    OptimalControl.Ipopt,
                    OptimalControl.MadNLP,
                    OptimalControl.Uno,
                    OptimalControl.MadNCL,
                    OptimalControl.Knitro,
                )
                    Test.@test S <: OptimalControl.AbstractNLPSolver
                end
            end
            Test.@testset "Discretizers" begin
                # CTDirect implements the CTSolvers-owned abstract type.
                Test.@test OptimalControl.Collocation <: OptimalControl.AbstractDiscretizer
            end
        end

        Test.@testset "Method Signatures" begin
            Test.@testset "discretize" begin
                Test.@test hasmethod(
                    discretize,
                    Tuple{OptimalControl.AbstractModel,OptimalControl.AbstractDiscretizer},
                )
            end
            Test.@testset "ocp_model" begin
                Test.@test hasmethod(ocp_model, Tuple{OptimalControl.DiscretizedModel})
            end
            Test.@testset "nlp_model" begin
                Test.@test hasmethod(
                    nlp_model,
                    Tuple{
                        OptimalControl.DiscretizedModel,
                        Any,
                        OptimalControl.AbstractNLPModeler,
                    },
                )
            end
            Test.@testset "ocp_solution" begin
                # ⚠️ takes a `BuiltModel` (the NLP-side object), not the
                # `DiscretizedModel` — the old assertion had it wrong.
                Test.@test hasmethod(
                    ocp_solution,
                    Tuple{
                        CTSolvers.Optimization.BuiltModel,
                        SolverCore.AbstractExecutionStats,
                        OptimalControl.AbstractNLPModeler,
                    },
                )
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctsolvers() = TestCtsolvers.test_ctsolvers()
