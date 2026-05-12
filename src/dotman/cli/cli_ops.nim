import ../platform/path
import ../operations/profile_store

proc runInit*() =
  profile_store.initDotfiles()
  echo "Initialized at " & getDotmanDir()

proc runProfileCreate*(name: string) =
  profile_store.createProfile(name)
  echo "Created profile: " & name

proc runProfileClone*(source: string, dest: string) =
  profile_store.cloneProfile(source, dest)
  echo "Cloned " & source & " to " & dest

proc runProfileRemove*(name: string) =
  profile_store.removeProfile(name)
  echo "Removed profile: " & name

proc runProfileList*() =
  let profiles = profile_store.listProfiles()
  if profiles.len == 0:
    echo "No profiles found"
    return

  for p in profiles:
    echo p
