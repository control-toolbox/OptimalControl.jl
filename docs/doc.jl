#!/usr/bin/env julia

"""
    Documentation Generation Script for OptimalControl.jl

This script generates the documentation for OptimalControl.jl and then removes
OptimalControl from the docs/Project.toml to keep it clean.

Usage (from any directory):
    julia docs/doc.jl
    # OR
    julia --project=. docs/doc.jl
    # OR  
    julia --project=docs docs/doc.jl

The script will:
1. Activate the docs environment
2. Add OptimalControl as a development dependency in docs environment
3. Generate the documentation using docs/make.jl
4. Remove OptimalControl from docs/Project.toml
5. Clean up the docs environment
"""

using Pkg

println("🚀 Starting documentation generation for OptimalControl.jl...")

# Step 0: Activate docs environment (works from any directory)
docs_dir = joinpath(@__DIR__)
println("📁 Activating docs environment at: $docs_dir")
Pkg.activate(docs_dir)

# Step 1: Add OptimalControl as development dependency
println("📦 Adding OptimalControl as development dependency...")
# Get the project root (parent of docs directory)
project_root = dirname(docs_dir)
Pkg.develop(; path=project_root)

# Step 2: Generate documentation
println("📚 Building documentation...")
include(joinpath(docs_dir, "make.jl"))

# Step 3: Remove OptimalControl from docs environment
println("🧹 Cleaning up docs environment...")
Pkg.rm("OptimalControl")

println("✅ Documentation generated successfully!")
println("📖 Documentation available at: $(joinpath(docs_dir, "build", "index.html"))")
println("🗂️  OptimalControl removed from docs/Project.toml")