# Run every documentation probe, each in a fresh Julia process with the docs environment:
#
#     julia --project=docs docs/probes/run.jl            # all probes
#     julia --project=docs docs/probes/run.jl links      # the probes whose name contains "links"
#
# Exit code 0 when all probes pass. See README.md.

const HERE = @__DIR__
const DOCS_ENV = normpath(joinpath(HERE, ".."))

probes = sort!(filter(readdir(HERE)) do f
    endswith(f, ".jl") && f ∉ ("run.jl", "common.jl") &&
        (isempty(ARGS) || any(a -> occursin(a, f), ARGS))
end)

failed = String[]
for probe in probes
    println("── ", probe)
    cmd = `$(Base.julia_cmd()) --startup-file=no --project=$DOCS_ENV $(joinpath(HERE, probe))`
    ok = success(pipeline(cmd; stdout=stdout, stderr=stderr))
    ok || push!(failed, probe)
    println(ok ? "   PASS" : "   FAIL")
end

println()
println(length(probes) - length(failed), "/", length(probes), " probes pass")
isempty(failed) || (println("failed: ", join(failed, ", ")); exit(1))
