import std/strutils
import ../core/[types, path_pool]

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
    relPathIds*: seq[int32]
    homePathIds*: seq[int32]
    categories*: seq[Category]
    statuses*: seq[LinkStatus]
    pathPool*: PathPool

proc initStatusData*(capacity: int = 8192): StatusData =
  StatusData(
    count: 0,
    capacity: capacity,
    linked: 0,
    notLinked: 0,
    conflicts: 0,
    relPathIds: newSeq[int32](capacity),
    homePathIds: newSeq[int32](capacity),
    categories: newSeq[Category](capacity),
    statuses: newSeq[LinkStatus](capacity),
    pathPool: initPathPool(capacity * 2),
  )

proc getCategory*(relPath: string): Category {.noSideEffect.} =
  let sep = relPath.find('/')
  let head =
    if sep < 0:
      relPath
    else:
      relPath[0 ..< sep]

  case head
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
    data: var StatusData,
    relPath, homePath: string,
    category: Category,
    status: LinkStatus,
) =
  if data.count >= data.capacity:
    let newCap = data.capacity * 2
    data.relPathIds.setLen(newCap)
    data.homePathIds.setLen(newCap)
    data.categories.setLen(newCap)
    data.statuses.setLen(newCap)
    data.capacity = newCap

  data.relPathIds[data.count] = data.pathPool.internPath(relPath)
  data.homePathIds[data.count] = data.pathPool.internPath(homePath)
  data.categories[data.count] = category
  data.statuses[data.count] = status
  data.count += 1

  case status
  of Linked:
    inc(data.linked)
  of NotLinked:
    inc(data.notLinked)
  of Conflict, OtherProfile:
    inc(data.conflicts)

proc relPathAt*(data: StatusData, index: int): string {.inline.} =
  result = data.pathPool.getPath(data.relPathIds[index])

proc homePathAt*(data: StatusData, index: int): string {.inline.} =
  result = data.pathPool.getPath(data.homePathIds[index])

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
    data.relPathIds[index] = data.relPathIds[last]
    data.homePathIds[index] = data.homePathIds[last]
    data.categories[index] = data.categories[last]
    data.statuses[index] = data.statuses[last]

  data.count -= 1
