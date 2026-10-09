# [With AI](@id modelling-with-ai)

An AI assistant can learn the syntax of the OptimalControl.jl DSL from its documentation, and
then translate a problem written in standard mathematics into this DSL. Here is a typical
prompt, pointing to the [abstract syntax](@ref modelling-abstract-syntax) page:

```text
Learn the syntax of OptimalControl.jl DSL described at the link below 
to translate math into this DSL (Julia language): 
https://control-toolbox.org/OptimalControl.jl/dev/modelling/abstract-syntax
```

```@raw html
<div style="display:flex; align-items:center; gap:8px; margin:16px 0;">
  <span style="font-weight:600; color:#666;">Try with:</span>
  <!-- ChatGPT -->
  <a href="https://chat.openai.com/?q=Learn+the+syntax+of+OptimalControl.jl+DSL+described+at+the+link+below+to+translate+math+into+this+DSL+(Julia+language):+https://control-toolbox.org/OptimalControl.jl/dev/modelling/abstract-syntax" target="_blank" rel="nofollow noreferrer noopener" style="padding:4px 10px; background-color:#10A37F; color:#fff; border-radius:20px; font-size:13px; font-weight:600; text-decoration:none; transition:opacity 0.3s;">
    ChatGPT
  </a>

  <!-- Claude -->
  <a href="https://claude.ai/new?q=Learn+the+syntax+of+OptimalControl.jl+DSL+described+at+the+link+below+to+translate+math+into+this+DSL+(Julia+language):+https://control-toolbox.org/OptimalControl.jl/dev/modelling/abstract-syntax" target="_blank" rel="nofollow noreferrer noopener" style="padding:4px 10px; background-color:#CC9B7A; color:#fff; border-radius:20px; font-size:13px; font-weight:600; text-decoration:none; transition:opacity 0.3s;">
    Claude
  </a>

  <!-- Perplexity -->
  <a href="https://www.perplexity.ai/search/new?q=Learn+the+syntax+of+OptimalControl.jl+DSL+described+at+the+link+below+to+translate+math+into+this+DSL+(Julia+language):+https://control-toolbox.org/OptimalControl.jl/dev/modelling/abstract-syntax" target="_blank" rel="nofollow noreferrer noopener" style="padding:4px 10px; background-color:#9C4DE2; color:#fff; border-radius:20px; font-size:13px; font-weight:600; text-decoration:none; transition:opacity 0.3s;">
    Perplexity
  </a>

  <!-- Mistral AI -->
  <a href="https://chat.mistral.ai/chat?q=Learn+the+syntax+of+OptimalControl.jl+DSL+described+at+the+link+below+to+translate+math+into+this+DSL+(Julia+language):+https://control-toolbox.org/OptimalControl.jl/dev/modelling/abstract-syntax" target="_blank" rel="nofollow noreferrer noopener" style="padding:4px 10px; background-color:#FF7000; color:#fff; border-radius:20px; font-size:13px; font-weight:600; text-decoration:none; transition:opacity 0.3s;">
    Mistral
  </a>
</div>
```

Here is an extract of the answer of an assistant (here [claude.ai](https://claude.ai)) to the request below:

```text
Translate the problem below into this DSL:

    minimise the final time tf 
    under the constraint q''(t) = u(t) 
    with -1 <= u(t) <= 1, 
    q(0) = 1, q'(0) = -2, q(tf) = 3, q'(tf) = 1, and q'(t) <= 1.
```

```@setup ai
using OptimalControl
using NLPModelsIpopt
```

```@example ai
ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    
    # Variable constraint
    tf ≥ 0
    
    # Control constraint
    -1 ≤ u(t) ≤ 1
    
    # Initial conditions
    q(0) == 1
    v(0) == -2
    
    # Final conditions  
    q(tf) == 3
    v(tf) == 1
    
    # Path constraint
    v(t) ≤ 1
    
    # Dynamics (q'' = u becomes first-order system)
    ẋ(t) == [v(t), u(t)]
    
    # Objective: minimize final time
    tf → min
end
nothing # hide
```

The answer is correct: this page builds it when the documentation is built, and it solves:

```@example ai
sol = solve(ocp; display=false)
println("tf = ", objective(sol))
```

The answer can then be refined by further requests, for instance:

```text
Use a form compatible with examodels.
```

The assistant writes the dynamics coordinate by coordinate:

```@example ai
ocp_exa = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    
    # Variable constraint
    tf ≥ 0
    
    # Control constraint
    -1 ≤ u(t) ≤ 1
    
    # Initial conditions
    q(0) == 1
    v(0) == -2
    
    # Final conditions  
    q(tf) == 3
    v(tf) == 1
    
    # Path constraint
    v(t) ≤ 1
    
    # Dynamics (coordinate-wise for ExaModels)
    ∂(q)(t) == v(t)
    ∂(v)(t) == u(t)
    
    # Objective: minimize final time
    tf → min
end
nothing # hide
```

This form is valid, but it was not needed: the `:exa` modeler (ExaModels) also accepts the
vector form of the first answer. Both solve with it:

```@example ai
sol_vector = solve(ocp, :exa; display=false)
sol_coord = solve(ocp_exa, :exa; display=false)
println("tf: vector form = ", objective(sol_vector), ", coordinatewise = ", objective(sol_coord))
```

```@example ai
@assert isapprox(objective(sol), 6.5; rtol=1e-3)                            # hide
@assert isapprox(objective(sol_vector), objective(sol); rtol=1e-6)          # hide
@assert isapprox(objective(sol_coord), objective(sol); rtol=1e-6)           # hide
nothing                                                                     # hide
```

It is also possible to feed the model directly with math definitions (here from a snapshot), as in the [example](https://control-toolbox.org/OptimalControlProblems.jl/stable/problems/rocket.html) below:

```text
translate the problem below into OptimalControl.jl DSL:
```

```@raw html
<img src="../assets/rocket-def.png" 
     alt="rocket-def" 
     style="
         display: block;
         margin-left: 30px;
         margin-right: 30px;
         margin-top: 20px;
         margin-bottom: 20px;
         width: calc(100% - 60px);
         max-width: 800px;
         height: auto;
     ">

```

This prompt generates the following code, which is also built and solved here:

```@example ai
# Parameters
h₀ = 1
v₀ = 0
m₀ = 1
g₀ = 1
Tc = 3.5
hc = 500
vc = 620
mc = 0.6

# Derived constants
Dc = 0.5 * vc * m₀ / g₀
mf = mc * m₀
c = 0.5 * sqrt(g₀ * h₀)
Tmax = Tc * m₀ * g₀

# Auxiliary functions
D(h, v) = Dc * v^2 * exp(-hc * (h - h₀) / h₀)
g(h) = g₀ * (h₀ / h)^2

rocket = @def begin
    # Variable (free final time)
    tf ∈ R, variable
    
    # Time
    t ∈ [0, tf], time
    
    # State: (altitude, velocity, mass)
    x = (h, v, m) ∈ R³, state
    
    # Control: thrust
    T ∈ R, control
    
    # Dynamics
    ∂(h)(t) == v(t)
    ∂(v)(t) == (T(t) - D(h(t), v(t)) - m(t) * g(h(t))) / m(t)
    ∂(m)(t) == -T(t) / c
    
    # Initial conditions
    h(0) == h₀
    v(0) == v₀
    m(0) == m₀
    
    # Final condition
    m(tf) == mf
    
    # State constraints
    h(t) ≥ h₀
    v(t) ≥ v₀
    mf ≤ m(t) ≤ m₀
    
    # Control constraint
    0 ≤ T(t) ≤ Tmax
    
    # Variable constraint
    tf ≥ 0
    
    # Objective: maximize final altitude h(tf)
    -h(tf) → min
end
nothing # hide
```

```@example ai
sol = solve(rocket; display=false)
println("h(tf) = ", -objective(sol), ", tf = ", variable(sol))
```

```@example ai
@assert isapprox(-objective(sol), 1.012837; atol=1e-5)   # hide
nothing                                                   # hide
```

This is the Goddard problem, also solved in the [guided tour](@ref getting-started-guided-tour),
with the same final altitude.

## See also

- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — what the AI is being taught.
- [Example gallery](@ref examples-gallery) — more worked problems.
- [Guided tour](@ref getting-started-guided-tour) — the Goddard rocket, solved in depth.
