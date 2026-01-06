import std/[parseopt, options, os]
import types, colors, completion

type
  Command* = enum
    CmdInit
    CmdMake
    CmdClone
    CmdRemove
    CmdList
    CmdAdd
    CmdSet
    CmdUnset
    CmdStatus
    CmdPush
    CmdPull
    CmdHelp
    CmdVersion
    CmdDeleteProfile
    CmdCompletion

  CommandArgs* = object
    command*: Command
    profile*: string
    fileName*: string
    sourceProfile*: string

  StatusFlags* = object
    profile*: string
    filter*: StatusFilter
    category*: Option[Category]
    useAscii*: bool
    verbose*: bool

  ParsedCommand* = object
    command*: Command
    args*: CommandArgs
    statusFlags*: Option[StatusFlags]
    deleteProfileName*: string
    completionKind*: CompletionType

proc initParsedCommand*(): ParsedCommand =
  ParsedCommand(
    command: CmdHelp,
    args: CommandArgs(profile: MainProfile, fileName: "", sourceProfile: ""),
    statusFlags: none(StatusFlags),
    deleteProfileName: "",
    completionKind: BashCompletion,
  )

proc getCategory(catName: string): Category =
  case catName
  of "config":
    return Config
  of "share":
    return Share
  of "home":
    return Home
  of "local":
    return Local
  of "bin":
    return Bin
  else:
    colors.actionError("Unknown category: " & catName)
    quit(1)

proc parseStatusFlags*(p: var OptParser, profile: string): StatusFlags =
  result = StatusFlags(
    profile: profile,
    filter: FilterAll,
    category: none(Category),
    useAscii: false,
    verbose: false,
  )

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
          result.profile = p.key
        else:
          result.profile = p.val
      of "category":
        if p.val.len == 0:
          p.next()
          result.category = some(getCategory(if p.val.len == 0: p.key else: p.val))
        else:
          result.category = some(getCategory(p.val))
      of "conflicts":
        result.filter = FilterConflicts
      of "linked":
        result.filter = FilterLinked
      of "not-linked":
        result.filter = FilterNotLinked
      of "other":
        result.filter = FilterOther
      of "ascii":
        result.useAscii = true
      of "verbose", "v":
        result.verbose = true
      else:
        colors.actionError("Unknown option for status: " & p.key)
        quit(1)
    of cmdArgument:
      colors.actionError("Unexpected argument: " & p.key)
      quit(1)

proc parseCommand*(): ParsedCommand =
  result = initParsedCommand()

  if paramCount() == 0:
    return result

  var p = initOptParser()

  while true:
    p.next()
    case p.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      if p.key == "delete-profile":
        if p.val.len == 0:
          p.next()
          result.deleteProfileName = p.key
        else:
          result.deleteProfileName = p.val
        result.command = CmdDeleteProfile
        return result
    of cmdArgument:
      break

  p = initOptParser()
  var command = ""

  while true:
    p.next()
    case p.kind
    of cmdEnd:
      break
    of cmdShortOption, cmdLongOption:
      case p.key
      of "i", "init":
        result.command = CmdInit
      of "m", "make":
        result.command = CmdMake
        result.args.fileName = if p.val.len == 0: "" else: p.val
      of "c", "clone":
        result.command = CmdClone
      of "r", "remove":
        result.command = CmdRemove
        result.args.fileName = p.val
      of "l", "list":
        result.command = CmdList
      of "a", "add":
        result.command = CmdAdd
        result.args.fileName = p.val
      of "s", "set":
        result.command = CmdSet
        result.args.fileName = p.val
      of "u", "unset":
        result.command = CmdUnset
        result.args.fileName = p.val
      of "profile":
        result.args.profile = if p.val.len == 0: "" else: p.val
      of "help", "h":
        result.command = CmdHelp
      of "v", "version":
        result.command = CmdVersion
      of "completion":
        result.command = CmdCompletion
        result.completionKind = BashCompletion

        p.next()
        if p.kind in {cmdShortOption, cmdLongOption}:
          case p.key
          of "bash":
            result.completionKind = BashCompletion
          of "zsh":
            result.completionKind = ZshCompletion
          of "fish":
            result.completionKind = FishCompletion
          else:
            discard
        return result
    of cmdArgument:
      if command == "":
        command = p.key
        case command
        of "init":
          result.command = CmdInit
        of "make":
          result.command = CmdMake
        of "clone":
          result.command = CmdClone
        of "remove":
          result.command = CmdRemove
        of "list":
          result.command = CmdList
        of "add":
          result.command = CmdAdd
        of "set":
          result.command = CmdSet
        of "unset":
          result.command = CmdUnset
        of "status":
          result.command = CmdStatus
          result.statusFlags = some(parseStatusFlags(p, result.args.profile))
        of "push":
          result.command = CmdPush
        of "pull":
          result.command = CmdPull
        of "help":
          result.command = CmdHelp
        of "version":
          result.command = CmdVersion
        else:
          colors.actionError("Unknown command: " & command)
          quit(1)
      else:
        case result.command
        of CmdMake:
          result.args.fileName = p.key
        of CmdClone:
          if result.args.sourceProfile.len == 0:
            result.args.sourceProfile = p.key
          else:
            result.args.fileName = p.key
        of CmdRemove, CmdAdd, CmdSet, CmdUnset:
          result.args.fileName = p.key
        of CmdPush, CmdPull:
          result.args.profile = p.key
        else:
          discard

  return result
