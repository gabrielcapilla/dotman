import std/[parseopt, os]
import core/[help, types]
import
  systems/[
    cli_ops, add_system, remove_system, set_system, unset_system, status_system,
    push_system, pull_system,
  ]
import components/profiles

proc parseCli*() =
  var p = initOptParser()
  var currentProfile = MainProfile
  var command = ""

  if paramCount() == 0:
    help.showHelp()
    return

  while true:
    p.next()
    case p.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      let key = p.key
      let val = p.val

      case key
      of "i", "init":
        cli_ops.runInit()
      of "m", "make":
        if val.len == 0:
          p.next()
        cli_ops.runProfileCreate(if val.len == 0: p.key else: val)
      of "c", "clone":
        if val.len == 0:
          p.next()
        let src = if val.len == 0: p.key else: val
        p.next()
        cli_ops.runProfileClone(src, p.key)
      of "r", "remove":
        if val.len == 0:
          p.next()
        let name = if val.len == 0: p.key else: val
        remove_system.removeFile(currentProfile, name)
      of "l", "list":
        cli_ops.runProfileList()
      of "a", "add":
        if val.len == 0:
          p.next()
        add_system.addFile(currentProfile, if val.len == 0: p.key else: val)
      of "s", "set":
        if val.len == 0:
          p.next()
        set_system.moveFileToProfile(currentProfile, if val.len == 0: p.key else: val)
      of "u", "unset":
        if val.len == 0:
          p.next()
        unset_system.unsetFile(currentProfile, if val.len == 0: p.key else: val)
      of "profile":
        if val.len == 0:
          p.next()
          currentProfile = p.key
        else:
          currentProfile = val
      of "help", "h":
        help.showHelp()
      of "v", "version":
        help.showVersion()
      else:
        echo "Unknown option: " & key
        quit(1)
    of cmdArgument:
      if command == "":
        command = p.key
        case command
        of "init":
          cli_ops.runInit()
        of "make":
          p.next()
          cli_ops.runProfileCreate(p.key)
        of "clone":
          p.next()
          let src = p.key
          p.next()
          cli_ops.runProfileClone(src, p.key)
        of "remove":
          p.next()
          remove_system.removeFile(currentProfile, p.key)
        of "list":
          cli_ops.runProfileList()
        of "add":
          p.next()
          add_system.addFile(currentProfile, p.key)
        of "set":
          p.next()
          set_system.moveFileToProfile(currentProfile, p.key)
        of "unset":
          p.next()
          unset_system.unsetFile(currentProfile, p.key)
        of "status":
          status_system.showStatus(currentProfile)
        of "push":
          p.next()
          push_system.pushProfile(p.key)
        of "pull":
          p.next()
          pull_system.pullProfile(p.key)
        of "help":
          help.showHelp()
        of "version":
          help.showVersion()
        else:
          echo "Unknown command: " & command
          quit(1)

when isMainModule:
  try:
    parseCli()
  except ProfileError as e:
    echo "Error: " & e.msg
    quit(1)
