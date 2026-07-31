# ============================================================================
# CTBase Reexports Tests
# ============================================================================
# CTBase grew considerably in v2.1.0-beta. It now owns:
#
#   - the `Data` type vocabulary `Flow` dispatches on   (was CTFlows)
#   - the whole strategy / option layer                 (was CTSolvers)
#   - the traits (`is_autonomous`, `has_variable`, …)   (re-exported by CTModels)
#
# ⚠️ Several of these names — `describe`, `options`, `name`, `value`, `id`,
# `force`, `parameter` — also exist in `Base` or in a sibling package, so
# `isdefined` proves nothing about them. Ownership assertions throughout.

module TestCtbase

using Test: Test
using OptimalControl # using is mandatory since we test exported symbols
using CTBase: CTBase

include(joinpath(@__DIR__, "..", "..", "helpers", "reexport.jl"))
using .ReexportUtils: reexports, imports, is_exported

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const CurrentModule = TestCtbase

# The `Data` vocabulary, grouped as in imports/ctbase.jl.
const DATA_TYPES = (
    # Vector fields
    :AbstractVectorField,
    :VectorField,
    :ControlledVectorField,
    :ComposedVectorField,
    :AbstractControlledVectorField,
    # Hamiltonians
    :AbstractHamiltonian,
    :Hamiltonian,
    :ComposedHamiltonian,
    :AbstractHamiltonianVectorField,
    :HamiltonianVectorField,
    # Pseudo-Hamiltonians
    :AbstractPseudoHamiltonian,
    :PseudoHamiltonian,
    :AbstractPseudoHamiltonianVectorField,
    :PseudoHamiltonianVectorField,
    # Control laws
    :AbstractControlLaw,
    :ControlLaw,
    # Path constraints
    :AbstractPathConstraint,
    :PathConstraint,
    # Multipliers
    :AbstractMultiplier,
    :Multiplier,
)

# ⚠️ These are *factory functions*, not types — a correction to what the
# migration report assumed. `OpenLoop`, `ClosedLoop` and `DynClosedLoop` all
# build a `ControlLaw{F,Kind,…}`; the three kinds are encoded in a trait
# parameter (`OpenLoopFeedback`, `ClosedLoopFeedback`, `DynClosedLoopFeedback`),
# not in three distinct types. Same story for the constraint kinds, which all
# build a `PathConstraint{F,Kind,…}`.
# Consequence: `OpenLoop <: AbstractControlLaw` is a `TypeError`, not a false
# assertion — dispatching on the kind means dispatching on the trait.
const DATA_FACTORIES = (
    # control-law kinds
    :OpenLoop,
    :ClosedLoop,
    :DynClosedLoop,
    # path-constraint kinds
    :StateConstraint,
    :ControlConstraint,
    :MixedConstraint,
)

function test_ctbase()
    Test.@testset "CTBase reexports" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@testset "Generated Code Prefix" begin
            Test.@test isdefined(OptimalControl, :CTBase)
            Test.@test isdefined(CurrentModule, :CTBase)
            Test.@test CTBase isa Module
        end

        # --------------------------------------------------------------------
        # Exceptions
        # --------------------------------------------------------------------
        Test.@testset "Exceptions" begin
            for T in (
                :CTException,
                :IncorrectArgument,
                :PreconditionError,
                :NotImplemented,
                :ParsingError,
                :AmbiguousDescription,
                :ExtensionError,
            )
                Test.@testset "$T" begin
                    Test.@test imports(OptimalControl, T, CTBase.Exceptions)
                    Test.@test !isdefined(CurrentModule, T)
                    Test.@test getfield(OptimalControl, T) isa DataType
                end
            end
        end

        Test.@testset "Exception inheritance" begin
            for T in (
                OptimalControl.IncorrectArgument,
                OptimalControl.PreconditionError,
                OptimalControl.NotImplemented,
                OptimalControl.ParsingError,
                OptimalControl.AmbiguousDescription,
                OptimalControl.ExtensionError,
            )
                Test.@test T <: OptimalControl.CTException
            end
        end

        # --------------------------------------------------------------------
        # Core
        # --------------------------------------------------------------------
        Test.@testset "Core" begin
            for T in (:NotProvided, :NotProvidedType, :ctNumber)
                Test.@test isdefined(OptimalControl, T)
                Test.@test !is_exported(OptimalControl, T)
            end
            # `NotProvided` is the default of the flow `variable=` keyword.
            Test.@test OptimalControl.NotProvided === CTBase.Core.NotProvided
        end

        # --------------------------------------------------------------------
        # Traits — owned by CTBase.Traits, re-exported by CTModels.Models
        # --------------------------------------------------------------------
        Test.@testset "Traits" begin
            for f in (
                :is_autonomous,
                :is_nonautonomous,
                :is_variable,
                :is_nonvariable,
                :has_variable,
                :has_control,
                :is_control_free,
            )
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTBase.Traits)
                    Test.@test isdefined(CurrentModule, f)
                end
            end
        end

        # --------------------------------------------------------------------
        # Data — moved here from CTFlows
        # --------------------------------------------------------------------
        Test.@testset "Data vocabulary" begin
            for T in DATA_TYPES
                Test.@testset "$T" begin
                    Test.@test reexports(OptimalControl, T, CTBase.Data)
                    Test.@test isdefined(CurrentModule, T)
                    Test.@test getfield(OptimalControl, T) isa DataType ||
                        getfield(OptimalControl, T) isa UnionAll
                end
            end
            for f in DATA_FACTORIES
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTBase.Data)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end

            Test.@testset "controlled_vector_field" begin
                # An accessor on a `ComposedVectorField`, not a constructor.
                # Its siblings `control_law` / `pseudo_hamiltonian` are the
                # CTFlows.Systems ones (§8) — this one has no homonym, so the
                # `Data` version is the one exported.
                Test.@test reexports(OptimalControl, :controlled_vector_field, CTBase.Data)
                Test.@test hasmethod(controlled_vector_field, Tuple{ComposedVectorField})
            end

            Test.@testset "hierarchy" begin
                Test.@test Hamiltonian <: AbstractHamiltonian
                Test.@test ComposedHamiltonian <: AbstractHamiltonian
                Test.@test VectorField <: AbstractVectorField
                Test.@test HamiltonianVectorField <: AbstractHamiltonianVectorField
                Test.@test PseudoHamiltonian <: AbstractPseudoHamiltonian
                Test.@test ControlLaw <: AbstractControlLaw
                Test.@test PathConstraint <: AbstractPathConstraint
                Test.@test Multiplier <: AbstractMultiplier
            end

            Test.@testset "control-law kinds are traits, not types" begin
                # The three kinds all build a `ControlLaw`; they differ by the
                # feedback trait parameter. Dispatching on the kind therefore
                # means dispatching on the trait.
                laws = (
                    OpenLoop(t -> 1.0),
                    ClosedLoop((t, x) -> 1.0),
                    DynClosedLoop((t, x, p) -> 1.0),
                )
                for l in laws
                    Test.@test l isa ControlLaw
                    Test.@test l isa AbstractControlLaw
                end
                # …and the traits really are distinct.
                Test.@test length(unique(typeof.(laws))) == 3
            end

            Test.@testset "constraint kinds are traits, not types" begin
                cs = (
                    StateConstraint(x -> x),
                    ControlConstraint(u -> u),
                    MixedConstraint((x, u) -> x),
                )
                for c in cs
                    Test.@test c isa PathConstraint
                    Test.@test c isa AbstractPathConstraint
                end
                Test.@test length(unique(typeof.(cs))) == 3
            end

            Test.@testset "constructor keywords use the is_ prefix" begin
                # ⚠️ v2.1.0-beta rename: `autonomous=` → `is_autonomous=`,
                # `variable=` → `is_variable=`.
                X = VectorField((t, x) -> [t + x[2], -x[1]]; is_autonomous=false)
                Test.@test X(1.0, [1.0, 2.0]) ≈ [3.0, -1.0]

                Xv = VectorField((x, v) -> [x[2] + v, -x[1]]; is_variable=true)
                Test.@test Xv([1.0, 2.0], 1.0) ≈ [3.0, -1.0]

                H = Hamiltonian((t, x, p) -> t + x[1] * p[1]; is_autonomous=false)
                Test.@test H(1.0, [1.0, 2.0], [3.0, 4.0]) ≈ 4.0

                Hv = Hamiltonian((x, p, v) -> v + x[1] * p[1]; is_variable=true)
                Test.@test Hv([1.0, 2.0], [3.0, 4.0], 1.0) ≈ 4.0
            end
        end

        # --------------------------------------------------------------------
        # Strategies — moved here from CTSolvers
        # --------------------------------------------------------------------
        Test.@testset "Strategy Types" begin
            for T in (
                :AbstractStrategy,
                :StrategyRegistry,
                :StrategyMetadata,
                :StrategyOptions,
                :RoutedOption,
                :BypassValue,
                :AbstractStrategyParameter,
            )
                Test.@testset "$T" begin
                    Test.@test imports(OptimalControl, T, CTBase.Strategies)
                    Test.@test !isdefined(CurrentModule, T)
                end
            end
        end

        Test.@testset "Strategy Parameters" begin
            for P in (:CPU, :GPU)
                Test.@test reexports(OptimalControl, P, CTBase.Strategies)
                Test.@test isdefined(CurrentModule, P)
                Test.@test getfield(OptimalControl, P) <:
                    OptimalControl.AbstractStrategyParameter
            end
        end

        Test.@testset "Strategy Functions" begin
            # `describe`, `options`, `id`, `force`, `parameter` all collide
            # with `Base` names — ownership is the only meaningful assertion.
            for f in (
                :id,
                :metadata,
                :describe,
                :options,
                :option_names,
                :option_type,
                :option_description,
                :option_default,
                :option_defaults,
                :option_value,
                :option_source,
                :has_option,
                :create_registry,
                :strategy_ids,
                :type_from_id,
                :parameter,
                :default_parameter,
                :available_parameters,
                :force,
                :route_to,
                :bypass,
            )
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTBase.Strategies)
                    Test.@test isdefined(CurrentModule, f)
                    Test.@test getfield(OptimalControl, f) isa Function
                end
            end

            Test.@testset "describe(::Symbol)" begin
                # OptimalControl adds a one-argument method that injects its
                # own registry — deliberate piracy, see src/helpers/describe.jl.
                Test.@test hasmethod(describe, Tuple{Symbol})
                Test.@test any(m -> parentmodule(m) === OptimalControl, methods(describe))
            end
        end

        # --------------------------------------------------------------------
        # Options
        # --------------------------------------------------------------------
        Test.@testset "Options" begin
            for T in (:OptionDefinition, :OptionValue)
                Test.@testset "$T" begin
                    # `OptionDefinition` is exported by both `Options` and
                    # `Strategies` — same object; `Options` is the owner.
                    Test.@test imports(OptimalControl, T, CTBase.Options)
                end
            end
            for f in (:is_user, :is_default, :is_computed)
                Test.@testset "$f" begin
                    Test.@test reexports(OptimalControl, f, CTBase.Options)
                    Test.@test isdefined(CurrentModule, f)
                end
            end

            Test.@testset "deliberate omissions" begin
                # `value` and `name` are genuine homonyms across CTBase.Options
                # and CTModels.Components. `name` goes to CTModels (§8);
                # `value` is internal on both sides and exported by neither.
                Test.@test getfield(OptimalControl, :name) !==
                    getfield(CTBase.Options, :name)
                Test.@test !is_exported(OptimalControl, :value)
                # `description` is a homonym across Options and Strategies.
                Test.@test !is_exported(OptimalControl, :description)
                # No export at all for the tag hierarchy.
                Test.@test !isdefined(OptimalControl, :AbstractTag)
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_ctbase() = TestCtbase.test_ctbase()
