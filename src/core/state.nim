import std/tables, options
import types, result
import ../components/[profiles, status]

type AppState* = object
  profiles*: ProfileData
  currentProfileId*: ProfileId
  statusCache*: Table[ProfileId, StatusData]
  initialized*: bool

proc initAppState*(profiles: ProfileData, currentId: ProfileId): AppState =
  AppState(
    profiles: profiles,
    currentProfileId: currentId,
    statusCache: initTable[ProfileId, StatusData](),
    initialized: true,
  )

proc getStatusCache*(state: AppState, profileId: ProfileId): Option[StatusData] =
  if profileId in state.statusCache:
    return some(state.statusCache[profileId])
  return none(StatusData)

proc setStatusCache*(state: var AppState, profileId: ProfileId, data: StatusData) =
  state.statusCache[profileId] = data

proc clearStatusCache*(state: var AppState, profileId: ProfileId) =
  if profileId in state.statusCache:
    state.statusCache.del(profileId)

proc invalidateProfileCache*(state: var AppState, profileId: ProfileId) =
  state.clearStatusCache(profileId)

proc reloadProfiles*(state: var AppState) =
  state.profiles = loadProfiles()
  state.statusCache.clear()

proc switchProfile*(state: var AppState, profileName: string): ProfileId =
  var foundId = ProfileIdInvalid
  for i in 0 ..< state.profiles.count:
    if state.profiles.active[i] and state.profiles.names[i].data == profileName:
      foundId = state.profiles.ids[i]
      break

  if foundId == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)

  state.currentProfileId = foundId
  foundId
