import std/os
import ../core/path
import ../components/profiles
import path_resolution

proc validatePull*(profile: string): seq[string] =
  let profileDir = getDotmanDir() / profile
  var linksToRemove: seq[string] = @[]

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath
        let relPath = categoryPath / itemPath
        let homePath = resolveDestPath(profileDir, relPath)

        if dirExists(fullPath) or fileExists(fullPath):
          if symlinkExists(homePath):
            let target = expandSymlink(homePath)
            if target == fullPath:
              linksToRemove.add(homePath)

  return linksToRemove

proc pullProfile*(profile: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  echo "Validating..."

  let linksToRemove = validatePull(profile)

  if linksToRemove.len == 0:
    echo "Warning: No symlinks found for profile '" & profile & "'"
    echo "Nothing to pull."
    return

  echo "Removing symlinks..."

  var removedCount = 0
  let totalLinks = linksToRemove.len

  for homePath in linksToRemove:
    if symlinkExists(homePath):
      removeFile(homePath)
      removedCount += 1
      echo "  Removed " & $removedCount & "/" & $totalLinks & ": " & homePath

  echo ""
  echo "Done! " & $removedCount & " links removed."
