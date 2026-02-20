# ==============================================================================
# CTSolvers Coverage Post-Processing
# ==============================================================================
#
# See test/README.md for details.
#
# Usage:
#   julia --project=@. -e 'using Pkg; Pkg.test("CTSolvers"; coverage=true); include("test/coverage.jl")'
#
# ==============================================================================

pushfirst!(LOAD_PATH, @__DIR__)
using Coverage
using CTBase
CTBase.postprocess_coverage(; root_dir=dirname(@__DIR__))