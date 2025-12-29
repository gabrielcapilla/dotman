type
  LinkStatus* = enum
    Linked
    NotLinked
    Conflict
    OtherProfile

  StatusData* = object
    count*: int
    capacity*: int
    linked*: int
    notLinked*: int
    conflicts*: int
    relPaths*: seq[string]
    homePaths*: seq[string]
    statuses*: seq[LinkStatus]

  StatusReport* = object
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
