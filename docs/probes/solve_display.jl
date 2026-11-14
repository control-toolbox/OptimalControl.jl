# Page: solve/overview.md, section "Turning the display off"
# Claim: display=false silences both the configuration box and the solver's own log.
# The docs build cannot show an absence of output reliably, so it is checked here, on the
# process's standard output (Ipopt writes from C).

include("common.jl")
using OptimalControl
using NLPModelsIpopt

ocp = eval(ENERGY_DEF)
solve(ocp; display=false)   # first call: compilation, outside the capture

function captured_output(f)
    path, io = mktemp()
    redirect_stdout(io) do
        f()
        return Base.Libc.flush_cstdio()
    end
    close(io)
    return read(path, String)
end

out = captured_output(() -> solve(ocp; display=false))
check(isempty(strip(out)), "display=false prints nothing, Ipopt log included")

out = captured_output(() -> solve(ocp))
check(
    occursin("Configuration", out) && occursin("Ipopt", out),
    "the default display prints the configuration box and Ipopt's log",
)
