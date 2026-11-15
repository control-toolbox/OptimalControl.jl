# ============================================================================
# Constants in the expressions of a problem (non-regression, #481)
# ============================================================================
# A constant written inside a vector expression of `@def` used to break the default
# `:adnlp` modeler with `Cannot determine ordering of Dual tags`: in a boundary constraint
# involving the variable (fixed by ADNLPModels 0.8.14), and as a component of the dynamics
# (fixed by ADNLPModels 0.8.15). The bug lives at the boundary `@def` × ADNLPModels ×
# `solve`, which no single package owns, so it is tested here.
#
# Each problem is compared with the same problem written with the workaround that always
# worked (`-1 + 0v`, `0 * u(t)`), and with `:exa` where it applies: the same objective.

module TestConstantComponents

using Test: Test
using OptimalControl
using NLPModelsIpopt: NLPModelsIpopt # arms the Ipopt solver

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# --- A constant in a boundary constraint that involves the variable -------------------

const BOUNDARY_LITERAL = @def begin
    v ∈ R, variable
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    -1 ≤ v ≤ 1
    x(0) - [-1, v] == [0, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

const BOUNDARY_ONE = @def begin
    v ∈ R, variable
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    -1 ≤ v ≤ 1
    x(0) - [-one(v), v] == [0, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

# The workaround: the constant made to depend on the variable.
const BOUNDARY_WORKAROUND = @def begin
    v ∈ R, variable
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    -1 ≤ v ≤ 1
    x(0) - [-1 + 0v, v] == [0, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

# --- A constant component of the dynamics ---------------------------------------------

const DYNAMICS_ZERO = @def begin
    t ∈ [0, 1], time
    x ∈ R³, state
    u ∈ R, control
    x(0) == [-1, 0, 2]
    x₁(1) == 0
    x₂(1) == 0
    ẋ(t) == [x₂(t), u(t), 0]
    0.5∫(u(t)^2) → min
end

const DYNAMICS_ONE = @def begin
    t ∈ [0, 1], time
    x ∈ R³, state
    u ∈ R, control
    x(0) == [-1, 0, 2]
    x₁(1) == 0
    x₂(1) == 0
    ẋ(t) == [x₂(t), u(t), 1.0]
    0.5∫(u(t)^2) → min
end

# The workaround: the constant made to depend on the control.
const DYNAMICS_WORKAROUND = @def begin
    t ∈ [0, 1], time
    x ∈ R³, state
    u ∈ R, control
    x(0) == [-1, 0, 2]
    x₁(1) == 0
    x₂(1) == 0
    ẋ(t) == [x₂(t), u(t), 0 * u(t)]
    0.5∫(u(t)^2) → min
end

_solve(ocp, modeler::Symbol) = solve(ocp, modeler; display=false)

function test_constant_components()
    Test.@testset "Constants in expressions (#481)" verbose = VERBOSE showtiming =
        SHOWTIMING begin
        Test.@testset "boundary constraint with the variable, :adnlp" begin
            ref = _solve(BOUNDARY_WORKAROUND, :adnlp)
            Test.@test successful(ref)
            for (name, ocp) in (
                "x(0) - [-1, v]" => BOUNDARY_LITERAL, "x(0) - [-one(v), v]" => BOUNDARY_ONE
            )
                Test.@testset "$name" begin
                    sol = _solve(ocp, :adnlp)
                    Test.@test successful(sol)
                    Test.@test objective(sol) ≈ objective(ref) rtol = 1e-6
                    Test.@test variable(sol) ≈ variable(ref) atol = 1e-6
                end
            end
        end

        Test.@testset "constant component of the dynamics" begin
            ref = _solve(DYNAMICS_WORKAROUND, :adnlp)
            Test.@test successful(ref)
            # The double integrator from -1 to 0 in unit time: J = 6, up to the
            # discretisation error.
            Test.@test objective(ref) ≈ 6 rtol = 1e-3
            for (name, ocp) in
                ("[x₂(t), u(t), 0]" => DYNAMICS_ZERO, "[x₂(t), u(t), 1.0]" => DYNAMICS_ONE)
                for modeler in (:adnlp, :exa)
                    Test.@testset "$name, $modeler" begin
                        sol = _solve(ocp, modeler)
                        Test.@test successful(sol)
                        Test.@test objective(sol) ≈ objective(ref) rtol = 1e-6
                    end
                end
            end
            # The constant component is integrated as such: x₃(1) = 2 + c.
            Test.@test state(_solve(DYNAMICS_ZERO, :adnlp))(1.0)[3] ≈ 2 atol = 1e-8
            Test.@test state(_solve(DYNAMICS_ONE, :adnlp))(1.0)[3] ≈ 3 atol = 1e-8
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_constant_components() = TestConstantComponents.test_constant_components()
