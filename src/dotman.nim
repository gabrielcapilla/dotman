import components/profiles
import systems/command_dispatcher
import core/[types, state, command_parser, result, completion]

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
