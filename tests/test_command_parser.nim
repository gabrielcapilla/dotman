import std/[os, osproc, strutils, sequtils, unittest, options]
import ../src/core/[command_parser, types]

proc runHelper(args: seq[string]): tuple[code: int, output: string] =
  let cmd =
    "DOTMAN_PARSER_HELPER=1 " & getAppFilename().quoteShell & " " &
    args.mapIt(it.quoteShell).join(" ")
  let res = execCmdEx(cmd)
  (res.exitCode, res.output)

if existsEnv("DOTMAN_PARSER_HELPER"):
  let parsed = parseCommand()
  echo "command=", $parsed.command
  echo "profile=", parsed.args.profile
  echo "file=", parsed.args.fileName
  echo "source=", parsed.args.sourceProfile
  echo "delete=", parsed.deleteProfileName
  if parsed.statusFlags.isSome():
    let flags = parsed.statusFlags.get()
    echo "status=true"
    echo "status_profile=", flags.profile
    echo "status_filter=", $flags.filter
    echo "status_category=",
      if flags.category.isSome():
        $flags.category.get()
      else:
        "none"
    echo "status_ascii=", $flags.useAscii
    echo "status_verbose=", $flags.verbose
  else:
    echo "status=false"
  quit(0)

suite "Command Parser Integration":
  test "parse help command":
    let res = runHelper(@["help"])
    check res.code == 0
    check res.output.contains("command=CmdHelp")

  test "parse init command":
    let res = runHelper(@["init"])
    check res.code == 0
    check res.output.contains("command=CmdInit")

  test "parse init short option":
    let res = runHelper(@["-i"])
    check res.code == 0
    check res.output.contains("command=CmdInit")

  test "parse add command with file":
    let res = runHelper(@["add", ".bashrc"])
    check res.code == 0
    check res.output.contains("command=CmdAdd")
    check res.output.contains("file=.bashrc")

  test "parse remove command with file":
    let res = runHelper(@["remove", ".bashrc"])
    check res.code == 0
    check res.output.contains("command=CmdRemove")
    check res.output.contains("file=.bashrc")

  test "parse make command with profile name":
    let res = runHelper(@["make", "laptop"])
    check res.code == 0
    check res.output.contains("command=CmdMake")
    check res.output.contains("file=laptop")

  test "parse clone command":
    let res = runHelper(@["clone", "main", "laptop"])
    check res.code == 0
    check res.output.contains("command=CmdClone")
    check res.output.contains("source=main")
    check res.output.contains("file=laptop")

  test "parse list command":
    let res = runHelper(@["list"])
    check res.code == 0
    check res.output.contains("command=CmdList")

  test "parse status command with flags":
    let res = runHelper(@["status", "--category", "config", "--linked", "--ascii"])
    check res.code == 0
    check res.output.contains("command=CmdStatus")
    check res.output.contains("status=true")
    check res.output.contains("status_filter=FilterLinked")
    check res.output.contains("status_category=Config")
    check res.output.contains("status_ascii=true")

  test "parse push command with profile":
    let res = runHelper(@["push", "laptop"])
    check res.code == 0
    check res.output.contains("command=CmdPush")
    check res.output.contains("profile=laptop")

  test "parse pull command with profile":
    let res = runHelper(@["pull", "laptop"])
    check res.code == 0
    check res.output.contains("command=CmdPull")
    check res.output.contains("profile=laptop")

  test "parse version command":
    let res = runHelper(@["version"])
    check res.code == 0
    check res.output.contains("command=CmdVersion")

  test "parse set command with file":
    let res = runHelper(@["set", ".bashrc"])
    check res.code == 0
    check res.output.contains("command=CmdSet")
    check res.output.contains("file=.bashrc")

  test "parse unset command with file":
    let res = runHelper(@["unset", ".bashrc"])
    check res.code == 0
    check res.output.contains("command=CmdUnset")
    check res.output.contains("file=.bashrc")

  test "parse delete-profile option":
    let res = runHelper(@["--delete-profile", "old"])
    check res.code == 0
    check res.output.contains("command=CmdDeleteProfile")
    check res.output.contains("delete=old")

  test "unknown command returns error":
    let res = runHelper(@["unknown-cmd"])
    check res.code != 0

suite "Command Types":
  test "CommandArgs has correct default profile":
    let args = CommandArgs(
      command: CmdHelp, profile: MainProfile, fileName: "", sourceProfile: ""
    )
    check args.profile == "main"

  test "ParsedCommand initializes correctly":
    let parsed = initParsedCommand()
    check parsed.command == CmdHelp
    check parsed.args.profile == "main"
    check parsed.deleteProfileName == ""

suite "Enum Values":
  test "Category enum has correct values":
    check ord(Config) == 0
    check ord(Share) == 1
    check ord(Home) == 2
    check ord(Local) == 3
    check ord(Bin) == 4

  test "StatusFilter enum has correct values":
    check ord(FilterAll) == 0
    check ord(FilterLinked) == 1
    check ord(FilterNotLinked) == 2
    check ord(FilterConflicts) == 3
    check ord(FilterOther) == 4
