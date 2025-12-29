import std/[os, strutils]
import ../core/path
import ../components/profiles
import path_resolution
import symlink_ops

proc validatePush*(profile: string): seq[string] =
  let profileDir = getDotmanDir() / profile
  let home = getHomeDir()
  var conflicts: seq[string] = @[]

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath
        let relPath = categoryPath / itemPath
        let homePath = resolveDestPath(profileDir, relPath)

        if dirExists(fullPath) or fileExists(fullPath):
          if fileExists(homePath) or dirExists(homePath):
            if symlinkExists(homePath):
              let target = expandSymlink(homePath)
              if target != fullPath and target.startsWith(profileDir):
                conflicts.add(homePath & " (linked to other profile)")
              elif not target.startsWith(profileDir):
                conflicts.add(homePath & " (exists, not managed by dotman)")
            else:
              conflicts.add(homePath & " (exists, not managed by dotman)")

  return conflicts

proc pushProfile*(profile: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  echo "Validating..."

  let conflicts = validatePush(profile)
  if conflicts.len > 0:
    echo "Error: Cannot push, conflicts found:"
    for conflict in conflicts:
      echo "  " & conflict
    raise ProfileError(msg: "Fix conflicts and try again")

  var totalFiles = 0
  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath
      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath
        if dirExists(fullPath) or fileExists(fullPath):
          totalFiles += 1

  if totalFiles == 0:
    echo "Warning: No files found in profile '" & profile & "'"
    echo "Nothing to push."
    return

  echo "Creating symlinks..."

  var linkedCount = 0
  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath
        let relPath = categoryPath / itemPath

        if dirExists(fullPath) or fileExists(fullPath):
          let homePath = resolveDestPath(profileDir, relPath)

          if symlinkExists(homePath):
            let target = expandSymlink(homePath)
            if target == fullPath:
              linkedCount += 1
              echo "  Skipped: " & homePath & " (already linked)"
            else:
              raise ProfileError(msg: "Conflict detected: " & homePath)
          else:
            let (head, _) = splitPath(homePath)
            if head != "" and not dirExists(head):
              createDir(head)

            symlink_ops.createLink(fullPath, homePath)
            linkedCount += 1
            echo "  Linked " & $linkedCount & "/" & $totalFiles & ": " & homePath &
              " → dotman/" & profile & "/" & relPath

  echo ""
  echo "Done! " & $linkedCount & " files linked."
