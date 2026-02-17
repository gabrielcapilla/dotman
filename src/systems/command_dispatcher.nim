import std/[strformat, os, options]
import ../core/[types, state, colors, help, path, command_parser, result]
import ../components/profiles
import
  ../systems/[
    cli_ops, add_system, remove_system, set_system, unset_system, status_display,
    push_system, pull_system, execution_engine, profile_ops, scan_system,
  ]

proc reloadAndFindProfile*(state: var AppState, profileName: string): ProfileResult =
  state.reloadProfiles()
  if not dirExists(getDotmanDir()):
    return err[ProfileId]("Not initialized. Run 'dotman init' first.")
  state.profiles.findProfileIdSafe(profileName)

proc ensureProfileInitialized*(
    state: var AppState, profileName: string
): ProfileResult =
  if state.currentProfileId == ProfileIdInvalid:
    return state.reloadAndFindProfile(profileName)
  return ok(state.currentProfileId)

proc ensureProfileInitializedOrQuit*(
    state: var AppState, profileName: string
): ProfileId =
  let res = state.ensureProfileInitialized(profileName)
  if not res.success:
    colors.actionError(res.error)
    quit(1)
  res.value

proc executeInit*(state: var AppState) =
  cli_ops.runInit()
  let res = state.reloadAndFindProfile(MainProfile)
  if not res.success:
    colors.actionError(res.error)
    quit(1)
  state.currentProfileId = res.value

proc executeMake*(state: var AppState, profileName: string) =
  cli_ops.runProfileCreate(profileName)
  let res = state.reloadAndFindProfile(MainProfile)
  if not res.success:
    colors.actionError(res.error)
    quit(1)
  state.currentProfileId = res.value

proc executeClone*(state: var AppState, source: string, dest: string) =
  cli_ops.runProfileClone(source, dest)
  state.reloadProfiles()

proc executeRemove*(state: var AppState, fileName: string) =
  let profileId = state.ensureProfileInitializedOrQuit(MainProfile)
  let plan = remove_system.planRemoveFile(state.profiles, profileId, fileName)
  discard execution_engine.executePlan(plan, verbose = false)
  colors.actionSuccess(fmt"Removed {fileName}")

proc executeList*() =
  cli_ops.runProfileList()

proc executeAdd*(state: var AppState, fileName: string) =
  let profileId = state.ensureProfileInitializedOrQuit(MainProfile)
  let plan = add_system.planAddFile(state.profiles, profileId, fileName)
  discard execution_engine.executePlan(plan, verbose = false)
  colors.actionSuccess(fmt"Linked {fileName}")

proc executeSet*(state: var AppState, fileName: string) =
  let profileId = state.ensureProfileInitializedOrQuit(MainProfile)
  let plan = set_system.planMoveFileToProfile(state.profiles, profileId, fileName)
  discard execution_engine.executePlan(plan, verbose = false)
  colors.actionSuccess(fmt"Moving {fileName} to profile")
  colors.actionSuccess(fmt"Linked {fileName}")

proc executeUnset*(state: var AppState, fileName: string) =
  let profileId = state.ensureProfileInitializedOrQuit(MainProfile)
  let plan = unset_system.planUnsetFile(state.profiles, profileId, fileName)
  discard execution_engine.executePlan(plan, verbose = false)
  colors.actionSuccess(fmt"Restoring {fileName}")

proc showStatus*(
    profiles: ProfileData, profile: string, profileId: ProfileId, flags: StatusFlags
) =
  let data = scanProfileSimple(profiles, profileId)

  if flags.filter == FilterAll:
    status_display.showCategorySummary(
      data,
      profile,
      useAscii = flags.useAscii,
      category = flags.category,
      verbose = flags.verbose,
    )
  else:
    status_display.showDetailedReport(data, profile, flags.filter, flags.category)

proc executeStatus*(state: var AppState, flags: StatusFlags) =
  let profile = if flags.profile.len == 0: MainProfile else: flags.profile
  let res = state.reloadAndFindProfile(profile)
  if not res.success:
    colors.actionError(res.error)
    quit(1)
  showStatus(state.profiles, profile, res.value, flags)

proc executePush*(state: var AppState, profileName: string) =
  state.reloadProfiles()
  let pushProfileId = state.profiles.findProfileId(profileName)
  if pushProfileId == ProfileIdInvalid:
    if not dirExists(getDotmanDir()):
      colors.actionError("Not initialized. Run 'dotman init' first.")
      quit(1)
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = push_system.planPushProfile(state.profiles, pushProfileId)
  discard execution_engine.executePlan(plan, verbose = false)
  if plan.count == 1:
    colors.actionSuccess(fmt"Linked {profileName}")
  else:
    colors.actionSuccess(fmt"Linked {plan.count} files")

proc executePull*(state: var AppState, profileName: string) =
  state.reloadProfiles()
  let pullProfileId = state.profiles.findProfileId(profileName)
  if pullProfileId == ProfileIdInvalid:
    if not dirExists(getDotmanDir()):
      colors.actionError("Not initialized. Run 'dotman init' first.")
      quit(1)
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = pull_system.planPullProfile(state.profiles, pullProfileId)
  discard execution_engine.executePlan(plan, verbose = false)
  if plan.count == 1:
    colors.actionSuccess(fmt"Unlinked {profileName}")
  else:
    colors.actionSuccess(fmt"Unlinked {plan.count} files")

proc executeDeleteProfile*(profileName: string) =
  profile_ops.removeProfile(profileName)
  echo "Removed profile: " & profileName

proc dispatch*(parsed: ParsedCommand, state: var AppState) =
  case parsed.command
  of CmdInit:
    executeInit(state)
  of CmdMake:
    let name = if parsed.args.fileName.len == 0: "" else: parsed.args.fileName
    if name.len == 0:
      colors.actionError("make requires a profile name")
      quit(1)
    executeMake(state, name)
  of CmdClone:
    let src = parsed.args.sourceProfile
    let dest = parsed.args.fileName
    if src.len == 0 or dest.len == 0:
      colors.actionError("clone requires source and destination profiles")
      quit(1)
    executeClone(state, src, dest)
  of CmdRemove:
    if parsed.args.fileName.len == 0:
      colors.actionError("remove requires a file name")
      quit(1)
    executeRemove(state, parsed.args.fileName)
  of CmdList:
    executeList()
  of CmdAdd:
    if parsed.args.fileName.len == 0:
      colors.actionError("add requires a file name")
      quit(1)
    executeAdd(state, parsed.args.fileName)
  of CmdSet:
    if parsed.args.fileName.len == 0:
      colors.actionError("set requires a file name")
      quit(1)
    executeSet(state, parsed.args.fileName)
  of CmdUnset:
    if parsed.args.fileName.len == 0:
      colors.actionError("unset requires a file name")
      quit(1)
    executeUnset(state, parsed.args.fileName)
  of CmdStatus:
    if parsed.statusFlags.isNone():
      colors.actionError("status flags not parsed")
      quit(1)
    executeStatus(state, parsed.statusFlags.get())
  of CmdPush:
    let profile = if parsed.args.profile.len == 0: MainProfile else: parsed.args.profile
    executePush(state, profile)
  of CmdPull:
    let profile = if parsed.args.profile.len == 0: MainProfile else: parsed.args.profile
    executePull(state, profile)
  of CmdHelp:
    help.showHelp()
  of CmdVersion:
    help.showVersion()
  of CmdDeleteProfile:
    discard
  of CmdCompletion:
    discard
