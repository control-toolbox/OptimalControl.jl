function test_goddard_indirect()
    ocp, obj = Goddard()
    g(x) = vmax - x[2] # todo: g(x, u) ≥ 0 (cf. nonnegative multiplier), could be retrieved from constraints
    final_mass_cons(xf) = xf[3] - mf

    # bang controls
    u0 = 0
    u1 = 1

    # singular control
    H0 = Lift(F0)
    H1 = Lift(F1)
    H01 = @Lie {H0, H1}
    H001 = @Lie {H0, H01}
    H101 = @Lie {H1, H01}
    us(x, p) = -H001(x, p) / H101(x, p)

    # boundary control
    #ub(x) = -(F0 ⋅ g)(x) / (F1 ⋅ g)(x)
    ub(x) = -Lie(F0, g)(x) / Lie(F1, g)(x)
    #μ(x, p) = H01(x, p) / (F1 ⋅ g)(x) 
    μ(x, p) = H01(x, p) / Lie(F1, g)(x)

    # flows
    f0 = Flow(ocp, (x, p, v) -> u0)
    f1 = Flow(ocp, (x, p, v) -> u1)
    fs = Flow(ocp, (x, p, v) -> us(x, p))
    fb = Flow(ocp, (x, p, v) -> ub(x), (x, u, v) -> g(x), (x, p, v) -> μ(x, p))

    # shooting function
    function shoot!(s, p0, t1, t2, t3, tf) # B+ S C B0 structure
        x1, p1 = f1(t0, x0, p0, t1)
        x2, p2 = fs(t1, x1, p1, t2)
        x3, p3 = fb(t2, x2, p2, t3)
        xf, pf = f0(t3, x3, p3, tf)
        s[1] = final_mass_cons(xf)
        s[2:3] = pf[1:2] - [1, 0]
        s[4] = H1(x1, p1)
        s[5] = H01(x1, p1)
        s[6] = g(x2)
        return s[7] = H0(xf, pf) # free tf
    end

    # tests
    p0 = [3.9457646586891744, 0.15039559623165552, 0.05371271293970545]
    t1 = 0.023509684041879215
    t2 = 0.059737380899876
    t3 = 0.10157134842432228
    tf = 0.20204744057100849

    # test shooting function with solve from NonlinearSolve
    s = zeros(eltype(p0), 7)
    ξ0 = [p0; t1; t2; t3; tf]
    shoot!(s, ξ, λ) = shoot!(s, ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])
    prob = NonlinearProblem(shoot!, ξ0)
    sol = solve(prob)
    ξ = sol.u
    p0, t1, t2, t3, tf = ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7]
    @test norm(s) < 1e-6
end
