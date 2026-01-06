import std/strutils
import ../core/types

type
  CategoryStats* = object
    linked*: int
    notLinked*: int
    conflicts*: int
    other*: int

  StatusData* = object
    count*: int
    capacity*: int
    linked*: int
    notLinked*: int
    conflicts*: int
    relPaths*: seq[string]
    homePaths*: seq[string]
    statuses*: seq[LinkStatus]

proc initStatusData*(capacity: int = 8192): StatusData =
  StatusData(
    count: 0,
    capacity: capacity,
    linked: 0,
    notLinked: 0,
    conflicts: 0,
    relPaths: newSeq[string](capacity),
    homePaths: newSeq[string](capacity),
    statuses: newSeq[LinkStatus](capacity),
  )

proc getCategory*(relPath: string): Category {.noSideEffect.} =
  let parts = relPath.split("/")
  if parts.len == 0:
    return Config

  case parts[0]
  of "config":
    return Config
  of "share":
    return Share
  of "home":
    return Home
  of "local":
    return Local
  of "bin":
    return Bin
  else:
    return Config

proc addStatusEntry*(
    data: var StatusData, relPath, homePath: string, status: LinkStatus
) =
  if data.count >= data.capacity:
    let newCap = data.capacity * 2
    data.relPaths.setLen(newCap)
    data.homePaths.setLen(newCap)
    data.statuses.setLen(newCap)
    data.capacity = newCap

  data.relPaths[data.count] = relPath
  data.homePaths[data.count] = homePath
  data.statuses[data.count] = status
  data.count += 1

  case status
  of Linked:
    inc(data.linked)
  of NotLinked:
    inc(data.notLinked)
  of Conflict, OtherProfile:
    inc(data.conflicts)

proc removeIndex*(data: var StatusData, index: int) =
  if index < 0 or index >= data.count:
    raise newException(IndexDefect, "Index out of bounds")

  let last = data.count - 1

  let removedStatus = data.statuses[index]
  case removedStatus
  of Linked:
    dec(data.linked)
  of NotLinked:
    dec(data.notLinked)
  of Conflict, OtherProfile:
    dec(data.conflicts)

  if index != last:
    data.relPaths[index] = data.relPaths[last]
    data.homePaths[index] = data.homePaths[last]
    data.statuses[index] = data.statuses[last]

  data.count -= 1
