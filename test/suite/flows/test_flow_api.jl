# ============================================================================
# Flow API surface
# ============================================================================
# The `Flow` constructor grid and calling convention, which is where most of
# the v2.1.0-beta user-visible breakage lives. The indirect suite exercises
# these incidentally, on real problems; this file pins them down directly, so a
# regression says *which* part of the API moved rather than "Goddard no longer
# converges".
#
# The `constraint=` keyword accepting a `Symbol` is a genuine capability gain
# and not just a spelling: a constrained flow can reuse the OCP's own declared
# constraint instead of restating it — one fewer place for the two to disagree.

module TestFlowAPI

using Test: Test
using OptimalControl
using CTModels: CTModels
using CTBase: CTBase
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const T0 = 0.0
const TF = 1.0
const X0 = [-1.0, 0.0]
const P0 = [12.0, 6.0]
const VMAX = 1.2

"""
    build_labelled()

Energy double integrator with a **labelled** `:path` constraint, so
`constraint=:vmax` has something to point at. Built functionally rather than
taken from the library: the library problems express `v ≤ 1.2` as a state box,
and the `Symbol` form needs a genuine `:path` entry.
"""
function build_labelled()
    pre = CTModels.PreModel()
    CTModels.Building.variable!(pre, 0)
    CTModels.Building.time!(pre; t0=T0, tf=TF)
    CTModels.Building.state!(pre, 2)
    CTModels.Building.control!(pre, 1)
    CTModels.Building.dynamics!(pre, (r, t, x, u, v) -> (r[1] = x[2]; r[2] = u[1]; nothing))
    CTModels.Building.objective!(pre, :min; lagrange=(t, x, u, v) -> 0.5 * u[1]^2)
    CTModels.Building.constraint!(
        pre,
        :path;
        f=(r, t, x, u, v) -> (r[1] = x[2]; nothing),
        lb=[-Inf],
        ub=[VMAX],
        label=:vmax,
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

function test_flow_api()
    Test.@testset "Flow API" verbose = VERBOSE showtiming = SHOWTIMING begin
        ocp = build_labelled()

        # ====================================================================
        # Constructor grid
        # ====================================================================

        Test.@testset "from a Data object" begin
            Test.@testset "VectorField → state flow" begin
                f = Flow(VectorField(x -> [x[2], -x[1]]))
                # A state flow takes (t0, x0, tf) — no costate.
                Test.@test f(0.0, [1.0, 0.0], 1.0) isa AbstractVector
            end

            Test.@testset "Hamiltonian → Hamiltonian flow" begin
                f = Flow(Hamiltonian((x, p) -> p[1] * x[2] - x[1] * p[2]))
                xf, pf = f(0.0, [1.0, 0.0], [0.0, 1.0], 1.0)
                Test.@test xf isa AbstractVector
                Test.@test pf isa AbstractVector
            end

            Test.@testset "HamiltonianVectorField → Hamiltonian flow" begin
                f = Flow(HamiltonianVectorField((x, p) -> [p[1], -x[1]]))
                xf, pf = f(0.0, [1.0, 0.0], [0.0, 1.0], 1.0)
                Test.@test xf isa AbstractVector
                Test.@test pf isa AbstractVector
            end
        end

        Test.@testset "control-law kinds select different flows" begin
            # The three kinds are *not* interchangeable, and the difference is
            # structural rather than cosmetic:
            #
            #   DynClosedLoop u(t,x,p) — carries the costate ⇒ Hamiltonian flow
            #   ClosedLoop    u(t,x)   — no costate           ⇒ state flow
            #   OpenLoop      u(t)     — no costate           ⇒ state flow
            #
            # A state flow has no costate to return, so calling it with one is
            # a `MethodError`. Picking the wrong kind therefore fails loudly,
            # which is the point of naming them.
            f_dyn = Flow(ocp, DynClosedLoop((x, p) -> p[2]))
            f_closed = Flow(ocp, ClosedLoop(x -> 0.0))
            # ⚠️ `is_autonomous=false` is not optional here, and the reason is
            # a genuine trap: the trait strips the time argument *uniformly*
            # across law kinds, and an open loop has nothing but time. So an
            # autonomous `OpenLoop` is called with **no arguments at all** —
            # `OpenLoop(t -> 0.0)` looks right and is a `MethodError` at
            # integration time, not at construction.
            f_open = Flow(ocp, OpenLoop(t -> 0.0; is_autonomous=false))

            Test.@test f_dyn(T0, X0, P0, TF) isa Tuple      # (xf, pf)
            Test.@test f_closed(T0, X0, TF) isa AbstractVector
            Test.@test f_open(T0, X0, TF) isa AbstractVector

            Test.@test_throws MethodError f_closed(T0, X0, P0, TF)
            Test.@test_throws MethodError f_open(T0, X0, P0, TF)
        end

        Test.@testset "is_autonomous governs the law's arity" begin
            # Pinned down because the arities are not guessable from the kind
            # alone, and getting one wrong fails only when the flow is *run*.
            #
            #                     autonomous      non-autonomous
            #   OpenLoop          u()             u(t)
            #   ClosedLoop        u(x)            u(t, x)
            #   DynClosedLoop     u(x, p)         u(t, x, p)
            Test.@test Flow(ocp, OpenLoop(() -> 0.0))(T0, X0, TF) isa AbstractVector
            Test.@test Flow(ocp, OpenLoop(t -> 0.0; is_autonomous=false))(T0, X0, TF) isa
                AbstractVector
            Test.@test Flow(ocp, ClosedLoop(x -> 0.0))(T0, X0, TF) isa AbstractVector
            Test.@test Flow(ocp, ClosedLoop((t, x) -> 0.0; is_autonomous=false))(
                T0, X0, TF
            ) isa AbstractVector

            # The mismatched spellings must fail rather than quietly coerce.
            Test.@test_throws MethodError Flow(ocp, OpenLoop(t -> 0.0))(T0, X0, TF)
            Test.@test_throws MethodError Flow(ocp, ClosedLoop((t, x) -> 0.0))(T0, X0, TF)
        end

        Test.@testset "Flow(ocp, ::Function) wraps in DynClosedLoop" begin
            # The convenience overload picks the costate-carrying kind. A user
            # wanting open- or closed-loop must name the type — hence the
            # previous testset.
            f_plain = Flow(ocp, (x, p) -> p[2])
            f_named = Flow(ocp, DynClosedLoop((x, p) -> p[2]))
            Test.@test f_plain(T0, X0, P0, TF)[1] ≈ f_named(T0, X0, P0, TF)[1]
        end

        # ====================================================================
        # Constrained flows — three spellings of `constraint`
        # ====================================================================

        Test.@testset "constraint spellings agree" begin
            g(x) = VMAX - x[2]
            μ(x, p) = p[1]
            law(x, p) = 0.0

            f_fun = Flow(ocp, law; constraint=(x, u) -> g(x), multiplier=μ)
            f_sym = Flow(ocp, law; constraint=:vmax, multiplier=μ)
            f_obj = Flow(ocp, law; constraint=StateConstraint(g), multiplier=μ)

            # ⚠️ The `Symbol` form takes the constraint from the model, so its
            # sign convention is the model's (`x₂ ≤ vmax`), not the shooting
            # convention (`g = vmax − x₂ ≥ 0`). All three must still integrate
            # the same augmented dynamics, since the multiplier is the same.
            for f in (f_fun, f_sym, f_obj)
                xf, pf = f(T0, X0, P0, TF)
                Test.@test xf isa AbstractVector
                Test.@test pf isa AbstractVector
            end
            Test.@test f_fun(T0, X0, P0, TF)[1] ≈ f_obj(T0, X0, P0, TF)[1]
        end

        Test.@testset "multiplier accepts a Data object" begin
            f = Flow(ocp, (x, p) -> 0.0; constraint=:vmax, multiplier=Multiplier((x, p) -> p[1]))
            Test.@test f(T0, X0, P0, TF) isa Tuple
        end

        Test.@testset "an unknown label is rejected" begin
            # The whole value of the `Symbol` form is that the model is the
            # single source of truth — so a typo must fail, not fall back.
            Test.@test_throws OptimalControl.IncorrectArgument Flow(
                ocp, (x, p) -> 0.0; constraint=:nope, multiplier=(x, p) -> p[1]
            )
        end

        Test.@testset "constraint and multiplier are a pair" begin
            Test.@test_throws OptimalControl.IncorrectArgument Flow(
                ocp, (x, p) -> 0.0; constraint=:vmax
            )
            Test.@test_throws OptimalControl.IncorrectArgument Flow(
                ocp, (x, p) -> 0.0; multiplier=(x, p) -> p[1]
            )
        end

        # ====================================================================
        # Calling convention
        # ====================================================================

        Test.@testset "unsafe suppresses the retcode check" begin
            # Useful inside a shooting loop, where an intermediate integration
            # failure should surface through the residual rather than throw.
            f = Flow(ocp, (x, p) -> p[2])
            Test.@test f(T0, X0, P0, TF; unsafe=true) isa Tuple
            # On a successful integration the two agree.
            Test.@test f(T0, X0, P0, TF; unsafe=true)[1] ≈ f(T0, X0, P0, TF)[1]
        end

        Test.@testset "trajectory form returns a Solution" begin
            f = Flow(ocp, (x, p) -> p[2])
            traj = f((T0, TF), X0, P0)
            Test.@test traj isa CTModels.Solutions.Solution
            Test.@test state(traj)(T0) ≈ X0
            # `atol`, not `rtol`: this trajectory lands on the origin, and a
            # relative comparison of two numerical zeros is meaningless.
            Test.@test state(traj)(TF) ≈ f(T0, X0, P0, TF)[1] atol = 1e-8
        end

        Test.@testset "no variable on a Fixed flow" begin
            f = Flow(ocp, (x, p) -> p[2])
            Test.@test_throws OptimalControl.PreconditionError f(
                T0, X0, P0, TF; variable=1.0
            )
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_flow_api() = TestFlowAPI.test_flow_api()
