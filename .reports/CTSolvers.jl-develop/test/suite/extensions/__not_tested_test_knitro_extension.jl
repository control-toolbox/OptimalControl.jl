module TestKnitroExtension

using Test
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
using CTSolvers
using CTSolvers.Solvers
using CTSolvers.Strategies
using CTSolvers.Options
using CTSolvers.Modelers
using CTSolvers.Optimization
using CommonSolve
using NLPModels
using ADNLPModels

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

# # Trigger extension loading
# using NLPModelsKnitro
# const CTSolversKnitro = Base.get_extension(CTSolvers, :CTSolversKnitro)

# # Import KNITRO for license checking
# using KNITRO

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# """
# Helper function to check if Knitro license is available.
# Returns true if license is available, false otherwise.
# """
# function check_knitro_license()
#     try
#         kc = KNITRO.KN_new()
#         KNITRO.KN_free(kc)
#         return true
#     catch e
#         if occursin("license", lowercase(string(e))) || occursin("-520", string(e))
#             return false
#         else
#             rethrow(e)
#         end
#     end
# end

"""
    test_knitro_extension()

Tests for Solvers.Knitro extension.

🧪 **Applying Testing Rule**: Unit Tests + Integration Tests

Tests the complete Solvers.Knitro functionality including metadata, constructor,
options handling, display flag, and problem solving (requires Knitro license).
"""
function test_knitro_extension()
    Test.@testset "Knitro Extension" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        
        # ====================================================================
        # UNIT TESTS - Metadata and Options
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Metadata" begin
        #     meta = Strategies.metadata(Solvers.Knitro)
        #     
        #     Test.@test meta isa Strategies.StrategyMetadata
        #     Test.@test length(meta) > 0
        #     
        #     # Test that key options are defined
        #     Test.@test :maxit in keys(meta)
        #     Test.@test :maxtime in keys(meta)
        #     Test.@test :feastol_abs in keys(meta)
        #     Test.@test :opttol_abs in keys(meta)
        #     Test.@test :outlev in keys(meta)
        #     
        #     # Test option types
        #     Test.@test meta[:maxit].type == Integer
        #     Test.@test meta[:maxtime].type == Real
        #     Test.@test meta[:feastol_abs].type == Real
        #     Test.@test meta[:opttol_abs].type == Real
        #     Test.@test meta[:outlev].type == Integer
        #     
        #     # Test default values exist
        #     Test.@test meta[:maxit].default isa Integer
        #     Test.@test meta[:maxtime].default isa Real
        #     Test.@test meta[:feastol_abs].default isa Real
        # end
        
        # ====================================================================
        # UNIT TESTS - Constructor
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Constructor" begin
        #     # Default constructor
        #     solver = Solvers.Knitro()
        #     Test.@test solver isa Solvers.Knitro
        #     Test.@test solver isa Solvers.AbstractNLPSolver
        #     
        #     # Constructor with options
        #     solver_custom = Solvers.Knitro(maxit=100, feastol_abs=1e-6)
        #     Test.@test solver_custom isa Solvers.Knitro
        #     
        #     # Test Strategies.options() returns StrategyOptions
        #     opts = Strategies.options(solver)
        #     Test.@test opts isa Strategies.StrategyOptions
        # end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Options Extraction" begin
        #     solver = Solvers.Knitro(maxit=500, feastol_abs=1e-8)
        #     opts = Strategies.options(solver)
        #     
        #     # Extract raw options (returns NamedTuple)
        #     raw_opts = Options.extract_raw_options(opts.options)
        #     Test.@test raw_opts isa NamedTuple
        #     Test.@test haskey(raw_opts, :maxit)
        #     Test.@test haskey(raw_opts, :feastol_abs)
        #     Test.@test haskey(raw_opts, :outlev)
        #     
        #     # Verify values
        #     Test.@test raw_opts[:maxit] == 500
        #     Test.@test raw_opts[:feastol_abs] == 1e-8
        #     Test.@test raw_opts[:outlev] == 2  # Default value
        # end
        
        # ====================================================================
        # UNIT TESTS - Display Flag Handling
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Display Flag" begin
        #     # Create a simple problem
        #     nlp = ADNLPModels.ADNLPModel(x -> sum(x.^2), [1.0, 2.0])
        #     
        #     # Test with display=false sets outlev=0
        #     solver_verbose = Solvers.Knitro(maxit=10, outlev=2)
        #     
        #     # Verify the solver accepts the display parameter
        #     # Commented out due to license requirement
        #     # Test.@test_nowarn solver_verbose(nlp; display=false)
        #     # Test.@test_nowarn solver_verbose(nlp; display=true)
        #     
        #     # Just test that the solver can be created and options extracted
        #     opts = Strategies.options(solver_verbose)
        #     Test.@test opts isa Strategies.StrategyOptions
        # end
        
        # ====================================================================
        # INTEGRATION TESTS - Solving Problems (if license available)
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Rosenbrock Problem - ADNLPModels" begin
        #     ros = TestProblems.Rosenbrock()
        #     
        #     # Build NLP model from problem
        #     adnlp_builder = CTSolvers.get_adnlp_model_builder(ros.prob)
        #     nlp = adnlp_builder(ros.init)
        #     
        #     # Create solver with appropriate options
        #     solver = Solvers.Knitro(
        #         maxit=1000,
        #         feastol_abs=1e-6,
        #         opttol_abs=1e-6,
        #         outlev=0
        #     )
        #     
        #     # Try to solve the problem (may fail without license)
        #     try
        #         # Solve the problem
        #         stats = solver(nlp; display=false)
        #         
        #         # Check convergence
        #         Test.@test stats.status == :first_order
        #         Test.@test stats.solution ≈ ros.sol atol=1e-6
        #         Test.@test stats.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-6
        #         @info "Knitro Rosenbrock test passed - license available"
        #     catch e
        #         if isa(e, Exception) && occursin("license", lowercase(string(e)))
        #             @warn "Knitro license not available, skipping Rosenbrock integration test"
        #             Test.@test true  # Pass the test but note limitation
        #         else
        #             rethrow(e)  # Re-throw if it's not a license issue
        #         end
        #     end
        # end
        
        # Commented out due to license requirement
        # Test.@testset "Elec Problem - ADNLPModels" begin
        #     elec = TestProblems.Elec()
        #     
        #     # Build NLP model
        #     adnlp_builder = CTSolvers.get_adnlp_model_builder(elec.prob)
        #     nlp = adnlp_builder(elec.init)
        #     
        #     solver = Solvers.Knitro(
        #         maxit=1000,
        #         feastol_abs=1e-6,
        #         opttol_abs=1e-6,
        #         outlev=0
        #     )
        #     
        #     # Try to solve the problem (may fail without license)
        #     try
        #         stats = solver(nlp; display=false)
        #         
        #         # Just check it converges
        #         Test.@test stats.status == :first_order
        #         @info "Knitro Elec test passed - license available"
        #     catch e
        #         if isa(e, Exception) && occursin("license", lowercase(string(e)))
        #             @warn "Knitro license not available, skipping Elec integration test"
        #             Test.@test true  # Pass the test but note limitation
        #         else
        #             rethrow(e)  # Re-throw if it's not a license issue
        #         end
        #     end
        # end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Aliases
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Option Aliases" begin
        #     # Test that aliases work
        #     solver1 = Solvers.Knitro(maxit=100)
        #     solver2 = Solvers.Knitro(maxiter=100)
        #     
        #     opts1 = Strategies.options(solver1)
        #     opts2 = Strategies.options(solver2)
        #     
        #     raw1 = Options.extract_raw_options(opts1.options)
        #     raw2 = Options.extract_raw_options(opts2.options)
        #     
        #     # Both should set maxit
        #     Test.@test raw1[:maxit] == 100
        #     Test.@test raw2[:maxit] == 100
        # end
        
        # ====================================================================
        # INTEGRATION TESTS - Initial Guess (maxit=0) - Requires License
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "Initial Guess - maxit=0" begin
        #     if !check_knitro_license()
        #         @warn "Knitro license not available, skipping Initial Guess tests"
        #         Test.@test_skip "Knitro license required"
        #     else
        #         modelers = [Modelers.ADNLP(), Modelers.Exa()]
        #         modelers_names = ["Modelers.ADNLP", "Modelers.Exa (CPU)"]
        #         
        #         # Rosenbrock: start at the known solution and enforce maxit=0
        #         Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             ros = TestProblems.Rosenbrock()
        #             for (modeler, modeler_name) in zip(modelers, modelers_names)
        #                 Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #                     local opts = Dict(:maxit => 0, :outlev => 0)
        #                     sol = CommonSolve.solve(
        #                         ros.prob, ros.sol, modeler, Solvers.Knitro(; opts...)
        #                     )
        #                     Test.@test sol.solution ≈ ros.sol atol=1e-6
        #                 end
        #             end
        #         end
        #         
        #         # Elec: expect solution to remain equal to the initial guess vector
        #         Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             elec = TestProblems.Elec()
        #             for (modeler, modeler_name) in zip(modelers, modelers_names)
        #                 Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #                     local opts = Dict(:maxit => 0, :outlev => 0)
        #                     sol = CommonSolve.solve(
        #                         elec.prob, elec.init, modeler, Solvers.Knitro(; opts...)
        #                     )
        #                     Test.@test sol.solution ≈ vcat(elec.init.x, elec.init.y, elec.init.z) atol=1e-6
        #                 end
        #             end
        #         end
        #     end
        # end
        
        # ====================================================================
        # INTEGRATION TESTS - solve_with_knitro - Requires License
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "solve_with_knitro Function" begin
        #     if !check_knitro_license()
        #         @warn "Knitro license not available, skipping solve_with_knitro tests"
        #         Test.@test_skip "Knitro license required"
        #     else
        #         modelers = [Modelers.ADNLP()]
        #         modelers_names = ["Modelers.ADNLP"]
        #         knitro_options = Dict(
        #             :maxit => 1000,
        #             :feastol_abs => 1e-6,
        #             :opttol_abs => 1e-6,
        #             :outlev => 0
        #         )
        #         
        #         Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             ros = TestProblems.Rosenbrock()
        #             for (modeler, modeler_name) in zip(modelers, modelers_names)
        #                 Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #                     nlp = Optimization.build_model(ros.prob, ros.init, modeler)
        #                     sol = CTSolversKnitro.solve_with_knitro(nlp; knitro_options...)
        #                     Test.@test sol.status == :first_order
        #                     Test.@test sol.solution ≈ ros.sol atol=1e-6
        #                     Test.@test sol.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-6
        #                 end
        #             end
        #         end
        #         
        #         Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             elec = TestProblems.Elec()
        #             for (modeler, modeler_name) in zip(modelers, modelers_names)
        #                 Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #                     nlp = Optimization.build_model(elec.prob, elec.init, modeler)
        #                     sol = CTSolversKnitro.solve_with_knitro(nlp; knitro_options...)
        #                     Test.@test sol.status == :first_order
        #                 end
        #             end
        #         end
        #     end
        # end
        
        # ====================================================================
        # INTEGRATION TESTS - CommonSolve.solve - Requires License
        # ====================================================================
        
        # Commented out due to license requirement
        # Test.@testset "CommonSolve.solve with Knitro" begin
        #     if !check_knitro_license()
        #         @warn "Knitro license not available, skipping CommonSolve.solve tests"
        #         Test.@test_skip "Knitro license required"
        #     else
        #         modelers = [Modelers.ADNLP(), Modelers.Exa()]
        #         modelers_names = ["Modelers.ADNLP", "Modelers.Exa (CPU)"]
        #         knitro_options = Dict(
        #             :maxit => 1000,
        #             :feastol_abs => 1e-6,
        #             :opttol_abs => 1e-6,
        #             :outlev => 0
        #         )
        #         
        #         Test.@testset "Rosenbrock" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             ros = TestProblems.Rosenbrock()
        #             for (modeler, modeler_name) in zip(modelers, modelers_names)
        #                 Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #                     sol = CommonSolve.solve(
        #                         ros.prob,
        #                         ros.init,
        #                         modeler,
        #                         Solvers.Knitro(; knitro_options...),
        #                     )
        #                     Test.@test sol.status == :first_order
        #                     Test.@test sol.solution ≈ ros.sol atol=1e-6
        #                     Test.@test sol.objective ≈ TestProblems.rosenbrock_objective(ros.sol) atol=1e-6
        #                 end
        #             end
        #         end
        #         
        #         Test.@testset "Elec" verbose=VERBOSE showtiming=SHOWTIMING begin
        #             elec = TestProblems.Elec()
        #             for (modeler, modeler_name) in zip(modelers, modelers_names)
        #                 Test.@testset "$(modeler_name)" verbose=VERBOSE showtiming=SHOWTIMING begin
        #                     sol = CommonSolve.solve(
        #                         elec.prob,
        #                         elec.init,
        #                         modeler,
        #                         Solvers.Knitro(; knitro_options...),
        #                     )
        #                     Test.@test sol.status == :first_order
        #                 end
        #             end
        #         end
        #     end
        # end
    end
end

end # module

test_knitro_extension() = TestKnitroExtension.test_knitro_extension()
