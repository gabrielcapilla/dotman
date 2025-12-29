import std/os
import path_resolution
import ../components/symlinks

proc createLink*(source: string, dest: string) =
  if symlinkExists(dest):
    removeFile(dest)

  let (head, _) = splitPath(dest)
  if head != "" and not dirExists(head):
    createDir(head)

  os.createSymlink(source, dest)

proc createSymlinksRecursive*(
    profileDir: string, item: string, batch: var SymlinkBatch
) =
  let sourcePath = profileDir / item
  let destPath = resolveDestPath(profileDir, item)

  if dirExists(sourcePath):
    for kind, path in walkDir(sourcePath, relative = true):
      let relPath = item / path
      let fullSource = profileDir / relPath
      let fullDest = resolveDestPath(profileDir, relPath)

      if kind == pcFile:
        batch.links[batch.count] = SymlinkRef(source: fullSource, dest: fullDest)
        batch.count += 1
  elif fileExists(sourcePath):
    batch.links[batch.count] = SymlinkRef(source: sourcePath, dest: destPath)
    batch.count += 1
