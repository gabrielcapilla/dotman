import std/[os, strutils]
import ../core/path
import ../components/profiles
import ../components/status
import path_resolution

proc scanProfile*(profile: string): StatusReport =
  let profileDir = getDotmanDir() / profile
  let home = getHomeDir()

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  result = StatusReport(linked: 0, notLinked: 0, conflicts: 0, files: @[])

  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        let fullPath = catDir / itemPath
        let relPath = categoryPath / itemPath

        if dirExists(fullPath) or fileExists(fullPath):
          let homePath = resolveDestPath(profileDir, relPath)

          var status: LinkStatus

          if symlinkExists(homePath):
            let target = expandSymlink(homePath)
            if target == fullPath:
              status = Linked
              result.linked += 1
            elif target.startsWith(profileDir):
              status = OtherProfile
              result.conflicts += 1
            else:
              status = Conflict
              result.conflicts += 1
          elif fileExists(homePath) or dirExists(homePath):
            status = Conflict
            result.conflicts += 1
          else:
            status = NotLinked
            result.notLinked += 1

          result.files.add(
            FileStatus(relPath: relPath, homePath: homePath, status: status)
          )

proc showStatus*(profile: string) =
  let report = scanProfile(profile)

  echo ""
  echo "Status for profile '" & profile & "':"
  echo ""

  var linkedCount = 0
  var notLinkedCount = 0
  var conflictCount = 0

  for i in 0 ..< report.files.len:
    let file = report.files[i]

    if file.status == Linked:
      echo "  " & file.homePath & " → dotman/" & profile & "/" & file.relPath
      linkedCount += 1
    elif file.status == NotLinked:
      echo "  " & file.relPath & " (not linked)"
      notLinkedCount += 1
    elif file.status == Conflict:
      echo "  " & file.homePath & " (conflict: exists, not managed by dotman)"
      conflictCount += 1
    elif file.status == OtherProfile:
      echo "  " & file.homePath & " (conflict: linked to other profile)"
      conflictCount += 1

  echo ""
  echo "Total: " & $linkedCount & " linked, " & $notLinkedCount & " not linked, " &
    $conflictCount & " conflicts"
  echo ""
