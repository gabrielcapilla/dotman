import std/os
import ../core/[types, result, execution]
import ../components/[batches, profiles]
import path_resolution, symlink_ops

proc validatePull*(profiles: ProfileData, profileId: ProfileId): FileBatch =
  let profileDir = profiles.getProfilePath(profileId)
  var batch = initFileBatch(1024)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath
      for kind2, itemPath in walkDir(catDir, relative = true):
        let fullPath = catDir / itemPath
        let relPath = categoryPath / itemPath
        let destPath = resolveDestPath(profileDir, relPath)

        if kind2 == pcDir and dirExists(fullPath):
          if symlinkExists(destPath) and dirExists(destPath):
            let target = expandSymlink(destPath)
            if target == fullPath:
              batch.addToFileBatch(fullPath, destPath)
          elif dirExists(destPath) or symlinkExists(destPath):
            var tempBatch = initFileBatch(64)
            createSymlinksRecursive(profileDir, relPath, tempBatch)
            for i in 0 ..< tempBatch.count:
              batch.addToFileBatch(tempBatch.sourceAt(i), tempBatch.destinationAt(i))
        elif kind2 == pcFile and fileExists(fullPath):
          if symlinkExists(destPath):
            let target = expandSymlink(destPath)
            if target == fullPath:
              batch.addToFileBatch(fullPath, destPath)

  return batch

proc planPullProfile*(profiles: ProfileData, profileId: ProfileId): ExecutionPlan =
  let profileDir = profiles.getProfilePath(profileId)
  let profileName = profiles.names[int32(profileId)].data

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profileName)

  echo "Validating..."

  let linksToRemove = validatePull(profiles, profileId)

  if linksToRemove.count == 0:
    raise ProfileError(msg: "No symlinks found for profile '" & profileName & "'")

  result = initExecutionPlan(linksToRemove.count)
  for i in 0 ..< linksToRemove.count:
    let homePath = linksToRemove.destinationAt(i)
    result.addRemoveSymlink(homePath)
