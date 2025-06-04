function fsolve(f, j, x; kwargs...)
    try
        MINPACK.fsolve(f, j, x; kwargs...)
    catch e
        println("Erreur using MINPACK")
        println(e)
        println("hybrj not supported. Replaced by hybrd even if it is not visible on the doc.")
        MINPACK.fsolve(f, x; kwargs...)
    end
end

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
    t1 = 0.025246759388000528
    t2 = 0.061602092906721286
    t3 = 0.10401664867856217
    tf = 0.20298394547952422
    p0 = [3.9428857983400074, 0.14628855388160236, 0.05412448008321635]

    # test shooting function
    s = zeros(eltype(p0), 7)
    shoot!(s, p0, t1, t2, t3, tf)
    s_guess_sol = [
        -0.02456074767656735,
        -0.05699760226157302,
        0.0018629693253921868,
        -0.027013078908634858,
        -0.21558816838342798,
        -0.0121146739026253,
        0.015713236406057297,
    ]
    @test s ≈ s_guess_sol atol = 1e-6

    # solve and compare
    ξ0 = [p0; t1; t2; t3; tf]
    backend = AutoForwardDiff()
    nle! = (s, ξ) -> shoot!(s, ξ[1:3], ξ[4], ξ[5], ξ[6], ξ[7])
    jnle! = (js, ξ) -> jacobian!(nle!, similar(ξ), js, backend, ξ)
    indirect_sol = fsolve(nle!, jnle!, ξ0; show_trace=true)

    p0 = indirect_sol.x[1:3]
    t1 = indirect_sol.x[4]
    t2 = indirect_sol.x[5]
    t3 = indirect_sol.x[6]
    tf = indirect_sol.x[7]

    shoot!(s, p0, t1, t2, t3, tf)
    @test norm(s) < 1e-6
end
