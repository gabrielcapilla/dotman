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
  if relativePath.len == 0 or relativePath[0] == '/':
    return false

  var segmentStart = 0
  for i in 0 .. relativePath.len:
    if i == relativePath.len or relativePath[i] == '/':
      let segmentLen = i - segmentStart
      if segmentLen == 0:
        return false
      if segmentLen == 1 and relativePath[segmentStart] == '.':
        return false
      if
        segmentLen == 2 and relativePath[segmentStart] == '.' and
          relativePath[segmentStart + 1] == '.':
        return false
      segmentStart = i + 1

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
