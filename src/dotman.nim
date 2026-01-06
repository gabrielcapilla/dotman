import components/profiles
import std/[parseopt, options, os]
import systems/[status_display, scan_system, command_dispatcher]
import core/[types, path, state, colors, command_parser, result, completion]

proc parseStatusFlags*(
    p: var OptParser, profiles: ProfileData, currentProfile: string
) =
  var profile = currentProfile
  var filter = FilterAll
  var category: Option[Category] = none(Category)
  var useAscii = false
  var verbose = false

  while true:
    p.next()
    case p.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      case p.key
      of "profile":
        if p.val.len == 0:
          p.next()
          profile = p.key
        else:
          profile = p.val
      of "category":
        if p.val.len == 0:
          p.next()
          let catName = if p.val.len == 0: p.key else: p.val
          case catName
          of "config":
            category = some(Config)
          of "share":
            category = some(Share)
          of "home":
            category = some(Home)
          of "local":
            category = some(Local)
          of "bin":
            category = some(Bin)
          else:
            echo "Unknown category: " & catName
            quit(1)
      of "conflicts":
        filter = FilterConflicts
      of "linked":
        filter = FilterLinked
      of "not-linked":
        filter = FilterNotLinked
      of "other":
        filter = FilterOther
      of "ascii":
        useAscii = true
      of "verbose", "v":
        verbose = true
      else:
        echo "Unknown option for status: " & p.key
        quit(1)
    of cmdArgument:
      colors.actionError("Unexpected argument: " & p.key)
      quit(1)

  let profileId = profiles.findProfileId(profile)
  if profileId == ProfileIdInvalid:
    if not dirExists(getDotmanDir()):
      echo "Error: Not initialized. Run 'dotman init' first."
      quit(1)
    raise ProfileError(msg: "Profile not found: " & profile)

  let data = scanProfileSimple(profiles, profileId)

  if filter == FilterAll:
    status_display.showCategorySummary(
      data, profile, useAscii = useAscii, category = category, verbose = verbose
    )
  else:
    status_display.showDetailedReport(data, profile, filter, category)

when isMainModule:
  try:
    let parsed = command_parser.parseCommand()

    if parsed.command == CmdDeleteProfile:
      executeDeleteProfile(parsed.deleteProfileName)
      quit(0)

    if parsed.command == CmdCompletion:
      completion.printCompletion(parsed.completionKind)
      quit(0)

    let initialProfiles = loadProfiles()
    let initialProfileId = initialProfiles.findProfileId(MainProfile)
    var appState = initAppState(initialProfiles, initialProfileId)

    command_dispatcher.dispatch(parsed, appState)
  except ProfileError as e:
    echo "Error: " & e.msg
    quit(1)
