import std/[os, strutils]
import ../core/category_map
import ../core/[result, path_safety]

proc resolveDestPath*(
    profileDir: string, relativePath: string
): string {.noSideEffect.} =
  if not safeRelativePath(relativePath):
    raise ProfileError(msg: "Invalid relative path: " & relativePath)

  let home = getHomeDir()
  let sep = relativePath.find('/')
  let category =
    if sep < 0:
      relativePath
    else:
      relativePath[0 ..< sep]
  let filename =
    if sep < 0:
      ""
    else:
      relativePath[sep + 1 ..^ 1]

  getDestPath(category, home, filename)

proc resolveDestPathParts*(
    category: string, filename: string
): string {.noSideEffect.} =
  if category.len == 0:
    raise ProfileError(msg: "Category cannot be empty")
  if filename.len > 0 and not safeRelativePath(filename):
    raise ProfileError(msg: "Invalid relative path segment: " & filename)

  getDestPath(category, getHomeDir(), filename)
