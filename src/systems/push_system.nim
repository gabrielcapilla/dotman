import std/os
import ../core/path
import ../components/batches
import ../components/profiles
import symlink_ops
import validation_system

proc validatePush*(profile: string): ValidationResult =
  let profileDir = getDotmanDir() / profile
  var batch = initFileBatch(1024)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath
      for kind2, itemPath in walkDir(catDir, relative = true):
        createSymlinksRecursive(profileDir, categoryPath / itemPath, batch)

  validateBatch(batch, profileDir)

proc pushProfile*(profile: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  echo "Validating..."

  let validationResult = validatePush(profile)
  if validationResult.hasConflicts:
    echo "Error: Cannot push, conflicts found:"
    for i in 0 ..< validationResult.count:
      let error = validationResult.errors[i]
      echo "  " & error.path & " (" & error.reason & ")"
    raise ProfileError(msg: "Fix conflicts and try again")

  var batch = initFileBatch(1024)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath
      for kind2, itemPath in walkDir(catDir, relative = true):
        createSymlinksRecursive(profileDir, categoryPath / itemPath, batch)

  if batch.count == 0:
    echo "Warning: No files found in profile '" & profile & "'"
    echo "Nothing to push."
    return

  echo "Creating symlinks..."

  for i in 0 ..< batch.count:
    let source = batch.sources[i]
    let dest = batch.destinations[i]
    symlink_ops.createLink(source, dest)
    echo "  Linked " & $(i + 1) & "/" & $batch.count & ": " & dest

  echo ""
  echo "Done! " & $batch.count & " files linked."
