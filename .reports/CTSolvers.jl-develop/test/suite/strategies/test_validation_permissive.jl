"""
Unit tests for permissive mode validation in strategy option building.

Tests the behavior of build_strategy_options() in permissive mode,
ensuring unknown options are accepted with warnings while known options
are still validated.
"""
module TestValidationPermissive

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Solvers
import CTSolvers.Options
import NLPModelsIpopt

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_validation_permissive()
    Test.@testset "Permissive Mode Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Known Options Work Normally
        # ====================================================================
        
        Test.@testset "Known Options Work Normally" begin
            opts = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, mode=:permissive)
            Test.@test opts[:max_iter] == 100
            Test.@test Strategies.source(opts, :max_iter) == :user
        end
        
        # ====================================================================
        # UNIT TESTS - Type Validation Still Applied
        # ====================================================================
        
        Test.@testset "Type Validation Still Applied" begin
            # Type validation should work even in permissive mode for known options
            Test.@test_throws Exception begin
                Strategies.build_strategy_options(Solvers.Ipopt; max_iter=1.5, mode=:permissive)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Custom Validation Still Applied
        # ====================================================================
        
        Test.@testset "Custom Validation Still Applied" begin
            # Custom validation should work even in permissive mode
            redirect_stderr(devnull) do
                Test.@test_throws Exception begin
                    Strategies.build_strategy_options(Solvers.Ipopt; tol=-1.0, mode=:permissive)
                end
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Unknown Options Accepted with Warning
        # ====================================================================
        
        Test.@testset "Unknown Option Accepted with Warning" begin
            # Capture warning
            opts = Test.@test_logs (:warn, r"Unrecognized options") begin
                Strategies.build_strategy_options(Solvers.Ipopt; unknown_option=123, mode=:permissive)
            end
            Test.@test haskey(opts.options, :unknown_option)
            Test.@test opts[:unknown_option] == 123
        end
        
        Test.@testset "Multiple Unknown Options Accepted" begin
            opts = Test.@test_logs (:warn, r"Unrecognized options") begin
                Strategies.build_strategy_options(
                    Solvers.Ipopt;
                    unknown1=123,
                    unknown2=456,
                    mode=:permissive
                )
            end
            Test.@test opts[:unknown1] == 123
            Test.@test opts[:unknown2] == 456
        end
        
        Test.@testset "Mix Known/Unknown Options Accepted" begin
            opts = Test.@test_logs (:warn, r"Unrecognized options") begin
                Strategies.build_strategy_options(
                    Solvers.Ipopt;
                    max_iter=1000,
                    unknown=123,
                    mode=:permissive
                )
            end
            Test.@test opts[:max_iter] == 1000
            Test.@test opts[:unknown] == 123
        end
        
        # ====================================================================
        # UNIT TESTS - Options Have Correct Source
        # ====================================================================
        
        Test.@testset "Unknown Options Have User Source" begin
            opts = Test.@test_logs (:warn,) begin
                Strategies.build_strategy_options(Solvers.Ipopt; custom_opt=123, mode=:permissive)
            end
            Test.@test Strategies.source(opts, :custom_opt) == :user
        end
        
        # ====================================================================
        # UNIT TESTS - Warning Message Quality
        # ====================================================================
        
        Test.@testset "Warning Contains Option List" begin
            # We can't easily test warning content, but we can verify it warns
            Test.@test_logs (:warn,) begin
                Strategies.build_strategy_options(Solvers.Ipopt; custom1=1, custom2=2, mode=:permissive)
            end
        end
        
        # ====================================================================
        # UNIT TESTS - Integration with Known Options
        # ====================================================================
        
        Test.@testset "Permissive Mode Preserves Known Option Behavior" begin
            # Test that known options work exactly the same in permissive mode
            opts_strict = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, tol=1e-6)
            opts_permissive = Strategies.build_strategy_options(Solvers.Ipopt; max_iter=100, tol=1e-6, mode=:permissive)
            
            Test.@test opts_strict[:max_iter] == opts_permissive[:max_iter]
            Test.@test opts_strict[:tol] == opts_permissive[:tol]
            Test.@test Strategies.source(opts_strict, :max_iter) == Strategies.source(opts_permissive, :max_iter)
        end
        
        # ====================================================================
        # UNIT TESTS - Different Value Types
        # ====================================================================
        
        Test.@testset "Unknown Options with Different Types" begin
            opts = Test.@test_logs (:warn,) begin
                Strategies.build_strategy_options(
                    Solvers.Ipopt;
                    custom_int=123,
                    custom_float=1.5,
                    custom_string="test",
                    custom_bool=true,
                    mode=:permissive
                )
            end
            
            Test.@test opts[:custom_int] == 123
            Test.@test opts[:custom_float] == 1.5
            Test.@test opts[:custom_string] == "test"
            Test.@test opts[:custom_bool] == true
        end
    end
end

end # module

# Export test function to outer scope
test_validation_permissive() = TestValidationPermissive.test_validation_permissive()
