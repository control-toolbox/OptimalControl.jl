module TestMadNCLExtension

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
import MadNCL
import MadNLP
import MadNLPMumps
import MadNLPGPU

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

# Trigger extension loading
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# CUDA availability check
is_cuda_on() = CUDA.functional()

"""
    test_madncl_extension()

Tests for Solvers.MadNCL extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete Solvers.MadNCL functionality including metadata, constructor,
options handling (including ncl_options), display flag, and problem solving.
"""
function test_madncl_extension()
    Test.@testset "MadNCL Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        Test.@testset "Metadata" begin
            meta = Strategies.metadata(Solvers.MadNCL)
            
            Test.@test meta isa Strategies.StrategyMetadata
            Test.@test length(meta) > 0
            
            # Test that key options are defined
            Test.@test :max_iter in keys(meta)
            Test.@test :tol in keys(meta)
            Test.@test :print_level in keys(meta)
            Test.@test :linear_solver in keys(meta)
            Test.@test :ncl_options in keys(meta)
            
            # Test Imported MadNLP Options
            Test.@test Options.default(meta[:acceptable_iter]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:acceptable_tol]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:max_wall_time]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:diverging_iterates_tol]) isa Options.NotProvidedType
            Test.@test :nlp_scaling in keys(meta)
            Test.@test :jacobian_constant in keys(meta)
            Test.@test Options.default(meta[:bound_push]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:bound_fac]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:constr_mult_init_max]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:fixed_variable_treatment]) isa Options.NotProvidedType
            Test.@test Options.default(meta[:equality_treatment]) isa Options.NotProvidedType
            Test.@test :kkt_system in keys(meta)
            Test.@test :hessian_approximation in keys(meta)
            Test.@test :mu_init in keys(meta)

            # Test option types
            Test.@test Options.type(meta[:max_iter]) == Integer
            Test.@test Options.type(meta[:tol]) == Real
            Test.@test Options.type(meta[:print_level]) == MadNLP.LogLevels
            Test.@test Options.type(meta[:linear_solver]) == Type{<:MadNLP.AbstractLinearSolver}
            Test.@test Options.type(meta[:ncl_options]) == MadNCL.NCLOptions
            Test.@test Options.type(meta[:acceptable_tol]) == Real
            Test.@test Options.type(meta[:kkt_system]) == Union{Type{<:MadNLP.AbstractKKTSystem},UnionAll}

            # Check ncl_options description
            Test.@test occursin("rho_init", Options.description(meta[:ncl_options]))
            Test.@test occursin("max_auglag_iter", meta[:ncl_options].description)
            Test.@test occursin("opt_tol", Options.description(meta[:ncl_options]))
            
            # Test default values
            Test.@test Options.default(meta[:max_iter]) isa Integer
            Test.@test Options.default(meta[:tol]) isa Real
            Test.@test Options.default(meta[:print_level]) isa MadNLP.LogLevels
            Test.@test Options.default(meta[:linear_solver]) == MadNLPMumps.MumpsSolver
            Test.@test Options.default(meta[:ncl_options]) isa MadNCL.NCLOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        Test.@testset "Constructor" begin
            # Default constructor
            solver = Solvers.MadNCL()
            Test.@test solver isa Solvers.MadNCL
            Test.@test solver isa Solvers.AbstractNLPSolver
            
            # Constructor with options
            solver_custom = Solvers.MadNCL(max_iter=100, tol=1e-6)
            Test.@test solver_custom isa Solvers.MadNCL
            
            # Test Strategies.options() returns StrategyOptions
            opts = Strategies.options(solver)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        Test.@testset "Options Extraction" begin
            solver = Solvers.MadNCL(max_iter=500, tol=1e-8)
            opts = Strategies.options(solver)
            
            # Extract raw options (returns NamedTuple)
            raw_opts = Options.extract_raw_options(opts.options)
            Test.@test raw_opts isa NamedTuple
            Test.@test haskey(raw_opts, :max_iter)
            Test.@test haskey(raw_opts, :tol)
            Test.@test haskey(raw_opts, :print_level)
            Test.@test haskey(raw_opts, :ncl_options)
            
            # Verify values
            Test.@test raw_opts.max_iter == 500
            Test.@test raw_opts.tol == 1e-8
            Test.@test raw_opts.print_level == MadNLP.INFO
            Test.@test raw_opts.ncl_options isa MadNCL.NCLOptions
        end
        
        # ====================================================================
        # UNIT TESTS - NCLOptions Handling
        # ====================================================================
        
        Test.@testset "NCLOptions" begin
            # Test with default ncl_options
            solver_default = Solvers.MadNCL()
            opts_default = Strategies.options(solver_default)
            raw_default = Options.extract_raw_options(opts_default.options)
            
            Test.@test haskey(raw_default, :ncl_options)
            Test.@test raw_default.ncl_options isa MadNCL.NCLOptions
            
            # Test with custom ncl_options
            custom_ncl = MadNCL.NCLOptions{Float64}(
                verbose=false,
                opt_tol=1e-6,
                feas_tol=1e-6
            )
            solver_custom = Solvers.MadNCL(ncl_options=custom_ncl)
            opts_custom = Strategies.options(solver_custom)
            raw_custom = Options.extract_raw_options(opts_custom.options)
            
            Test.@test raw_custom.ncl_options === custom_ncl
        end
        
        # ====================================================================
        # UNIT TESTS - Advanced Option Validation
        # ====================================================================

        Test.@testset "Option Validation" begin
            # Should behave exactly like MadNLP validation
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNCL(acceptable_tol=-1.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNCL(max_wall_time=0.0)
                Test.@test_throws Exceptions.IncorrectArgument Solvers.MadNCL(bound_push=-1.0)
            end

            # Valid construction
            Test.@test_nowarn Solvers.MadNCL(acceptable_tol=1e-5, max_wall_time=100.0)
        end

        # ====================================================================
        # UNIT TESTS - Pass-through
        # ====================================================================

        Test.@testset "MadNLP Option Pass-through" begin
            # Create a simple dummy problem
            ros = TestProblems.Rosenbrock()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)

            # checking that it runs without error with these options
            solver = Solvers.MadNCL(
                max_iter=1,
                print_level=MadNLP.ERROR,
                acceptable_tol=1e-2,
                mu_init=0.1
            )

            # Just ensure the call works and options are accepted
            Test.@test_nowarn solver(nlp, display=false)
        end

        # ====================================================================
        # UNIT TESTS - Display Flag Handling (Special for MadNCL)
        # ====================================================================
        
        Test.@testset "Display Flag" begin
            # MadNCL requires problems with constraints
            # Using Elec problem which has constraints
            elec = TestProblems.Elec()
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            # Test with display=false sets print_level=MadNLP.ERROR
            # and reconstructs ncl_options with verbose=false
            solver_verbose = Solvers.MadNCL(
                max_iter=10,
                print_level=MadNLP.INFO
            )
            
            # Just test that the solver can be created with options
            opts = Strategies.options(solver_verbose)
            Test.@test opts isa Strategies.StrategyOptions
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (CPU)
        # ====================================================================
        
        Test.@testset "Rosenbrock Problem - CPU" begin
            ros = TestProblems.Rosenbrock()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
            nlp = adnlp_builder(ros.init)
            
            solver = Solvers.MadNCL(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Just check it converges
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        Test.@testset "Elec Problem - CPU" begin
            elec = TestProblems.Elec()
            
            # Build NLP model
            adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp = adnlp_builder(elec.init)
            
            solver = Solvers.MadNCL(
                max_iter=3000,
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
            adnlp_builder = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp = adnlp_builder(max_prob.init)
            
            solver = Solvers.MadNCL(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            stats = solver(nlp; display=false)
            
            # Check convergence
            Test.@test Symbol(stats.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test length(stats.solution) == 1
            Test.@test stats.solution[1] ≈ max_prob.sol[1] atol=1e-6
            # Note: MadNCL does NOT invert the sign (unlike MadNLP)
            Test.@test stats.objective ≈ TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-6
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU (if CUDA available)
        # ====================================================================
        
        Test.@testset "GPU Tests" begin
            # Check if CUDA is available and functional
            if CUDA.functional()
                Test.@testset "Rosenbrock Problem - GPU" begin
                    ros = TestProblems.Rosenbrock()
                    
                    # Note: GPU linear solver would need to be configured
                    # For now, just test that the solver can be created
                    solver = Solvers.MadNCL(
                        max_iter=1000,
                        tol=1e-6,
                        print_level=MadNLP.ERROR
                    )
                    
                    Test.@test solver isa Solvers.MadNCL
                end
            else
                # CUDA not functional — skip silently (reported in runtests.jl)
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        Test.@testset "Option Aliases" begin
            # Test that aliases work
            solver1 = Solvers.MadNCL(max_iter=100)
            solver2 = Solvers.MadNCL(maxiter=100)
            
            opts1 = Strategies.options(solver1)
            opts2 = Strategies.options(solver2)
            
            raw1 = Options.extract_raw_options(opts1.options)
            raw2 = Options.extract_raw_options(opts2.options)
            
            # Both should set max_iter
            Test.@test raw1[:max_iter] == 100
            Test.@test raw2[:max_iter] == 100
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Multiple Solves
        # ====================================================================
        
        Test.@testset "Multiple Solves" begin
            solver = Solvers.MadNCL(
                max_iter=1000,
                tol=1e-6,
                print_level=MadNLP.ERROR
            )
            
            # Solve different problems with same solver
            elec = TestProblems.Elec()
            max_prob = TestProblems.Max1MinusX2()
            
            # Build NLP models
            adnlp_builder1 = CTSolvers.get_adnlp_model_builder(elec.prob)
            nlp1 = adnlp_builder1(elec.init)
            
            adnlp_builder2 = CTSolvers.get_adnlp_model_builder(max_prob.prob)
            nlp2 = adnlp_builder2(max_prob.init)
            
            stats1 = solver(nlp1; display=false)
            stats2 = solver(nlp2; display=false)
            
            Test.@test Symbol(stats1.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
            Test.@test Symbol(stats2.status) in (:SOLVE_SUCCEEDED, :SOLVED_TO_ACCEPTABLE_LEVEL)
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess with NCLOptions (max_iter=0)
        # ====================================================================
        
        Test.@testset "Initial Guess - NCLOptions" begin
            BaseType = Float64
            modelers = [Modelers.ADNLP(), Modelers.Exa(; base_type=BaseType)]
            modelers_names = ["Modelers.ADNLP", "Modelers.Exa (CPU)"]
            linear_solvers = [MadNLP.UmfpackSolver, MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Umfpack", "Mumps"]
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = TestProblems.Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            # Create NCLOptions with max_auglag_iter=0 to prevent outer iterations
                            ncl_opts = MadNCL.NCLOptions{BaseType}(
                                verbose=false,
                                max_auglag_iter=0
                            )
                            
                            local opts = Dict(
                                :max_iter => 0,
                                :print_level => MadNLP.ERROR,
                                :ncl_options => ncl_opts
                            )
                            
                            sol = CommonSolve.solve(
                                elec.prob,
                                elec.init,
                                modeler,
                                Solvers.MadNCL(; opts..., linear_solver=linear_solver),
                            )
                            Test.@test sol.status == MadNLP.MAXIMUM_ITERATIONS_EXCEEDED
                            Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_madncl (direct function)
        # ====================================================================
        
        Test.@testset "solve_with_madncl Function" begin
            BaseType = Float64
            modelers = [Modelers.ADNLP(), Modelers.Exa(; base_type=BaseType)]
            modelers_names = ["Modelers.ADNLP", "Modelers.Exa (CPU)"]
            madncl_options = Dict(
                :max_iter => 1000,
                :tol => 1e-6,
                :print_level => MadNLP.ERROR,
                :ncl_options => MadNCL.NCLOptions{Float64}(; verbose=false)
            )
            linear_solvers = [MadNLPMumps.MumpsSolver]
            linear_solver_names = ["Mumps"]
            
            Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
                elec = TestProblems.Elec()
                for (modeler, modeler_name) in zip(modelers, modelers_names)
                    for (linear_solver, linear_solver_name) in zip(linear_solvers, linear_solver_names)
                        Test.@testset "$(modeler_name), $(linear_solver_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
                            nlp = Optimization.build_model(elec.prob, elec.init, modeler)
                            sol = CTSolversMadNCL.solve_with_madncl(nlp; linear_solver=linear_solver, madncl_options...)
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
                            sol = CTSolversMadNCL.solve_with_madncl(nlp; linear_solver=linear_solver, madncl_options...)
                            Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                            Test.@test length(sol.solution) == 1
                            Test.@test sol.solution[1] ≈ max_prob.sol[1] atol=1e-6
                            # MadNCL does NOT invert sign (unlike MadNLP)
                            Test.@test sol.objective ≈ TestProblems.max1minusx2_objective(max_prob.sol) atol=1e-6
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - GPU Tests
        # ====================================================================
        
        Test.@testset "GPU Tests" begin
            if is_cuda_on()
                gpu_modeler = Modelers.Exa(backend=CUDA.CUDABackend())
                gpu_solver = Solvers.MadNCL(
                    max_iter=1000,
                    tol=1e-6,
                    print_level=MadNLP.ERROR,
                    linear_solver=MadNLPGPU.CUDSSSolver,
                    ncl_options=MadNCL.NCLOptions{Float64}(; verbose=false)
                )

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
                # https://github.com/MadNLP/MadNLP.jl/issues/518
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
        # INTEGRATION TESTS - GPU solve_with_madncl (direct function)
        # ====================================================================

        Test.@testset "GPU - solve_with_madncl" begin
            if is_cuda_on()
                gpu_modeler = Modelers.Exa(backend=CUDA.CUDABackend())
                madncl_options = Dict(
                    :max_iter => 1000,
                    :tol => 1e-6,
                    :print_level => MadNLP.ERROR,
                    :linear_solver => MadNLPGPU.CUDSSSolver,
                    :ncl_options => MadNCL.NCLOptions{Float64}(; verbose=false)
                )

                Test.@testset "Elec - GPU" begin
                    elec = TestProblems.Elec()
                    nlp = Optimization.build_model(elec.prob, elec.init, gpu_modeler)
                    sol = CTSolversMadNCL.solve_with_madncl(nlp; madncl_options...)
                    Test.@test sol.status == MadNLP.SOLVE_SUCCEEDED
                    Test.@test isfinite(sol.objective)
                end

                # NOTE: Max1MinusX2 is a maximization problem (minimize=false)
                # ExaModels on GPU treats maximization as minimization, causing
                # convergence to constraint bound x≈5 instead of x=0
                # Test disabled until ExaModels GPU supports maximization correctly
                # Test.@testset "Max1MinusX2 - GPU" begin
                #     max_prob = TestProblems.Max1MinusX2()
                #     nlp = Optimization.build_model(max_prob.prob, max_prob.init, gpu_modeler)
                #     sol = CTSolversMadNCL.solve_with_madncl(nlp; madncl_options...)
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
                ncl_opts_0 = MadNCL.NCLOptions{Float64}(
                    verbose=false,
                    max_auglag_iter=0
                )
                gpu_solver_0 = Solvers.MadNCL(
                    max_iter=0,
                    print_level=MadNLP.ERROR,
                    linear_solver=MadNLPGPU.CUDSSSolver,
                    ncl_options=ncl_opts_0
                )

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

test_madncl_extension() = TestMadNCLExtension.test_madncl_extension()
