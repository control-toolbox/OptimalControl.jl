# ============================================================================
# Staged direct method: discretize, build the NLP, solve it by hand, read it back
# ============================================================================
# `solve` chains three stages. A user can run them one by one, to solve the NLP
# with a solver of their own and get a `Solution` back (#1077):
#
#     docp  = discretize(ocp, discretizer)
#     built = OptimalControl.build_model(docp, init, modeler)
#     stats = <any NLP solver>(built.nlp)
#     sol   = ocp_solution(built, stats, modeler)
#
# Everything is reached through OptimalControl: no CTSolvers in scope. The
# chain is checked against `solve` on the same discretized problem, for both
# modelers (ExaModels needs the cache `BuiltModel` carries to read its
# solution back).

module TestStagedPipeline

using Test: Test
using OptimalControl # using is mandatory: the stages are tested as user-facing names
using NLPModelsIpopt: NLPModelsIpopt

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# Energy-minimal double integrator: J = 6 for the continuous problem.
function build_energy()
    return @def begin
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(1) == [0, 0]
        ẋ(t) == [v(t), u(t)]
        0.5∫(u(t)^2) → min
    end
end

function test_staged_pipeline()
    Test.@testset "Staged pipeline" verbose = VERBOSE showtiming = SHOWTIMING begin
        ocp = build_energy()
        discretizer = OptimalControl.Collocation(; grid_size=50, scheme=:trapeze)
        docp = discretize(ocp, discretizer)
        init = build_initial_guess(ocp, nothing)
        solver = OptimalControl.Ipopt(; print_level=0)

        Test.@test ocp_model(docp) === ocp

        for modeler in (OptimalControl.ADNLP(), OptimalControl.Exa())
            Test.@testset "$(nameof(typeof(modeler)))" begin
                built = OptimalControl.build_model(docp, init, modeler)
                Test.@test built isa OptimalControl.BuiltModel

                # The NLP of `built` is the one `nlp_model` returns.
                nlp = nlp_model(docp, init, modeler)
                Test.@test built.nlp.meta.nvar == nlp.meta.nvar == 3 * 51
                Test.@test built.nlp.meta.ncon == nlp.meta.ncon == 2 * 50 + 4

                # Solved by hand, read back as a Solution.
                stats = NLPModelsIpopt.ipopt(built.nlp; print_level=0)
                sol = ocp_solution(built, stats, modeler)
                Test.@test sol isa OptimalControl.Solution
                Test.@test successful(sol)

                # Same result as `solve` on the same discretized problem.
                ref = solve(docp, init, modeler, solver; display=false)
                Test.@test isapprox(objective(sol), objective(ref); rtol=1e-6)
                Test.@test isapprox(objective(sol), 6; rtol=1e-2)
                Test.@test isapprox(state(sol)(0.5), state(ref)(0.5); atol=1e-6)
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_staged_pipeline() = TestStagedPipeline.test_staged_pipeline()
