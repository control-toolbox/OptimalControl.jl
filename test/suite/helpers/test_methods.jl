# ============================================================================
# Available Methods Tests
# ============================================================================
# This file tests the `methods()` function, verifying that it correctly
# returns the list of all supported solving methods (valid combinations
# of discretizer, modeler, solver, and parameter).

module TestAvailableMethods

import Test
import OptimalControl

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_methods()
    Test.@testset "methods Tests" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS
        # ====================================================================

        Test.@testset "Return Type" begin
            methods = OptimalControl.methods()
            Test.@test methods isa Tuple
            Test.@test all(m -> m isa Tuple{Symbol, Symbol, Symbol, Symbol}, methods)
        end

        Test.@testset "Content Verification" begin
            methods = OptimalControl.methods()

            # CPU methods (all existing methods now with :cpu parameter)
            Test.@test (:collocation, :adnlp, :ipopt, :cpu) in methods
            Test.@test (:collocation, :adnlp, :madnlp, :cpu) in methods
            Test.@test (:collocation, :adnlp, :madncl, :cpu) in methods
            Test.@test (:collocation, :adnlp, :knitro, :cpu) in methods
            Test.@test (:collocation, :exa, :ipopt, :cpu) in methods
            Test.@test (:collocation, :exa, :madnlp, :cpu) in methods
            Test.@test (:collocation, :exa, :madncl, :cpu) in methods
            Test.@test (:collocation, :exa, :knitro, :cpu) in methods
            
            # GPU methods (new functionality)
            Test.@test (:collocation, :exa, :madnlp, :gpu) in methods
            Test.@test (:collocation, :exa, :madncl, :gpu) in methods
            
            # Total count: 8 CPU methods + 2 GPU methods = 10 methods
            Test.@test length(methods) == 10
        end

        Test.@testset "Parameter Distribution" begin
            methods = OptimalControl.methods()
            
            # Count CPU and GPU methods
            cpu_methods = filter(m -> m[4] == :cpu, methods)
            gpu_methods = filter(m -> m[4] == :gpu, methods)
            
            Test.@test length(cpu_methods) == 8  # All original methods now with :cpu
            Test.@test length(gpu_methods) == 2  # Only GPU-capable combinations
        end

        Test.@testset "Uniqueness" begin
            methods = OptimalControl.methods()
            Test.@test length(methods) == length(unique(methods))
        end

        Test.@testset "Determinism" begin
            m1 = OptimalControl.methods()
            m2 = OptimalControl.methods()
            Test.@test m1 === m2
        end

        Test.@testset "GPU Method Logic" begin
            methods = OptimalControl.methods()
            
            # GPU methods should only include GPU-capable strategies
            gpu_methods = filter(m -> m[4] == :gpu, methods)
            
            # All GPU methods should use Exa modeler (only GPU-capable modeler)
            Test.@test all(m -> m[2] == :exa, gpu_methods)
            
            # GPU methods should use GPU-capable solvers
            Test.@test all(m -> m[3] in (:madnlp, :madncl), gpu_methods)
        end

        # ====================================================================
        # PERFORMANCE TESTS
        # ====================================================================

        Test.@testset "Performance Characteristics" begin
            Test.@testset "Allocation-free" begin
                # methods() should be allocation-free (returns precomputed tuple)
                allocs = Test.@allocated OptimalControl.methods()
                Test.@test allocs == 0
            end

            Test.@testset "Type Stability" begin
                # Should be type stable
                Test.@test_nowarn Test.@inferred OptimalControl.methods()
            end

            Test.@testset "Multiple Calls Performance" begin
                # Multiple calls should be fast and allocation-free
                allocs_total = 0
                for i in 1:10
                    allocs_total += Test.@allocated OptimalControl.methods()
                end
                Test.@test allocs_total == 0
            end
        end

        # ====================================================================
        # EDGE CASE TESTS
        # ====================================================================

        Test.@testset "Edge Cases" begin
            Test.@testset "Method Structure Validation" begin
                methods = OptimalControl.methods()
                
                # All methods should be 4-tuples
                Test.@test all(length(m) == 4 for m in methods)
                
                # All elements should be symbols
                Test.@test all(all(x isa Symbol for x in m) for m in methods)
                
                # Parameter should be either :cpu or :gpu
                Test.@test all(m[4] in (:cpu, :gpu) for m in methods)
            end

            Test.@testset "Discretizer Consistency" begin
                methods = OptimalControl.methods()
                
                # All methods should use :collocation discretizer
                Test.@test all(m[1] == :collocation for m in methods)
            end

            Test.@testset "Modeler Distribution" begin
                methods = OptimalControl.methods()
                
                # Should have both adnlp and exa modelers
                modelers = Set(m[2] for m in methods)
                Test.@test :adnlp in modelers
                Test.@test :exa in modelers
                
                # Exa should appear in both CPU and GPU methods
                exa_methods = filter(m -> m[2] == :exa, methods)
                Test.@test any(m[4] == :cpu for m in exa_methods)
                Test.@test any(m[4] == :gpu for m in exa_methods)
            end

            Test.@testset "Solver Distribution" begin
                methods = OptimalControl.methods()
                
                # Should have all expected solvers
                solvers = Set(m[3] for m in methods)
                expected_solvers = Set([:ipopt, :madnlp, :madncl, :knitro])
                Test.@test issubset(expected_solvers, solvers)
                
                # GPU methods should only use GPU-capable solvers
                gpu_methods = filter(m -> m[4] == :gpu, methods)
                gpu_solvers = Set(m[3] for m in gpu_methods)
                Test.@test gpu_solvers == Set([:madnlp, :madncl])
            end
        end

        # ====================================================================
        # INTEGRATION TESTS
        # ====================================================================

        Test.@testset "Integration Scenarios" begin
            Test.@testset "Method Selection by Parameter" begin
                methods = OptimalControl.methods()
                
                cpu_methods = filter(m -> m[4] == :cpu, methods)
                gpu_methods = filter(m -> m[4] == :gpu, methods)
                
                # CPU methods should include all combinations except GPU-only
                Test.@test length(cpu_methods) == 8
                Test.@test length(gpu_methods) == 2
                
                # Total should match expected
                Test.@test length(methods) == length(cpu_methods) + length(gpu_methods)
            end

            Test.@testset "Method Compatibility" begin
                methods = OptimalControl.methods()
                
                # All methods should be compatible with the strategy registry
                # This is a basic sanity check - actual compatibility would require
                # checking against the registry which would be more complex
                Test.@test length(methods) > 0
                Test.@test all(m isa Tuple{Symbol, Symbol, Symbol, Symbol} for m in methods)
            end

            Test.@testset "Method Consistency Over Time" begin
                # Methods should be consistent across multiple calls
                methods1 = OptimalControl.methods()
                methods2 = OptimalControl.methods()
                methods3 = OptimalControl.methods()
                
                Test.@test methods1 == methods2 == methods3
                Test.@test methods1 === methods2 === methods3  # Should be identical object
            end
        end
    end
end

end # module

test_methods() = TestAvailableMethods.test_methods()
