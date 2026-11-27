# ============================================================================
# A flow on any horizon, through the public API
# ============================================================================
# CTFlows 0.20 (control-toolbox/CTFlows.jl#547) integrates a concatenation of flows on any
# horizon — after a switching time, before one, inside a single phase, backward — and returns
# every trajectory in increasing time. The behaviour is tested in CTFlows; this file checks
# that a user gets it with the names OptimalControl exports (#1093), so that a compat bump or
# a re-export cannot lose it: the values, the `Solution` of a backward call, and the Jacobian
# of a shooting function with respect to a switching time.
#
# Problem: time-minimal double integrator, x(0) = (-1, 0), x(tf) = (0, 0), |u| ≤ 1. The
# extremal is u = +1 on [0, 1], u = -1 on [1, 2], tf = 2, from p(0) = (1, 1), with
# p(t) = (1, 1 - t); (q, v)(0.5) = (-0.875, 0.5), (q, v)(1.5) = (-0.125, 0.5).

module TestFlowHorizon

using Test: Test
using OptimalControl # using is mandatory: the API is tested as exported names
using OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator
using ForwardDiff: ForwardDiff

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const TOL = 1e-8

function build_time_min()
    return @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        -1 ≤ u(t) ≤ 1
        x(0) == [-1, 0]
        x(tf) == [0, 0]
        ẋ(t) == [v(t), u(t)]
        tf → min
    end
end

_opts() = (; reltol=1e-12, abstol=1e-12)

function test_flow_horizon()
    Test.@testset "Flow on any horizon" verbose = VERBOSE showtiming = SHOWTIMING begin
        ocp = build_time_min()
        f_plus = Flow(ocp, (x, p, v) -> 1; label="u = +1", _opts()...)
        f_minus = Flow(ocp, (x, p, v) -> -1; label="u = -1", _opts()...)
        tf = 2.0
        f_bb = f_plus * (1.0, f_minus)

        Test.@testset "point call: a part of the horizon, and backward" begin
            x, p = f_bb(0.0, [-1.0, 0.0], [1.0, 1.0], 0.5; variable=tf)
            Test.@test x ≈ [-0.875, 0.5] atol = TOL
            Test.@test p ≈ [1.0, 0.5] atol = TOL
            x, p = f_bb(1.5, [-0.125, 0.5], [1.0, -0.5], tf; variable=tf)
            Test.@test x ≈ [0.0, 0.0] atol = TOL
            Test.@test p ≈ [1.0, -1.0] atol = TOL
            x, p = f_bb(tf, [0.0, 0.0], [1.0, -1.0], 0.0; variable=tf)
            Test.@test x ≈ [-1.0, 0.0] atol = TOL
            Test.@test p ≈ [1.0, 1.0] atol = TOL
        end

        Test.@testset "trajectory call: backward, in increasing time" begin
            sol = f_bb((tf, 0.0), [0.0, 0.0], [1.0, -1.0]; variable=tf)
            T = time_grid(sol)
            Test.@test issorted(T) && first(T) == 0.0 && last(T) == tf
            Test.@test switching_times(sol) == [1.0]
            Test.@test phase_labels(sol) == ["u = +1", "u = -1"]
            Test.@test objective(sol) ≈ tf atol = TOL
            Test.@test state(sol)(0.5) ≈ [-0.875, 0.5] atol = TOL
            Test.@test left_limit(sol, :control, 1) ≈ 1
            Test.@test right_limit(sol, :control, 1) ≈ -1
            # a horizon in the second phase only
            s2 = f_bb((1.5, tf), [-0.125, 0.5], [1.0, -0.5]; variable=tf)
            Test.@test isempty(switching_times(s2))
            Test.@test phase_labels(s2) == ["u = -1"]
        end

        Test.@testset "a single flow backward: the same Solution" begin
            g = @def begin
                t ∈ [0, 1], time
                x = (q, v) ∈ R², state
                u ∈ R, control
                x(0) == [-1, 0]
                x(1) == [0, 0]
                ẋ(t) == [v(t), u(t)]
                0.5∫(u(t)^2) → min
            end
            f = Flow(g, (x, p) -> p[2]; _opts()...)
            sf = f((0.0, 1.0), [-1.0, 0.0], [12.0, 6.0])
            sb = f((1.0, 0.0), [0.0, 0.0], [12.0, -6.0])
            Test.@test time_grid(sb)[[1, end]] == [0.0, 1.0]
            Test.@test objective(sb) ≈ 6 atol = TOL
            Test.@test objective(sb) ≈ objective(sf) atol = TOL
        end

        Test.@testset "the Jacobian of a shooting function with respect to t₁ and tf" begin
            H = pseudo_hamiltonian(ocp)
            function shoot!(s, ξ)
                p0, t1, tf_ = ξ[1:2], ξ[3], ξ[4]
                φ = f_plus * (t1, f_minus)
                xf, pf = φ(0.0, [-1.0, 0.0], p0, tf_; variable=tf_, unsafe=true)
                s[1:2] = xf
                s[3] = f_plus(0.0, [-1.0, 0.0], p0, t1; variable=tf_, unsafe=true)[2][2]
                s[4] = H(xf, pf, -1, tf_) - 1
                return nothing
            end
            ξ = [1.1, 0.9, 1.05, 2.1]
            J = ForwardDiff.jacobian(shoot!, zeros(4), ξ)
            h = 1e-6
            fd = reduce(
                hcat,
                map(1:4) do j
                    e = zeros(4)
                    e[j] = h
                    sp, sm = zeros(4), zeros(4)
                    shoot!(sp, ξ + e)
                    shoot!(sm, ξ - e)
                    (sp - sm) / 2h
                end,
            )
            Test.@test J ≈ fd atol = 1e-5
        end
    end
end

end # module

test_flow_horizon() = TestFlowHorizon.test_flow_horizon()
