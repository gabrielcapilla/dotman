import std/os
import ../components/batches
import ../components/profiles
import path_resolution

proc createLink*(source: string, dest: string) =
  if symlinkExists(dest):
    removeFile(dest)
  elif dirExists(dest) and dirExists(source):
    raise ProfileError(
      msg:
        "Directory exists at " & dest & ". Please remove it first or use different path."
    )
  elif fileExists(dest) or dirExists(dest):
    raise ProfileError(
      msg:
        "Conflict: " & dest &
        " exists and is not a symlink. Please move or remove it first."
    )

  let (head, _) = splitPath(dest)
  if head != "" and not dirExists(head):
    createDir(head)

  try:
    os.createSymlink(source, dest)
  except OSError as e:
    raise ProfileError(msg: "Failed to create symlink: " & e.msg)

proc createSymlinksRecursive*(profileDir: string, item: string, batch: var FileBatch) =
  let sourcePath = profileDir / item
  let destPath = resolveDestPath(profileDir, item)

  if dirExists(sourcePath):
    if not dirExists(destPath) and not symlinkExists(destPath):
      batch.addToFileBatch(sourcePath, destPath)
    else:
      for path in walkDirRec(sourcePath, relative = true):
        if fileExists(sourcePath / path):
          let relPath = item / path
          let fullSource = profileDir / relPath
          let fullDest = resolveDestPath(profileDir, relPath)
          batch.addToFileBatch(fullSource, fullDest)
  elif fileExists(sourcePath):
    batch.addToFileBatch(sourcePath, destPath)
