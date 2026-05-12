import std/[options, tables]
import ../domain/[result, types]
import ../domain/[profiles, status]

type AppState* = object
  profiles*: ProfileData
  statusCache*: Table[ProfileId, StatusData]
  currentProfileId*: ProfileId
  initialized*: bool

proc initAppState*(profiles: sink ProfileData, currentId: ProfileId): AppState =
  AppState(
    profiles: profiles,
    statusCache: initTable[ProfileId, StatusData](),
    currentProfileId: currentId,
    initialized: true,
  )

proc getStatusCache*(state: var AppState, profileId: ProfileId): Option[StatusData] =
  if profileId in state.statusCache:
    return some(state.statusCache[profileId])
  return none(StatusData)

proc setStatusCache*(state: var AppState, profileId: ProfileId, data: sink StatusData) =
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
  let foundId = state.profiles.findProfileId(profileName)
  if foundId == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)

  state.currentProfileId = foundId
  foundId
