"""
Integration tests for strict/permissive validation with real strategies.

Tests that the mode parameter works correctly with actual solver and modeler types.
"""

module TestRealStrategiesMode

import Test
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Modelers
import CTSolvers.Solvers

# Load extensions if available for testing
try
    import NLPModelsIpopt
    import MadNLP
    import MadNLPMumps
catch
    # Extension packages might not be available in standard test environment
end

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Test Function
# ============================================================================

function test_real_strategies_mode()
    Test.@testset "Real Strategies Mode Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # INTEGRATION TESTS - Real Modelers
        # ====================================================================
        
        Test.@testset "Modelers.ADNLP Mode Validation" begin
            
            Test.@testset "Strict mode rejects unknown options" begin
                # Should throw error for unknown option
                Test.@test_throws Exception Modelers.ADNLP(
                    backend=:default,
                    unknown_option=123
                )
                
                # Verify it's the right kind of error
                try
                    Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123
                    )
                    Test.@test false  # Should not reach here
                catch e
                    Test.@test occursin("Unknown", string(e)) || occursin("Unrecognized", string(e))
                end
            end
            
            Test.@testset "Strict mode accepts known options" begin
                # Should work with known options
                modeler = Modelers.ADNLP(
                    backend=:default,
                    show_time=true
                )
                Test.@test modeler isa Modelers.ADNLP
                Test.@test Strategies.option_value(modeler, :backend) == :default
                Test.@test Strategies.option_value(modeler, :show_time) == true
                Test.@test Strategies.option_source(modeler, :backend) == :user
                Test.@test Strategies.option_source(modeler, :show_time) == :user
            end
            
            Test.@testset "Permissive mode accepts unknown options" begin
                # Should work with warning
                redirect_stderr(devnull) do
                    modeler = Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123;
                        mode=:permissive
                    )
                    Test.@test modeler isa Modelers.ADNLP
                    
                    # Unknown option should be stored
                    Test.@test Strategies.has_option(modeler, :unknown_option)
                    Test.@test Strategies.option_value(modeler, :unknown_option) == 123
                    Test.@test Strategies.option_source(modeler, :unknown_option) == :user
                end
            end
            
            Test.@testset "Permissive mode validates known options" begin
                # Type validation should still work
                redirect_stderr(devnull) do
                    Test.@test_throws Exception Modelers.ADNLP(
                        backend=:default,
                        show_time="invalid";
                        mode=:permissive
                    )
                end
            end
        end
        
        Test.@testset "Modelers.Exa Mode Validation" begin
            
            Test.@testset "Strict mode rejects unknown options" begin
                # Should throw error for unknown option
                Test.@test_throws Exception Modelers.Exa(
                    backend=nothing,
                    unknown_option=123
                )
            end
            
            Test.@testset "Strict mode accepts known options" begin
                # Should work with known options
                modeler = Modelers.Exa(
                    backend=nothing
                )
                Test.@test modeler isa Modelers.Exa
                Test.@test Strategies.option_value(modeler, :backend) === nothing
            end
            
            Test.@testset "Permissive mode accepts unknown options" begin
                # Should work with warning
                redirect_stderr(devnull) do
                    modeler = Modelers.Exa(
                        backend=nothing,
                        unknown_option=123;
                        mode=:permissive
                    )
                    Test.@test modeler isa Modelers.Exa
                    Test.@test Strategies.has_option(modeler, :unknown_option)
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Real Solvers (if extensions available)
        # ====================================================================
        
        Test.@testset "Solver Mode Validation" begin
            # Test with any available solver extensions
            available_solvers = []
            
            # Check for available solver extensions
            if isdefined(CTSolvers, :Solvers) && isdefined(Solvers, :Ipopt)
                push!(available_solvers, Solvers.Ipopt)
            end
            
            if isdefined(CTSolvers, :Solvers) && isdefined(Solvers, :MadNLP)
                push!(available_solvers, Solvers.MadNLP)
            end
            
            if isempty(available_solvers)
                Test.@testset "No solver extensions available" begin
                    Test.@test_skip "No solver extensions available for testing"
                end
                return
            end
            
            for solver_type in available_solvers
                Test.@testset "$(nameof(solver_type)) Mode Validation" begin
                    
                    Test.@testset "Strict mode rejects unknown options" begin
                        # Should throw error for unknown option
                        Test.@test_throws Exception solver_type(
                            max_iter=1000,
                            unknown_option=123
                        )
                    end
                    
                    Test.@testset "Strict mode accepts known options" begin
                        # Should work with known options
                        solver = solver_type(max_iter=1000)
                        Test.@test solver isa solver_type
                        Test.@test Strategies.option_value(solver, :max_iter) == 1000
                        Test.@test Strategies.option_source(solver, :max_iter) == :user
                    end
                    
                    Test.@testset "Permissive mode accepts unknown options" begin
                        # Should work with warning
                        redirect_stderr(devnull) do
                            solver = solver_type(
                                max_iter=1000,
                                unknown_option=123;
                                mode=:permissive
                            )
                            Test.@test solver isa solver_type
                            Test.@test Strategies.has_option(solver, :unknown_option)
                        end
                    end
                    
                    Test.@testset "Permissive mode validates known options" begin
                        # Type validation should still work
                        redirect_stderr(devnull) do
                            Test.@test_throws Exception solver_type(
                                max_iter="invalid";
                                mode=:permissive
                            )
                        end
                    end
                end
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Mode Parameter Propagation
        # ====================================================================
        
        Test.@testset "Mode Parameter Propagation" begin
            
            Test.@testset "Default mode is strict" begin
                # Without specifying mode, should be strict
                Test.@test_throws Exception Modelers.ADNLP(
                    backend=:default,
                    unknown_option=123
                )
            end
            
            Test.@testset "Explicit strict same as default" begin
                # Explicit :strict should behave same as default
                error1 = nothing
                error2 = nothing
                
                try
                    Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123
                    )
                catch e
                    error1 = e
                end
                
                try
                    Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123;
                        mode=:strict
                    )
                catch e
                    error2 = e
                end
                
                Test.@test error1 !== nothing
                Test.@test error2 !== nothing
                Test.@test typeof(error1) == typeof(error2)
            end
            
            Test.@testset "Mode parameter validation" begin
                # Invalid mode should throw error
                Test.@test_throws Exception Modelers.ADNLP(
                    backend=:default;
                    mode=:invalid
                )
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Option Sources
        # ====================================================================
        
        Test.@testset "Option Source Tracking" begin
            
            Test.@testset "Known options have :user source" begin
                modeler = Modelers.ADNLP(
                    backend=:default,
                    show_time=true
                )
                Test.@test Strategies.option_source(modeler, :backend) == :user
                Test.@test Strategies.option_source(modeler, :show_time) == :user
            end
            
            Test.@testset "Unknown options have :user source in permissive" begin
                redirect_stderr(devnull) do
                    modeler = Modelers.ADNLP(
                        backend=:default,
                        unknown_option=123;
                        mode=:permissive
                    )
                    Test.@test Strategies.option_source(modeler, :unknown_option) == :user
                end
            end
            
            Test.@testset "Default options have :default source" begin
                modeler = Modelers.ADNLP()
                Test.@test Strategies.option_source(modeler, :backend) == :default
            end
        end
        
        # ====================================================================
        # INTEGRATION TESTS - Mixed Options
        # ====================================================================
        
        Test.@testset "Mixed Known/Unknown Options" begin
            
            Test.@testset "Strict mode rejects mix" begin
                # Should throw even with known options present
                Test.@test_throws Exception Modelers.ADNLP(
                    backend=:default,
                    show_time=true,
                    unknown_option=123
                )
            end
            
            Test.@testset "Permissive mode accepts mix" begin
                # Should work with both known and unknown
                redirect_stderr(devnull) do
                    modeler = Modelers.ADNLP(
                        backend=:default,
                        show_time=true,
                        unknown_option=123,
                        another_unknown="test";
                        mode=:permissive
                    )
                    Test.@test modeler isa Modelers.ADNLP
                    Test.@test Strategies.option_value(modeler, :backend) == :default
                    Test.@test Strategies.option_value(modeler, :show_time) == true
                    Test.@test Strategies.option_value(modeler, :unknown_option) == 123
                    Test.@test Strategies.option_value(modeler, :another_unknown) == "test"
                end
            end
            
            Test.@testset "Known options still validated in permissive" begin
                # Type validation should still work for known options
                redirect_stderr(devnull) do
                    Test.@test_throws Exception Modelers.ADNLP(
                        backend=:default,
                        show_time="invalid",  # Wrong type (Bool expected)
                        unknown_option=123;
                        mode=:permissive
                    )
                end
            end
        end
    end
end

end # module

# Export test function to outer scope
test_real_strategies_mode() = TestRealStrategiesMode.test_real_strategies_mode()
