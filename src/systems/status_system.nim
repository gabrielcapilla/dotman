import std/os
import ../core/path
import ../components/profiles
import ../components/status
import scan_system

proc showReport*(data: StatusData, profile: string) =
  echo ""
  echo "Status for profile '" & profile & "':"
  echo ""

  var linkedCount = 0
  var notLinkedCount = 0
  var conflictCount = 0

  for i in 0 ..< data.count:
    let relPath = data.relPaths[i]
    let homePath = data.homePaths[i]
    let status = data.statuses[i]

    case status
    of Linked:
      echo "  " & homePath & " → dotman/" & profile & "/" & relPath
      linkedCount += 1
    of NotLinked:
      echo "  " & relPath & " (not linked)"
      notLinkedCount += 1
    of Conflict:
      echo "  " & homePath & " (conflict: exists, not managed by dotman)"
      conflictCount += 1
    of OtherProfile:
      echo "  " & homePath & " (conflict: linked to other profile)"
      conflictCount += 1

  echo ""
  echo "Total: " & $linkedCount & " linked, " & $notLinkedCount & " not linked, " &
    $conflictCount & " conflicts"
  echo ""

proc showStatus*(profile: string) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  let data = scanProfileSimple(profileDir)
  showReport(data, profile)
