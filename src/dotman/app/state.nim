import ../domain/types
import ../domain/profiles

type AppState* = object
  profiles*: ProfileData
  currentProfileId*: ProfileId

proc initAppState*(profiles: sink ProfileData, currentId: ProfileId): AppState =
  AppState(profiles: profiles, currentProfileId: currentId)

proc reloadProfiles*(state: var AppState) =
  state.profiles = loadProfiles()
