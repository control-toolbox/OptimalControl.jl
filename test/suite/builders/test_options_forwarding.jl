module TestOptionsForwarding

using Test
#import OptimalControl
import ADNLPModels
import ExaModels
import CTSolvers
import CTDirect
import CTModels
import CUDA

# CUDA availability check
is_cuda_on() = CUDA.functional()

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_options_forwarding()
    @testset "Options forwarding" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ----------------------------------------------------------------
        # Common setup: Beam problem, small grid for speed
        # ----------------------------------------------------------------
        pb = Beam()
        ocp = pb.ocp
        disc = CTDirect.Collocation(grid_size=50, scheme=:midpoint)
        normalized_init = CTModels.build_initial_guess(ocp, pb.init)
        docp = CTDirect.discretize(ocp, disc)

        # ================================================================
        # CTSolvers.Exa options
        # ================================================================
        @testset "Exa" begin

            # --- base_type: Float32 instead of default Float64 ---
            @testset "base_type" begin
                @test begin
                    modeler = CTSolvers.Exa(base_type=Float32)
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    eltype(nlp) == Float32
                end
            end

            # --- backend: CUDA backend if available ---
            if is_cuda_on()
                @testset "backend (CUDA)" begin
                    @test begin
                        modeler = CTSolvers.Exa(backend=CUDA.CUDABackend())
                        nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                        # With CUDA backend, x0 should be CUDA array
                        nlp.meta.x0 isa CUDA.CuArray
                    end
                end
            end
        end

        # ================================================================
        # CTSolvers.ADNLP options — basic
        # ================================================================
        @testset "ADNLP basic" begin

            # --- name: custom model name ---
            @testset "name" begin
                @test begin
                    modeler = CTSolvers.ADNLP(name="BeamTest")
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
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
                modeler_default = CTSolvers.ADNLP(backend=:default)
                modeler_optimized = CTSolvers.ADNLP(backend=:optimized)
                nlp_default = CTSolvers.nlp_model(docp, normalized_init, modeler_default)
                nlp_optimized = CTSolvers.nlp_model(docp, normalized_init, modeler_optimized)
                @test typeof(nlp_default.adbackend) != typeof(nlp_optimized.adbackend)
            end
        end

        # ================================================================
        # CTSolvers.ADNLP options — advanced backend overrides
        #
        # CTSolvers v0.2.5-beta now supports backend overrides with both
        # Types and instances. These tests verify that non-default backends
        # are properly forwarded through the discretization → modeling pipeline.
        # ================================================================
        @testset "ADNLP advanced" begin

            # --- gradient_backend: ReverseDiffADGradient instead of default ForwardDiffADGradient ---
            @testset "gradient_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        gradient_backend=ADNLPModels.ReverseDiffADGradient,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.gradient_backend isa ADNLPModels.ReverseDiffADGradient
                end
            end

            # --- hessian_backend: EmptyADbackend instead of default SparseADHessian ---
            @testset "hessian_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        hessian_backend=ADNLPModels.EmptyADbackend,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.hessian_backend isa ADNLPModels.EmptyADbackend
                end
            end

            # --- jacobian_backend: EmptyADbackend instead of default SparseADJacobian ---
            @testset "jacobian_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        jacobian_backend=ADNLPModels.EmptyADbackend,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jacobian_backend isa ADNLPModels.EmptyADbackend
                end
            end

            # --- hprod_backend: ReverseDiffADHvprod instead of default ForwardDiffADHvprod ---
            @testset "hprod_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        hprod_backend=ADNLPModels.ReverseDiffADHvprod,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.hprod_backend isa ADNLPModels.ReverseDiffADHvprod
                end
            end

            # --- jprod_backend: ReverseDiffADJprod instead of default ForwardDiffADJprod ---
            @testset "jprod_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        jprod_backend=ADNLPModels.ReverseDiffADJprod,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jprod_backend isa ADNLPModels.ReverseDiffADJprod
                end
            end

            # --- jtprod_backend: ReverseDiffADJtprod instead of default ForwardDiffADJtprod ---
            @testset "jtprod_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        jtprod_backend=ADNLPModels.ReverseDiffADJtprod,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.jtprod_backend isa ADNLPModels.ReverseDiffADJtprod
                end
            end

            # --- ghjvprod_backend: EmptyADbackend instead of default ForwardDiffADGHjvprod ---
            @testset "ghjvprod_backend" begin
                @test begin
                    modeler = CTSolvers.ADNLP(
                        ghjvprod_backend=ADNLPModels.EmptyADbackend,
                    )
                    nlp = CTSolvers.nlp_model(docp, normalized_init, modeler)
                    nlp.adbackend.ghjvprod_backend isa ADNLPModels.EmptyADbackend
                end
            end
        end

    end
end

end # module

# Redefine in outer scope for TestRunner
test_options_forwarding() = TestOptionsForwarding.test_options_forwarding()
