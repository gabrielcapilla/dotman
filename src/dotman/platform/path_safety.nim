import std/[os, strutils]

proc canonicalPath*(path: string): string {.inline.} =
  absolutePath(path).normalizedPath

proc isWithinPath*(path: string, root: string): bool =
  let p = canonicalPath(path)
  let r = canonicalPath(root)

  if p == r:
    return true

  let rootPrefix =
    if r.endsWith(DirSep):
      r
    else:
      r & $DirSep

  p.startsWith(rootPrefix)

proc safeRelativePath*(relativePath: string): bool =
  if relativePath.len == 0:
    return false
  if relativePath[0] == '/':
    return false

  let parts = relativePath.split('/')
  for part in parts:
    if part.len == 0 or part == "." or part == "..":
      return false

  true

proc relativeFromRoot*(path: string, root: string): string =
  let p = canonicalPath(path)
  let r = canonicalPath(root)

  if not isWithinPath(p, r):
    return ""
  if p == r:
    return ""

  let prefixLen = r.len + 1
  if prefixLen >= p.len:
    return ""
  p[prefixLen ..^ 1]
