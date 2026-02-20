module TestCoverageValidation

import Test
import CTBase.Exceptions
import CTSolvers.Modelers
import ADNLPModels

# Fake ADBackend for testing (must be at top-level)
struct FakeCoverageBackend <: ADNLPModels.ADBackend end

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_coverage_validation()
    Test.@testset "Coverage: Modelers Validation" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - validate_adnlp_backend
        # ====================================================================

        Test.@testset "validate_adnlp_backend" begin
            # Valid backends
            Test.@test Modelers.validate_adnlp_backend(:default) == :default
            Test.@test Modelers.validate_adnlp_backend(:optimized) == :optimized
            Test.@test Modelers.validate_adnlp_backend(:generic) == :generic
            Test.@test Modelers.validate_adnlp_backend(:manual) == :manual

            # Enzyme/Zygote warnings (packages not loaded) - capture to avoid console output
            redirect_stderr(devnull) do
                Test.@test_logs (:warn,) Modelers.validate_adnlp_backend(:enzyme)
                Test.@test_logs (:warn,) Modelers.validate_adnlp_backend(:zygote)
            end

            # Invalid backend
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_adnlp_backend(:invalid)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_adnlp_backend(:foo)
        end

        # ====================================================================
        # UNIT TESTS - validate_exa_base_type
        # ====================================================================

        Test.@testset "validate_exa_base_type" begin
            # Valid types
            Test.@test Modelers.validate_exa_base_type(Float64) == Float64
            Test.@test Modelers.validate_exa_base_type(Float32) == Float32
            Test.@test Modelers.validate_exa_base_type(Float16) == Float16
            Test.@test Modelers.validate_exa_base_type(BigFloat) == BigFloat

            # Invalid types
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(Int)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(String)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_exa_base_type(Bool)
        end

        # ====================================================================
        # UNIT TESTS - validate_gpu_preference
        # ====================================================================

        Test.@testset "validate_gpu_preference" begin
            # Valid preferences
            Test.@test Modelers.validate_gpu_preference(:cuda) == :cuda
            Test.@test Modelers.validate_gpu_preference(:rocm) == :rocm
            Test.@test Modelers.validate_gpu_preference(:oneapi) == :oneapi

            # Invalid preferences
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_gpu_preference(:invalid)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_gpu_preference(:metal)
        end

        # ====================================================================
        # UNIT TESTS - validate_precision_mode
        # ====================================================================

        Test.@testset "validate_precision_mode" begin
            # Valid modes
            Test.@test Modelers.validate_precision_mode(:standard) == :standard

            # :high and :mixed emit @info
            Test.@test_logs (:info,) Modelers.validate_precision_mode(:high)
            Test.@test_logs (:info,) Modelers.validate_precision_mode(:mixed)

            # Invalid modes
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_precision_mode(:invalid)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_precision_mode(:ultra)
        end

        # ====================================================================
        # UNIT TESTS - validate_model_name
        # ====================================================================

        Test.@testset "validate_model_name" begin
            # Valid names
            Test.@test Modelers.validate_model_name("MyModel") == "MyModel"
            Test.@test Modelers.validate_model_name("test-name") == "test-name"
            Test.@test Modelers.validate_model_name("name_123") == "name_123"

            # Empty name
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_model_name("")

            # Special characters warning
            Test.@test_logs (:warn,) Modelers.validate_model_name("name with spaces")
            Test.@test_logs (:warn,) Modelers.validate_model_name("name.with.dots")
        end

        # ====================================================================
        # UNIT TESTS - validate_matrix_free
        # ====================================================================

        Test.@testset "validate_matrix_free" begin
            # Basic validation
            Test.@test Modelers.validate_matrix_free(true) == true
            Test.@test Modelers.validate_matrix_free(false) == false

            # Large problem recommendation
            Test.@test_logs (:info,) Modelers.validate_matrix_free(false, 200_000)

            # Small problem with matrix_free=true recommendation
            Test.@test_logs (:info,) Modelers.validate_matrix_free(true, 500)

            # No recommendation for normal sizes
            Test.@test Modelers.validate_matrix_free(true, 5000) == true
            Test.@test Modelers.validate_matrix_free(false, 5000) == false
        end

        # ====================================================================
        # UNIT TESTS - validate_optimization_direction
        # ====================================================================

        Test.@testset "validate_optimization_direction" begin
            Test.@test Modelers.validate_optimization_direction(true) == true
            Test.@test Modelers.validate_optimization_direction(false) == false
        end

        # ====================================================================
        # UNIT TESTS - validate_backend_override
        # ====================================================================

        Test.@testset "validate_backend_override" begin
            # Valid overrides: nothing
            Test.@test Modelers.validate_backend_override(nothing) === nothing
            # Valid overrides: Type{<:ADBackend}
            Test.@test Modelers.validate_backend_override(FakeCoverageBackend) == FakeCoverageBackend
            # Valid overrides: ADBackend instance
            Test.@test Modelers.validate_backend_override(FakeCoverageBackend()) isa ADNLPModels.ADBackend

            # Invalid overrides: non-ADBackend types
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(Float64)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(Int)
            # Invalid overrides: other values
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override("invalid")
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(123)
            Test.@test_throws Exceptions.IncorrectArgument Modelers.validate_backend_override(:symbol)
        end
    end
end

end # module

test_coverage_validation() = TestCoverageValidation.test_coverage_validation()
