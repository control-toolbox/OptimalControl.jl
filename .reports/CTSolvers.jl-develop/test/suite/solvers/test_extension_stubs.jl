module TestExtensionStubs

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Solvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

struct DummyTag <: Solvers.AbstractTag end

"""
    test_extension_stubs()

Tests for extension stub functions throwing ExtensionError.

🧪 **Applying Testing Rule**: Error Tests

Tests that stub functions throw appropriate ExtensionError when extensions
are not loaded, with helpful error messages.
"""
function test_extension_stubs()
    Test.@testset "Extension Stubs" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ====================================================================
        # UNIT TESTS - Solvers.Ipopt Stub
        # ====================================================================
        
        Test.@testset "Solvers.Ipopt stub" begin
            # Test that build_ipopt_solver throws ExtensionError with IpoptTag
            Test.@test_throws Exceptions.ExtensionError Solvers.build_ipopt_solver(DummyTag())
            
            # Capture the error and verify its content
            err = nothing
            try
                Solvers.build_ipopt_solver(DummyTag())
            catch e
                err = e
            end
            
            Test.@test err isa Exceptions.ExtensionError
            
            # Verify error message content
            err_str = string(err)
            Test.@test occursin("Ipopt", err_str)
            Test.@test occursin("NLPModelsIpopt", err_str)
            Test.@test occursin("to create Ipopt, access options, and solve problems", err_str)
        end
        
        # ====================================================================
        # UNIT TESTS - Solvers.Knitro Stub (Commented out - no license)
        # ====================================================================
        
        # Commented out - no Knitro license available
        # Test.@testset "Solvers.Knitro stub" begin
        #     Test.@test_throws Exceptions.ExtensionError Solvers.build_knitro_solver(DummyTag())
        #     
        #     err = nothing
        #     try
        #         Solvers.build_knitro_solver(DummyTag())
        #     catch e
        #         err = e
        #     end
        #     
        #     Test.@test err isa Exceptions.ExtensionError
        #     
        #     err_str = string(err)
        #     Test.@test occursin("Knitro", err_str)
        #     Test.@test occursin("NLPModelsKnitro", err_str)
        #     Test.@test occursin("to create Knitro, access options, and solve problems", err_str)
        # end
        
        # ====================================================================
        # UNIT TESTS - Solvers.MadNLP Stub
        # ====================================================================
        
        Test.@testset "Solvers.MadNLP stub" begin
            Test.@test_throws Exceptions.ExtensionError Solvers.build_madnlp_solver(DummyTag())
            
            err = nothing
            try
                Solvers.build_madnlp_solver(DummyTag())
            catch e
                err = e
            end
            
            Test.@test err isa Exceptions.ExtensionError
            
            err_str = string(err)
            Test.@test occursin("MadNLP", err_str)
            Test.@test occursin("MadNLP", err_str)
            Test.@test occursin("to create MadNLP, access options, and solve problems", err_str)
        end
        
        # ====================================================================
        # UNIT TESTS - Solvers.MadNCL Stub
        # ====================================================================
        
        Test.@testset "Solvers.MadNCL stub" begin
            Test.@test_throws Exceptions.ExtensionError Solvers.build_madncl_solver(DummyTag())
            
            err = nothing
            try
                Solvers.build_madncl_solver(DummyTag())
            catch e
                err = e
            end
            
            Test.@test err isa Exceptions.ExtensionError
            
            err_str = string(err)
            Test.@test occursin("MadNCL", err_str)
            Test.@test occursin("MadNCL", err_str)
            Test.@test occursin("to create MadNCL, access options, and solve problems", err_str)
        end
        
        # ====================================================================
        # UNIT TESTS - All Stubs Throw Consistently
        # ====================================================================
        
        Test.@testset "All stubs throw ExtensionError" begin
            # Verify that all build_*_solver stubs throw ExtensionError
            stubs = [
                () -> Solvers.build_ipopt_solver(DummyTag()),
                # Commented out - no Knitro license available
                # () -> Solvers.build_knitro_solver(DummyTag()),
                () -> Solvers.build_madnlp_solver(DummyTag()),
                () -> Solvers.build_madncl_solver(DummyTag())
            ]
            
            for stub in stubs
                Test.@test_throws Exceptions.ExtensionError stub()
            end
        end
    end
end

end # module

test_extension_stubs() = TestExtensionStubs.test_extension_stubs()
