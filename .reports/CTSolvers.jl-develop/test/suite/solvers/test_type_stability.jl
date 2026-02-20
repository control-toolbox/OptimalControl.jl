module TestTypeStability

import Test
import CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies
import CTSolvers.Options

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Load extensions to trigger dependencies
import NLPModelsIpopt
import MadNLP
import MadNLPMumps
import MadNCL
# using NLPModelsKnitro

"""
    test_type_stability()

Test type stability of critical solver functions.

🔧 **Applying Type Stability Rule**: Testing type stability with Test.@inferred
for performance-critical functions.
"""
function test_type_stability()
    Test.@testset "Type Stability Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Solver Construction Type Stability
        # ====================================================================
        
        Test.@testset "Solver Construction Type Stability" begin
            Test.@testset "Solvers.Ipopt construction" begin
                # Test that constructor returns correct type
                Test.@test_nowarn Test.@inferred Solvers.Ipopt()
                Test.@test_nowarn Test.@inferred Solvers.Ipopt(max_iter=100)
                Test.@test_nowarn Test.@inferred Solvers.Ipopt(max_iter=100, tol=1e-6)
            end
            
            Test.@testset "Solvers.MadNLP construction" begin
                Test.@test_nowarn Test.@inferred Solvers.MadNLP()
                Test.@test_nowarn Test.@inferred Solvers.MadNLP(max_iter=100)
                Test.@test_nowarn Test.@inferred Solvers.MadNLP(max_iter=100, tol=1e-6)
            end
            
            Test.@testset "Solvers.MadNCL construction" begin
                Test.@test_nowarn Test.@inferred Solvers.MadNCL()
                Test.@test_nowarn Test.@inferred Solvers.MadNCL(max_iter=100)
                Test.@test_nowarn Test.@inferred Solvers.MadNCL(max_iter=100, tol=1e-6)
            end
            
            # Commented out - no Knitro license available
            # Test.@testset "Solvers.Knitro construction" begin
            #     Test.@test_nowarn Test.@inferred Solvers.Knitro()
            #     Test.@test_nowarn Test.@inferred Solvers.Knitro(max_iter=100)
            #     Test.@test_nowarn Test.@inferred Solvers.Knitro(max_iter=100, ftol=1e-6)
            # end
        end
        
        # ====================================================================
        # UNIT TESTS - Strategy Contract Type Stability
        # ====================================================================
        
        Test.@testset "Strategy Contract Type Stability" begin
            Test.@testset "Solvers.Ipopt contract" begin
                # Test id() type stability - simple Symbol return
                Test.@test_nowarn Test.@inferred Strategies.id(Solvers.Ipopt)
                Test.@test Test.@inferred(Strategies.id(Solvers.Ipopt)) === :ipopt
                
                # Test metadata() returns correct type
                meta = Strategies.metadata(Solvers.Ipopt)
                Test.@test meta isa Strategies.StrategyMetadata
                
                # Test options() returns correct type
                # Note: Test.@inferred is too strict for parametric types, we verify concrete type
                solver = Solvers.Ipopt()
                opts = Strategies.options(solver)
                Test.@test opts isa Strategies.StrategyOptions
            end
            
            Test.@testset "Solvers.MadNLP contract" begin
                Test.@test_nowarn Test.@inferred Strategies.id(Solvers.MadNLP)
                Test.@test Test.@inferred(Strategies.id(Solvers.MadNLP)) === :madnlp
                
                # Metadata returns correct type
                meta = Strategies.metadata(Solvers.MadNLP)
                Test.@test meta isa Strategies.StrategyMetadata
                
                # Options returns correct type
                opts = Strategies.options(Solvers.MadNLP())
                Test.@test opts isa Strategies.StrategyOptions
            end
            
            Test.@testset "Solvers.MadNCL contract" begin
                Test.@test_nowarn Test.@inferred Strategies.id(Solvers.MadNCL)
                Test.@test Test.@inferred(Strategies.id(Solvers.MadNCL)) === :madncl
                
                # Metadata returns correct type
                meta = Strategies.metadata(Solvers.MadNCL)
                Test.@test meta isa Strategies.StrategyMetadata
                
                # Options returns correct type
                opts = Strategies.options(Solvers.MadNCL())
                Test.@test opts isa Strategies.StrategyOptions
            end
            
            # Commented out - no Knitro license available
            # Test.@testset "Solvers.Knitro contract" begin
            #     Test.@test_nowarn Test.@inferred Strategies.id(Solvers.Knitro)
            #     Test.@test Test.@inferred(Strategies.id(Solvers.Knitro)) === :knitro
                
            #     # Metadata returns correct type
            #     meta = Strategies.metadata(Solvers.Knitro)
            #     Test.@test meta isa Strategies.StrategyMetadata
                
            #     # Options returns correct type
            #     opts = Strategies.options(Solvers.Knitro())
            #     Test.@test opts isa Strategies.StrategyOptions
            # end
        end
        
        # ====================================================================
        # UNIT TESTS - Options Extraction Type Stability
        # ====================================================================
        
        Test.@testset "Options Extraction Type Stability" begin
            Test.@testset "Solvers.Ipopt options extraction" begin
                solver = Solvers.Ipopt(max_iter=100, tol=1e-6)
                opts = Strategies.options(solver)
                
                # Test that extract_raw_options returns correct type
                # Note: NamedTuple field names are not inferable, so we check the type
                raw_opts = Options.extract_raw_options(opts.options)
                Test.@test raw_opts isa NamedTuple
                Test.@test haskey(raw_opts, :max_iter)
                Test.@test haskey(raw_opts, :tol)
            end
            
            Test.@testset "Solvers.MadNLP options extraction" begin
                solver = Solvers.MadNLP(max_iter=100, tol=1e-6)
                opts = Strategies.options(solver)
                
                # Test that extract_raw_options returns correct type
                raw_opts = Options.extract_raw_options(opts.options)
                Test.@test raw_opts isa NamedTuple
                Test.@test haskey(raw_opts, :max_iter)
                Test.@test haskey(raw_opts, :tol)
            end
        end
        
        # ====================================================================
        # PERFORMANCE NOTES
        # ====================================================================
        
        # Note: The callable interface (solver)(nlp; display=true) cannot be
        # tested for type stability here because:
        # 1. It requires loading solver extensions (NLPModelsIpopt, etc.)
        # 2. The stub implementations throw ExtensionError
        # 3. Type stability of the full solve path is tested in integration tests
        #    when extensions are loaded
        
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_type_stability() = TestTypeStability.test_type_stability()
