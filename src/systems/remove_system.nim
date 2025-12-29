import std/os
import ../core/path
import ../components/batches
import ../components/profiles
import symlink_ops
import add_system
import path_resolution

proc removeFile*(profile: string, name: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  let relPath = findFileInProfile(profile, name)
  let fullPath = profileDir / relPath
  let destPath = resolveDestPath(profileDir, relPath)
  var batch = initFileBatch(64)

  if symlinkExists(destPath) and dirExists(destPath):
    batch.addToFileBatch(fullPath, destPath)
  elif dirExists(fullPath):
    createSymlinksRecursive(profileDir, relPath, batch)
  elif fileExists(fullPath):
    batch.addToFileBatch(fullPath, destPath)

  if batch.count == 0:
    raise ProfileError(msg: "File not found in profile: " & name)

  for i in 0 ..< batch.count:
    let dest = batch.destinations[i]
    if symlinkExists(dest):
      removeFile(dest)
      echo "Removed: " & dest
