import std/os
import ../core/[types, result, execution]
import ../components/[batches, profiles]
import symlink_ops, validation_system

proc validatePush*(profiles: ProfileData, profileId: ProfileId): ValidationResult =
  let profileDir = profiles.getProfilePath(profileId)
  var batch = initFileBatch(1024)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath
      for kind2, itemPath in walkDir(catDir, relative = true):
        createSymlinksRecursive(profileDir, categoryPath / itemPath, batch)

  validateBatch(batch, profileDir)

proc planPushProfile*(profiles: ProfileData, profileId: ProfileId): ExecutionPlan =
  let profileDir = profiles.getProfilePath(profileId)
  let profileName = profiles.names[int32(profileId)].data

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profileName)

  echo "Validating..."

  let validationResult = validatePush(profiles, profileId)
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
    raise ProfileError(msg: "No files found in profile '" & profileName & "'")

  result = initExecutionPlan(batch.count)
  for i in 0 ..< batch.count:
    let source = batch.sources[i]
    let dest = batch.destinations[i]
    result.addCreateSymlink(source, dest)
