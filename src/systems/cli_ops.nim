import ../core/path
import profile_ops

proc runInit*() =
  profile_ops.initDotfiles()
  echo "Initialized at " & getDotmanDir()

proc runProfileCreate*(name: string) =
  profile_ops.createProfile(name)
  echo "Created profile: " & name

proc runProfileClone*(source: string, dest: string) =
  profile_ops.cloneProfile(source, dest)
  echo "Cloned " & source & " to " & dest

proc runProfileRemove*(name: string) =
  profile_ops.removeProfile(name)
  echo "Removed profile: " & name

proc runProfileList*() =
  let profiles = profile_ops.listProfiles()
  if profiles.len == 0:
    echo "No profiles found"
    return

  for p in profiles:
    echo p
