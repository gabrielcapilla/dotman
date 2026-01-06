import std/[os, strutils]
import ../core/[types, result, execution]
import ../components/profiles
import path_resolution, add_system

proc isDotmanManaged*(linkPath: string, profileDir: string): bool =
  if not symlinkExists(linkPath):
    return false

  let target = expandSymlink(linkPath)

  if target.startsWith(profileDir):
    return true

  return false

proc planUnsetFile*(
    profiles: ProfileData, profileId: ProfileId, name: string
): ExecutionPlan =
  let profileDir = profiles.getProfilePath(profileId)

  let relPath = findFileInProfile(profiles, profileId, name)
  let homePath = resolveDestPath(profileDir, relPath)

  if not isDotmanManaged(homePath, profileDir):
    raise ProfileError(msg: "File is not managed by dotman")

  let target = expandSymlink(homePath)

  result = initExecutionPlan(3)

  result.addRemoveSymlink(homePath)

  result.addCreateDir(homePath.parentDir)

  if fileExists(target):
    result.addMoveFile(target, homePath)
  elif dirExists(target):
    result.addMoveDir(target, homePath)
