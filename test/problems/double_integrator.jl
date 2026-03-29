# Double integrator optimal control problems used for indirect method tests.

using OptimalControl

"""
    DoubleIntegratorTime()

Return data for the double integrator time minimization problem.

The problem consists in minimising the final time `tf` for the system:
- ẋ₁(t) = x₂(t)
- ẋ₂(t) = u(t)
- u(t) ∈ [-1, 1]

with boundary conditions:
- x(0) = (-1, 0)
- x(tf) = (0, 0)

The function returns a NamedTuple with fields:
  * `ocp`   – CTParser/@def optimal control problem
  * `obj`   – reference optimal objective value (tf = 2.0)
  * `name`  – short problem name
  * `x0`    – initial state
  * `xf`    – final state
  * `t0`    – initial time
  * `tf`    – final time (reference value)
  * `u_max` – maximum control value
  * `u_min` – minimum control value
"""
function DoubleIntegratorTime()
    t0 = 0.0
    x0 = [-1.0, 0.0]
    xf = [0.0, 0.0]
    u_max = 1.0
    u_min = -1.0
    
    @def ocp begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        
        -1 ≤ u(t) ≤ 1
        
        q(0) == -1
        v(0) == 0
        q(tf) == 0
        v(tf) == 0
        
        ẋ(t) == [v(t), u(t)]
        
        tf → min
    end
    
    return (
        ocp=ocp,
        obj=2.0,
        name="double_integrator_time",
        x0=x0,
        xf=xf,
        t0=t0,
        tf=2.0,
        u_max=u_max,
        u_min=u_min
    )
end

"""
    DoubleIntegratorEnergy()

Return data for the double integrator energy minimization problem (unconstrained).

The problem consists in minimising ∫₀¹ u²(t)/2 dt for the system:
- ẋ₁(t) = x₂(t)
- ẋ₂(t) = u(t)

with boundary conditions:
- x(0) = (-1, 0)
- x(1) = (0, 0)

The function returns a NamedTuple with fields:
  * `ocp`  – CTParser/@def optimal control problem
  * `obj`  – reference optimal objective value (6.0)
  * `name` – short problem name
  * `x0`   – initial state
  * `xf`   – final state
  * `t0`   – initial time
  * `tf`   – final time
"""
function DoubleIntegratorEnergy()
    t0 = 0.0
    tf = 1.0
    x0 = [-1.0, 0.0]
    xf = [0.0, 0.0]
    
    @def ocp begin
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        
        x(0) == [-1, 0]
        x(1) == [0, 0]
        
        ∂(q)(t) == v(t)
        ∂(v)(t) == u(t)
        
        0.5∫(u(t)^2) → min
    end
    
    return (ocp=ocp, obj=6.0, name="double_integrator_energy", x0=x0, xf=xf, t0=t0, tf=tf)
end

"""
    DoubleIntegratorEnergyConstrained()

Return data for the double integrator energy minimization problem with state constraint.

The problem consists in minimising ∫₀¹ u²(t)/2 dt for the system:
- ẋ₁(t) = x₂(t)
- ẋ₂(t) = u(t)
- v(t) ≤ v_max = 1.2

with boundary conditions:
- x(0) = (-1, 0)
- x(1) = (0, 0)

The function returns a NamedTuple with fields:
  * `ocp`   – CTParser/@def optimal control problem
  * `obj`   – reference optimal objective value (nothing - no reference available)
  * `name`  – short problem name
  * `x0`    – initial state
  * `xf`    – final state
  * `t0`    – initial time
  * `tf`    – final time
  * `v_max` – maximum velocity constraint
"""
function DoubleIntegratorEnergyConstrained()
    t0 = 0.0
    tf = 1.0
    x0 = [-1.0, 0.0]
    xf = [0.0, 0.0]
    v_max = 1.2
    
    @def ocp begin
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        
        v(t) ≤ 1.2
        
        x(0) == [-1, 0]
        x(1) == [0, 0]
        
        ∂(q)(t) == v(t)
        ∂(v)(t) == u(t)
        
        0.5∫(u(t)^2) → min
    end
    
    return (
        ocp=ocp,
        obj=nothing,
        name="double_integrator_energy_constrained",
        x0=x0,
        xf=xf,
        t0=t0,
        tf=tf,
        v_max=v_max
    )
end
