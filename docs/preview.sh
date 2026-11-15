#!/usr/bin/env bash
# Local preview of the documentation that stays browsable while it is rebuilt.
#
# `docs/make.jl` writes the site into `docs/build/`, and clears that folder first, so a
# server pointed at it returns 404 for the whole build. This script builds as usual, then
# copies the finished site into `docs/build-preview/` and swaps it in at the very end. A
# server pointed at `docs/build-preview/` keeps showing the previous site until then, and
# a failed build leaves it untouched.
#
# Usage, from anywhere:
#
#   docs/preview.sh build [LOG]   build the docs, then update the preview
#                                 (the output of make.jl goes to LOG, default the terminal)
#   docs/preview.sh serve [PORT]  serve the preview on http://localhost:PORT (default 5174)
#
# Typical session: run `serve` once in a terminal, then `build` after each change and reload
# the page when it prints "preview updated".
#
# This is a local tool: it does not change `make.jl`, and the build runs with whatever
# `draft` setting and `@meta Draft` markers the sources have. `docs/build-preview*/` is
# git-ignored.

set -euo pipefail

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$DOCS_DIR")"
PREVIEW="$DOCS_DIR/build-preview"
SITE="$DOCS_DIR/build/1" # where DocumenterVitepress puts the built site

usage() {
    sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 1
}

build() {
    local log="${1:-/dev/stdout}"
    cd "$REPO_DIR"
    if ! julia --project=docs docs/make.jl >"$log" 2>&1; then
        echo "build failed, preview kept (see $log)" >&2
        exit 1
    fi
    if [ ! -d "$SITE" ]; then
        echo "build succeeded but $SITE is missing, preview kept" >&2
        exit 1
    fi
    # Copy first, then swap with two renames: the preview is never missing for more than
    # the instant between them.
    rm -rf "$PREVIEW.new" "$PREVIEW.old"
    cp -R "$SITE" "$PREVIEW.new"
    if [ -d "$PREVIEW" ]; then mv "$PREVIEW" "$PREVIEW.old"; fi
    mv "$PREVIEW.new" "$PREVIEW"
    rm -rf "$PREVIEW.old"
    echo "preview updated"
}

serve() {
    local port="${1:-5174}"
    if [ ! -d "$PREVIEW" ]; then
        if [ -d "$SITE" ]; then
            cp -R "$SITE" "$PREVIEW" # start from the last build, if any
        else
            echo "no preview yet: run '$0 build' first" >&2
            exit 1
        fi
    fi
    exec npx serve "$PREVIEW" --listen "$port"
}

case "${1:-}" in
    build) build "${2:-}" ;;
    serve) serve "${2:-}" ;;
    *) usage ;;
esac
