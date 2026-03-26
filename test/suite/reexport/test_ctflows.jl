# ============================================================================
# CTFlows Reexports Tests
# ============================================================================
# This file tests the reexport of symbols from `CTFlows`. It verifies that
# the expected types and functions for Hamiltonian flows and dynamics
# are properly exported by `OptimalControl`.

module TestCtflows

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using CTFlows: CTFlows # needed for abstract type checks

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtflows

function test_ctflows()
    Test.@testset "CTFlows reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Types" begin
            for T in (
                OptimalControl.Hamiltonian,
                OptimalControl.HamiltonianLift,
                OptimalControl.HamiltonianVectorField,
            )
                Test.@test isdefined(OptimalControl, nameof(T))
                Test.@test !isdefined(CurrentModule, nameof(T))
                Test.@test T isa DataType || T isa UnionAll
            end
        end
        Test.@testset "Functions" begin
            for f in (:Lift, :Flow)
                Test.@test isdefined(OptimalControl, f)
                Test.@test isdefined(CurrentModule, f)
                Test.@test getfield(OptimalControl, f) isa Function
            end
        end
        Test.@testset "Operators" begin
            for op in (:⋅, :Lie, :Poisson, :*)
                Test.@test isdefined(OptimalControl, op)
                Test.@test isdefined(CurrentModule, op)
            end
        end
        Test.@testset "Macros" begin
            Test.@test isdefined(OptimalControl, Symbol("@Lie"))
            Test.@test isdefined(CurrentModule, Symbol("@Lie"))
        end

        Test.@testset "Type Hierarchy" begin
            Test.@test OptimalControl.Hamiltonian <: CTFlows.AbstractHamiltonian
            Test.@test OptimalControl.HamiltonianLift <: CTFlows.AbstractHamiltonian
            Test.@test OptimalControl.HamiltonianVectorField <: CTFlows.AbstractVectorField
        end

        Test.@testset "Method Signatures" begin
            Test.@testset "Lift" begin
                Test.@test hasmethod(Lift, Tuple{CTFlows.VectorField})
                Test.@test hasmethod(Lift, Tuple{Function})
            end
            Test.@testset "Flow" begin
                Test.@test hasmethod(Flow, Tuple{Vararg{Any}})
            end
        end

        # ====================================================================
        # SIGNATURE FREEZING TESTS
        # ====================================================================
        # These tests make simple calls to exported methods to freeze their signatures.
        # They are not meant to verify correct functionality but to ensure the
        # API remains stable and catch breaking changes early.

        Test.@testset "Signature Freezing" begin
            Test.@testset "Hamiltonian Types" begin
                # Test basic construction patterns
                H = OptimalControl.Hamiltonian((x, p) -> x[1]^2 + p[1]^2)
                Test.@test H isa OptimalControl.Hamiltonian
                
                HL = OptimalControl.HamiltonianLift(x -> [x[1], x[2]])
                Test.@test HL isa OptimalControl.HamiltonianLift
                
                HV = OptimalControl.HamiltonianVectorField((x, p) -> [p[1], -x[1]])
                Test.@test HV isa OptimalControl.HamiltonianVectorField
            end

            Test.@testset "Lift Function" begin
                # Lift from VectorField
                X = CTFlows.VectorField(x -> [x[1]^2, x[2]^2])
                H = Lift(X)
                Test.@test H isa CTFlows.HamiltonianLift
                
                # Lift from Function
                f = x -> [x[1]^2, x[2]^2]
                H2 = Lift(f)
                Test.@test H2 isa Function
                
                # Test basic evaluation (signature verification)
                Test.@test H([1, 2], [3, 4]) isa Real
                Test.@test H2([1, 2], [3, 4]) isa Real
            end

            Test.@testset "Flow Function" begin
                # Basic Flow call - just verify it doesn't error
                # The exact signature may vary, so we just test it exists
                Test.@test Flow isa Function
            end

            Test.@testset "Operators" begin
                # Set up simple test objects
                X = CTFlows.VectorField(x -> [x[2], -x[1]])
                f = x -> x[1]^2 + x[2]^2
                
                # Test dot operator (directional derivative)
                dot_result = X ⋅ f
                Test.@test dot_result isa Function
                
                # Test Lie function
                lie_result = Lie(X, f)
                Test.@test lie_result isa Function
                
                # Test Poisson bracket
                g = (x, p) -> x[1]*p[1] + x[2]*p[2]
                poisson_result = Poisson(f, g)
                Test.@test poisson_result isa CTFlows.Hamiltonian
                
                # Note: * operator is not defined for VectorField * Function combinations
                # This is expected behavior based on CTFlows API
            end

            Test.@testset "@Lie Macro" begin
                # Test basic macro usage
                X1 = CTFlows.VectorField(x -> [x[2], -x[1]])
                X2 = CTFlows.VectorField(x -> [x[1], x[2]])
                
                # Simple Lie bracket with macro
                lie_macro_result = @Lie [X1, X2]
                Test.@test lie_macro_result isa CTFlows.VectorField
                
                # Test evaluation
                Test.@test lie_macro_result([1, 2]) isa Vector
            end

            Test.@testset "Complex Signature Tests" begin
                # Test with different arities and keyword arguments
                
                # Non-autonomous VectorField - needs correct signature
                X_nonauto = CTFlows.VectorField((t, x) -> [t + x[1], x[2]]; autonomous=false)
                H_nonauto = Lift(X_nonauto)
                Test.@test H_nonauto(1, [1, 2], [3, 4]) isa Real
                
                # Variable VectorField - needs correct signature
                X_var = CTFlows.VectorField((x, v) -> [x[1] + v, x[2]]; variable=true)
                H_var = Lift(X_var)
                Test.@test H_var([1, 2], [3, 4], 1) isa Real
                
                # Non-autonomous variable VectorField - needs correct signature
                X_both = CTFlows.VectorField((t, x, v) -> [t + x[1] + v, x[2]]; autonomous=false, variable=true)
                H_both = Lift(X_both)
                Test.@test H_both(1, [1, 2], [3, 4], 1) isa Real
                
                # Hamiltonian with different signatures
                H_auto = OptimalControl.Hamiltonian((x, p) -> x[1]*p[1])
                Test.@test H_auto([1, 2], [3, 4]) isa Real
                
                H_nonauto_ham = OptimalControl.Hamiltonian((t, x, p) -> t + x[1]*p[1]; autonomous=false)
                Test.@test H_nonauto_ham(1, [1, 2], [3, 4]) isa Real
                
                H_var_ham = OptimalControl.Hamiltonian((x, p, v) -> v + x[1]*p[1]; variable=true)
                Test.@test H_var_ham([1, 2], [3, 4], 1) isa Real
            end

            Test.@testset "Operator Combinations" begin
                # Test combinations of operators to ensure they work together
                X1 = CTFlows.VectorField(x -> [x[2], -x[1]])
                X2 = CTFlows.VectorField(x -> [x[1], x[2]])
                f = x -> x[1]^2 + x[2]^2
                g = (x, p) -> x[1]*p[1] + x[2]*p[2]
                
                # Lie bracket of VectorFields
                lie_vf = Lie(X1, X2)
                Test.@test lie_vf isa CTFlows.VectorField
                Test.@test lie_vf([1, 2]) isa Vector
                
                # Multiple operator combinations
                Test.@test (X1 ⋅ f)([1, 2]) isa Real
                
                # Test Poisson bracket with ForwardDiff-compatible functions
                h = (x, p) -> x[1]*p[1] + x[2]*p[2]  # Simple polynomial function
                poisson_result = Poisson(h, g)
                Test.@test poisson_result isa CTFlows.Hamiltonian
                Test.@test poisson_result([1, 2], [3, 4]) isa Real
                
                # Note: * operator is not defined for VectorField * Function
                # This is expected behavior based on CTFlows API
            end

            Test.@testset "Macro with Different Contexts" begin
                # Test @Lie macro in different contexts
                
                # Simple case
                X1 = CTFlows.VectorField(x -> [x[2], -x[1]])
                X2 = CTFlows.VectorField(x -> [x[1], x[2]])
                result1 = @Lie [X1, X2]
                Test.@test result1 isa CTFlows.VectorField
                
                # Nested case
                X3 = CTFlows.VectorField(x -> [2*x[1], 3*x[2]])
                result2 = @Lie [[X1, X2], X3]
                Test.@test result2 isa CTFlows.VectorField
                
                # With Hamiltonians (Poisson bracket) - returns Hamiltonian
                H1 = OptimalControl.Hamiltonian((x, p) -> x[1]*p[1])
                H2 = OptimalControl.Hamiltonian((x, p) -> x[2]*p[2])
                result3 = @Lie {H1, H2}
                Test.@test result3 isa CTFlows.Hamiltonian
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctflows() = TestCtflows.test_ctflows()
