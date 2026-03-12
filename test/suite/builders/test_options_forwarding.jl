# ============================================================================
# Strategy Options Forwarding Tests
# ============================================================================
# This file tests that strategy options (e.g., `display`, `print_level`, `max_iter`)
# are correctly forwarded and processed from the high-level `OptimalControl`
# API down to the underlying `CTSolvers` constructors, preserving their default
# values or correctly overriding them with user inputs.

module TestOptionsForwarding

using Test: Test
using OptimalControl: OptimalControl
using ADNLPModels: ADNLPModels
using ExaModels: ExaModels
using CUDA: CUDA

# CUDA availability check
is_cuda_on() = CUDA.functional()

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
import .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_options_forwarding()
    Test.@testset "Options forwarding" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ----------------------------------------------------------------
        # Common setup: Beam problem, small grid for speed
        # ----------------------------------------------------------------
        pb = TestProblems.Beam()
        ocp = pb.ocp
        disc = OptimalControl.Collocation(grid_size=50, scheme=:midpoint)
        normalized_init = OptimalControl.build_initial_guess(ocp, pb.init)
        docp = OptimalControl.discretize(ocp, disc)

        # ================================================================
        # OptimalControl.Exa options
        # ================================================================
        Test.@testset "Exa" begin

            # --- base_type: Float32 instead of default Float64 ---
            Test.@testset "base_type" begin
                Test.@test begin
                    modeler = OptimalControl.Exa(base_type=Float32)
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    eltype(nlp) == Float32
                end
            end

            # --- backend: CUDA backend if available ---
            if is_cuda_on()
                Test.@testset "backend (CUDA)" begin
                    Test.@test begin
                        modeler = OptimalControl.Exa(backend=CUDA.CUDABackend())
                        nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                        # With CUDA backend, x0 should be CUDA array
                        nlp.meta.x0 isa CUDA.CuArray
                    end
                end
            end
        end

        # ================================================================
        # OptimalControl.ADNLP options — basic
        # ================================================================
        Test.@testset "ADNLP basic" begin

            # --- name: custom model name ---
            Test.@testset "name" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(name="BeamTest")
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.meta.name == "BeamTest"
                end
            end

            # --- show_time: not stored on the model, skip ---
            # show_time only controls printing during build and is not
            # inspectable on the resulting ADNLPModel.

            # --- backend: :default instead of :optimized ---
            # OptimalControl.build_adnlp_model DOES forward the backend option.
            # :default uses ForwardDiffADGradient, :optimized uses
            # ReverseDiffADGradient — so the adbackend types differ.
            Test.@testset "backend" begin
                modeler_default = OptimalControl.ADNLP(backend=:default)
                modeler_optimized = OptimalControl.ADNLP(backend=:optimized)
                nlp_default = OptimalControl.nlp_model(
                    docp, normalized_init, modeler_default
                )
                nlp_optimized = OptimalControl.nlp_model(
                    docp, normalized_init, modeler_optimized
                )
                Test.@test typeof(nlp_default.adbackend) != typeof(nlp_optimized.adbackend)
            end
        end

        # ================================================================
        # OptimalControl.ADNLP options — advanced backend overrides
        #
        # CTSolvers v0.2.5-beta now supports backend overrides with both
        # Types and instances. These tests verify that non-default backends
        # are properly forwarded through the discretization → modeling pipeline.
        # ================================================================
        Test.@testset "ADNLP advanced" begin

            # --- gradient_backend: ReverseDiffADGradient instead of default ForwardDiffADGradient ---
            Test.@testset "gradient_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        gradient_backend=ADNLPModels.ReverseDiffADGradient
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.gradient_backend isa ADNLPModels.ReverseDiffADGradient
                end
            end

            # --- hessian_backend: EmptyADbackend instead of default SparseADHessian ---
            Test.@testset "hessian_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        hessian_backend=ADNLPModels.EmptyADbackend
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.hessian_backend isa ADNLPModels.EmptyADbackend
                end
            end

            # --- jacobian_backend: EmptyADbackend instead of default SparseADJacobian ---
            Test.@testset "jacobian_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        jacobian_backend=ADNLPModels.EmptyADbackend
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jacobian_backend isa ADNLPModels.EmptyADbackend
                end
            end

            # --- hprod_backend: ReverseDiffADHvprod instead of default ForwardDiffADHvprod ---
            Test.@testset "hprod_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        hprod_backend=ADNLPModels.ReverseDiffADHvprod
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.hprod_backend isa ADNLPModels.ReverseDiffADHvprod
                end
            end

            # --- jprod_backend: ReverseDiffADJprod instead of default ForwardDiffADJprod ---
            Test.@testset "jprod_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        jprod_backend=ADNLPModels.ReverseDiffADJprod
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jprod_backend isa ADNLPModels.ReverseDiffADJprod
                end
            end

            # --- jtprod_backend: ReverseDiffADJtprod instead of default ForwardDiffADJtprod ---
            Test.@testset "jtprod_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        jtprod_backend=ADNLPModels.ReverseDiffADJtprod
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jtprod_backend isa ADNLPModels.ReverseDiffADJtprod
                end
            end

            # --- ghjvprod_backend: EmptyADbackend instead of default ForwardDiffADGHjvprod ---
            Test.@testset "ghjvprod_backend" begin
                Test.@test begin
                    modeler = OptimalControl.ADNLP(
                        ghjvprod_backend=ADNLPModels.EmptyADbackend
                    )
                    nlp = OptimalControl.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.ghjvprod_backend isa ADNLPModels.EmptyADbackend
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_options_forwarding() = TestOptionsForwarding.test_options_forwarding()
