import std/os
import ../core/[types, result, execution]
import ../components/[batches, profiles]
import symlink_ops, validation_system

proc findFileInProfile*(
    profiles: ProfileData, profileId: ProfileId, name: string
): string =
  let profileDir = profiles.getProfilePath(profileId)
  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile directory not found: " & profileDir)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for kind, itemPath in walkDir(catDir, relative = true):
        if kind == pcDir and itemPath == name:
          return categoryPath / itemPath

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, yieldFilter = {pcFile, pcDir}, relative = true):
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

proc planAddFile*(
    profiles: ProfileData, profileId: ProfileId, name: string
): ExecutionPlan =
  let profileDir = profiles.getProfilePath(profileId)
  let relPath = findFileInProfile(profiles, profileId, name)

  var batch = initFileBatch(1024)

  createSymlinksRecursive(profileDir, relPath, batch)

  if batch.count == 0:
    raise ProfileError(msg: "No files found to link for '" & name & "'")

  let validationResult = validateBatch(batch, profileDir)

  if validationResult.hasConflicts:
    for i in 0 ..< validationResult.count:
      let error = validationResult.errors[i]
      raise ProfileError(msg: "Conflict: " & error.path & " (" & error.reason & ")")

  result = initExecutionPlan(batch.count)
  for i in 0 ..< batch.count:
    let source = batch.sources[i]
    let dest = batch.destinations[i]
    result.addCreateSymlink(source, dest)
