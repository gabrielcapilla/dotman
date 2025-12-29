import std/os
import ../core/[path, types]
import ../components/profiles

proc initDotfiles*() =
  let dir = getDotmanDir()
  if dirExists(dir):
    raise ProfileError(msg: "Already initialized")

  createDir(dir)
  createDir(dir / MainProfile)

proc createProfile*(name: string) =
  let dir = getDotmanDir()
  if not dirExists(dir):
    raise ProfileError(msg: "Not initialized")

  let profilePath = dir / name
  if dirExists(profilePath):
    raise ProfileError(msg: "Profile exists: " & name)

  createDir(profilePath)

proc cloneProfile*(source: string, dest: string) =
  let dir = getDotmanDir()
  if not dirExists(dir):
    raise ProfileError(msg: "Not initialized")

  let sourcePath = dir / source
  let destPath = dir / dest

  if not dirExists(sourcePath):
    raise ProfileError(msg: "Source not found: " & source)

  if dirExists(destPath):
    raise ProfileError(msg: "Profile exists: " & dest)

  copyDir(sourcePath, destPath)

proc removeProfile*(name: string) =
  if name == MainProfile:
    raise ProfileError(msg: "Cannot remove main profile")

  let dir = getDotmanDir()
  let profilePath = dir / name

  if not dirExists(profilePath):
    raise ProfileError(msg: "Profile not found: " & name)

  removeDir(profilePath)

proc listProfiles*(): seq[string] =
  let dir = getDotmanDir()
  if not dirExists(dir):
    return @[]

  result = @[]
  for kind, path in walkDir(dir):
    if kind == pcDir:
      result.add(path.splitPath.tail)
