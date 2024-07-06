using JuMP
using Ipopt
using Plots

function refine_grid(X, Y, N)

    model = JuMP.Model(optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0))

    v = abs.( Y[1:end-1].*(X[2:end]-X[1:end-1]) )
    println(v)
    K = length(v)

    @variables(model, begin
        0 ≤ n[1:K] ≤ N
    end)

    @constraint(model, c, sum(n)-N==0)

    @objective(
        model,
        Min,
        sum(
            (v[k]*n[l]-v[l]*n[k])^2 for k in 1:K-1, l in k+1:K
        ),
    )

    optimize!(model)

    # add points
    X_ = []
    Y_ = []
    for k ∈ 1:K
        x  = X[k]
        y  = Y[k] 
        nk = round(value(n[k]))
        Δx = (X[k+1]-x)/(nk+1)

        #
        push!(X_, x)
        push!(Y_, y)

        #
        for i ∈ 1:nk
            push!(X_, x+i*Δx)
            push!(Y_, y)
        end
    end
    push!(X_, X[end])
    push!(Y_, Y[end])

    return X_, Y_
end

N = 11
X = 0:4
Y = [2, 1, 3, 2, 2]

p = plot(X, Y; seriestype=:steppost, markershape=:circle, ylims=(0, 4), color=1)

X_, Y_ = refine_grid(X, Y, N)

plot!(X_, Y_; markershape=:circle, seriestype=:scatter, color=2)