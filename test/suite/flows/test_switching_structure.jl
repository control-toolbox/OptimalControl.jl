# ============================================================================
# Switching structure of a multi-phase solution
# ============================================================================
# The `Solution` of a concatenation of flows keeps its switching times, its
# phase labels and the left and right limits at each switching time (CTModels
# `SwitchingModel`). This file checks that a user reads them with the names
# OptimalControl exports, without loading CTModels (#1079).
#
# Problem: time-minimal double integrator, x(0) = (-1, 0), x(tf) = (0, 0),
# |u| ≤ 1. The extremal is u = +1 on [0, 1], u = -1 on [1, 2], tf = 2, from
# p(0) = (1, 1); at t = 1, x = (-1/2, 1), and the control jumps from +1 to -1.

module TestSwitchingStructure

using Test: Test
using OptimalControl # using is mandatory: the accessors are tested as exported names
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function build_time_min()
    return @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        q(0) == -1
        v(0) == 0
        q(tf) == 0
        v(tf) == 0
        ẋ(t) == [v(t), u(t)]
        tf → min
    end
end

function test_switching_structure()
    Test.@testset "Switching structure" verbose = VERBOSE showtiming = SHOWTIMING begin
        ocp = build_time_min()
        f_plus = Flow(ocp, (x, p, v) -> 1; label="bang +")
        f_minus = Flow(ocp, (x, p, v) -> -1; label="bang −")
        x0, p0, tf = [-1.0, 0.0], [1.0, 1.0], 2.0

        Test.@testset "two phases" begin
            sol = (f_plus * (1.0, f_minus))((0.0, tf), x0, p0; variable=tf)

            Test.@test has_switching(sol)
            Test.@test switching_times(sol) == [1.0]
            Test.@test phase_labels(sol) == ["bang +", "bang −"]

            # The control jumps; the state and the costate are continuous.
            Test.@test left_limit(sol, :control, 1) ≈ 1
            Test.@test right_limit(sol, :control, 1) ≈ -1
            Test.@test isapprox(left_limit(sol, :state, 1), [-0.5, 1.0]; atol=1e-8)
            Test.@test isapprox(right_limit(sol, :state, 1), [-0.5, 1.0]; atol=1e-8)
            Test.@test isapprox(
                left_limit(sol, :costate, 1), right_limit(sol, :costate, 1); atol=1e-8
            )
        end

        Test.@testset "one phase" begin
            sol = f_plus((0.0, 1.0), x0, p0; variable=tf)

            Test.@test !has_switching(sol)
            Test.@test isempty(switching_times(sol))
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_switching_structure() = TestSwitchingStructure.test_switching_structure()
