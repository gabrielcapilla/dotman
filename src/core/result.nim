type ProfileError* = ref object of CatchableError

type Result*[T] = object
  case success*: bool
  of true:
    value*: T
  of false:
    error*: string

proc ok*[T](value: T): Result[T] {.inline.} =
  Result[T](success: true, value: value)

proc err*[T](error: string): Result[T] {.inline.} =
  Result[T](success: false, error: error)

proc isSuccess*[T](res: Result[T]): bool {.inline.} =
  res.success

proc isError*[T](res: Result[T]): bool {.inline.} =
  not res.success

proc unwrap*[T](res: Result[T]): T {.inline.} =
  if res.success:
    return res.value
  raise newException(ValueError, "Attempted to unwrap error result: " & res.error)

proc unwrapOr*[T](res: Result[T], default: T): T {.inline.} =
  if res.success:
    return res.value
  return default

proc getError*[T](res: Result[T]): string {.inline.} =
  if res.success:
    return ""
  return res.error

proc `or`*[T](res: Result[T], default: T): T {.inline.} =
  res.unwrapOr(default)

proc map*[T, U](res: Result[T], fn: proc(x: T): U): Result[U] {.inline.} =
  if res.success:
    return ok(fn(res.value))
  return err[U](res.error)

proc `?`*[T](res: Result[T]): T =
  if not res.success:
    return default(T)
  return res.value

proc tryCatch*[T](fn: proc(): T, defaultMsg: string): Result[T] =
  try:
    return ok(fn())
  except ProfileError as e:
    return err[T](e.msg)
  except Exception as e:
    return err[T](defaultMsg & ": " & e.msg)

proc unwrapOrRaise*[T](res: Result[T]) =
  if not res.success:
    raise ProfileError(msg: res.error)
