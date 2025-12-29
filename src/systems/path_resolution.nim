import std/[os, strutils]
import ../core/category_map

proc resolveDestPath*(profileDir: string, relativePath: string): string =
  let home = getHomeDir()
  let parts = relativePath.split("/")
  let category = parts[0]

  let filename =
    if parts.len > 1:
      parts[1 ..^ 1].join("/")
    else:
      ""

  getDestPath(category, home, filename)
