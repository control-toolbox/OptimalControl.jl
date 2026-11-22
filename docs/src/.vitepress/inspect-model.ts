// inspect-model.ts — display an executed problem again, with some lines flagged,
// without duplicating it. Works on any page.
//
// 1. Above the executed @example block, an id comment (in a ```@raw html block):
//        <!-- model: richer -->
// 2. Wherever the problem must be shown, a ```julia fence containing only
//        @inspect-model richer "variable" "(cons_u)" "q̇(s) =="
//    is rewritten at render time (hooked in config.mts) into the problem tagged `richer`,
//    with `# [!code warning]` on every line containing one of the quoted fragments.
//
// Fragments are plain substrings, matched with runs of whitespace collapsed to one space.
// An unknown id fails the build.

import { readFileSync } from 'node:fs'

const norm = (s: string) => s.replace(/\s+/g, ' ')

function escapeRe(s: string): string {
    return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

// The processed page holds the id comment, then the problem as a ```julia fence.
function modelLines(id: string, env: { path?: string }): string[] {
    if (!env.path) throw new Error('inspect-model: env.path unavailable')
    const md = readFileSync(env.path, 'utf-8')
    const re = new RegExp(
        `<!--\\s*model:\\s*${escapeRe(id)}\\s*-->\\s*` +
            '```julia\\n((?:(?!```)[\\s\\S])*?)\\n```'
    )
    const m = re.exec(md)
    if (!m) throw new Error(`inspect-model: no problem tagged "${id}" in ${env.path}`)
    return m[1].split('\n')
}

export function inspectModel(id: string, fragments: string[], env: { path?: string }): string {
    const wanted = fragments.map(norm)
    return modelLines(id, env)
        .map(line =>
            wanted.some(f => norm(line).includes(f)) ? `${line}  # [!code warning]` : line
        )
        .join('\n')
}

// `@inspect-model <id> "frag" "frag" ...` -> [id, fragments]
export function parseMarker(content: string): [string, string[]] | null {
    const m = /^@inspect-model\s+(\S+)\s*(.*)$/s.exec(content.trim())
    if (!m) return null
    const fragments = [...m[2].matchAll(/"([^"]*)"/g)].map(x => x[1])
    return [m[1], fragments]
}
