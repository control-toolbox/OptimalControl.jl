"""
Unit tests for mode parameter validation and behavior.

Tests the mode parameter itself: validation, default behavior, and error handling.
"""
module TestValidationMode

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Solvers
import NLPModelsIpopt

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_validation_mode()
    Test.@testset "Mode Parameter Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Mode Parameter Validation
        # ====================================================================
        
        Test.@testset "Valid Modes Accepted" begin
            # :strict should work
            opts = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, mode=:strict)
            Test.@test opts[:max_iter] == 100
            
            # :permissive should work
            opts = Test.@test_logs (:warn,) match_mode=:any begin
                Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, custom=1, mode=:permissive)
            end
            Test.@test opts[:max_iter] == 100
        end
        
        Test.@testset "Invalid Mode Rejected" begin
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, mode=:invalid)
            end
            
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; mode=:wrong)
            end
        end
        
        Test.@testset "Invalid Mode Error Message" begin
            try
                Strategies.build_strategy_options(Solvers.Ipopt; mode=:invalid)
                Test.@test false
            catch e
                msg = string(e)
                Test.@test occursin("Invalid", msg) || occursin("mode", msg)
                Test.@test occursin(":strict", msg)
                Test.@test occursin(":permissive", msg)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Default Mode Behavior
        # ====================================================================
        
        Test.@testset "Default Mode is Strict" begin
            # Without mode parameter, should behave as strict
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; unknown_option=123)
            end
        end
        
        Test.@testset "Explicit Strict Same as Default" begin
            # Explicit mode=:strict should be identical to default
            try
                Strategies.build_strategy_options(Solvers.Ipopt; unknown=123)
                Test.@test false
            catch e1
                try
                    Strategies.build_strategy_options(Solvers.Ipopt; unknown=123, mode=:strict)
                    Test.@test false
                catch e2
                    # Both should throw the same type of error
                    Test.@test typeof(e1) == typeof(e2)
                end
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Mode Parameter Type
        # ====================================================================
        
        Test.@testset "Mode Must Be Symbol" begin
            # String should not work
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; mode="strict")
            end
        end
    end
end

end # module

# Export test function to outer scope
test_validation_mode() = TestValidationMode.test_validation_mode()
