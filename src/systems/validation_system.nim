import std/[os, strutils]
import ../core/iteration
import ../components/batches

type
  ValidationError* = object
    path*: string
    reason*: string

  ValidationResult* = object
    hasConflicts*: bool
    count*: int
    capacity*: int
    errors*: seq[ValidationError]

proc initValidationResult*(capacity: int = 1024): ValidationResult {.noSideEffect.} =
  ValidationResult(
    hasConflicts: false,
    count: 0,
    capacity: capacity,
    errors: newSeq[ValidationError](capacity),
  )

proc addValidationError*(result: var ValidationResult, path: string, reason: string) =
  if result.count >= result.capacity:
    let newCap = result.capacity * 2
    result.errors.setLen(newCap)
    result.capacity = newCap

  result.errors[result.count] = ValidationError(path: path, reason: reason)
  result.count += 1
  result.hasConflicts = true

proc validateBatch*(batch: FileBatch, profileDir: string): ValidationResult =
  result = initValidationResult(batch.count)

  forBatch(batch.count):
    let dest = batch.destinations[i]
    let source = batch.sources[i]

    var hasError = false
    var errorReason = ""

    if fileExists(dest) or dirExists(dest):
      if symlinkExists(dest):
        let target = expandSymlink(dest)
        if target != source:
          if target.startsWith(profileDir):
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
        if target.startsWith(profileDir):
          result.addValidationError(dest, "linked to other profile")
        else:
          result.addValidationError(dest, "exists, not managed by dotman")
    else:
      result.addValidationError(dest, "exists and is not a symlink")

  return result
