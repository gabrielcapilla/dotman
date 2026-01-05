import ../core/types

type
  ProfileData* = object
    count*: int
    capacity*: int
    ids*: seq[ProfileId]
    names*: seq[ProfileName]
    paths*: seq[string]
    active*: seq[bool]

  ProfileList* = object
    names*: seq[ProfileName]
    paths*: seq[string]

  ProfileError* = ref object of CatchableError

proc initProfileData*(capacity: int = MaxProfiles.int): ProfileData =
  ProfileData(
    count: 0,
    capacity: capacity,
    ids: newSeq[ProfileId](capacity),
    names: newSeq[ProfileName](capacity),
    paths: newSeq[string](capacity),
    active: newSeq[bool](capacity),
  )

proc addProfile*(data: var ProfileData, name: string, path: string): ProfileId =
  if data.count >= data.capacity:
    raise ProfileError(msg: "Profile capacity exceeded")

  let idx = data.count
  data.ids[idx] = ProfileId(idx)
  data.names[idx] = ProfileName(data: name)
  data.paths[idx] = path
  data.active[idx] = true
  data.count += 1

  data.ids[idx]

proc removeProfile*(data: var ProfileData, id: ProfileId) =
  let idx = int32(id)
  if idx < 0 or idx >= data.count:
    raise ProfileError(msg: "Invalid profile ID")

  data.active[idx] = false

proc removeIndex*(data: var ProfileData, index: int) =
  if index < 0 or index >= data.count:
    raise newException(IndexDefect, "Index out of bounds")

  let last = data.count - 1

  if index != last:
    data.ids[index] = data.ids[last]
    data.names[index] = data.names[last]
    data.paths[index] = data.paths[last]
    data.active[index] = data.active[last]

  data.count -= 1

proc findProfileId*(data: ProfileData, name: string): ProfileId =
  for i in 0 ..< data.count:
    if data.active[i] and data.names[i].data == name:
      return data.ids[i]
  ProfileIdInvalid

proc getProfilePath*(data: ProfileData, id: ProfileId): string =
  let idx = int32(id)
  if idx < 0 or idx >= data.count or not data.active[idx]:
    raise ProfileError(msg: "Profile not found")
  data.paths[idx]

proc initProfileList*(capacity: int = MaxProfiles.int): ProfileList =
  ProfileList(
    names: newSeqOfCap[ProfileName](capacity), paths: newSeqOfCap[string](capacity)
  )

proc findProfile*(list: ProfileList, name: string): int =
  for i in 0 ..< list.names.len:
    if list.names[i].data == name:
      return i
  -1
