function kepl2cart(a, e, i, RAAN, omega, theta, mu)  # Copy of the matlab function
    # Initial conditions
    r_orb      = a * (1 - e^2) / (1 + e * cos(theta)) .* [cos(theta); sin(theta); 0]
    v_orb      = sqrt(mu / a / (1 - e^2)) .* [- sin(theta); e + cos(theta); 0]

    ARAAN      = [cos(RAAN) sin(RAAN) 0; - sin(RAAN) cos(RAAN) 0; 0 0 1]
    Ai         = [1 0 0; 0 cos(i) sin(i); 0 -sin(i) cos(i)]
    Aomega     = [cos(omega) sin(omega) 0; - sin(omega) cos(omega) 0; 0 0 1]

    Atot       = ARAAN' * Ai' * Aomega'

    r          = Atot * r_orb # [m]
    v          = Atot * v_orb # [m / s]
    return r, v
end