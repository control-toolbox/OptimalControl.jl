module TestCoverageAbstractStrategy

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Strategies
import CTSolvers.Options

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake strategy types for testing (must be at module top-level)
# ============================================================================

struct CovFakeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:CovFakeStrategy}) = :cov_fake

Strategies.metadata(::Type{<:CovFakeStrategy}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :max_iter,
        type = Int,
        default = 100,
        description = "Maximum iterations",
        aliases = (:maxiter,)
    ),
    Options.OptionDefinition(
        name = :tol,
        type = Float64,
        default = 1e-6,
        description = "Convergence tolerance"
    )
)

Strategies.options(s::CovFakeStrategy) = s.options

struct CovNoOptionsStrategy <: Strategies.AbstractStrategy
    data::Int
end

Strategies.id(::Type{<:CovNoOptionsStrategy}) = :cov_no_opts

Strategies.metadata(::Type{<:CovNoOptionsStrategy}) = Strategies.StrategyMetadata()

struct CovNoIdStrategy <: Strategies.AbstractStrategy end

struct CovNoMetaStrategy <: Strategies.AbstractStrategy end

Strategies.id(::Type{<:CovNoMetaStrategy}) = :cov_no_meta

# Single-option strategy for singular display
struct CovSingleOptStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:CovSingleOptStrategy}) = :cov_single

Strategies.metadata(::Type{<:CovSingleOptStrategy}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :value,
        type = Int,
        default = 42,
        description = "Single value"
    )
)

Strategies.options(s::CovSingleOptStrategy) = s.options

# ============================================================================
# Test function
# ============================================================================

function test_coverage_abstract_strategy()
    Test.@testset "Coverage: Abstract Strategy" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - show(io, MIME"text/plain", strategy) - pretty display
        # ====================================================================

        Test.@testset "show(io, MIME text/plain) - instance display" begin
            opts = Strategies.StrategyOptions(
                max_iter = Options.OptionValue(200, :user),
                tol = Options.OptionValue(1e-8, :default)
            )
            strategy = CovFakeStrategy(opts)

            buf = IOBuffer()
            show(buf, MIME("text/plain"), strategy)
            output = String(take!(buf))

            Test.@test occursin("CovFakeStrategy", output)
            Test.@test occursin("instance", output)
            Test.@test occursin("cov_fake", output)
            Test.@test occursin("max_iter", output)
            Test.@test occursin("200", output)
            Test.@test occursin("user", output)
            Test.@test occursin("tol", output)
            Test.@test occursin("default", output)
            Test.@test occursin("Tip:", output)
        end

        Test.@testset "show(io, MIME text/plain) - no id" begin
            opts = Strategies.StrategyOptions()
            strategy = CovNoIdStrategy()

            buf = IOBuffer()
            show(buf, MIME("text/plain"), strategy)
            output = String(take!(buf))

            Test.@test occursin("CovNoIdStrategy", output)
            Test.@test occursin("instance", output)
            Test.@test !occursin("id:", output)
        end

        Test.@testset "show(io, MIME text/plain) - no options" begin
            strategy = CovNoOptionsStrategy(42)

            buf = IOBuffer()
            show(buf, MIME("text/plain"), strategy)
            output = String(take!(buf))

            Test.@test occursin("CovNoOptionsStrategy", output)
            Test.@test occursin("Tip:", output)
        end

        Test.@testset "show(io, MIME text/plain) - single option (└─ prefix)" begin
            opts = Strategies.StrategyOptions(
                value = Options.OptionValue(42, :default)
            )
            strategy = CovSingleOptStrategy(opts)

            buf = IOBuffer()
            show(buf, MIME("text/plain"), strategy)
            output = String(take!(buf))

            Test.@test occursin("└─", output)
            Test.@test occursin("value", output)
        end

        # ====================================================================
        # UNIT TESTS - show(io, strategy) - compact display
        # ====================================================================

        Test.@testset "show(io, strategy) - compact display" begin
            opts = Strategies.StrategyOptions(
                max_iter = Options.OptionValue(200, :user),
                tol = Options.OptionValue(1e-8, :default)
            )
            strategy = CovFakeStrategy(opts)

            buf = IOBuffer()
            show(buf, strategy)
            output = String(take!(buf))

            Test.@test occursin("CovFakeStrategy(", output)
            Test.@test occursin("max_iter=200", output)
            Test.@test occursin("tol=", output)
            Test.@test occursin(")", output)
        end

        Test.@testset "show(io, strategy) - no options" begin
            strategy = CovNoOptionsStrategy(42)

            buf = IOBuffer()
            show(buf, strategy)
            output = String(take!(buf))

            Test.@test occursin("CovNoOptionsStrategy(", output)
            Test.@test occursin(")", output)
        end

        # ====================================================================
        # UNIT TESTS - describe(strategy_type)
        # ====================================================================

        Test.@testset "describe(strategy_type) - full metadata" begin
            buf = IOBuffer()
            Strategies.describe(buf, CovFakeStrategy)
            output = String(take!(buf))

            Test.@test occursin("CovFakeStrategy", output)
            Test.@test occursin("strategy type", output)
            Test.@test occursin("cov_fake", output)
            Test.@test occursin("supertype", output)
            Test.@test occursin("metadata", output)
            Test.@test occursin("2 options defined", output)
            Test.@test occursin("max_iter", output)
            Test.@test occursin("tol", output)
            Test.@test occursin("description:", output)
        end

        Test.@testset "describe(strategy_type) - single option (singular)" begin
            buf = IOBuffer()
            Strategies.describe(buf, CovSingleOptStrategy)
            output = String(take!(buf))

            Test.@test occursin("1 option defined", output)
            Test.@test occursin("└─", output)
        end

        Test.@testset "describe(strategy_type) - no metadata (early return)" begin
            buf = IOBuffer()
            Strategies.describe(buf, CovNoIdStrategy)
            output = String(take!(buf))

            Test.@test occursin("CovNoIdStrategy", output)
            Test.@test occursin("supertype", output)
            Test.@test !occursin("metadata", output)
        end

        Test.@testset "describe(strategy_type) - empty metadata (0 options)" begin
            buf = IOBuffer()
            Strategies.describe(buf, CovNoOptionsStrategy)
            output = String(take!(buf))

            Test.@test occursin("CovNoOptionsStrategy", output)
            Test.@test occursin("0 options defined", output)
        end

        Test.@testset "describe(stdout, strategy_type)" begin
            redirect_stdout(devnull) do
                Test.@test_nowarn Strategies.describe(CovFakeStrategy)
            end
        end

        # ====================================================================
        # UNIT TESTS - options() default with field access
        # ====================================================================

        Test.@testset "options() default - field access" begin
            opts = Strategies.StrategyOptions(
                max_iter = Options.OptionValue(100, :default)
            )
            strategy = CovFakeStrategy(opts)
            Test.@test Strategies.options(strategy) === opts
        end

        Test.@testset "options() default - no options field" begin
            strategy = CovNoOptionsStrategy(42)
            Test.@test_throws Exceptions.NotImplemented Strategies.options(strategy)
        end

        # ====================================================================
        # UNIT TESTS - NotImplemented errors
        # ====================================================================

        Test.@testset "NotImplemented errors" begin
            Test.@test_throws Exceptions.NotImplemented Strategies.id(CovNoIdStrategy)
            Test.@test_throws Exceptions.NotImplemented Strategies.metadata(CovNoIdStrategy)
        end
    end
end

end # module

test_coverage_abstract_strategy() = TestCoverageAbstractStrategy.test_coverage_abstract_strategy()
