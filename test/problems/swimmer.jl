# Microswimmer example from Bocop

# +++ make 2 versions: 1 stroke periodic and free N strokes

function swimmer()
    @def swimmer begin
        tf = 25
        t ∈ [0, tf], time
        x ∈ R^5, state
        u ∈ R^2, control

        # bounds
        -3.15 ≤ x[3](t) ≤ 3.15
        [-1.5, -1.5] ≤ x[4:5](t) ≤ [1.5, 1.5]
        [-1, -1] ≤ u(t) ≤ [1, 1]

        # initial conditions
        x[1:2](0) == [0, 0]
        -3.15 ≤ x[3](0) ≤ 0
        0 ≤ x[4](0) ≤ Inf # to break symmetry

        # final conditions
        #x[1](tf) ≤ -0.5 # target displacement for min energy problem
        x[2](tf) == 0

        # periodicity
        #x[3:5](tf) - x[3:5](0) == [0, 0, 0]
        #x[3:5](tf) - x[3:5](0) == 0 NB. WITH JUST 0 PARSE OK BUT DIM ERROR LATER

        #coefficients for dynamics 
        th = x[3](t)
        b1 = x[4](t)
        b3 = x[5](t)
        u1 = u[1](t)
        u2 = u[2](t)

        aux =
            543 +
            186 * cos(b1) +
            37 * cos(2 * b1) +
            12 * cos(b1 - 2 * b3) +
            30 * cos(b1 - b3) +
            2 * cos(2 * (b1 - b3)) +
            12 * cos(2 * b1 - b3) +
            186 * cos(b3) +
            37 * cos(2 * b3) - 6 * cos(b1 + b3) - 3 * cos(2 * (b1 + b3)) -
            6 * cos(2 * b1 + b3) - 6 * cos(b1 + 2 * b3)

        g11 =
            (
                -42 * sin(b1 - th) - 2 * sin(2 * b1 - th) - 24 * sin(th) -
                300 * sin(b1 + th) - 12 * sin(2 * b1 + th) - 6 * sin(b1 - th - 2 * b3) -
                sin(2 * b1 - th - 2 * b3) + 4 * sin(th - 2 * b3) -
                12 * sin(b1 + th - 2 * b3) - sin(2 * b1 + th - 2 * b3) +
                18 * sin(b1 - th - b3) +
                8 * sin(th - b3) - 54 * sin(b1 + th - b3) - 2 * sin(2 * b1 + th - b3) -
                18 * sin(b1 - th + b3) - 38 * sin(th + b3) - 90 * sin(b1 + th + b3) -
                6 * sin(b1 - th + 2 * b3) - 18 * sin(th + 2 * b3) -
                30 * sin(b1 + th + 2 * b3)
            ) / (4 * aux)

        g12 =
            (
                -42 * cos(b1 - th) - 2 * cos(2 * b1 - th) +
                24 * cos(th) +
                300 * cos(b1 + th) +
                12 * cos(2 * b1 + th) - 6 * cos(b1 - th - 2 * b3) -
                cos(2 * b1 - th - 2 * b3) - 4 * cos(th - 2 * b3) +
                12 * cos(b1 + th - 2 * b3) +
                cos(2 * b1 + th - 2 * b3) +
                18 * cos(b1 - th - b3) - 8 * cos(th - b3) +
                54 * cos(b1 + th - b3) +
                2 * cos(2 * b1 + th - b3) - 18 * cos(b1 - th + b3) +
                38 * cos(th + b3) +
                90 * cos(b1 + th + b3) - 6 * cos(b1 - th + 2 * b3) +
                18 * cos(th + 2 * b3) +
                30 * cos(b1 + th + 2 * b3)
            ) / (4 * aux)

        g13 =
            -(
                105 +
                186 * cos(b1) +
                2 * cos(2 * b1) +
                12 * cos(b1 - 2 * b3) +
                30 * cos(b1 - b3) +
                cos(2 * (b1 - b3)) - 4 * cos(2 * b3) - 6 * cos(b1 + b3) -
                6 * cos(b1 + 2 * b3)
            ) / (2 * aux)

        g21 =
            (
                8 * sin(b1 - th) +
                4 * sin(2 * b1 - th) +
                24 * sin(th) +
                38 * sin(b1 + th) +
                18 * sin(2 * b1 + th) - 2 * sin(b1 - th - 2 * b3) -
                sin(2 * b1 - th - 2 * b3) - 2 * sin(th - 2 * b3) -
                sin(2 * b1 + th - 2 * b3) - 54 * sin(b1 - th - b3) -
                12 * sin(2 * b1 - th - b3) - 42 * sin(th - b3) + 18 * sin(b1 + th - b3) -
                6 * sin(2 * b1 + th - b3) +
                18 * sin(b1 - th + b3) +
                6 * sin(2 * b1 - th + b3) +
                300 * sin(th + b3) +
                90 * sin(b1 + th + b3) +
                30 * sin(2 * b1 + th + b3) +
                12 * sin(th + 2 * b3)
            ) / (4 * aux)

        g22 =
            (
                8 * cos(b1 - th) + 4 * cos(2 * b1 - th) - 24 * cos(th) - 38 * cos(b1 + th) -
                18 * cos(2 * b1 + th) - 2 * cos(b1 - th - 2 * b3) -
                cos(2 * b1 - th - 2 * b3) +
                2 * cos(th - 2 * b3) +
                cos(2 * b1 + th - 2 * b3) - 54 * cos(b1 - th - b3) -
                12 * cos(2 * b1 - th - b3) + 42 * cos(th - b3) - 18 * cos(b1 + th - b3) +
                6 * cos(2 * b1 + th - b3) +
                18 * cos(b1 - th + b3) +
                6 * cos(2 * b1 - th + b3) - 300 * cos(th + b3) - 90 * cos(b1 + th + b3) -
                30 * cos(2 * b1 + th + b3) - 12 * cos(th + 2 * b3)
            ) / (4 * aux)

        g23 =
            -(
                105 - 4 * cos(2 * b1) +
                30 * cos(b1 - b3) +
                cos(2 * (b1 - b3)) +
                12 * cos(2 * b1 - b3) +
                186 * cos(b3) +
                2 * cos(2 * b3) - 6 * cos(b1 + b3) - 6 * cos(2 * b1 + b3)
            ) / (2 * aux)

        ẋ(t) == [g11 * u1 + g21 * u2, g12 * u1 + g22 * u2, g13 * u1 + g23 * u2, u1, u2]
        x[1](tf) → max
        #∫(u1^2 + u2^2) → min
    end

    return ((ocp=swimmer, obj=0.984273, name="swimmer", init=nothing))
end
