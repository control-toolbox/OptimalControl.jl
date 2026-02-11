# Optimal control-level tests for solve on OCPs.

struct OCDummyOCP <: CTModels.AbstractOptimalControlProblem end

struct OCDummyDiscretizedOCP <: CTModels.AbstractOptimizationProblem end

struct OCDummyInit <: CTModels.AbstractOptimalControlInitialGuess
    x0::Vector{Float64}
end

struct OCDummyStats <: SolverCore.AbstractExecutionStats
    tag::Symbol
end

struct OCDummySolution <: CTModels.AbstractOptimalControlSolution end

struct OCFakeDiscretizer <: CTDirect.AbstractOptimalControlDiscretizer
    calls::Base.RefValue{Int}
end

function (d::OCFakeDiscretizer)(ocp::CTModels.AbstractOptimalControlProblem)
    d.calls[] += 1
    return OCDummyDiscretizedOCP()
end

struct OCFakeModeler <: CTModels.AbstractOptimizationModeler
    model_calls::Base.RefValue{Int}
    solution_calls::Base.RefValue{Int}
end

function (m::OCFakeModeler)(
    prob::CTModels.AbstractOptimizationProblem, init::OCDummyInit
)::NLPModels.AbstractNLPModel
    m.model_calls[] += 1
    f(z) = sum(z .^ 2)
    return ADNLPModels.ADNLPModel(f, init.x0)
end

function (m::OCFakeModeler)(
    prob::CTModels.AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    m.solution_calls[] += 1
    return OCDummySolution()
end

struct OCFakeSolverNLP <: CTSolvers.AbstractOptimizationSolver
    calls::Base.RefValue{Int}
end

function (s::OCFakeSolverNLP)(
    nlp::NLPModels.AbstractNLPModel; display::Bool
)::SolverCore.AbstractExecutionStats
    s.calls[] += 1
    return OCDummyStats(:solver_called)
end

function test_optimalcontrol_solve_api()
    Test.@testset "raw defaults" verbose = VERBOSE showtiming = SHOWTIMING begin
        Test.@test OptimalControl.OptimalControl.__initial_guess() === nothing
    end

    Test.@testset "description helpers" verbose = VERBOSE showtiming = SHOWTIMING begin
        methods = OptimalControl.available_methods()
        Test.@test !isempty(methods)

        first_method = methods[1]
        Test.@test first_method[1] === :collocation
        Test.@test any(
            m -> m[1] === :collocation && (:adnlp in m) && (:ipopt in m), methods
        )

        # Partial descriptions are completed using complete with priority order.
        method_from_disc = CTBase.complete(:collocation; descriptions=methods)
        Test.@test :collocation in method_from_disc

        method_from_solver = CTBase.complete(:ipopt; descriptions=methods)
        Test.@test :ipopt in method_from_solver

        # Discretizer options registry: keys inferred from the Collocation tool
        method = (:collocation, :adnlp, :ipopt)
        keys_from_method = OptimalControl._discretizer_options_keys(method)
        keys_from_type = CTModels.options_keys(OptimalControl.Collocation)
        Test.@test keys_from_method == keys_from_type

        # Discretizer symbol helper
        for m in methods
            Test.@test OptimalControl._get_discretizer_symbol(m) === :collocation
        end

        # Error when no discretizer symbol is present in the method
        Test.@test_throws OptimalControl.IncorrectArgument OptimalControl._get_discretizer_symbol((
            :adnlp, :ipopt
        ))

        # Modeler and solver symbol helpers using registries
        for m in methods
            msym = OptimalControl._get_modeler_symbol(m)
            Test.@test msym in OptimalControl.CTModels.modeler_symbols()
            ssym = OptimalControl._get_solver_symbol(m)
            Test.@test ssym in CTSolvers.solver_symbols()
        end

        # _modeler_options_keys / _solver_options_keys should match options_keys
        method_ad_ip = (:collocation, :adnlp, :ipopt)
        Test.@test Set(OptimalControl._modeler_options_keys(method_ad_ip)) ==
                   Set(CTModels.options_keys(OptimalControl.ADNLPModeler))
        Test.@test Set(OptimalControl._solver_options_keys(method_ad_ip)) ==
                   Set(CTModels.options_keys(OptimalControl.IpoptSolver))

        method_exa_mad = (:collocation, :exa, :madnlp)
        Test.@test Set(OptimalControl._modeler_options_keys(method_exa_mad)) ==
                   Set(CTModels.options_keys(OptimalControl.ExaModeler))
        Test.@test Set(OptimalControl._solver_options_keys(method_exa_mad)) ==
                   Set(CTModels.options_keys(OptimalControl.MadNLPSolver))

        # Multiple symbols of the same family in a method should raise an error
        Test.@test_throws OptimalControl.IncorrectArgument OptimalControl._get_modeler_symbol((
            :collocation, :adnlp, :exa, :ipopt
        ))
        Test.@test_throws OptimalControl.IncorrectArgument OptimalControl._get_solver_symbol((
            :collocation, :adnlp, :ipopt, :madnlp
        ))

        # _build_modeler_from_method should construct the appropriate modeler
        m_ad = OptimalControl._build_modeler_from_method(
            (:collocation, :adnlp, :ipopt), (; backend=:manual)
        )
        Test.@test m_ad isa OptimalControl.ADNLPModeler

        m_exa = OptimalControl._build_modeler_from_method(
            (:collocation, :exa, :ipopt), NamedTuple()
        )
        Test.@test m_exa isa OptimalControl.ExaModeler

        # _build_solver_from_method should construct the appropriate solver
        s_ip = OptimalControl._build_solver_from_method(
            (:collocation, :adnlp, :ipopt), NamedTuple()
        )
        Test.@test s_ip isa OptimalControl.IpoptSolver

        s_mad = OptimalControl._build_solver_from_method(
            (:collocation, :adnlp, :madnlp), NamedTuple()
        )
        Test.@test s_mad isa OptimalControl.MadNLPSolver

        # Modeler options normalization helper
        Test.@test OptimalControl._normalize_modeler_options(nothing) === NamedTuple()
        Test.@test OptimalControl._normalize_modeler_options((backend=:manual,)) ==
                   (backend=:manual,)
        Test.@test OptimalControl._normalize_modeler_options((; backend=:manual)) ==
                   (backend=:manual,)

        Test.@testset "description ambiguity pre-check (ownerless key)" verbose = VERBOSE showtiming = SHOWTIMING begin
            method = (:collocation, :adnlp, :ipopt)

            # foo does not correspond to any tool nor to solve -> error
            Test.@test_throws OptimalControl.IncorrectArgument begin
                OptimalControl._ensure_no_ambiguous_description_kwargs(method, (foo=1,))
            end
        end
    end

    Test.@testset "option routing helpers" verbose = VERBOSE showtiming = SHOWTIMING begin
        # _extract_option_tool without explicit tool tag
        v, tool = OptimalControl._extract_option_tool(1.0)
        Test.@test v == 1.0
        Test.@test tool === nothing

        # _extract_option_tool with explicit tool tag
        v2, tool2 = OptimalControl._extract_option_tool((42, :solver))
        Test.@test v2 == 42
        Test.@test tool2 === :solver

        # Non-ambiguous routing: single owner
        v3, owner3 = OptimalControl._route_option_for_description(
            :tol, 1e-6, Symbol[:solver], :description
        )
        Test.@test v3 == 1e-6
        Test.@test owner3 === :solver

        # Unknown ownership: empty owner list
        owners_empty = Symbol[]
        Test.@test_throws OptimalControl.IncorrectArgument OptimalControl._route_option_for_description(
            :foo, 1, owners_empty, :description
        )

        # Ambiguous ownership in description mode
        owners_amb = Symbol[:discretizer, :solver]
        err = nothing
        try
            OptimalControl._route_option_for_description(:foo, 1.0, owners_amb, :description)
        catch e
            err = e
        end
        Test.@test err isa OptimalControl.IncorrectArgument

        # Disambiguation via (value, tool)
        v4, owner4 = OptimalControl._route_option_for_description(
            :foo, (2.0, :solver), owners_amb, :description
        )
        Test.@test v4 == 2.0
        Test.@test owner4 === :solver

        # Ambiguous when coming from explicit mode should also throw
        Test.@test_throws OptimalControl.IncorrectArgument OptimalControl._route_option_for_description(
            :foo, 1.0, owners_amb, :explicit
        )
    end

    Test.@testset "description kwarg splitting" verbose = VERBOSE showtiming = SHOWTIMING begin
        # Ensure that description-mode parsing and splitting of kwargs produces
        # well-typed NamedTuples and routes options to the expected tools.
        parsed = OptimalControl._parse_top_level_kwargs_description((
            initial_guess=OCDummyInit([1.0, 2.0]),
            display=false,
            modeler_options=(backend=:manual,),
            tol=1e-6,
        ))

        pieces = OptimalControl._split_kwargs_for_description(
            (:collocation, :adnlp, :ipopt), parsed
        )

        Test.@test pieces.initial_guess isa OCDummyInit
        Test.@test pieces.display == false
        Test.@test pieces.disc_kwargs == NamedTuple()
        Test.@test pieces.modeler_options == (backend=:manual,)
        Test.@test haskey(pieces.solver_kwargs, :tol)
        Test.@test pieces.solver_kwargs.tol == 1e-6

        # Solve-level aliases should be accepted in description mode.
        parsed_alias = OptimalControl._parse_top_level_kwargs_description((
            init=OCDummyInit([3.0, 4.0]),
            display=false,
            modeler_options=(backend=:manual,),
            tol=2e-6,
        ))

        pieces_alias = OptimalControl._split_kwargs_for_description(
            (:collocation, :adnlp, :ipopt), parsed_alias
        )

        Test.@test pieces_alias.initial_guess isa OCDummyInit
        Test.@test pieces_alias.display == false
        Test.@test pieces_alias.disc_kwargs == NamedTuple()
        Test.@test pieces_alias.modeler_options == (backend=:manual,)
        Test.@test haskey(pieces_alias.solver_kwargs, :tol)
        Test.@test pieces_alias.solver_kwargs.tol == 2e-6

        # Conflicting aliases for initial_guess should raise.
        Test.@test_throws OptimalControl.IncorrectArgument begin
            OptimalControl._parse_top_level_kwargs_description((
                initial_guess=OCDummyInit([1.0, 2.0]), i=OCDummyInit([3.0, 4.0])
            ))
        end

        Test.@testset "description-mode solve/tool disambiguation" verbose = VERBOSE showtiming = SHOWTIMING begin
            init = OCDummyInit([1.0, 2.0])

            # 1) Alias i tagged :solve -> used as initial_guess, not kept in other_kwargs
            parsed_solve = OptimalControl._parse_top_level_kwargs_description((
                i=(init, :solve), tol=1e-6
            ))

            Test.@test parsed_solve.initial_guess isa OCDummyInit
            Test.@test parsed_solve.initial_guess === init
            Test.@test !haskey(parsed_solve.other_kwargs, :i)
            Test.@test haskey(parsed_solve.other_kwargs, :tol)
            Test.@test parsed_solve.other_kwargs.tol == 1e-6

            # 2) Alias i tagged :solver -> ignored by solve, left for the tools
            parsed_solver = OptimalControl._parse_top_level_kwargs_description((
                i=(init, :solver), tol=2e-6
            ))

            # initial_guess stays at its default, alias i is kept in other_kwargs
            Test.@test parsed_solver.initial_guess === OptimalControl.__initial_guess()
            Test.@test haskey(parsed_solver.other_kwargs, :i)
            Test.@test parsed_solver.other_kwargs.i == (init, :solver)
            Test.@test haskey(parsed_solver.other_kwargs, :tol)
            Test.@test parsed_solver.other_kwargs.tol == 2e-6

            # 3) display tagged :solve -> top-level display
            parsed_display_solve = OptimalControl._parse_top_level_kwargs_description((
                display=(false, :solve),
            ))
            Test.@test parsed_display_solve.display == false
            Test.@test !haskey(parsed_display_solve.other_kwargs, :display)

            # 4) display tagged :solver -> ignored by solve, left for the tools
            parsed_display_solver = OptimalControl._parse_top_level_kwargs_description((
                display=(false, :solver),
            ))
            Test.@test parsed_display_solver.display == OptimalControl.__display()
            Test.@test haskey(parsed_display_solver.other_kwargs, :display)
            Test.@test parsed_display_solver.other_kwargs.display == (false, :solver)
        end
    end

    Test.@testset "explicit-mode solve kwarg aliases" verbose = VERBOSE showtiming = SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        # Using the "init" alias for initial_guess.
        sol_init = solve(
            prob;
            init=init,
            discretizer=discretizer,
            modeler=modeler,
            solver=solver,
            display=false,
        )
        Test.@test sol_init isa OCDummySolution

        # Using the short "i" alias for initial_guess.
        discretizer_calls[] = 0
        model_calls[] = 0
        solution_calls[] = 0
        solver_calls[] = 0

        sol_i = solve(
            prob;
            i=init,
            discretizer=discretizer,
            modeler=modeler,
            solver=solver,
            display=false,
        )
        Test.@test sol_i isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1

        # Short aliases for components d/m/s in explicit mode.
        discretizer_calls[] = 0
        model_calls[] = 0
        solution_calls[] = 0
        solver_calls[] = 0

        sol_dms = solve(
            prob; initial_guess=init, d=discretizer, m=modeler, s=solver, display=false
        )
        Test.@test sol_dms isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1

        # Conflicting aliases for initial_guess in explicit mode should raise.
        Test.@test_throws OptimalControl.IncorrectArgument begin
            solve(
                prob;
                initial_guess=init,
                init=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
            )
        end
    end

    Test.@testset "display helpers" verbose = VERBOSE showtiming = SHOWTIMING begin
        method = (:collocation, :adnlp, :ipopt)
        discretizer = OptimalControl.Collocation()
        modeler = OptimalControl.ADNLPModeler()
        solver = OptimalControl.IpoptSolver()

        buf = sprint() do io
            OptimalControl._display_ocp_method(
                io, method, discretizer, modeler, solver; display=true
            )
        end
        Test.@test occursin("ADNLPModels", buf)
        Test.@test occursin("NLPModelsIpopt", buf)
    end

    # ========================================================================
    # Unit test: solve(ocp, init, discretizer, modeler, solver)
    # ========================================================================

    Test.@testset "solve(ocp, init, discretizer, modeler, solver)" verbose = VERBOSE showtiming = SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        sol = OptimalControl._solve(prob, init, discretizer, modeler, solver; display=false)

        Test.@test sol isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    Test.@testset "explicit-mode kwarg validation" verbose = VERBOSE showtiming = SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        # modeler_options is forbidden in explicit mode
        Test.@test_throws OptimalControl.IncorrectArgument begin
            solve(
                prob;
                initial_guess=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
                modeler_options=(backend=:manual,),
            )
        end

        # Unknown kwargs are rejected in explicit mode
        Test.@test_throws OptimalControl.IncorrectArgument begin
            solve(
                prob;
                initial_guess=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
                unknown_kwarg=1,
            )
        end

        # Mixing description with explicit components is rejected
        Test.@test_throws OptimalControl.IncorrectArgument begin
            solve(
                prob,
                :collocation;
                initial_guess=init,
                discretizer=discretizer,
                display=false,
            )
        end
    end

    Test.@testset "solve(ocp; kwargs)" verbose = VERBOSE showtiming = SHOWTIMING begin
        prob = OCDummyOCP()
        init = OCDummyInit([1.0, 2.0])

        discretizer_calls = Ref(0)
        model_calls = Ref(0)
        solution_calls = Ref(0)
        solver_calls = Ref(0)

        discretizer = OCFakeDiscretizer(discretizer_calls)
        modeler = OCFakeModeler(model_calls, solution_calls)
        solver = OCFakeSolverNLP(solver_calls)

        sol = solve(
            prob;
            initial_guess=init,
            discretizer=discretizer,
            modeler=modeler,
            solver=solver,
            display=false,
        )

        Test.@test sol isa OCDummySolution
        Test.@test discretizer_calls[] == 1
        Test.@test model_calls[] == 1
        Test.@test solver_calls[] == 1
        Test.@test solution_calls[] == 1
    end

    # ========================================================================
    # Integration tests: Beam OCP level with Ipopt and MadNLP
    # ========================================================================

    Test.@testset "Beam OCP level" verbose = VERBOSE showtiming = SHOWTIMING begin
        ipopt_options = Dict(
            :max_iter => 1000,
            :tol => 1e-6,
            :print_level => 0,
            :mu_strategy => "adaptive",
            :linear_solver => "Mumps",
            :sb => "yes",
        )

        madnlp_options = Dict(:max_iter => 1000, :tol => 1e-6, :print_level => MadNLP.ERROR)

        beam_data = Beam()
        ocp = beam_data.ocp
        init = OptimalControl.initial_guess(ocp; beam_data.init...)
        discretizer = OptimalControl.Collocation()

        modelers = [OptimalControl.ADNLPModeler(; backend=:manual), OptimalControl.ExaModeler()]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

        # ------------------------------------------------------------------
        # OCP level: solve(ocp, init, discretizer, modeler, solver)
        # ------------------------------------------------------------------

        Test.@testset "OCP level (Ipopt)" verbose = VERBOSE showtiming = SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose = VERBOSE showtiming = SHOWTIMING begin
                    solver = OptimalControl.IpoptSolver(; ipopt_options...)
                    sol = OptimalControl._solve(
                        ocp, init, discretizer, modeler, solver; display=false
                    )
                    Test.@test sol isa Solution
                    Test.@test successful(sol)
                    Test.@test isfinite(objective(sol))
                    Test.@test objective(sol) ≈ beam_data.obj atol = 1e-2
                    Test.@test iterations(sol) <= ipopt_options[:max_iter]
                    Test.@test constraints_violation(sol) <= 1e-6
                end
            end
        end

        Test.@testset "OCP level (MadNLP)" verbose = VERBOSE showtiming = SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose = VERBOSE showtiming = SHOWTIMING begin
                    solver = OptimalControl.MadNLPSolver(; madnlp_options...)
                    sol = OptimalControl._solve(
                        ocp, init, discretizer, modeler, solver; display=false
                    )
                    Test.@test sol isa Solution
                    Test.@test successful(sol)
                    Test.@test isfinite(objective(sol))
                    Test.@test objective(sol) ≈ beam_data.obj atol = 1e-2
                    Test.@test iterations(sol) <= madnlp_options[:max_iter]
                    Test.@test constraints_violation(sol) <= 1e-6
                end
            end
        end

        # ------------------------------------------------------------------
        # OCP level with @init (Ipopt, ADNLPModeler)
        # ------------------------------------------------------------------

        Test.@testset "OCP level with @init (Ipopt, ADNLPModeler)" verbose = VERBOSE showtiming = SHOWTIMING begin
            init_macro = OptimalControl.@init ocp begin
                x := [0.05, 0.1]
                u := 0.1
            end
            modeler = OptimalControl.ADNLPModeler(; backend=:manual)
            solver = OptimalControl.IpoptSolver(; ipopt_options...)
            sol = OptimalControl._solve(
                ocp, init_macro, discretizer, modeler, solver; display=false
            )
            Test.@test sol isa Solution
            Test.@test successful(sol)
            Test.@test isfinite(objective(sol))
        end

        # ------------------------------------------------------------------
        # OCP level: keyword-based API solve(ocp; ...)
        # ------------------------------------------------------------------

        Test.@testset "OCP level keyword API (Ipopt, ADNLPModeler)" verbose = VERBOSE showtiming = SHOWTIMING begin
            modeler = OptimalControl.ADNLPModeler(; backend=:manual)
            solver = OptimalControl.IpoptSolver(; ipopt_options...)
            sol = solve(
                ocp;
                initial_guess=init,
                discretizer=discretizer,
                modeler=modeler,
                solver=solver,
                display=false,
            )
            Test.@test sol isa Solution
            Test.@test successful(sol)
            Test.@test isfinite(objective(sol))
            Test.@test iterations(sol) <= ipopt_options[:max_iter]
            Test.@test constraints_violation(sol) <= 1e-6
        end

        # ------------------------------------------------------------------
        # OCP level: description-based API solve(ocp, description; ...)
        # ------------------------------------------------------------------

        Test.@testset "OCP level description API" verbose = VERBOSE showtiming = SHOWTIMING begin
            desc_cases = [
                ((:collocation, :adnlp, :ipopt), ipopt_options),
                ((:collocation, :adnlp, :madnlp), madnlp_options),
                ((:collocation, :exa, :ipopt), ipopt_options),
                ((:collocation, :exa, :madnlp), madnlp_options),
            ]

            for (method_syms, options) in desc_cases
                Test.@testset "description = $(method_syms)" verbose = VERBOSE showtiming = SHOWTIMING begin
                    sol = solve(
                        ocp, method_syms...; initial_guess=init, display=false, options...
                    )
                    Test.@test sol isa Solution
                    Test.@test successful(sol)
                    Test.@test isfinite(objective(sol))

                    if :ipopt in method_syms
                        Test.@test iterations(sol) <= ipopt_options[:max_iter]
                        Test.@test constraints_violation(sol) <= 1e-6
                    elseif :madnlp in method_syms
                        Test.@test iterations(sol) <= madnlp_options[:max_iter]
                        Test.@test constraints_violation(sol) <= 1e-6
                    end
                end
            end

            # modeler_options is allowed in description mode and forwarded to the
            # modeler constructor.
            Test.@testset "description API with modeler_options" verbose = VERBOSE showtiming = SHOWTIMING begin
                sol = solve(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    modeler_options=(backend=:manual,),
                    display=false,
                    ipopt_options...,
                )
                Test.@test sol isa Solution
                Test.@test successful(sol)
            end

            # Tagged options using the (value, tool) convention: discretizer options
            # are explicitly routed to the discretizer, and Ipopt options to the solver.
            Test.@testset "description API with explicit tool tags" verbose = VERBOSE showtiming = SHOWTIMING begin
                sol = solve(
                    ocp,
                    :collocation,
                    :adnlp,
                    :ipopt;
                    initial_guess=init,
                    display=false,
                    # Discretizer options
                    grid=(get_option_value(discretizer, :grid), :discretizer),
                    scheme=(get_option_value(discretizer, :scheme), :discretizer),
                    # Ipopt solver options
                    max_iter=(ipopt_options[:max_iter], :solver),
                    tol=(ipopt_options[:tol], :solver),
                    print_level=(ipopt_options[:print_level], :solver),
                    mu_strategy=(ipopt_options[:mu_strategy], :solver),
                    linear_solver=(ipopt_options[:linear_solver], :solver),
                    sb=(ipopt_options[:sb], :solver),
                )
                Test.@test sol isa Solution
                Test.@test successful(sol)
                Test.@test isfinite(objective(sol))
                Test.@test iterations(sol) <= ipopt_options[:max_iter]
                Test.@test constraints_violation(sol) <= 1e-6
            end
        end
    end

    # ========================================================================
    # Integration tests: Goddard OCP level with Ipopt and MadNLP
    # ========================================================================

    Test.@testset "Goddard OCP level" verbose = VERBOSE showtiming = SHOWTIMING begin
        ipopt_options = Dict(
            :max_iter => 1000,
            :tol => 1e-6,
            :print_level => 0,
            :mu_strategy => "adaptive",
            :linear_solver => "Mumps",
            :sb => "yes",
        )

        madnlp_options = Dict(:max_iter => 1000, :tol => 1e-6, :print_level => MadNLP.ERROR)

        gdata = Goddard()
        ocp_g = gdata.ocp
        init_g = OptimalControl.initial_guess(ocp_g; gdata.init...)
        discretizer_g = OptimalControl.Collocation()

        modelers = [OptimalControl.ADNLPModeler(; backend=:manual), OptimalControl.ExaModeler()]
        modelers_names = ["ADNLPModeler (manual)", "ExaModeler (CPU)"]

        # ------------------------------------------------------------------
        # OCP level: solve(ocp_g, init_g, discretizer_g, modeler, solver)
        # ------------------------------------------------------------------

        Test.@testset "OCP level (Ipopt)" verbose = VERBOSE showtiming = SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose = VERBOSE showtiming = SHOWTIMING begin
                    solver = OptimalControl.IpoptSolver(; ipopt_options...)
                    sol = OptimalControl._solve(
                        ocp_g, init_g, discretizer_g, modeler, solver; display=false
                    )
                    Test.@test sol isa Solution
                    Test.@test successful(sol)
                    Test.@test isfinite(objective(sol))
                    Test.@test objective(sol) ≈ gdata.obj atol = 1e-4
                    Test.@test iterations(sol) <= ipopt_options[:max_iter]
                    Test.@test constraints_violation(sol) <= 1e-6
                end
            end
        end

        Test.@testset "OCP level (MadNLP)" verbose = VERBOSE showtiming = SHOWTIMING begin
            for (modeler, modeler_name) in zip(modelers, modelers_names)
                Test.@testset "$(modeler_name)" verbose = VERBOSE showtiming = SHOWTIMING begin
                    solver = OptimalControl.MadNLPSolver(; madnlp_options...)
                    sol = OptimalControl._solve(
                        ocp_g, init_g, discretizer_g, modeler, solver; display=false
                    )
                    Test.@test sol isa Solution
                    Test.@test successful(sol)
                    Test.@test isfinite(objective(sol))
                    Test.@test objective(sol) ≈ gdata.obj atol = 1e-4
                    Test.@test iterations(sol) <= madnlp_options[:max_iter]
                    Test.@test constraints_violation(sol) <= 1e-6
                end
            end
        end

        # ------------------------------------------------------------------
        # OCP level keyword API (Ipopt, ADNLPModeler)
        # ------------------------------------------------------------------

        Test.@testset "OCP level keyword API (Ipopt, ADNLPModeler)" verbose = VERBOSE showtiming = SHOWTIMING begin
            modeler = OptimalControl.ADNLPModeler(; backend=:manual)
            solver = OptimalControl.IpoptSolver(; ipopt_options...)
            sol = solve(
                ocp_g;
                initial_guess=init_g,
                discretizer=discretizer_g,
                modeler=modeler,
                solver=solver,
                display=false,
            )
            Test.@test sol isa Solution
            Test.@test successful(sol)
            Test.@test isfinite(objective(sol))
            Test.@test iterations(sol) <= ipopt_options[:max_iter]
            Test.@test constraints_violation(sol) <= 1e-6
        end

        # ------------------------------------------------------------------
        # OCP level description API (Ipopt and MadNLP)
        # ------------------------------------------------------------------

        Test.@testset "OCP level description API" verbose = VERBOSE showtiming = SHOWTIMING begin
            desc_cases = [
                ((:collocation, :adnlp, :ipopt), ipopt_options),
                ((:collocation, :adnlp, :madnlp), madnlp_options),
                ((:collocation, :exa, :ipopt), ipopt_options),
                ((:collocation, :exa, :madnlp), madnlp_options),
            ]

            for (method_syms, options) in desc_cases
                Test.@testset "description = $(method_syms)" verbose = VERBOSE showtiming = SHOWTIMING begin
                    sol = solve(
                        ocp_g,
                        method_syms...;
                        initial_guess=init_g,
                        display=false,
                        options...,
                    )
                    Test.@test sol isa Solution
                    Test.@test successful(sol)
                    Test.@test isfinite(objective(sol))

                    if :ipopt in method_syms
                        Test.@test iterations(sol) <= ipopt_options[:max_iter]
                        Test.@test constraints_violation(sol) <= 1e-6
                    elseif :madnlp in method_syms
                        Test.@test iterations(sol) <= madnlp_options[:max_iter]
                        Test.@test constraints_violation(sol) <= 1e-6
                    end
                end
            end
        end
    end
end