import std/[os, tables]
import ../core/[types, path, result]

type ProfileData* = object
  count*: int
  capacity*: int
  ids*: seq[ProfileId]
  names*: seq[ProfileName]
  paths*: seq[string]
  active*: seq[bool]
  nameIndex*: Table[string, ProfileId]

proc initProfileData*(capacity: int = MaxProfiles.int): ProfileData =
  ProfileData(
    count: 0,
    capacity: capacity,
    ids: newSeq[ProfileId](capacity),
    names: newSeq[ProfileName](capacity),
    paths: newSeq[string](capacity),
    active: newSeq[bool](capacity),
    nameIndex: initTable[string, ProfileId](capacity),
  )

proc addProfile*(data: var ProfileData, name: string): ProfileId =
  if data.count >= data.capacity:
    raise ProfileError(msg: "Profile capacity exceeded")

  let idx = data.count
  data.ids[idx] = ProfileId(idx)
  data.names[idx] = ProfileName(data: name)
  data.paths[idx] = getDotmanDir() / name
  data.active[idx] = true
  data.nameIndex[name] = ProfileId(idx)
  data.count += 1

  data.ids[idx]

proc removeProfile*(data: var ProfileData, id: ProfileId) =
  let idx = int32(id)
  if idx < 0 or idx >= data.count:
    raise ProfileError(msg: "Invalid profile ID")

  data.active[idx] = false
  data.nameIndex.del(data.names[idx].data)

proc removeIndex*(data: var ProfileData, index: int) =
  if index < 0 or index >= data.count:
    raise newException(IndexDefect, "Index out of bounds")

  let last = data.count - 1

  data.nameIndex.del(data.names[index].data)

  if index != last:
    data.ids[index] = data.ids[last]
    data.names[index] = data.names[last]
    data.paths[index] = data.paths[last]
    data.active[index] = data.active[last]

    data.nameIndex[data.names[index].data] = data.ids[index]

  data.count -= 1

proc findProfileId*(data: ProfileData, name: string): ProfileId {.inline.} =
  if name in data.nameIndex:
    let id = data.nameIndex[name]
    let idx = int32(id)
    if data.active[idx]:
      return id
  ProfileIdInvalid

proc findProfileIdSafe*(data: ProfileData, name: string): ProfileResult =
  if name in data.nameIndex:
    let id = data.nameIndex[name]
    let idx = int32(id)
    if data.active[idx]:
      return ok(id)
    return err[ProfileId]("Profile is inactive: " & name)
  return err[ProfileId]("Profile not found: " & name)

proc getProfilePath*(data: ProfileData, id: ProfileId): string =
  let idx = int32(id)
  if idx < 0 or idx >= data.count or not data.active[idx]:
    raise ProfileError(msg: "Profile not found")
  data.paths[idx]

proc loadProfiles*(): ProfileData =
  result = initProfileData()
  let dir = getDotmanDir()
  if not dirExists(dir):
    return result

  for kind, path in walkDir(dir):
    if kind == pcDir:
      let name = path.splitPath.tail
      discard result.addProfile(name)
