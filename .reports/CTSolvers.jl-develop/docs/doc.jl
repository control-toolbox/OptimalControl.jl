#!/usr/bin/env julia

"""
    Documentation Generation Script for CTSolvers.jl

This script generates the documentation for CTSolvers.jl and then removes
CTSolvers from the docs/Project.toml to keep it clean.

Usage (from any directory):
    julia docs/doc.jl
    # OR
    julia --project=. docs/doc.jl
    # OR  
    julia --project=docs docs/doc.jl

The script will:
1. Activate the docs environment
2. Add CTSolvers as a development dependency in docs environment
3. Generate the documentation using docs/make.jl
4. Remove CTSolvers from docs/Project.toml
5. Clean up the docs environment

Author: Olivier Cots
Date: February 4, 2026
"""

using Pkg

println("🚀 Starting documentation generation for CTSolvers.jl...")

# Step 0: Activate docs environment (works from any directory)
docs_dir = joinpath(@__DIR__)
println("📁 Activating docs environment at: $docs_dir")
Pkg.activate(docs_dir)

# Step 1: Add CTSolvers as development dependency
println("📦 Adding CTSolvers as development dependency...")
# Get the project root (parent of docs directory)
project_root = dirname(docs_dir)
Pkg.develop(path=project_root)

# Step 2: Generate documentation
println("📚 Building documentation...")
include(joinpath(docs_dir, "make.jl"))

# Step 3: Remove CTSolvers from docs environment
println("🧹 Cleaning up docs environment...")
Pkg.rm("CTSolvers")

println("✅ Documentation generated successfully!")
println("📖 Documentation available at: $(joinpath(docs_dir, "build", "index.html"))")
println("🗂️  CTSolvers removed from docs/Project.toml")