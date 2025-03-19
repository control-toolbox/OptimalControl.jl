println("testing: discrete continuation")

test1 = true
test2 = true
test3 = true
draw_plot = false

# double integrator 
if test1
    if !isdefined(Main, :double_integrator_minenergy)
        include("../problems/double_integrator.jl")
    end
    @testset verbose = true showtiming = true ":continuation :double_integrator" begin
        init = nothing
        obj_list = []
        for T = 1:5
            ocp = double_integrator_minenergy(T).ocp
            sol = direct_solve(ocp, display = false, init = init, grid_size=100)
            init = sol
            push!(obj_list, CTModels.objective(sol))
        end
        @test obj_list ≈ [12, 1.5, 0.44, 0.19, 0.096] rtol = 1e-2
    end
end

# parametric
if test2
    if !isdefined(Main, :parametric)
        include("../problems/parametric.jl")
    end

    @testset verbose = true showtiming = true ":continuation :parametric_ocp" begin
        init = ()
        obj_list = []
        for ρ in [0.1, 5, 10, 30, 100]
            ocp = parametric(ρ).ocp
            sol = direct_solve(ocp, display = false, init = init)
            init = sol
            push!(obj_list, CTModels.objective(sol))
        end
        @test obj_list ≈ [-0.034, -1.67, -6.2, -35, -148] rtol = 1e-2
    end
end

# goddard
if test3
    if !isdefined(Main, :goddard)
        include("../problems/goddard.jl")
    end
    sol0 = direct_solve(goddard().ocp, display = false)

    @testset verbose = true showtiming = true ":continuation :goddard" begin
        sol = sol0
        Tmax_list = []
        obj_list = []
        for Tmax = 3.5:-0.5:1
            sol = direct_solve(goddard(Tmax = Tmax).ocp, display = false, init = sol)
            push!(Tmax_list, Tmax)
            push!(obj_list, CTModels.objective(sol))
        end
        @test obj_list ≈ [1.0125, 1.0124, 1.0120, 1.0112, 1.0092, 1.0036] rtol = 1e-2

        if draw_plot
            using Plots
            # plot obj(vmax)
            pobj = plot(
                Tmax_list,
                obj_list,
                label = "r(tf)",
                xlabel = "Maximal thrust (Tmax)",
                ylabel = "Maximal altitude r(tf)",
                seriestype = :scatter,
            )
            # plot multiple solutions
            plot(sol0)
            p = plot!(sol)
            display(plot(pobj, p, layout = 2, reuse = false, size = (1000, 500)))
        end
    end
end
