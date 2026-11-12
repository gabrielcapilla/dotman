import std/os
import ../domain/types, ../platform/path_safety
import ../domain/batches

proc conflictReason(source, dest, profileDir: string): string =
  if not (fileExists(dest) or dirExists(dest)):
    return ""
  if not symlinkExists(dest):
    return "exists and is not a symlink"
  let target = expandSymlink(dest)
  if target == source:
    return ""
  if isWithinPath(target, profileDir):
    return "linked to other profile"
  "exists, not managed by dotman"

proc validateBatch*(batch: var FileBatch, profileDir: string): ValidationResult =
  result = initValidationResult(batch.count)

  for i in 0 ..< batch.count:
    let dest = batch.destinationAt(i)
    let source = batch.sourceAt(i)
    let errorReason = conflictReason(source, dest, profileDir)
    if errorReason.len > 0:
      result.addValidationError(dest, errorReason)

proc validateSingleLink*(source, dest, profileDir: string): ValidationResult =
  result = initValidationResult(1)

  let errorReason = conflictReason(source, dest, profileDir)
  if errorReason.len > 0:
    result.addValidationError(dest, errorReason)

  return result
