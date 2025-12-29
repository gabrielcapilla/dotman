import ../core/types

type
  Profile* = object
    name*: ProfileName
    path*: string

  ProfileList* = object
    count*: int
    profiles*: seq[Profile]

  ProfileError* = ref object of CatchableError

proc initProfileList*(capacity: int = MaxProfiles.int): ProfileList =
  ProfileList(count: 0, profiles: newSeq[Profile](capacity))

proc findProfile*(list: ProfileList, name: string): int =
  for i in 0 ..< list.count:
    if list.profiles[i].name.data == name:
      return i
  -1
