import std/[os, strutils, sequtils]
import ../core/path
import ../components/profiles
import symlink_ops

proc inferCategoryFromHome*(
    homePath: string
): tuple[category: string, relPath: string] =
  let home = getHomeDir()

  if not homePath.startsWith(home):
    raise ProfileError(msg: "File must be in $HOME")

  let relPath = homePath[home.len ..^ 1]
  let parts = relPath.split("/").filterIt(it.len > 0)

  if parts.len == 0:
    raise ProfileError(msg: "Invalid path")

  let pathParts = parts[0 ..^ 2]
  let filename = parts[^1]

  if parts[0] == ".config":
    return (
      "config",
      if parts.len > 1:
        parts[1 ..^ 1].join("/")
      else:
        "",
    )
  elif parts[0] == ".local":
    if parts.len > 1 and parts[1] == "bin":
      return (
        "bin",
        if parts.len > 2:
          parts[2 ..^ 1].join("/")
        else:
          "",
      )
    elif parts.len > 1 and parts[1] == "share":
      return (
        "share",
        if parts.len > 2:
          parts[2 ..^ 1].join("/")
        else:
          "",
      )
    else:
      return (
        "local",
        if parts.len > 1:
          parts[1 ..^ 1].join("/")
        else:
          "",
      )
  else:
    return ("home", relPath)

proc countFilesInDir*(path: string): int =
  result = 0
  for kind, _ in walkDir(path):
    if kind == pcFile:
      result += 1

proc moveFileToProfile*(profile: string, homePath: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  if symlinkExists(homePath):
    raise ProfileError(msg: "File is a symlink. Use 'add' instead")

  let (category, relPath) = inferCategoryFromHome(homePath)

  var destDir = profileDir / category
  var destPath = destDir / relPath

  if dirExists(destPath):
    raise ProfileError(msg: "Already exists in profile: " & relPath)
  if fileExists(destPath):
    raise ProfileError(msg: "Already exists in profile: " & relPath)

  if fileExists(homePath) or dirExists(homePath):
    if dirExists(homePath):
      let count = countFilesInDir(homePath)
      if count > 20:
        echo "Large directory (" & $count & " files). Moving..."

      createDir(destDir)
      moveDir(homePath, destPath)
    else:
      createDir(destDir)
      moveFile(homePath, destPath)

    symlink_ops.createLink(destPath, homePath)
    echo "Set: " & homePath & " → " & destPath
  else:
    raise ProfileError(msg: "File not found: " & homePath)
