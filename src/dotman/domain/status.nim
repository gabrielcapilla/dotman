import std/[os, strutils]
import ../domain/[types, path_pool]

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
    itemPathIds*: seq[int32]
    subCategoryIds*: seq[int32]
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
    itemPathIds: newSeq[int32](capacity),
    subCategoryIds: newSeq[int32](capacity),
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

proc categoryName*(cat: Category): string {.inline.} =
  case cat
  of Config: "config"
  of Share: "share"
  of Home: "home"
  of Local: "local"
  of Bin: "bin"

proc subCategoryName(itemPath: string): string =
  let sep = itemPath.find('/')
  if sep < 0:
    itemPath
  else:
    itemPath[0 ..< sep]

proc addStatusEntry*(
    data: var StatusData, itemPath: string, category: Category, status: LinkStatus
) =
  if data.count >= data.capacity:
    let newCap = data.capacity * 2
    data.itemPathIds.setLen(newCap)
    data.subCategoryIds.setLen(newCap)
    data.categories.setLen(newCap)
    data.statuses.setLen(newCap)
    data.capacity = newCap

  data.itemPathIds[data.count] = data.pathPool.internPath(itemPath)
  data.subCategoryIds[data.count] = data.pathPool.internPath(itemPath.subCategoryName)
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

proc relPathAt*(data: var StatusData, index: int): string {.inline.} =
  result =
    data.categories[index].categoryName & "/" &
    data.pathPool.getPath(data.itemPathIds[index])

proc homePathAt*(data: var StatusData, index: int, homeDir: string): string {.inline.} =
  let itemPath = data.pathPool.getPath(data.itemPathIds[index])
  case data.categories[index]
  of Config:
    result = homeDir / ".config" / itemPath
  of Share:
    result = homeDir / ".local" / "share" / itemPath
  of Home:
    result = homeDir / itemPath
  of Local:
    result = homeDir / ".local" / itemPath
  of Bin:
    result = homeDir / ".local" / "bin" / itemPath

proc subCategoryAt*(data: var StatusData, index: int): string {.inline.} =
  result = data.pathPool.getPath(data.subCategoryIds[index])

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
    data.itemPathIds[index] = data.itemPathIds[last]
    data.subCategoryIds[index] = data.subCategoryIds[last]
    data.categories[index] = data.categories[last]
    data.statuses[index] = data.statuses[last]

  data.count -= 1
