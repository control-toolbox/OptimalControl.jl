using OptimalControl
using NLPModelsIpopt

ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end

sol = solve(ocp)

using JLD2
export_ocp_solution(sol; filename="my_solution")
sol_jld = import_ocp_solution(ocp; filename="my_solution")
println("Objective from computed solution: ", objective(sol))
println("Objective from imported solution: ", objective(sol_jld))
println("type of imported solution: ", typeof(sol_jld))

using JSON3
export_ocp_solution(sol; filename="my_solution", format=:JSON)
sol_json = import_ocp_solution(ocp; filename="my_solution", format=:JSON)
println("Objective from computed solution: ", objective(sol))
println("Objective from imported solution: ", objective(sol_json))
