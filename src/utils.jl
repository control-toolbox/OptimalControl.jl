function hello()
    hello = "Hello Control Toolbox!"
    println(hello)
    return hello
end

∇(f::Function, x) = ForwardDiff.gradient(f, x)
Jac(f::Function, x) = ForwardDiff.jacobian(f, x)

function vec2vec(x::Vector{<:Vector{<:Number}})
    y = x[1]
    for i ∈ range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

function vec2vec(x::Vector{<:Number}, n::Integer)
    y = [x[1:n]]
    for i ∈ n+1:n:length(x)-n+1
        y = vcat(y, [x[i:i+n-1]])
    end
    return y
end