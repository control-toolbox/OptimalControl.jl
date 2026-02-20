module TestCoverageOptions

import Test
import CTBase.Exceptions
import CTSolvers
import CTSolvers.Options
import CTSolvers.Strategies
import CTSolvers.Modelers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# Fake strategy for testing (must be at module top-level)
# ============================================================================

struct CovOptFakeStrategy <: Strategies.AbstractStrategy
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:CovOptFakeStrategy}) = :cov_opt_fake

Strategies.metadata(::Type{<:CovOptFakeStrategy}) = Strategies.StrategyMetadata(
    Options.OptionDefinition(
        name = :alpha,
        type = Float64,
        default = 1.0,
        description = "Alpha parameter"
    )
)

function test_coverage_options()
    Test.@testset "Coverage: Options & StrategyOptions" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - NotStored display (not_provided.jl)
        # ====================================================================

        Test.@testset "NotStored display" begin
            buf = IOBuffer()
            show(buf, Options.NotStored)
            Test.@test String(take!(buf)) == "NotStored"
        end

        Test.@testset "NotProvided display" begin
            buf = IOBuffer()
            show(buf, Options.NotProvided)
            Test.@test String(take!(buf)) == "NotProvided"
        end

        Test.@testset "NotStored type" begin
            Test.@test Options.NotStored isa Options.NotStoredType
            Test.@test typeof(Options.NotStored) == Options.NotStoredType
        end

        # ====================================================================
        # UNIT TESTS - StrategyOptions (strategy_options.jl)
        # ====================================================================

        Test.@testset "StrategyOptions - invalid value type" begin
            Test.@test_throws Exceptions.IncorrectArgument Strategies.StrategyOptions(
                (bad_key = 42,)
            )
        end

        Test.@testset "StrategyOptions - getproperty :options" begin
            opts = Strategies.StrategyOptions(
                alpha = Options.OptionValue(1.0, :default)
            )
            Test.@test opts.options isa NamedTuple
            Test.@test opts.alpha isa Options.OptionValue
            Test.@test Options.value(opts.alpha) == 1.0
        end

        Test.@testset "StrategyOptions - getindex" begin
            opts = Strategies.StrategyOptions(
                alpha = Options.OptionValue(2.0, :user)
            )
            Test.@test opts[:alpha] == 2.0
        end

        Test.@testset "StrategyOptions - get(Val)" begin
            opts = Strategies.StrategyOptions(
                alpha = Options.OptionValue(3.0, :computed)
            )
            Test.@test get(opts, Val(:alpha)) == 3.0
        end

        Test.@testset "StrategyOptions - source helpers" begin
            opts = Strategies.StrategyOptions(
                a = Options.OptionValue(1, :user),
                b = Options.OptionValue(2, :default),
                c = Options.OptionValue(3, :computed)
            )
            Test.@test Strategies.source(opts, :a) === :user
            Test.@test Strategies.source(opts, :b) === :default
            Test.@test Strategies.source(opts, :c) === :computed
            Test.@test Strategies.is_user(opts, :a) === true
            Test.@test Strategies.is_user(opts, :b) === false
            Test.@test Strategies.is_default(opts, :b) === true
            Test.@test Strategies.is_default(opts, :a) === false
            Test.@test Strategies.is_computed(opts, :c) === true
            Test.@test Strategies.is_computed(opts, :a) === false
        end

        Test.@testset "StrategyOptions - _raw_options" begin
            opts = Strategies.StrategyOptions(
                x = Options.OptionValue(10, :user)
            )
            raw = Strategies._raw_options(opts)
            Test.@test raw isa NamedTuple
            Test.@test raw.x isa Options.OptionValue
        end

        Test.@testset "StrategyOptions - collection interface" begin
            opts = Strategies.StrategyOptions(
                a = Options.OptionValue(1, :user),
                b = Options.OptionValue(2, :default)
            )

            # keys
            Test.@test :a in keys(opts)
            Test.@test :b in keys(opts)

            # values
            vals = collect(values(opts))
            Test.@test 1 in vals
            Test.@test 2 in vals

            # pairs
            ps = collect(pairs(opts))
            Test.@test any(p -> p.first == :a && p.second == 1, ps)

            # length
            Test.@test length(opts) == 2

            # isempty
            Test.@test !isempty(opts)
            Test.@test isempty(Strategies.StrategyOptions())

            # haskey
            Test.@test haskey(opts, :a)
            Test.@test !haskey(opts, :nonexistent)

            # iterate
            collected = []
            for v in opts
                push!(collected, v)
            end
            Test.@test length(collected) == 2
            Test.@test 1 in collected
            Test.@test 2 in collected
        end

        Test.@testset "StrategyOptions - display" begin
            opts = Strategies.StrategyOptions(
                a = Options.OptionValue(1, :user),
                b = Options.OptionValue(2, :default)
            )

            # Pretty display
            buf = IOBuffer()
            show(buf, MIME("text/plain"), opts)
            output = String(take!(buf))
            Test.@test occursin("StrategyOptions", output)
            Test.@test occursin("2 options", output)
            Test.@test occursin("a = 1", output)
            Test.@test occursin("user", output)

            # Compact display
            buf2 = IOBuffer()
            show(buf2, opts)
            output2 = String(take!(buf2))
            Test.@test occursin("StrategyOptions(", output2)
            Test.@test occursin("a=1", output2)

            # Single option (singular)
            opts1 = Strategies.StrategyOptions(
                x = Options.OptionValue(42, :default)
            )
            buf3 = IOBuffer()
            show(buf3, MIME("text/plain"), opts1)
            output3 = String(take!(buf3))
            Test.@test occursin("1 option:", output3)
        end

        # ====================================================================
        # UNIT TESTS - StrategyRegistry display (registry.jl)
        # ====================================================================

        Test.@testset "StrategyRegistry - display" begin
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (CovOptFakeStrategy,)
            )

            # Compact display
            buf = IOBuffer()
            show(buf, registry)
            output = String(take!(buf))
            Test.@test occursin("StrategyRegistry", output)
            Test.@test occursin("1 family", output)

            # Pretty display
            buf2 = IOBuffer()
            show(buf2, MIME("text/plain"), registry)
            output2 = String(take!(buf2))
            Test.@test occursin("StrategyRegistry", output2)
            Test.@test occursin("cov_opt_fake", output2)
        end

        Test.@testset "StrategyRegistry - validation errors" begin
            # Invalid family type
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                Int => (CovOptFakeStrategy,)
            )

            # Invalid strategies format (not a tuple)
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                Strategies.AbstractStrategy => [CovOptFakeStrategy]
            )

            # Duplicate family
            Test.@test_throws Exceptions.IncorrectArgument Strategies.create_registry(
                Strategies.AbstractStrategy => (CovOptFakeStrategy,),
                Strategies.AbstractStrategy => (CovOptFakeStrategy,)
            )

            # Family not found in registry
            registry = Strategies.create_registry(
                Strategies.AbstractStrategy => (CovOptFakeStrategy,)
            )
            Test.@test_throws Exceptions.IncorrectArgument Strategies.strategy_ids(
                Modelers.AbstractNLPModeler, registry
            )

            # Unknown strategy ID
            Test.@test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                :nonexistent, Strategies.AbstractStrategy, registry
            )

            # Family not found in type_from_id
            Test.@test_throws Exceptions.IncorrectArgument Strategies.type_from_id(
                :cov_opt_fake, Modelers.AbstractNLPModeler, registry
            )
        end
    end
end

end # module

test_coverage_options() = TestCoverageOptions.test_coverage_options()
