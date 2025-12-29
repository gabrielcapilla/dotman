import std/os
import ../core/path
import ../components/[profiles, symlinks]
import path_resolution, symlink_ops

proc findFileInProfile*(profile: string, name: string): string =
  let profileDir = getDotmanDir() / profile
  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for kind, itemPath in walkDir(catDir, relative = true):
        if kind == pcDir and itemPath == name:
          return categoryPath / itemPath

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath

        if dirExists(fullPath):
          let (head, tail) = itemPath.splitPath
          let dirName = if head == "": tail else: head.splitPath.tail
          if dirName == name or tail == name or itemPath == name:
            return categoryPath / itemPath
        else:
          let (_, tail) = itemPath.splitPath
          if tail == name:
            return categoryPath / itemPath

  raise ProfileError(msg: "File not found in profile: " & name)

proc addFile*(profile: string, name: string) =
  let profileDir = getDotmanDir() / profile
  let relPath = findFileInProfile(profile, name)
  let fullPath = profileDir / relPath

  if dirExists(fullPath):
    let destPath = resolveDestPath(profileDir, relPath)
    createLink(fullPath, destPath)
    echo "Linked: " & destPath & " → " & fullPath
  else:
    var batch = SymlinkBatch(count: 0, links: newSeq[SymlinkRef](1024))
    createSymlinksRecursive(profileDir, relPath, batch)

    for i in 0 ..< batch.count:
      let link = batch.links[i]
      createLink(link.source, link.dest)
      echo "Linked: " & link.dest & " → " & link.source
