import std/os
import ../core/path
import ../components/batches
import ../components/profiles
import path_resolution
import symlink_ops

proc validatePull*(profile: string): FileBatch =
  let profileDir = getDotmanDir() / profile
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
              batch.addToFileBatch(tempBatch.sources[i], tempBatch.destinations[i])
        elif kind2 == pcFile and fileExists(fullPath):
          if symlinkExists(destPath):
            let target = expandSymlink(destPath)
            if target == fullPath:
              batch.addToFileBatch(fullPath, destPath)

  return batch

proc pullProfile*(profile: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  echo "Validating..."

  let linksToRemove = validatePull(profile)

  if linksToRemove.count == 0:
    echo "Warning: No symlinks found for profile '" & profile & "'"
    echo "Nothing to pull."
    return

  echo "Removing symlinks..."

  var removedCount = 0
  for i in 0 ..< linksToRemove.count:
    let homePath = linksToRemove.destinations[i]
    if symlinkExists(homePath):
      removeFile(homePath)
      removedCount += 1
      echo "  Removed " & $removedCount & "/" & $linksToRemove.count & ": " & homePath

  echo ""
  echo "Done! " & $removedCount & " links removed."
