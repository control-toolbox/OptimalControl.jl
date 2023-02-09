function set_state_at_time_step!(x, i, dim_x, N, xu)
    if i > N
        error("trying to set x(t_i) for i > N")
    else
        xu[1+i*dim_x:(i+1)*dim_x] = x[1:dim_x]
    end
end

function set_control_at_time_step!(u, i, dim_x, N, m, xu)
    if i > N
        error("trying to set (t_i) for i > N")
    else
        xu[1+(N+1)*dim_x+i*m:m+(N+1)*dim_x+i*m] = u[1:m]
    end
end

function constant_init(dim_x, m, N, dim_xu, x, u)
    xu = zeros(dim_xu)
    if length(x) != dim_x
        error("vector x for initialization should be of size ",dim_x)
     if length(u) != m
        error("vector u for initialization should be of size ",m)
    for i in 1:N+1
        set_state_at_time_step(x, i, dim_x, N, xu)
        set_control_at_time_step(u, i, dim_x, N, m, xu)
    end
    return xu
end