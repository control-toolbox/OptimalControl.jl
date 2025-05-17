using OptimalControl
using NLPModelsIpopt
using Plots
using CTModels
using NonlinearSolve
using OrdinaryDiffEq

t0 = 0
tf = 2
x0 = 1
xf = 1/2
lb = 0.1

ocp = @def begin

    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1

    x(t0) == x0
    x(tf) == xf

    x(t) - lb ≥ 0, (1)

    ẋ(t) == u(t)

    ∫( x(t)^2 ) → min

end;

sol = solve(ocp; 
    grid_size=500, 
    print_level=4, 
    disc_method=:gauss_legendre_2,
);

plt = plot(sol, ocp)

#
t = time_grid(sol);
x = state(sol);
p = costate(sol);
u = control(sol);

#
h = (tf-t0)/length(t);

#
η = CTModels.dual(sol, ocp, :eq1);

#
pη1 = plot(plt[5]);
pη2 = plot(t, t->η(t)/h; color=:red, legend=false);
plot(pη1, pη2; layout=(2, 1))

# Voyons la constance du hamiltonien
g(x) = x - lb;
ε = 1e-3;
t12 = t[ 0 .≤ (g ∘ x).(t) .≤ ε ];
t1 = min(t12...)
t2 = max(t12...)

H(x, p, u, η) = p*u - x^2 + η*g(x);
H(t) = H(x(t), p(t), u(t), η(t)*h);
plt_H = plot(t, H; color=:green, label="direct")

# shooting
f1 = Flow(ocp, (x, p) -> -1);
f2 = Flow(ocp, (x, p) -> 0, (x, u) -> g(x), (x, p) -> 2x);
f3 = Flow(ocp, (x, p) -> +1);
function S(p0, t1, t2)
    x1, p1 = f1(t0, x0, p0, t1)
    x2, p2 = f2(t1, x1, p1, t2)
    x3, p3 = f3(t2, x2, p2, tf)
    return [ p1, g(x1), x3-xf ]
end;

ξ = [ p(t0), t1, t2 ]    # initial guess
nle! = (s, ξ, λ) -> s .= S(ξ...)    # auxiliary function
prob = NonlinearProblem(nle!, ξ)    # NLE problem with initial guess

indirect_sol = solve(prob, SimpleNewtonRaphson(); show_trace=Val(true))

# we retrieve the costate solution together with the times
p0 = indirect_sol.u[1]
t1 = indirect_sol.u[2]
t2 = indirect_sol.u[3]

f = f1 * (t1, f2) * (t2, f3);
sol_flow = f((t0, tf), x0, p0);
plot(sol_flow; label="indirect")

t_flow = time_grid(sol_flow);
x_flow = state(sol_flow);
p_flow = costate(sol_flow);
u_flow = control(sol_flow);
η_flow = t -> 2x(t) * (t1 ≤ t ≤ t2)

H_flow(t) = H(x_flow(t), p_flow(t), u_flow(t), η_flow(t));
plot!(plt_H, t, H_flow; color=:blue, label="indirect")

