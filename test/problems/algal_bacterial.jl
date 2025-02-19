# Optimal control of an algal-bacterial consortium system. Original code from Rand Asswad.

function algal_bacterial()

    # parameters
    s_in = 0.5
    β = 23e-3
    γ = 0.44
    dmax = 1.5
    ϕmax = 6.48; ks = 0.09;
    ρmax = 27.3e-3; kv = 0.57e-3;
    μmax = 1.0211; qmin = 2.7628e-3;
    ϕ(s) = ϕmax * s / (ks + s)
    ρ(v) = ρmax * v / (kv + v)
    μ(q) = μmax * (1 - qmin / q)
    t0 = 0; tf = 20
    x0 = [0.1629, 0.0487, 0.0003, 0.0177, 0.035, 0]

    @def algal_bacterial begin
        t ∈ [t0, tf], time
        x ∈ R⁶, state
        u ∈ R², control
        
        x(t0) == x0
        x(t) ≥ [0, 0, 0, qmin, 0, 0]
        [0, 0] ≤ u(t) ≤ [1, dmax]

        ẋ(t) == [
            u₂(t)*(s_in - x₁(t)) - ϕ(x₁(t))*x₂(t)/γ,
            ((1 - u₁(t))*ϕ(x₁(t)) - u₂(t))*x₂(t),
            u₁(t)*β*ϕ(x₁(t))*x₂(t) - ρ(x₃(t))*x₅(t) - u₂(t)*x₃(t),
            ρ(x₃(t)) - μ(x₄(t))*x₄(t),
            (μ(x₄(t)) - u₂(t))*x₅(t),
            u₂(t)*x₅(t),
        ]

        x₆(tf) → max
    end

return ((ocp = algal_bacterial, obj = 5.45, name = "algal_bacterial", init = nothing))
end
