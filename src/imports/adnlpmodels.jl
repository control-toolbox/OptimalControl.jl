# ADNLPModels reexports
#
# ⚠️ The import below is not decorative. Since v2.1.0-beta the ADNLP modeler
# sits behind the `CTSolversADNLPModels` extension, and Julia fires an
# extension when its trigger package is *loaded in the session*, not when it
# appears in `Project.toml`. OptimalControl declares ADNLPModels in `[deps]`
# precisely because that extension needs it, so OptimalControl must load it —
# otherwise we pay the install cost and ship a dead capability.
#
# Guarded by test/suite/extensions/test_extensions_armed.jl.

# The module name is not exported (#967): loading the package is what arms the extension.
using ADNLPModels: ADNLPModels # arms CTSolversADNLPModels
