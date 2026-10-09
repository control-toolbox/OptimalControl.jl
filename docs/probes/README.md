# Documentation probes

The documentation executes its code when it is built, and checks known values with hidden
`@assert`s. That is the first place to check a claim: an executed block, visible or hidden,
or a `@setup` block.

Some claims cannot be executed by the docs build. The probes in this directory check them:

- errors raised when a package is **not** loaded (the build process loads them all);
- behaviour that needs another environment (for instance, an integrator package the docs
  environment does not have);
- rules about a user session (what must be defined before a `@def` block);
- the absence of output (`display=false`);
- external URLs written in the sources.

## Running them

```bash
julia --project=docs docs/probes/run.jl          # all probes
julia --project=docs docs/probes/run.jl links    # only the probes whose name contains "links"
```

Each probe runs in a fresh Julia process. Some download packages into a temporary
environment the first time, and `links.jl` needs the network. They are not run in CI.

## Writing a probe

- One file per page or section, named after it: `<page>_<topic>.jl`.
- The header names the page, the claim it checks, and, for a known upstream bug, the issue.
- Start with `include("common.jl")`, then check each claim with `check(cond, claim)`, which
  prints the claim, or throws when it does not hold.
- A probe for a known bug checks the **current** behaviour. When the bug is fixed upstream,
  the probe fails: update the page (drop its one-line note) and the probe.
