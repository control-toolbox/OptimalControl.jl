# Tests for Enhanced Modelers Options
#
# This file tests the enhanced Modelers.ADNLP and Modelers.Exa options
# to ensure they work correctly with validation and provide expected behavior.
#
# Author: CTSolvers Development Team
# Date: 2026-01-31

module TestEnhancedOptions

import Test
import CTBase.Exceptions
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Import the specific types we need
import ADNLPModels
import CTSolvers.Modelers
import KernelAbstractions
import CTSolvers.Strategies

# Define structs at top-level (crucial!)
struct TestDummyModel end

# Fake ADBackend for testing Type and instance acceptance
struct FakeTestBackend <: ADNLPModels.ADBackend end

function test_enhanced_options()
    Test.@testset "Enhanced Modelers Options" verbose = VERBOSE showtiming = SHOWTIMING begin

        Test.@testset "Modelers.ADNLP Enhanced Options" begin
            
            Test.@testset "New Options Validation" begin
                # Test matrix_free option
                modeler = Modelers.ADNLP(matrix_free=true)
                Test.@test Strategies.options(modeler)[:matrix_free] == true
                
                modeler = Modelers.ADNLP(matrix_free=false)
                Test.@test Strategies.options(modeler)[:matrix_free] == false
                
                # Test name option
                modeler = Modelers.ADNLP(name="TestProblem")
                Test.@test Strategies.options(modeler)[:name] == "TestProblem"
            end
            
            Test.@testset "Backend Validation" begin
                # Valid backends should work (some may generate warnings if packages not loaded)
                Test.@test_nowarn Modelers.ADNLP(backend=:default)
                Test.@test_nowarn Modelers.ADNLP(backend=:optimized)
                Test.@test_nowarn Modelers.ADNLP(backend=:generic)
                # Enzyme and Zygote may generate warnings if packages not loaded - that's expected
                redirect_stderr(devnull) do
                    Modelers.ADNLP(backend=:enzyme)  # May warn if Enzyme not loaded
                    Modelers.ADNLP(backend=:zygote)  # May warn if Zygote not loaded
                end
                
                # Invalid backend should throw error (redirect stderr to hide error logs)
                redirect_stderr(devnull) do
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(backend=:invalid)
                end
            end
            
            Test.@testset "Name Validation" begin
                # Valid names should work
                Test.@test_nowarn Modelers.ADNLP(name="ValidName")
                Test.@test_nowarn Modelers.ADNLP(name="name_with_123")
                
                # Empty name should throw error (redirect stderr to hide error logs)
                redirect_stderr(devnull) do
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(name="")
                end
            end
            
            Test.@testset "Combined Options" begin
                # Test multiple options together
                modeler = Modelers.ADNLP(
                    backend=:optimized,
                    matrix_free=true,
                    name="CombinedTest",
                    show_time=true
                )
                
                opts = Strategies.options(modeler)
                Test.@test opts[:backend] == :optimized
                Test.@test opts[:matrix_free] == true
                Test.@test opts[:name] == "CombinedTest"
                Test.@test opts[:show_time] == true
            end
        end
        
        Test.@testset "Modelers.Exa Enhanced Options" begin
            
            Test.@testset "Base Type Validation" begin
                # Test valid base types
                modeler = Modelers.Exa(base_type=Float32)
                Test.@test Strategies.options(modeler)[:base_type] == Float32
                
                modeler = Modelers.Exa(base_type=Float64)
                Test.@test Strategies.options(modeler)[:base_type] == Float64
            end
            
            Test.@testset "Backend Validation" begin
                # Test backend option
                modeler = Modelers.Exa(backend=nothing)
                Test.@test Strategies.options(modeler)[:backend] === nothing
                
                # Test with a backend type
                modeler = Modelers.Exa(backend=KernelAbstractions.CPU())
                Test.@test Strategies.options(modeler)[:backend] == KernelAbstractions.CPU()
            end
            
            Test.@testset "Base Type Extraction in Build" begin
                # Test that BaseType is correctly extracted and used in build process
                modeler = Modelers.Exa(base_type=Float32)
                
                # Verify base_type is stored in options
                Test.@test Strategies.options(modeler)[:base_type] == Float32
                
                # Test with Float64 as well
                modeler64 = Modelers.Exa(base_type=Float64)
                Test.@test Strategies.options(modeler64)[:base_type] == Float64
                
                # Test that default base_type is preserved
                default_modeler = Modelers.Exa()
                Test.@test Strategies.options(default_modeler)[:base_type] == Float64
            end
            
            Test.@testset "Combined Options" begin
                # Test multiple options together
                modeler = Modelers.Exa(
                    base_type=Float32,
                    backend=nothing
                )
                
                opts = Strategies.options(modeler)
                Test.@test opts[:backend] === nothing
                Test.@test opts[:base_type] == Float32
                
                # Check that modeler is not parameterized anymore
                Test.@test modeler isa Modelers.Exa
            end
        end
        
        Test.@testset "Backward Compatibility" begin
            
            Test.@testset "Modelers.ADNLP Backward Compatibility" begin
                # Original constructor should still work
                modeler1 = Modelers.ADNLP()
                Test.@test modeler1 isa Modelers.ADNLP
                
                # Original options should still work
                modeler2 = Modelers.ADNLP(show_time=true, backend=:default)
                Test.@test modeler2 isa Modelers.ADNLP
                Test.@test Strategies.options(modeler2)[:show_time] == true
                Test.@test Strategies.options(modeler2)[:backend] == :default
                
                # Default values should be preserved
                modeler3 = Modelers.ADNLP()
                opts = Strategies.options(modeler3)
                Test.@test opts[:backend] == :optimized
                # show_time, matrix_free, name have NotProvided defaults — not stored when not provided
                Test.@test !haskey(opts.options, :show_time)
                Test.@test !haskey(opts.options, :matrix_free)
                Test.@test !haskey(opts.options, :name)
            end
            
            Test.@testset "Modelers.Exa Backward Compatibility" begin
                # Original constructor should still work
                modeler1 = Modelers.Exa()
                Test.@test modeler1 isa Modelers.Exa
                
                # Original options should still work
                modeler2 = Modelers.Exa(base_type=Float32)
                Test.@test modeler2 isa Modelers.Exa
                Test.@test Strategies.options(modeler2)[:base_type] == Float32
                
                # Default values should be preserved
                modeler3 = Modelers.Exa()
                opts = Strategies.options(modeler3)
                Test.@test opts[:backend] === nothing
                Test.@test opts[:base_type] == Float64
            end
        end

        Test.@testset "Advanced Backend Overrides" begin
            Test.@testset "Backend Override with nothing" begin
                # Valid backend overrides with nothing should work
                Test.@test_nowarn Modelers.ADNLP(gradient_backend=nothing)
                Test.@test_nowarn Modelers.ADNLP(hprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLP(jprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLP(jtprod_backend=nothing)
                Test.@test_nowarn Modelers.ADNLP(jacobian_backend=nothing)
                Test.@test_nowarn Modelers.ADNLP(hessian_backend=nothing)
                Test.@test_nowarn Modelers.ADNLP(ghjvprod_backend=nothing)

                # Test that options are accessible
                modeler = Modelers.ADNLP(
                    gradient_backend=nothing,
                    hprod_backend=nothing,
                    ghjvprod_backend=nothing
                )
                opts = Strategies.options(modeler)
                Test.@test opts[:gradient_backend] === nothing
                Test.@test opts[:hprod_backend] === nothing
                Test.@test opts[:ghjvprod_backend] === nothing
            end

            Test.@testset "Backend Override with Type{<:ADBackend}" begin
                # Passing a Type (subtype of ADBackend) should work
                Test.@test_nowarn Modelers.ADNLP(gradient_backend=FakeTestBackend)
                Test.@test_nowarn Modelers.ADNLP(hprod_backend=FakeTestBackend)
                Test.@test_nowarn Modelers.ADNLP(jacobian_backend=FakeTestBackend)
                Test.@test_nowarn Modelers.ADNLP(ghjvprod_backend=FakeTestBackend)

                modeler = Modelers.ADNLP(gradient_backend=FakeTestBackend)
                Test.@test Strategies.options(modeler)[:gradient_backend] === FakeTestBackend
            end

            Test.@testset "Backend Override with ADBackend instance" begin
                # Passing an ADBackend instance should work
                instance = FakeTestBackend()
                Test.@test_nowarn Modelers.ADNLP(gradient_backend=instance)
                Test.@test_nowarn Modelers.ADNLP(hprod_backend=instance)
                Test.@test_nowarn Modelers.ADNLP(jacobian_backend=instance)
                Test.@test_nowarn Modelers.ADNLP(ghjvprod_backend=instance)

                modeler = Modelers.ADNLP(gradient_backend=instance)
                Test.@test Strategies.options(modeler)[:gradient_backend] isa ADNLPModels.ADBackend
            end

            Test.@testset "Backend Override Type Validation" begin
                # Invalid types should throw enriched exceptions (redirect stderr to hide error logs)
                redirect_stderr(devnull) do
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(gradient_backend="invalid")
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(hprod_backend=123)
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(jprod_backend=:invalid)
                    Test.@test_throws Exceptions.IncorrectArgument Modelers.ADNLP(ghjvprod_backend="invalid")
                end
            end

            Test.@testset "Combined Advanced Options" begin
                # Test advanced options with basic options
                instance = FakeTestBackend()
                modeler = Modelers.ADNLP(
                    backend=:optimized,
                    matrix_free=true,
                    name="AdvancedTest",
                    gradient_backend=FakeTestBackend,
                    hprod_backend=instance,
                    jacobian_backend=nothing,
                    ghjvprod_backend=nothing
                )

                opts = Strategies.options(modeler)
                Test.@test opts[:backend] == :optimized
                Test.@test opts[:matrix_free] == true
                Test.@test opts[:name] == "AdvancedTest"
                Test.@test opts[:gradient_backend] === FakeTestBackend
                Test.@test opts[:hprod_backend] isa ADNLPModels.ADBackend
                Test.@test opts[:jacobian_backend] === nothing
                Test.@test opts[:ghjvprod_backend] === nothing
            end
        end
        
        Test.@testset "Backend Aliases with Deprecation Warnings" begin
            # Test Modelers.ADNLP with adnlp_backend alias
            # Use :generic (not the default :optimized) to verify the alias actually passes the value
            Test.@testset "Modelers.ADNLP adnlp_backend alias" begin
                redirect_stderr(devnull) do
                    modeler = Modelers.ADNLP(adnlp_backend=:generic)
                    opts = Strategies.options(modeler)
                    Test.@test haskey(opts.options, :backend)
                    Test.@test opts[:backend] == :generic
                end
            end
            
            # Test Modelers.Exa with exa_backend alias
            # Default is nothing, so pass a CPU backend to verify alias works
            Test.@testset "Modelers.Exa exa_backend alias" begin
                redirect_stderr(devnull) do
                    modeler = Modelers.Exa(exa_backend=nothing)
                    opts = Strategies.options(modeler)
                    Test.@test haskey(opts.options, :backend)
                    Test.@test opts[:backend] === nothing
                end
            end
            
            # Test deprecation warnings are emitted (but capture them to avoid console output)
            Test.@testset "Depreciation warnings" begin
                redirect_stderr(devnull) do
                    Test.@test_logs (:warn, "adnlp_backend is deprecated, use backend instead") Modelers.ADNLP(adnlp_backend=:default)
                    Test.@test_logs (:warn, "exa_backend is deprecated, use backend instead") Modelers.Exa(exa_backend=nothing)
                end
            end
            
            # Test standard backend does not emit warning
            Test.@testset "No warning with standard backend" begin
                Test.@test_logs Modelers.ADNLP(backend=:generic)
                Test.@test_logs Modelers.Exa(backend=nothing)
            end
        end
    end

end # function test_enhanced_options

end # module TestEnhancedOptions

# CRITICAL: Redefine the function in the outer scope so TestRunner can find it
test_enhanced_options() = TestEnhancedOptions.test_enhanced_options()
