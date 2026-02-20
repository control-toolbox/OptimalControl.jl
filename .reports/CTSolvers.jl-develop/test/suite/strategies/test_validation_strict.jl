"""
Unit tests for strict mode validation in strategy option building.

Tests the behavior of build_strategy_options() in strict mode (default),
ensuring unknown options are rejected with helpful error messages.
"""
module TestValidationStrict

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Solvers
import CTSolvers.Options
import NLPModelsIpopt
import CTBase.Exceptions

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_validation_strict()
    Test.@testset "Strict Mode Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Known Options Accepted
        # ====================================================================
        
        Test.@testset "Known Options Accepted" begin
            # Test with single known option
            opts = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100)
            Test.@test opts[:max_iter] == 100
            Test.@test Strategies.source(opts, :max_iter) == :user
            
            # Test with multiple known options
            opts = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=200, tol=1e-6)
            Test.@test opts[:max_iter] == 200
            Test.@test opts[:tol] == 1e-6
            
            # Test with alias
            opts = Strategies.build_strategy_options(Solvers.Ipopt; maxiter=300)
            Test.@test opts[:max_iter] == 300  # Alias resolved to primary name
        end
        
        # ====================================================================
        # UNIT TESTS - Default Options Used
        # ====================================================================
        
        Test.@testset "Default Options Used" begin
            opts = Strategies.build_strategy_options(Solvers.Ipopt)
            Test.@test Strategies.source(opts, :max_iter) == :default
            Test.@test Strategies.source(opts, :tol) == :default
        end
        
        # ====================================================================
        # UNIT TESTS - Unknown Options Rejected
        # ====================================================================
        
        Test.@testset "Unknown Option Rejected" begin
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; unknown_option=123)
            end
        end
        
        Test.@testset "Multiple Unknown Options Rejected" begin
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; unknown1=123, unknown2=456)
            end
        end
        
        Test.@testset "Mix Known/Unknown Options Rejected" begin
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; max_iter=1000, unknown=123)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Error Message Quality
        # ====================================================================
        
        Test.@testset "Error Message Contains Unknown Option" begin
            try
                Strategies.build_strategy_options(Solvers.Ipopt; unknown_option=123)
                Test.@test false  # Should not reach here
            catch e
                msg = string(e)
                Test.@test occursin("unknown_option", msg)
                Test.@test occursin("Unknown options", msg) || occursin("Unrecognized options", msg)
            end
        end
        
        Test.@testset "Error Message Contains Suggestions (Typo)" begin
            try
                Strategies.build_strategy_options(Solvers.Ipopt; max_it=1000)  # Typo
                Test.@test false
            catch e
                msg = string(e)
                Test.@test occursin("max_it", msg)
                Test.@test occursin("max_iter", msg)  # Should suggest correct name
            end
        end
        
        Test.@testset "Error Message Contains Available Options" begin
            try
                Strategies.build_strategy_options(Solvers.Ipopt; unknown=123)
                Test.@test false
            catch e
                msg = string(e)
                Test.@test occursin("Available options", msg) || occursin("options:", msg)
                Test.@test occursin("max_iter", msg)
                Test.@test occursin("tol", msg)
            end
        end
        
        Test.@testset "Error Message Suggests Permissive Mode" begin
            try
                Strategies.build_strategy_options(Solvers.Ipopt; custom_opt=123)
                Test.@test false
            catch e
                msg = string(e)
                Test.@test occursin("permissive", msg)
                Test.@test occursin("mode", msg)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Type Validation
        # ====================================================================
        
        Test.@testset "Type Validation Enforced" begin
            # This should fail type validation (max_iter expects Integer)
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy_options(Solvers.Ipopt; max_iter=1.5)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Custom Validation
        # ====================================================================
        
        Test.@testset "Custom Validation Enforced" begin
            # tol must be positive
            redirect_stderr(devnull) do
                Test.@test_throws Exceptions.IncorrectArgument begin
                    Strategies.build_strategy_options(Solvers.Ipopt; tol=-1.0)
                end
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Explicit Strict Mode
        # ====================================================================
        
        Test.@testset "Explicit Strict Mode" begin
            # mode=:strict should behave identically to default
            Test.@test_throws Exceptions.IncorrectArgument begin
                Strategies.build_strategy_options(Solvers.Ipopt; unknown=123, mode=:strict)
            end
            
            # Known options should work
            opts = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, mode=:strict)
            Test.@test opts[:max_iter] == 100
        end
    end
end

end # module

# Export test function to outer scope
test_validation_strict() = TestValidationStrict.test_validation_strict()
