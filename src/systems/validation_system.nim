import std/os
import ../core/[iteration, types, path_safety]
import ../components/batches

proc validateBatch*(batch: FileBatch, profileDir: string): ValidationResult =
  result = initValidationResult(batch.count)

  forBatch(batch.count):
    let dest = batch.destinationAt(i)
    let source = batch.sourceAt(i)

    var hasError = false
    var errorReason = ""

    if fileExists(dest) or dirExists(dest):
      if symlinkExists(dest):
        let target = expandSymlink(dest)
        if target != source:
          if isWithinPath(target, profileDir):
            errorReason = "linked to other profile"
            hasError = true
          else:
            errorReason = "exists, not managed by dotman"
            hasError = true
      else:
        errorReason = "exists and is not a symlink"
        hasError = true

    if hasError:
      result.addValidationError(dest, errorReason)

proc validateSingleLink*(source, dest, profileDir: string): ValidationResult =
  result = initValidationResult(1)

  if fileExists(dest) or dirExists(dest):
    if symlinkExists(dest):
      let target = expandSymlink(dest)
      if target != source:
        if isWithinPath(target, profileDir):
          result.addValidationError(dest, "linked to other profile")
        else:
          result.addValidationError(dest, "exists, not managed by dotman")
    else:
      result.addValidationError(dest, "exists and is not a symlink")

  return result
