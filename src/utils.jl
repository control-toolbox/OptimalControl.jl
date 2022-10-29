# method to compute gradient and Jacobian
"""
    ∇(f::Function, x)

TBW
"""
∇(f::Function, x) = ForwardDiff.gradient(f, x)
"""
    Jac(f::Function, x)

TBW
"""
Jac(f::Function, x) = ForwardDiff.jacobian(f, x)

# transform a Vector{<:Vector{<:Number}} to a Vector{<:Number}
"""
    vec2vec(x::Vector{<:Vector{<:Number}})

TBW
"""
function vec2vec(x::Vector{<:Vector{<:Number}})
    y = x[1]
    for i ∈ range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

# transform a Vector{<:Number} to a Vector{<:Vector{<:Number}}
"""
    vec2vec(x::Vector{<:Number}, n::Integer)

TBW
"""
function vec2vec(x::Vector{<:Number}, n::Integer)
    y = [x[1:n]]
    for i ∈ n+1:n:length(x)-n+1
        y = vcat(y, [x[i:i+n-1]])
    end
    return y
end