import dotman/domain/profiles
import dotman/app/[command_dispatcher, state]
import dotman/domain/[types, result]
import dotman/cli/[command_parser, completion]

when isMainModule:
  try:
    let parsed = command_parser.parseCommand()

    if parsed.command == CmdDeleteProfile:
      executeDeleteProfile(parsed.deleteProfileName)
      quit(0)

    if parsed.command == CmdCompletion:
      completion.printCompletion(parsed.completionKind)
      quit(0)

    var initialProfiles = loadProfiles()
    let initialProfileId = initialProfiles.findProfileId(MainProfile)
    var appState = initAppState(initialProfiles, initialProfileId)

    command_dispatcher.dispatch(parsed, appState)
  except ProfileError as e:
    echo "Error: " & e.msg
    quit(1)
