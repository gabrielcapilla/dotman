import std/os
import ../core/path
import ../components/profiles
import path_resolution, add_system

proc removeFile*(profile: string, name: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  let relPath = findFileInProfile(profile, name)
  let fullPath = profileDir / relPath
  var filesToRemove: seq[string] = @[]

  if dirExists(fullPath):
    let destPath = resolveDestPath(profileDir, relPath)
    filesToRemove.add(destPath)
  else:
    let destPath = resolveDestPath(profileDir, relPath)
    filesToRemove.add(destPath)

  if filesToRemove.len == 0:
    raise ProfileError(msg: "File not found in profile: " & name)

  for dest in filesToRemove:
    if symlinkExists(dest):
      removeFile(dest)
      echo "Removed: " & dest
