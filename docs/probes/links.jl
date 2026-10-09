# Pages: all hand-written pages (docs/src, docs/src-literate).
# Claim: every control-toolbox.org URL written in the sources answers. External links are not
# checked by Documenter here, and a moved page (such as `stable/` before a release) becomes a
# 404 silently.

include("common.jl")
using Downloads

sources = String[]
for dir in (joinpath(REPO_ROOT, "docs", "src"), joinpath(REPO_ROOT, "docs", "src-literate"))
    for (root, _, files) in walkdir(dir)
        occursin(joinpath("docs", "src", "api"), root) && continue
        occursin(joinpath("docs", "src", "public"), root) && continue
        for f in files
            (endswith(f, ".md") || endswith(f, ".jl")) && push!(sources, joinpath(root, f))
        end
    end
end

urls = Set{String}()
for file in sources, m in eachmatch(r"https://control-toolbox\.org/[^\s\)\]\"'<>`]*", read(file, String))
    push!(urls, rstrip(m.match, ['.', ',', ';', ':']))
end

status(url) = try
    Downloads.request(url; method="HEAD", timeout=30).status
catch
    0
end

for url in sort!(collect(urls))
    code = status(url)
    check(code == 200, "$url answers (HTTP $code)")
end
