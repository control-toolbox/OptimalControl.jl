# CTSolvers reexports
#
# The strategy/option layer this file used to own now lives in
# `CTBase.{Strategies,Options}` — see imports/ctbase.jl. What is left is the
# direct-method plumbing: modelers, solvers, the DOCP layer and integrators.

# For internal use
using CTSolvers: CTSolvers

# ---------------------------------------------------------------------------
# DOCP
#
# `AbstractDiscretizer` and `discretize` are *owned* by CTSolvers now;
# CTDirect only implements them.
# ---------------------------------------------------------------------------
import CTSolvers.DOCP: AbstractDiscretizer, DiscretizedModel

@reexport import CTSolvers.DOCP: discretize, ocp_model, nlp_model, ocp_solution

# `ocp_solution` takes the `BuiltModel` that `build_model` returns (the NLP and the
# cache the modeler needs to read its solution back): both are reached qualified,
# so a user can solve the NLP of `nlp_model` with a solver of their own (#1077).
import CTSolvers.Optimization: build_model, BuiltModel

# ---------------------------------------------------------------------------
# Modelers
# ---------------------------------------------------------------------------
import CTSolvers.Modelers: AbstractNLPModeler, ADNLP, Exa

# ---------------------------------------------------------------------------
# Solvers
# ---------------------------------------------------------------------------
import CTSolvers.Solvers: AbstractNLPSolver, Ipopt, MadNLP, MadNCL, Knitro, Uno

# ---------------------------------------------------------------------------
# Integrators
#
# ⚠️ Explicit list, deliberately not `@reexport using`: that would also pull
# `times` — which must stay `CTModels.Components.times`, the model component,
# not the integration grid (that one already has a name, `time_grid`) — and
# `merge`, which would shadow `Base.merge`.
# `status` and `successful` are the same objects as CTModels.Solutions', so
# they are re-exported from there (imports/ctmodels.jl).
# ---------------------------------------------------------------------------
@reexport import CTSolvers.Integrators:
    AbstractIntegrator, AbstractIntegrationResult, SciML, final_state, evaluate_at
