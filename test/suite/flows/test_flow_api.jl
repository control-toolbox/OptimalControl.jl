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
    CTModels.Building.dynamics!(pre, (r, t, x, u, v) -> (r[1]=x[2]; r[2]=u[1]; nothing))
    CTModels.Building.objective!(pre, :min; lagrange=(t, x, u, v) -> 0.5 * u[1]^2)
    CTModels.Building.constraint!(
        pre,
        :path;
        f=(r, t, x, u, v) -> (r[1]=x[2]; nothing),
        lb=[-Inf],
        ub=[VMAX],
        label=:vmax,
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

"""
    build_nonfixed()

The same dynamics as [`build_labelled`](@ref), on a `NonFixed` horizon: `tf` is
the OCP's own `variable` rather than a constant. Exists solely so "`variable=`
is mandatory when omitted" has a fixture to omit it *on* — `build_labelled`'s
OCP is `Fixed` and can only test the mirror-image guard rail (passing a
`variable` where there is none).
"""
function build_nonfixed()
    pre = CTModels.PreModel()
    CTModels.Building.variable!(pre, 1, :tf)
    CTModels.Building.time!(pre; t0=T0, indf=1)
    CTModels.Building.state!(pre, 2)
    CTModels.Building.control!(pre, 1)
    CTModels.Building.dynamics!(pre, (r, t, x, u, v) -> (r[1]=x[2]; r[2]=u[1]; nothing))
    CTModels.Building.objective!(pre, :min; mayer=(x0, xf, v) -> v[1])
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
            # OpenLoop is unconditionally `NonAutonomous` (CTBase#515) — an
            # open-loop control has nothing but time, so autonomy is not a
            # real choice for it the way it is for ClosedLoop/DynClosedLoop.
            # No `is_autonomous` keyword to pass here any more.
            f_open = Flow(ocp, OpenLoop(t -> 0.0))

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
            #   OpenLoop          — (CTBase#515: unconditionally NonAutonomous,
            #                        no autonomous spelling — see below)
            #   ClosedLoop        u(x)            u(t, x)
            #   DynClosedLoop     u(x, p)         u(t, x, p)
            Test.@test Flow(ocp, OpenLoop(t -> 0.0))(T0, X0, TF) isa AbstractVector
            Test.@test Flow(ocp, ClosedLoop(x -> 0.0))(T0, X0, TF) isa AbstractVector
            Test.@test Flow(ocp, ClosedLoop((t, x) -> 0.0; is_autonomous=false))(
                T0, X0, TF
            ) isa AbstractVector

            # The mismatched spellings must fail rather than quietly coerce.
            Test.@test_throws MethodError Flow(ocp, ClosedLoop((t, x) -> 0.0))(T0, X0, TF)

            Test.@testset "OpenLoop has no autonomous spelling (CTBase#515)" begin
                # Before the fix, `is_autonomous` defaulted to `true` for
                # OpenLoop too, and the uniform-call trait stripped `t`
                # *uniformly* across law kinds — so an "autonomous" OpenLoop
                # was called with **no arguments at all**. A zero-argument
                # closure like `() -> 0.0` therefore constructed silently and
                # only failed once the flow was integrated, with a bare
                # `MethodError` far from the mistake.
                #
                # OpenLoop is now unconditionally `NonAutonomous`, so there is
                # no autonomous spelling to reach for by mistake — only the
                # wrong number of arguments, still a `MethodError` (Julia does
                # not check a closure's arity at construction), but no longer
                # a *trap*: `OpenLoop(t -> 0.0)` above is the only correct
                # spelling, full stop.
                Test.@test_throws MethodError Flow(ocp, OpenLoop(() -> 0.0))(T0, X0, TF)
            end
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
            f = Flow(
                ocp, (x, p) -> 0.0; constraint=:vmax, multiplier=Multiplier((x, p) -> p[1])
            )
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

        Test.@testset "variable is mandatory on a NonFixed flow" begin
            # The mirror image of the guard rail above. Ported from what used
            # to be a per-problem check in `suite/indirect/test_goddard.jl`
            # and `test_double_integrator_time.jl` (both `NonFixed`, both
            # deleted now that shooting itself lives in
            # `suite/indirect/test_shooting_sweep.jl`) — this is the one
            # assertion from those files that was not already covered
            # generically here, so it moved rather than vanished.
            f = Flow(build_nonfixed(), (x, p, v) -> p[2])
            Test.@test_throws OptimalControl.PreconditionError f(T0, X0, P0, TF)
        end

        Test.@testset "deprecated v2.0 flow shims" begin
            # The old Flow(f::Function) constructor.
            e = try
                Flow(x -> [x[2], -x[1]])
            catch err
                err
            end
            Test.@test e isa OptimalControl.PreconditionError
            Test.@test occursin("Flow(f::Function)", e.msg)
            Test.@test occursin("Flow(VectorField", e.suggestion)

            # 5-positional Hamiltonian flow call.
            f = Flow(ocp, (x, p) -> p[2])
            e = try
                f(T0, X0, P0, TF, 0.0)
            catch err
                err
            end
            Test.@test e isa OptimalControl.PreconditionError
            Test.@test occursin("f(t0, x0, p0, tf, lambda)", e.msg)
            Test.@test occursin("f(t0, x0, p0, tf; variable=lambda)", e.suggestion)

            # 4-positional State flow call.
            f_closed = Flow(ocp, ClosedLoop(x -> 0.0))
            e = try
                f_closed(T0, X0, TF, 0.0)
            catch err
                err
            end
            Test.@test e isa OptimalControl.PreconditionError
            Test.@test occursin("f(t0, x0, tf, lambda)", e.msg)
            Test.@test occursin("f(t0, x0, tf; variable=lambda)", e.suggestion)

            # time and success on the OCP and on a Solution.
            traj = f((T0, TF), X0, P0)
            for (thunk, expected, suggestion) in (
                (() -> Base.time(ocp), "time(ocp)", "times(ocp)"),
                (() -> Base.time(traj), "time(sol)", "time_grid(sol)"),
                (() -> Base.success(traj), "success(sol)", "successful(sol)"),
            )
                e = try
                    thunk()
                catch err
                    err
                end
                Test.@test e isa OptimalControl.PreconditionError
                Test.@test occursin(expected, e.msg)
                Test.@test occursin(suggestion, e.suggestion)
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_flow_api() = TestFlowAPI.test_flow_api()
