# [Use AI](@id manual-ai-ded)

Using now common models from AI, it is an elementary task to have such an agent learn the syntax of OptimalControl.jl DSL, then use the agent to translate standard math into this DSL. Here is a typical prompt, pointing to the [DSL syntax](@ref manual-abstract-syntax):

```
learn the syntax of optimalcontrol.jl dsl described at the link below to translate math into this dsl (julia language):
https://control-toolbox.org/OptimalControl.jl/stable/manual-abstract.html
```

Now, here is an extract of, *e.g.*, [claude.ai](https://claude.ai) answer (Sonnet 4 model) to the request below:

```
translate the problem below into this DSL: minimise the final time tf under the constraint q''(t) = u(t) with -1 <= u(t) <= 1, q(0) = 1, q'(0) = -2, q(tf) = 3, q'(tf) = 1, and q'(t) <= 1
```

```julia
@def begin
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
```

The answer is syntactically correct and can be updated, for instance according to the new request below:

```
use a form compatible with examodels
```

```julia
@def begin
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
```