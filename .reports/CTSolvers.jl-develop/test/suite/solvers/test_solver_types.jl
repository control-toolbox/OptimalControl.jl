module TestSolverTypes

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Solvers
import CTSolvers.Strategies

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    test_solver_types()

Tests for solver type hierarchy and contracts.

🧪 **Applying Testing Rule**: Contract-First Testing

Tests the basic type hierarchy and Strategies.id() contract for all solvers
without requiring extensions to be loaded.
"""
function test_solver_types()
    Test.@testset "Solver Types and Contracts" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Type Hierarchy
        # ====================================================================
        
        Test.@testset "Type Hierarchy" begin
            # All solver types should inherit from AbstractNLPSolver
            Test.@test Solvers.Ipopt <: Solvers.AbstractNLPSolver
            Test.@test Solvers.MadNLP <: Solvers.AbstractNLPSolver
            Test.@test Solvers.MadNCL <: Solvers.AbstractNLPSolver
            # Commented out - no Knitro license available
            # Test.@test Solvers.Knitro <: Solvers.AbstractNLPSolver
            
            # AbstractNLPSolver should be abstract
            Test.@test isabstracttype(Solvers.AbstractNLPSolver)
            
            # Concrete solver types should not be abstract
            Test.@test !isabstracttype(Solvers.Ipopt)
            Test.@test !isabstracttype(Solvers.MadNLP)
            Test.@test !isabstracttype(Solvers.MadNCL)
            # Commented out - no Knitro license available
            # Test.@test !isabstracttype(Solvers.Knitro)
        end
        
        # ====================================================================
        # UNIT TESTS - Strategies.id() Contract
        # ====================================================================
        
            Test.@testset "Strategies.id() Contract" begin
                # Test that each solver type has a unique identifier
                Test.@test Strategies.id(Solvers.Ipopt) === :ipopt
                # Commented out - no Knitro license available
                # Test.@test Strategies.id(Solvers.Knitro) === :knitro
                Test.@test Strategies.id(Solvers.MadNLP) === :madnlp
                Test.@test Strategies.id(Solvers.MadNCL) === :madncl
                
                # Test that all IDs are unique
                ids = [
                    Strategies.id(Solvers.Ipopt),
                    # Commented out - no Knitro license available
                    # Strategies.id(Solvers.Knitro),
                    Strategies.id(Solvers.MadNLP),
                    Strategies.id(Solvers.MadNCL)
                ]
            Test.@test length(unique(ids)) == 3
            
            # Test that IDs are Symbols
            Test.@test Strategies.id(Solvers.Ipopt) isa Symbol
            # Commented out - no Knitro license available
            # Test.@test Strategies.id(Solvers.Knitro) isa Symbol
            Test.@test Strategies.id(Solvers.MadNLP) isa Symbol
            Test.@test Strategies.id(Solvers.MadNCL) isa Symbol
        end
        
        # ====================================================================
        # UNIT TESTS - Tag Types
        # ====================================================================
        
        Test.@testset "Tag Types" begin
            # Test that tag types exist and inherit from AbstractTag
            Test.@test Solvers.IpoptTag <: Solvers.AbstractTag
            # Commented out - no Knitro license available
            # Test.@test Solvers.KnitroTag <: Solvers.AbstractTag
            Test.@test Solvers.MadNLPTag <: Solvers.AbstractTag
            Test.@test Solvers.MadNCLTag <: Solvers.AbstractTag
            
            # Test that AbstractTag is abstract
            Test.@test isabstracttype(Solvers.AbstractTag)
            
            # Test that concrete tag types are not abstract
            Test.@test !isabstracttype(Solvers.IpoptTag)
            # Commented out - no Knitro license available
            # Test.@test !isabstracttype(Solvers.KnitroTag)
            Test.@test !isabstracttype(Solvers.MadNLPTag)
            Test.@test !isabstracttype(Solvers.MadNCLTag)
            
            # Test that tag types can be instantiated
            Test.@test_nowarn Solvers.IpoptTag()
            # Commented out - no Knitro license available
            # Test.@test_nowarn Solvers.KnitroTag()
            Test.@test_nowarn Solvers.MadNLPTag()
            Test.@test_nowarn Solvers.MadNCLTag()
        end
        
        # ====================================================================
        # UNIT TESTS - Struct Fields
        # ====================================================================
        
        Test.@testset "Struct Fields" begin
            # All solver structs should have an 'options' field of type StrategyOptions
            # Note: We can't construct solvers without extensions, but we can check field names
            Test.@test :options in fieldnames(Solvers.Ipopt)
            # Commented out - no Knitro license available
            # Test.@test :options in fieldnames(Solvers.Knitro)
            Test.@test :options in fieldnames(Solvers.MadNLP)
            Test.@test :options in fieldnames(Solvers.MadNCL)
            
            # Check that there's only one field
            Test.@test length(fieldnames(Solvers.Ipopt)) == 1
            # Commented out - no Knitro license available
            # Test.@test length(fieldnames(Solvers.Knitro)) == 1
            Test.@test length(fieldnames(Solvers.MadNLP)) == 1
            Test.@test length(fieldnames(Solvers.MadNCL)) == 1
        end
    end
end

end # module

test_solver_types() = TestSolverTypes.test_solver_types()
