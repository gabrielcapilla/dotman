import result

type ProfileId* = distinct int32

proc `==`*(x, y: ProfileId): bool {.borrow.}

type ProfileName* = object
  data*: string

const
  AppName* = "dotman"
  AppVersion* = "0.2.0"
  MaxProfiles* = 1024'i32
  MainProfile* = "main"
  ProfileIdInvalid* = ProfileId(-1)

type
  LinkStatus* = enum
    Linked
    NotLinked
    Conflict
    OtherProfile

  Category* = enum
    Config
    Share
    Home
    Local
    Bin

  StatusFilter* = enum
    FilterAll
    FilterLinked
    FilterNotLinked
    FilterConflicts
    FilterOther

  ValidationError* = object
    path*: string
    reason*: string

  ValidationResult* = object
    hasConflicts*: bool
    count*: int
    capacity*: int
    errors*: seq[ValidationError]

  ProfileResult* = Result[ProfileId]

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
