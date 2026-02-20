module TestMadNLPExtension

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Modelers
import CTSolvers.Optimization
import CommonSolve
import CUDA
import NLPModels
import ADNLPModels
import MadNLP
import MadNLPMumps
import ExaModels
import MadNLPGPU

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

# Trigger extension loading
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# CUDA availability check
is_cuda_on() = CUDA.functional()

"""
    test_madnlp_extension()

Tests for Solvers.MadNLP extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete Solvers.MadNLP functionality including metadata, constructor,
options handling, display flag, and problem solving on CPU (and GPU if available).
"""
function test_madnlp_extension()
    Test.@testset "MadNLP Extension" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.MadNLP)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :linear_solver in keys(meta)
            
            # Test termination options are defined
            Test.@test :acceptable_tol in keys(meta)
            Test.@test :acceptable_iter in keys(meta)
            Test.@test :max_wall_time in keys(meta)
            Test.@test :diverging_iterates_tol in keys(meta)

            # Test scaling and structure options
            Test.@test :nlp_scaling in keys(meta)
            Test.@test :nlp_scaling_max_gradient in keys(meta)
            Test.@test :jacobian_constant in keys(meta)
            Test.@test :hessian_constant in keys(meta)

            # Test initialization options
            Test.@test :bound_push in keys(meta)
            Test.@test :bound_fac in keys(meta)
            Test.@test :constr_mult_init_max in keys(meta)
            Test.@test :fixed_variable_treatment in keys(meta)
            Test.@test :equality_treatment in keys(meta)

            # Test option types
            Test.@test Options.type(meta[:max_iter]) == Integer
            Test.@test Options.type(meta[:tol]) == Real
            Test.@test Options.type(meta[:print_level]) == MadNLP.LogLevels
            Test.@test Options.type(meta[:linear_solver]) == Type{<:MadNLP.AbstractLinearSolver}
            
            # Test termination option types
            Test.@test Options.type(meta[:acceptable_tol]) == Real
            Test.@test Options.type(meta[:acceptable_iter]) == Integer
            Test.@test Options.type(meta[:max_wall_time]) == Real
            Test.@test Options.type(meta[:diverging_iterates_tol]) == Real

            # Test scaling and structure types
            Test.@test Options.type(meta[:nlp_scaling]) == Bool
            Test.@test Options.type(meta[:nlp_scaling_max_gradient]) == Real
            Test.@test Options.type(meta[:jacobian_constant]) == Bool
            Test.@test Options.type(meta[:hessian_constant]) == Bool

            # Test initialization types
            Test.@test Options.type(meta[:bound_push]) == Real
            Test.@test Options.type(meta[:bound_fac]) == Real
            Test.@test Options.type(meta[:constr_mult_init_max]) == Real
            Test.@test Options.type(meta[:fixed_variable_treatment]) == Type{<:MadNLP.AbstractFixedVariableTreatment}
            Test.@test Options.type(meta[:equality_treatment]) == Type{<:MadNLP.AbstractEqualityTreatment}
            Test.@test Options.type(meta[:kkt_system]) == Union{Type{<:MadNLP.AbstractKKTSystem},UnionAll}
            Test.@test Options.type(meta[:hessian_approximation]) == Union{Type{<:MadNLP.AbstractHessian},UnionAll}
            Test.@test Options.type(meta[:inertia_correction_method]) == Type{<:MadNLP.AbstractInertiaCorrector}
            Test.@test Options.type(meta[:mu_init]) == Real
            Test.@test Options.type(meta[:mu_min]) == Real
            Test.@test Options.type(meta[:tau_min]) == Real

            # Test default values
            Test.@test Options.default(meta[:max_iter]) isa Integer
            Test.@test Options.default(meta[:tol]) isa Real
            Test.@test Options.default(meta[:print_level]) isa MadNLP.LogLevels
            Test.@test Options.default(meta[:linear_solver]) == MadNLPMumps.MumpsSolver

            # Test termination option defaults - all use NotProvided to let MadNLP use its own defaults
            Test.@test Options.default(meta[:acceptable_iter]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:acceptable_tol]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:max_wall_time]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:diverging_iterates_tol]) isa Options.NotProvidedType

            # Test scaling and structure defaults - all use NotProvided
            Test.@test Options.default(meta[:nlp_scaling]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:nlp_scaling_max_gradient]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:jacobian_constant]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:hessian_constant]) isa Options.NotProvidedType

            # Test initialization defaults
            Test.@test Options.default(meta[:bound_push]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:bound_fac]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:constr_mult_init_max]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:fixed_variable_treatment]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:equality_treatment]) isa Options.NotProvidedType
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.MadNLP(print_level=MadNLP.ERROR)
            Test.@test solver isa Solvers.MadNLP
            Test.@test solver isa Solvers.AbstractNLPSolver
            
            # Constructor with options
            solver_custom = Solvers.MadNLP(max_iter=100, tol=1e-6, print_level=MadNLP.ERROR)
            Test.@test solver_custom isa Solvers.MadNLP
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.MadNLP(max_iter=500, tol=1e-8, print_level=MadNLP.ERROR)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            
            # Verify values
            Test.@test raw_opts.max_iter == 500
            Test.@test raw_opts.tol == 1e-8
            Test.@test raw_opts.print_level == MadNLP.ERROR
        end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # Create a simple problem
            nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
            
            # Test with display=false sets print_level=MadNLP.ERROR
            solver_verbose = Solvers.MadNLP(
                max_iter=10,
                print_level=MadNLP.INFO
            )
            
            # Verify the solver accepts the display parameter
            Test.@test_nowarn solver_verbose(nlp; display=false)
            redirect_stdout(devnull) do
                Test.@test_nowarn solver_verbose(nlp; display=true)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (CPU)
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - CPU" begin
            ros = TestProblems.Rosenbrock()
            
            # Build NLP model
            adnlp_builder = Optimization.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            solver = Solvers.MadNLP(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR,
                linear_solver=MadNLPMumps.MumpsSolver
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test stats isa MadNLP.MadNLPExecutionStats
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test stats.solution ≈ ros.sol atol=1e-4
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = TestProblems.Elec()
            
            # Build NLP model
            adnlp_builder = Optimization.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.MadNLP(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        Test.@testset "Max1MinusX2 Problem - CPU" begin
            max_prob = TestProblems.Max1MinusX2()
            
            # Build NLP model
            adnlp_builder = Optimization.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)
            
            solver = Solvers.MadNLP(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-6
            # Note: MadNLP 0.8 inverts the sign for maximization problems
            Test.@test -stats.objective ≈ TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-6
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU (if CUDA available)
        # ====================================================================
        
        Test.@testset "GPU Tests" begin
            if is_cuda_on()
                gpu_modeler = Modelers.Exa(backend=CUDA.CUDABackend())
                gpu_solver = Solvers.MadNLP(
                    max_iter=1000,
                    tol=1e-6,
                    print_level=MadNLP.ERROR,
                    linear_solver=MadNLPGPU.CUDSSSolver
                )

                Test.@testset "Rosenbrock - GPU" begin
                    ros = TestProblems.Rosenbrock()
                    nlp = Optimization.build_model(ros.prob, ros.init, gpu_modeler)
                    sol = CommonSolve.solve(
                        ros.prob, ros.init, gpu_modeler, gpu_solver;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test Array(sol.solution) ≈ ros.sol atol=1e-6
                    Test.@test sol.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-6
                end

                Test.@testset "Elec - GPU" begin
                    elec = TestProblems.Elec()
                    sol = CommonSolve.solve(
                        elec.prob, elec.init, gpu_modeler, gpu_solver;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(sol.objective)
                end

                # NOTE: Max1MinusX2 is a maximization problem (minimize=false)
                # ExaModels on GPU treats maximization as minimization, causing
                # convergence to constraint bound x≈5 instead of x=0
                # Test disabled until ExaModels GPU supports maximization correctly
                # Test.@testset "Max1MinusX2 - GPU" begin
                #     max_prob = TestProblems.Max1MinusX2()
                #     sol = CommonSolve.solve(
                #         max_prob.prob, max_prob.init, gpu_modeler, gpu_solver;
                #         display=false
                #     )
                #     Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                #     Test.@test length(sol.solution) == 1
                #     Test.@test Array(sol.solution)[1] ≈ max_prob.sol[1] atol=1e-6
                # end
            else
                # CUDA not functional — skip silently (reported in runtests.jl)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work for max_iter
            solver1 = Solvers.MadNLP(max_iter=100, print_level=MadNLP.ERROR)
            solver2 = Solvers.MadNLP(maxiter=100, print_level=MadNLP.ERROR)
            
            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)
            
            raw1 = Options.extract_raw_options(opts1.options)
            raw2 = Options.extract_raw_options(opts2.options)
            
            # Both should set max_iter
            Test.@test raw1[:max_iter] == 100
            Test.@test raw2[:max_iter] == 100

            # Test aliases for termination options
            solver_acc = Solvers.MadNLP(acc_tol=1e-5, print_level=MadNLP.ERROR)
            solver_time = Solvers.MadNLP(max_time=100.0, print_level=MadNLP.ERROR)

            raw_acc = Options.extract_raw_options(Strategies.options(solver_acc).options)
            raw_time = Options.extract_raw_options(Strategies.options(solver_time).options)

            Test.@test raw_acc[:acceptable_tol] == 1e-5
            Test.@test raw_time[:max_wall_time] == 100.0
        end

        # ====================================================================
        # UNIT TESTS - Option Validation
        # ====================================================================

        Test.@testset "Termination Options Validation" begin
            # Test invalid values throw IncorrectArgument (suppress error messages)
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(acceptable_tol=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(acceptable_tol=0.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(acceptable_iter=0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(max_wall_time=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(max_wall_time=0.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(diverging_iterates_tol=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(diverging_iterates_tol=0.0)
            end

            # Test valid values work (suppress solver output)
            Test.@test_nowarn Solvers.MadNLP(acceptable_tol=1e-5, acceptable_iter=10, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(max_wall_time=60.0, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(diverging_iterates_tol=1e10, print_level=MadNLP.ERROR)
        end

        Test.@testset "NLP Scaling Options Validation" begin
            # Test valid values
            Test.@test_nowarn Solvers.MadNLP(nlp_scaling=true, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(nlp_scaling_max_gradient=100.0, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(jacobian_constant=true, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(hessian_constant=true, print_level=MadNLP.ERROR)

            # Test aliases
            Test.@test_nowarn Solvers.MadNLP(jacobian_cst=true, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(hessian_cst=true, print_level=MadNLP.ERROR)

            # Test invalid values (suppress error messages)
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(nlp_scaling_max_gradient=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(nlp_scaling_max_gradient=0.0)
            end
        end

        Test.@testset "Initialization Options Validation" begin
            # Test valid values
            Test.@test_nowarn Solvers.MadNLP(bound_push=0.01, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(bound_fac=0.01, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(constr_mult_init_max=1000.0, print_level=MadNLP.ERROR)

            # Test Type values
            Test.@test_nowarn Solvers.MadNLP(fixed_variable_treatment=MadNLP.MakeParameter, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(equality_treatment=MadNLP.RelaxEquality, print_level=MadNLP.ERROR)

            # Test invalid values (suppress error messages)
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(bound_push=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(bound_push=0.0)

                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(bound_fac=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(bound_fac=0.0)

                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(constr_mult_init_max=-1.0)
            end
        end
        
        Test.@testset "Advanced Options Validation" begin
            # Test valid type values
            Test.@test_nowarn Solvers.MadNLP(kkt_system=MadNLP.SparseKKTSystem, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(hessian_approximation=MadNLP.BFGS, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(inertia_correction_method=MadNLP.InertiaAuto, print_level=MadNLP.ERROR)

            # Test valid real values
            Test.@test_nowarn Solvers.MadNLP(mu_init=1e-3, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(mu_min=1e-9, print_level=MadNLP.ERROR)
            Test.@test_nowarn Solvers.MadNLP(tau_min=0.99, print_level=MadNLP.ERROR)

            # Test invalid values (expect exceptions for type mismatches)
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(kkt_system=1)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(hessian_approximation=1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(inertia_correction_method="invalid")

                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(mu_init=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(mu_init=0.0)

                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(mu_min=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(mu_min=0.0)

                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(tau_min=-0.1)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNLP(tau_min=1.1)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - Multiple Solves
        # ====================================================================
        
        Test.@testset "Multiple Solves" begin
            solver = Solvers.MadNLP(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            # Solve different problems with same solver
            ros = TestProblems.Rosenbrock()
            max_prob = TestProblems.Max1MinusX2()
            
            # Build NLP models
            adnlp_builder = Optimization.get_adnlp_model_builder(ros.prob)
            nlp1 = adnlp_builder(ros.init)
            
            adnlp_builder2 = Optimization.get_adnlp_model_builder(max_prob.prob)
            nlp2 = adnlp_builder2(max_prob.init)
            
            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)
            
            Test.@test Symbol(stats1.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test Symbol(stats2.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess with Linear Solvers (max_iter=0)
        # ====================================================================
        
        Test.@testset "Initial Guess - Linear Solvers" begin
            BaseType = Float32
            modelers = [Modelers.ADNLP(), Modelers.Exa(; base_type=BaseType)]
            modelers_names = ["Modelers.ADNLP", "Modelers.Exa (CPU)"]
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            # Rosenbrock: start at the known solution and enforce max_iter=0
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = TestProblems.Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            local opts = Dict(:max_iter => 0, :print_level => MadNLP.ERROR)
                            sol = CommonSolve.solve(
                                ros.prob,
                                ros.sol,
                                modeler,
                                Solvers.MadNLP(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ ros.sol atol=1e-6
                        end
                    end
                end
            end
            
            # Elec
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = TestProblems.Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            local opts = Dict(:max_iter => 0, :print_level => MadNLP.ERROR)
                            sol = CommonSolve.solve(
                                elec.prob,
                                elec.init,
                                modeler,
                                Solvers.MadNLP(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_madnlp (direct function)
        # ====================================================================
        
        Test.@testset "solve_with_madnlp Function" begin
            BaseType = Float32
            modelers = [Modelers.ADNLP(), Modelers.Exa(; base_type=BaseType)]
            modelers_names = ["Modelers.ADNLP", "Modelers.Exa (CPU)"]
            madnlp_options = Dict(:max_iter => 1000, :tol => 1e-6, :print_level => MadNLP.ERROR)
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
                ros = TestProblems.Rosenbrock()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(ros.prob, ros.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test sol.solution ≈ ros.sol atol=1e-6
                            Test.@test sol.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-6
                        end
                    end
                end
            end
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = TestProblems.Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                        end
                    end
                end
            end
            
            Test.@testset "Max1MinusX2" verbose=VERBOSE showtiming=SHOWTIMING begin
                max_prob = TestProblems.Max1MinusX2()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(max_prob.prob, max_prob.init, modeler)
                            sol = CTSolversMadNLP.solve_with_madnlp(nlp; linear_solver=linear_solver, madnlp_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test length(sol.solution) == 1
                            Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                            # MadNLP inverts sign for maximization
                            Test.@test -sol.objective ≈ TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU solve_with_madnlp (direct function)
        # ====================================================================
        
        Test.@testset "GPU - solve_with_madnlp" begin
            if is_cuda_on()
                gpu_modeler = Modelers.Exa(backend=CUDA.CUDABackend())
                madnlp_options = Dict(
                    :max_iter => 1000,
                    :tol => 1e-6,
                    :print_level => MadNLP.ERROR,
                    :linear_solver => MadNLPGPU.CUDSSSolver
                )

                Test.@testset "Rosenbrock - GPU" begin
                    ros = TestProblems.Rosenbrock()
                    nlp = Optimization.build_model(ros.prob, ros.init, gpu_modeler)
                    sol = CTSolversMadNLP.solve_with_madnlp(nlp; madnlp_options...)
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test Array(sol.solution) ≈ ros.sol atol=1e-6
                    Test.@test sol.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-6
                end

                Test.@testset "Elec - GPU" begin
                    elec = TestProblems.Elec()
                    nlp = Optimization.build_model(elec.prob, elec.init, gpu_modeler)
                    sol = CTSolversMadNLP.solve_with_madnlp(nlp; madnlp_options...)
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(sol.objective)
                end

                # NOTE: Max1MinusX2 is a maximization problem (minimize=false)
                # https://github.com/MadNLP/MadNLP.jl/issues/518
                # ExaModels on GPU treats maximization as minimization, causing
                # convergence to constraint bound x≈5 instead of x=0
                # Test disabled until ExaModels GPU supports maximization correctly
                # Test.@testset "Max1MinusX2 - GPU" begin
                #     max_prob = TestProblems.Max1MinusX2()
                #     nlp = Optimization.build_model(max_prob.prob, max_prob.init, gpu_modeler)
                #     sol = CTSolversMadNLP.solve_with_madnlp(nlp; madnlp_options...)
                #     Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                #     Test.@test length(sol.solution) == 1
                #     Test.@test Array(sol.solution)[1] ≈ max_prob.sol[1] atol=1e-6
                # end
            else
                # CUDA not functional — skip silently (reported in runtests.jl)
            end
        end

        # ====================================================================
        # INTEGRATION TESTS - GPU Initial Guess (max_iter=0)
        # ====================================================================

        Test.@testset "GPU - Initial Guess (max_iter=0)" begin
            if is_cuda_on()
                gpu_modeler = Modelers.Exa(backend=CUDA.CUDABackend())
                gpu_solver_0 = Solvers.MadNLP(
                    max_iter=0,
                    print_level=MadNLP.ERROR,
                    linear_solver=MadNLPGPU.CUDSSSolver
                )

                Test.@testset "Rosenbrock - GPU" begin
                    ros = TestProblems.Rosenbrock()
                    sol = CommonSolve.solve(
                        ros.prob, ros.sol, gpu_modeler, gpu_solver_0;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                    Test.@test Array(sol.solution) ≈ ros.sol atol=1e-6
                end

                Test.@testset "Elec - GPU" begin
                    elec = TestProblems.Elec()
                    sol = CommonSolve.solve(
                        elec.prob, elec.init, gpu_modeler, gpu_solver_0;
                        display=false
                    )
                    Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                    expected = vcat(elec.init.x, elec.init.y, elec.init.z)
                    Test.@test Array(sol.solution) ≈ expected atol=1e-6
                end
            else
                # CUDA not functional — skip silently (reported in runtests.jl)
            end
        end
    end
end

end # module

test_madnlp_extension() = TestMadNLPExtension.test_madnlp_extension()
