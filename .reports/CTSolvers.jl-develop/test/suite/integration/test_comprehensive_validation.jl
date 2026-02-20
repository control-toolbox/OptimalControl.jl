"""
Comprehensive tests for strict/permissive validation across all strategies.

This test suite validates that the mode parameter works correctly for:
- All strategy types (modelers and solvers)
- All construction methods (direct, build_strategy, build_strategy_from_method, orchestration wrapper)
- All validation modes (strict, permissive)
- All option types (known, unknown, defaults)

Author: CTSolvers Development Team
Date: 2026-02-06
"""

module TestComprehensiveValidation

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options
import CTSolvers.Modelers
import CTSolvers.Solvers
import CTSolvers.Orchestration
import CTSolvers.Optimization

# Load extensions if available for testing
const IPOPT_AVAILABLE = try
    import NLPModelsIpopt
    true
catch
    false
end

const MADNLP_AVAILABLE = try
    import MadNLP
    import MadNLPMumps
    true
catch
    false
end

const MADNCL_AVAILABLE = try
    import MadNLP
    import MadNLPMumps
    import MadNCL
    true
catch
    false
end

# const KNITRO_AVAILABLE = try
#     import NLPModelsKnitro
#     import KNITRO
#     # Test if license is available
#     kc = KNITRO.KN_new()
#     KNITRO.KN_free(kc)
#     true
# catch e
#     if occursin("license", lowercase(string(e))) || occursin("-520", string(e))
#         false
#     else
#         false  # Any error means not available for testing
#     end
# end

# Always false - no license available
const KNITRO_AVAILABLE = false

# Test options for verbose output
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Utility Functions
# ============================================================================

"""
Test strategy construction with all methods for a given strategy type.

# Arguments
- `strategy_type`: The concrete strategy type to test
- `strategy_id`: The strategy ID symbol
- `family`: The abstract family type
- `known_options`: NamedTuple of known valid options
- `unknown_options`: NamedTuple of unknown options
- `registry`: Strategy registry to use
"""
function test_strategy_construction(
    strategy_type::Type,
    strategy_id::Symbol,
    family::Type{<:Strategies.AbstractStrategy},
    known_options::NamedTuple,
    unknown_options::NamedTuple,
    registry::Strategies.StrategyRegistry
)
    Test.@testset "Strategy Construction - $(strategy_type)" begin
        
        # ====================================================================
        # 1. Direct Constructor Tests
        # ====================================================================
        
        Test.@testset "Direct Constructor" begin
            Test.@testset "Strict Mode" begin
                # Known options only - should work
                Test.@test_nowarn strategy_type(; known_options...)
                strategy = strategy_type(; known_options...)
                Test.@test strategy isa strategy_type
                
                # Unknown option - should throw
                Test.@test_throws Exceptions.IncorrectArgument strategy_type(; known_options..., unknown_options...)
                
                # Verify error quality
                try
                    strategy_type(; known_options..., unknown_options...)
                    Test.@test false  # Should not reach here
                catch e
                    Test.@test e isa Exceptions.IncorrectArgument
                    Test.@test occursin("unknown", string(e)) || occursin("unrecognized", string(e)) || occursin("Invalid", string(e)) || occursin("not defined", string(e))
                end
            end
            
            Test.@testset "Permissive Mode" begin
                # Known + unknown options - should work with warning
                Test.@test_warn "Unrecognized options" strategy_type(; known_options..., unknown_options..., mode=:permissive)
                strategy = strategy_type(; known_options..., unknown_options..., mode=:permissive)
                Test.@test strategy isa strategy_type
                
                # Verify mode is NOT stored in options (correct behavior)
                Test.@test_throws Exception strategy.options.mode
            end
        end
        
        # ====================================================================
        # 2. build_strategy() Tests
        # ====================================================================
        
        Test.@testset "build_strategy()" begin
            Test.@testset "Strict Mode" begin
                # Known options only - should work
                Test.@test_nowarn Strategies.build_strategy(strategy_id, family, registry; known_options...)
                strategy = Strategies.build_strategy(strategy_id, family, registry; known_options...)
                Test.@test strategy isa strategy_type
                
                # Unknown option - should throw
                Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy(strategy_id, family, registry; known_options..., unknown_options...)
            end
            
            Test.@testset "Permissive Mode" begin
                # Known + unknown options - should work
                Test.@test_warn "Unrecognized options" Strategies.build_strategy(strategy_id, family, registry; known_options..., unknown_options..., mode=:permissive)
                strategy = Strategies.build_strategy(strategy_id, family, registry; known_options..., unknown_options..., mode=:permissive)
                Test.@test strategy isa strategy_type
                                # Verify mode is NOT stored in options (correct behavior)
                Test.@test_throws Exception strategy.options.mode
            end
        end
        
        # ====================================================================
        # 3. build_strategy_from_method() Tests
        # ====================================================================
        
        Test.@testset "build_strategy_from_method()" begin
            # Create method tuple with strategy ID
            method = if family == Modelers.AbstractNLPModeler
                (:collocation, strategy_id, :ipopt)
            else
                (:collocation, :adnlp, strategy_id)
            end
            
            Test.@testset "Strict Mode" begin
                # Known options only - should work
                Test.@test_nowarn Strategies.build_strategy_from_method(method, family, registry; known_options...)
                strategy = Strategies.build_strategy_from_method(method, family, registry; known_options...)
                Test.@test strategy isa strategy_type
                
                # Unknown option - should throw
                Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy_from_method(method, family, registry; known_options..., unknown_options...)
            end
            
            Test.@testset "Permissive Mode" begin
                # Known + unknown options - should work
                Test.@test_warn "Unrecognized options" Strategies.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                strategy = Strategies.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                Test.@test strategy isa strategy_type
                                # Verify mode is NOT stored in options (correct behavior)
                Test.@test_throws Exception strategy.options.mode
            end
        end
        
        # ====================================================================
        # 4. Orchestration Wrapper Tests
        # ====================================================================
        
        Test.@testset "Orchestration Wrapper" begin
            method = if family == Modelers.AbstractNLPModeler
                (:collocation, strategy_id, :ipopt)
            else
                (:collocation, :adnlp, strategy_id)
            end
            
            Test.@testset "Strict Mode" begin
                # Known options only - should work
                Test.@test_nowarn Orchestration.build_strategy_from_method(method, family, registry; known_options...)
                strategy = Orchestration.build_strategy_from_method(method, family, registry; known_options...)
                Test.@test strategy isa strategy_type
                
                # Unknown option - should throw
                Test.@test_throws Exceptions.IncorrectArgument Orchestration.build_strategy_from_method(method, family, registry; known_options..., unknown_options...)
            end
            
            Test.@testset "Permissive Mode" begin
                # Known + unknown options - should work
                Test.@test_warn "Unrecognized options" Orchestration.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                strategy = Orchestration.build_strategy_from_method(method, family, registry; known_options..., unknown_options..., mode=:permissive)
                Test.@test strategy isa strategy_type
                                # Verify mode is NOT stored in options (correct behavior)
                Test.@test_throws Exception strategy.options.mode
            end
        end
    end
end

"""
Test option recovery for a constructed strategy.

# Arguments
- `strategy`: The constructed strategy instance
- `known_options`: NamedTuple of known options that were passed
- `unknown_options`: NamedTuple of unknown options that were passed (empty for strict mode)
- `mode`: The validation mode used
"""
function test_option_recovery(
    strategy::Strategies.AbstractStrategy,
    known_options::NamedTuple,
    unknown_options::NamedTuple,
    mode::Symbol
)
    Test.@testset "Option Recovery - $(typeof(strategy))" begin
        # Test known options
        for (name, value) in pairs(known_options)
            Test.@test Strategies.has_option(strategy, name)
            Test.@test Strategies.option_value(strategy, name) == value
            Test.@test Strategies.option_source(strategy, name) == :user
        end
        
        # Test unknown options (only in permissive mode)
        if mode == :permissive
            for (name, value) in pairs(unknown_options)
                Test.@test Strategies.has_option(strategy, name)
                Test.@test Strategies.option_value(strategy, name) == value
                Test.@test Strategies.option_source(strategy, name) == :user
            end
        else
            # In strict mode, unknown options should not be present
            for (name, _) in pairs(unknown_options)
                Test.@test !has_option(strategy, name)
            end
        end
        
        # Test mode is NOT stored in options (correct behavior)
        Test.@test_throws Exception strategy.options.mode
        
        # Test some default options (should be present with :default source)
        metadata_def = Strategies.metadata(typeof(strategy))
        for (name, definition) in pairs(metadata_def)
            if !(definition.default isa Options.NotProvidedType) && !haskey(known_options, name)
                Test.@test Strategies.has_option(strategy, name)
                Test.@test Strategies.option_source(strategy, name) == :default
            end
        end
    end
end

"""
Test error quality for invalid mode parameter.
"""
function test_invalid_mode(strategy_type::Type)
    Test.@testset "Invalid Mode Tests - $(strategy_type)" begin
        Test.@test_throws Exceptions.IncorrectArgument strategy_type(; mode=:invalid)
        Test.@test_throws Exceptions.IncorrectArgument Strategies.build_strategy(:test, Strategies.AbstractStrategy, Strategies.create_registry(); mode=:invalid)
    end
end

# ============================================================================
# Main Test Function
# ============================================================================

function test_comprehensive_validation()
    Test.@testset "Comprehensive Strict/Permissive Validation" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # Create registries for testing
        modeler_registry = Strategies.create_registry(
            Modelers.AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa)
        )
        
        # Create solver registry based on available extensions
        solver_types = []
        IPOPT_AVAILABLE && push!(solver_types, Solvers.Ipopt)
        MADNLP_AVAILABLE && push!(solver_types, Solvers.MadNLP)
        MADNCL_AVAILABLE && push!(solver_types, Solvers.MadNCL)
        # KNITRO_AVAILABLE && push!(solver_types, Solvers.Knitro)  # Never available - no license
        
        solver_registry = if isempty(solver_types)
            Strategies.create_registry(Solvers.AbstractNLPSolver => ())
        else
            Strategies.create_registry(Solvers.AbstractNLPSolver => tuple(solver_types...))
        end
        
        # ====================================================================
        # TESTS FOR MODELERS
        # ====================================================================
        
        Test.@testset "Modelers" begin
            
            # ----------------------------------------------------------------
            # Modelers.ADNLP Tests
            # ----------------------------------------------------------------
            
            Test.@testset "Modelers.ADNLP" begin
                known_options = (backend=:default, show_time=true)
                unknown_options = (fake_option=123, custom_param="test")
                
                # Test all construction methods - redirect stderr to hide warnings
                redirect_stderr(devnull) do
                    test_strategy_construction(
                        Modelers.ADNLP, :adnlp, Modelers.AbstractNLPModeler,
                        known_options, unknown_options, modeler_registry
                    )
                end
                
                # Test option recovery for successful constructions
                Test.@testset "Option Recovery" begin
                    # Strict mode - known options only
                    strategy_strict = Modelers.ADNLP(; known_options...)
                    test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                    
                    # Permissive mode - known + unknown options
                    redirect_stderr(devnull) do
                        strategy_permissive = Modelers.ADNLP(; known_options..., unknown_options..., mode=:permissive)
                        test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                    end
                    
                    # Test build_strategy option recovery
                    redirect_stderr(devnull) do
                        strategy_build = Strategies.build_strategy(:adnlp, Modelers.AbstractNLPModeler, modeler_registry; known_options..., unknown_options..., mode=:permissive)
                        test_option_recovery(strategy_build, known_options, unknown_options, :permissive)
                    end
                end
                
                # Test invalid mode
                test_invalid_mode(Modelers.ADNLP)
            end
            
            # ----------------------------------------------------------------
            # Modelers.Exa Tests
            # ----------------------------------------------------------------
            
            Test.@testset "Modelers.Exa" begin
                known_options = (base_type=Float64, backend=:dense)
                unknown_options = (exa_fake=456, unknown_setting=true)
                
                # Test all construction methods - redirect stderr to hide warnings
                redirect_stderr(devnull) do
                    test_strategy_construction(
                        Modelers.Exa, :exa, Modelers.AbstractNLPModeler,
                        known_options, unknown_options, modeler_registry
                    )
                end
                
                # Test option recovery
                Test.@testset "Option Recovery" begin
                    strategy_strict = Modelers.Exa(; known_options...)
                    test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                    
                    redirect_stderr(devnull) do
                        strategy_permissive = Modelers.Exa(; known_options..., unknown_options..., mode=:permissive)
                        test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                    end
                end
                
                # Test invalid mode
                test_invalid_mode(Modelers.Exa)
            end
        end
        
        # ====================================================================
        # TESTS FOR SOLVERS (conditional based on available extensions)
        # ====================================================================
        
        Test.@testset "Solvers" begin
            
            # ----------------------------------------------------------------
            # Solvers.Ipopt Tests (if available)
            # ----------------------------------------------------------------
            
            if IPOPT_AVAILABLE
                Test.@testset "Solvers.Ipopt" begin
                    # Note: Solvers.Ipopt options are defined in the extension
                    # We'll use some common options that are typically available
                    known_options = (max_iter=1000, tol=1e-6)
                    unknown_options = (ipopt_fake=789, custom_ipopt_opt="value")
                    
                    # Test all construction methods - redirect stderr to hide warnings
                    redirect_stderr(devnull) do
                        test_strategy_construction(
                            Solvers.Ipopt, :ipopt, Solvers.AbstractNLPSolver,
                            known_options, unknown_options, solver_registry
                        )
                    end
                    
                    # Test option recovery
                    Test.@testset "Option Recovery" begin
                        strategy_strict = Solvers.Ipopt(; known_options...)
                        test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
                        redirect_stderr(devnull) do
                            strategy_permissive = Solvers.Ipopt(; known_options..., unknown_options..., mode=:permissive)
                            test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                        end
                    end
                    
                    # Test invalid mode
                    test_invalid_mode(Solvers.Ipopt)
                end
            else
                Test.@testset "Solvers.Ipopt (Not Available)" begin
                    Test.@test_skip "NLPModelsIpopt not available"
                end
            end
            
            # ----------------------------------------------------------------
            # Solvers.MadNLP Tests (if available)
            # ----------------------------------------------------------------
            
            if MADNLP_AVAILABLE
                Test.@testset "Solvers.MadNLP" begin
                    known_options = (max_iter=500, tol=1e-8)
                    unknown_options = (madnlp_fake=111, custom_madnlp=true)
                    
                    redirect_stderr(devnull) do
                        test_strategy_construction(
                            Solvers.MadNLP, :madnlp, Solvers.AbstractNLPSolver,
                            known_options, unknown_options, solver_registry
                        )
                    end
                    
                    Test.@testset "Option Recovery" begin
                        strategy_strict = Solvers.MadNLP(; known_options...)
                        test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
                        redirect_stderr(devnull) do
                            strategy_permissive = Solvers.MadNLP(; known_options..., unknown_options..., mode=:permissive)
                            test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                        end
                    end
                    
                    test_invalid_mode(Solvers.MadNLP)
                end
            else
                Test.@testset "Solvers.MadNLP (Not Available)" begin
                    Test.@test_skip "MadNLP not available"
                end
            end
            
            # ----------------------------------------------------------------
            # Solvers.MadNCL Tests (if available)
            # ----------------------------------------------------------------
            
            if MADNCL_AVAILABLE
                Test.@testset "Solvers.MadNCL" begin
                    known_options = (max_iter=300, tol=1e-10)
                    unknown_options = (madncl_fake=222, custom_ncl_opt=3.14)
                    
                    redirect_stderr(devnull) do
                        test_strategy_construction(
                            Solvers.MadNCL, :madncl, Solvers.AbstractNLPSolver,
                            known_options, unknown_options, solver_registry
                        )
                    end
                    
                    Test.@testset "Option Recovery" begin
                        strategy_strict = Solvers.MadNCL(; known_options...)
                        test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
                        redirect_stderr(devnull) do
                            strategy_permissive = Solvers.MadNCL(; known_options..., unknown_options..., mode=:permissive)
                            test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
                        end
                    end
                    
                    test_invalid_mode(Solvers.MadNCL)
                end
            else
                Test.@testset "Solvers.MadNCL (Not Available)" begin
                    Test.@test_skip "MadNCL not available"
                end
            end
            
            # ----------------------------------------------------------------
            # Solvers.Knitro Tests (if available)
            # ----------------------------------------------------------------
            
            # Commented out - no license available
            # if KNITRO_AVAILABLE
            #     Test.@testset "Solvers.Knitro" begin
            #         known_options = (maxit=200, feastol_abs=1e-12)
            #         unknown_options = (knitro_fake=333, custom_knitro="test")
                    
            #         test_strategy_construction(
            #             Solvers.Knitro, :knitro, Solvers.AbstractNLPSolver,
            #             known_options, unknown_options, solver_registry
            #         )
                    
            #         Test.@testset "Option Recovery" begin
            #             strategy_strict = Solvers.Knitro(; known_options...)
            #             test_option_recovery(strategy_strict, known_options, NamedTuple(), :strict)
                        
            #             strategy_permissive = Solvers.Knitro(; known_options..., unknown_options..., mode=:permissive)
            #             test_option_recovery(strategy_permissive, known_options, unknown_options, :permissive)
            #         end
                    
            #         test_invalid_mode(Solvers.Knitro)
            #     end
            # else
            #     Test.@testset "Solvers.Knitro (Not Available)" begin
            #         Test.@test_skip "NLPModelsKnitro not available or no license"
            #     end
            # end
        end
        
        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================
        
        Test.@testset "Integration Tests" begin
            Test.@testset "Mode Propagation" begin
                # Test that mode is correctly propagated through different construction methods
                registry = modeler_registry
                
                # Direct constructor - mode should NOT be stored in options
                modeler1 = Modelers.ADNLP(backend=:default; mode=:permissive)
                # Test.@test modeler1.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # build_strategy - mode should NOT be stored in options  
                modeler2 = Strategies.build_strategy(:adnlp, Modelers.AbstractNLPModeler, registry; backend=:default, mode=:permissive)
                # Test.@test modeler2.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # build_strategy_from_method - mode should NOT be stored in options
                method = (:collocation, :adnlp, :ipopt)
                modeler3 = Strategies.build_strategy_from_method(method, Modelers.AbstractNLPModeler, registry; backend=:default, mode=:permissive)
                # Test.@test modeler3.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # Orchestration wrapper - mode should NOT be stored in options
                modeler4 = Orchestration.build_strategy_from_method(method, Modelers.AbstractNLPModeler, registry; backend=:default, mode=:permissive)
                # Test.@test modeler4.options.mode == :permissive  # WRONG - mode should NOT be stored
                
                # CORRECT: Verify mode is NOT stored in options
                Test.@test_throws Exception modeler1.options.mode
                Test.@test_throws Exception modeler2.options.mode
                Test.@test_throws Exception modeler3.options.mode
                Test.@test_throws Exception modeler4.options.mode
            end
            
            Test.@testset "Error Quality" begin
                # Test that error messages are helpful
                try
                    Modelers.ADNLP(backend=:default, completely_unknown_option=999)
                    Test.@test false  # Should not reach here
                catch e
                    Test.@test e isa Exceptions.IncorrectArgument
                    Test.@test occursin("completely_unknown_option", string(e))
                    Test.@test occursin("unknown", string(e)) || occursin("unrecognized", string(e))
                end
                
                # Test invalid mode error
                try
                    Modelers.ADNLP(backend=:default; mode=:totally_invalid)
                    Test.@test false  # Should not reach here
                catch e
                    Test.@test e isa Exceptions.IncorrectArgument
                    Test.@test occursin("mode", string(e))
                    Test.@test occursin("strict", string(e)) || occursin("permissive", string(e))
                end
            end
            
            Test.@testset "Option Consistency" begin
                # Test that options are consistent across construction methods
                local known_options = (backend=:default, show_time=false)
                local unknown_options = (test_consistency=42)
                
                local registry = Strategies.create_registry(
                    Modelers.AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa)
                )
                
                # Create strategies with different methods - redirect stderr to hide warnings
                redirect_stderr(devnull) do
                    modeler1 = Modelers.ADNLP(; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                    modeler2 = Strategies.build_strategy(:adnlp, Modelers.AbstractNLPModeler, registry; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                    
                    method = (:collocation, :adnlp, :ipopt)
                    modeler3 = Strategies.build_strategy_from_method(method, Modelers.AbstractNLPModeler, registry; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                    modeler4 = Orchestration.build_strategy_from_method(method, Modelers.AbstractNLPModeler, registry; backend=:default, show_time=false, test_consistency=42, mode=:permissive)
                    
                    # Test that all have the same options
                    strategies = [modeler1, modeler2, modeler3, modeler4]
                    
                    for strategy in strategies
                        Test.@test Strategies.option_value(strategy, :backend) == :default
                        Test.@test Strategies.option_value(strategy, :show_time) == false
                        Test.@test Strategies.option_value(strategy, :test_consistency) == 42
                        Test.@test Strategies.option_source(strategy, :backend) == :user
                        Test.@test Strategies.option_source(strategy, :show_time) == :user
                        Test.@test Strategies.option_source(strategy, :test_consistency) == :user
                        # Verify mode is NOT stored in options (correct behavior)
                        Test.@test_throws Exception strategy.options.mode
                    end
                end
            end
        end
        
        # ====================================================================
        # REGRESSION TESTS
        # ====================================================================
        
        Test.@testset "Regression Tests" begin
            Test.@testset "Empty Options" begin
                # Test that strategies can be created with no options
                Test.@test_nowarn Modelers.ADNLP()
                Test.@test_nowarn Modelers.ADNLP(; mode=:permissive)
                
                # Test mode is NOT stored in options (correct behavior)
                modeler = Modelers.ADNLP()
                Test.@test_throws Exception modeler.options.mode  # Default
                
                modeler_permissive = Modelers.ADNLP(; mode=:permissive)
                Test.@test_throws Exception modeler_permissive.options.mode
            end
            
            Test.@testset "Mixed Valid/Invalid Options" begin
                # Test with a mix of valid and invalid options
                Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(
                    backend=:default,  # valid
                    show_time=true,    # valid  
                    fake_option=123,   # invalid
                    another_fake=456   # invalid
                )
                
                # In permissive mode, should work with warnings
                redirect_stderr(devnull) do
                    Test.@test_warn "Unrecognized options" Modelers.ADNLP(
                        backend=:default,  # valid
                        show_time=true,    # valid
                        fake_option=123,   # invalid but accepted
                        another_fake=456;   # invalid but accepted
                        mode=:permissive
                    )
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_comprehensive_validation() = TestComprehensiveValidation.test_comprehensive_validation()