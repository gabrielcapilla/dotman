import std/os
import ../core/path
import ../components/batches
import ../components/profiles
import symlink_ops
import validation_system

proc findFileInProfile*(profile: string, name: string): string =
  let profileDir = getDotmanDir() / profile
  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for kind, itemPath in walkDir(catDir, relative = true):
        if kind == pcDir and itemPath == name:
          return categoryPath / itemPath

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath

        if dirExists(fullPath):
          let (head, tail) = itemPath.splitPath
          let dirName = if head == "": tail else: head.splitPath.tail
          if dirName == name or tail == name or itemPath == name:
            return categoryPath / itemPath
        else:
          let (_, tail) = itemPath.splitPath
          if tail == name:
            return categoryPath / itemPath

  raise ProfileError(msg: "File not found in profile: " & name)

proc addFile*(profile: string, name: string) =
  let profileDir = getDotmanDir() / profile
  let relPath = findFileInProfile(profile, name)
  let fullPath = profileDir / relPath

  var batch = initFileBatch(1024)

  createSymlinksRecursive(profileDir, relPath, batch)

  if batch.count == 0:
    echo "Warning: No files found to link for '" & name & "'"
    return

  echo "Validating links..."
  let validationResult = validateBatch(batch, profileDir)

  if validationResult.hasConflicts:
    for i in 0 ..< validationResult.count:
      let error = validationResult.errors[i]
      raise ProfileError(msg: "Conflict: " & error.path & " (" & error.reason & ")")

  echo "Creating symlinks..."
  for i in 0 ..< batch.count:
    let source = batch.sources[i]
    let dest = batch.destinations[i]
    createLink(source, dest)
    echo "  Linked: " & dest & " → " & source
