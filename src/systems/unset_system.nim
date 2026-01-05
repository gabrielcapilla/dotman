import std/[os, strutils]
import ../core/path
import ../components/profiles
import path_resolution
import add_system

proc isDotmanManaged*(linkPath: string, profile: string): bool =
  let profileDir = getDotmanDir() / profile

  if not symlinkExists(linkPath):
    return false

  let target = expandSymlink(linkPath)

  if target.startsWith(profileDir):
    return true

  return false

proc unsetFile*(profile: string, name: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  let relPath = findFileInProfile(profile, name)
  let homePath = resolveDestPath(profileDir, relPath)

  if not isDotmanManaged(homePath, profile):
    raise ProfileError(msg: "File is not managed by dotman")

  let target = expandSymlink(homePath)

  removeFile(homePath)
  echo "Removed symlink: " & homePath

  if fileExists(target):
    moveFile(target, homePath)
  elif dirExists(target):
    moveDir(target, homePath)

  echo "Restored: " & homePath & " ← " & target
