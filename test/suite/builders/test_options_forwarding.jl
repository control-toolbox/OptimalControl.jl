module TestOptionsForwarding

using Test
using OptimalControl
import ADNLPModels
import ExaModels
import CTSolvers
import CTDirect
import CTModels

# Access KernelAbstractions through CTSolvers (transitive dependency, not a direct dep)
const KA = CTSolvers.Modelers.KernelAbstractions

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Mock GPU backend for testing ExaModeler backend forwarding.
# Subclasses KernelAbstractions.GPU so it is accepted by the ExaModeler
# option validator (which expects Union{Nothing, KernelAbstractions.Backend}).
struct MockGPUBackend <: KA.GPU end

function test_options_forwarding()
    @testset "Options forwarding" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ----------------------------------------------------------------
        # Common setup: Beam problem, small grid for speed
        # ----------------------------------------------------------------
        pb = Beam()
        ocp = pb.ocp
        disc = Collocation(grid_size=50, scheme=:midpoint)
        normalized_init = CTModels.build_initial_guess(ocp, pb.init)
        docp = CTDirect.discretize(ocp, disc)

        # ================================================================
        # ExaModeler options
        #
        # CTDirect.build_exa_model currently does NOT forward the modeler
        # options (kwarg name mismatch: `backend` vs `exa_backend`, and
        # `base_type` is not passed through). All tests are @test_broken.
        # ================================================================
        @testset "ExaModeler" begin

            # --- base_type: Float32 instead of default Float64 ---
            @testset "base_type" begin
                @test_broken begin
                    modeler = ExaModeler(base_type=Float32)
                    nlp = nlp_model(docp, normalized_init, modeler)
                    eltype(nlp) == Float32
                end
            end

            # --- backend: MockGPUBackend instead of default nothing ---
            # If forwarded, ExaCore would use the mock backend for array
            # conversion, producing non-Vector arrays. Currently ignored.
            @testset "backend" begin
                @test_broken begin
                    modeler = ExaModeler(backend=MockGPUBackend())
                    nlp = nlp_model(docp, normalized_init, modeler)
                    # If forwarded, x0 would NOT be a plain Vector
                    !(nlp.meta.x0 isa Vector)
                end
            end
        end

        # ================================================================
        # ADNLPModeler options — basic
        #
        # CTDirect.build_adnlp_model forwards `backend` (as the ADNLPModels
        # backend preset) but does NOT forward `name`, `show_time`, or
        # other modeler-level options.
        # ================================================================
        @testset "ADNLPModeler basic" begin

            # --- name: custom model name ---
            # Not forwarded by CTDirect: the builder always uses the
            # ADNLPModels default ("Generic").
            @testset "name" begin
                @test_broken begin
                    modeler = ADNLPModeler(name="BeamTest")
                    nlp = nlp_model(docp, normalized_init, modeler)
                    nlp.meta.name == "BeamTest"
                end
            end

            # --- show_time: not stored on the model, skip ---
            # show_time only controls printing during build and is not
            # inspectable on the resulting ADNLPModel.

            # --- backend: :default instead of :optimized ---
            # CTDirect.build_adnlp_model DOES forward the backend option.
            # :default uses ForwardDiffADGradient, :optimized uses
            # ReverseDiffADGradient — so the adbackend types differ.
            @testset "backend" begin
                modeler_default = ADNLPModeler(backend=:default)
                modeler_optimized = ADNLPModeler(backend=:optimized)
                nlp_default = nlp_model(docp, normalized_init, modeler_default)
                nlp_optimized = nlp_model(docp, normalized_init, modeler_optimized)
                @test typeof(nlp_default.adbackend) != typeof(nlp_optimized.adbackend)
            end
        end

        # ================================================================
        # ADNLPModeler options — advanced backend overrides
        #
        # These options are NOT forwarded by CTDirect.build_adnlp_model
        # (it only handles `backend` and `show_time` kwargs). All tests
        # are @test_broken.
        #
        # Note: the CTSolvers validator expects instances of ADBackend
        # subtypes (not bare Types) for these options.
        # ================================================================
        @testset "ADNLPModeler advanced" begin

            # --- gradient_backend ---
            @testset "gradient_backend" begin
                @test_broken begin
                    modeler = ADNLPModeler(
                        gradient_backend=ADNLPModels.ReverseDiffADGradient(),
                    )
                    nlp = nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.gradient_backend isa ADNLPModels.ReverseDiffADGradient
                end
            end

            # --- hessian_backend ---
            @testset "hessian_backend" begin
                @test_broken begin
                    modeler = ADNLPModeler(
                        hessian_backend=ADNLPModels.EmptyADbackend(),
                    )
                    nlp = nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.hessian_backend isa ADNLPModels.EmptyADbackend
                end
            end

            # --- jacobian_backend ---
            @testset "jacobian_backend" begin
                @test_broken begin
                    modeler = ADNLPModeler(
                        jacobian_backend=ADNLPModels.EmptyADbackend(),
                    )
                    nlp = nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jacobian_backend isa ADNLPModels.EmptyADbackend
                end
            end
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_options_forwarding() = TestOptionsForwarding.test_options_forwarding()
