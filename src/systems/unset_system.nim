import std/[os, strutils]
import ../core/path
import ../components/profiles

proc isDotmanManaged*(linkPath: string, profile: string): bool =
  let profileDir = getDotmanDir() / profile

  if not symlinkExists(linkPath):
    return false

  let target = expandSymlink(linkPath)

  if target.startsWith(profileDir):
    return true

  return false

proc unsetFile*(profile: string, homePath: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  if not isDotmanManaged(homePath, profile):
    raise ProfileError(msg: "File is not managed by dotman")

  let target = expandSymlink(homePath)

  removeFile(homePath)
  echo "Removed symlink: " & homePath

  let relPath = target[profileDir.len + 1 ..^ 1]

  if fileExists(target):
    moveFile(target, homePath)
  elif dirExists(target):
    moveDir(target, homePath)

  echo "Restored: " & homePath & " ← " & target
