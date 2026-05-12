import std/os
import ../domain/[types, result, execution]
import ../domain/[batches, profiles]
import symlinks, add, paths

proc planRemoveFile*(
    profiles: var ProfileData, profileId: ProfileId, name: string
): ExecutionPlan =
  let profileDir = profiles.getProfilePath(profileId)

  let relPath = findFileInProfile(profiles, profileId, name)
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

  result = initExecutionPlan(batch.count)
  for i in 0 ..< batch.count:
    let dest = batch.destinationAt(i)
    result.addRemoveSymlink(dest)
