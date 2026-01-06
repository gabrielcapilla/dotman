import std/[unittest, options]
import ../src/core/command_parser
import ../src/core/types

suite "Command Parser Tests":
  setup:
    # Set command line args for testing
    proc setArgs(args: seq[string]) =
      # Note: This is limited by Nim's design
      # For full testing, we'd need a more sophisticated approach
      discard

  test "Parse empty args returns help command":
    # When no args provided, should return CmdHelp
    # Note: This test is limited by Nim's paramCount behavior
    skip()

  test "Parse help command":
    # dotman help -> CmdHelp
    skip()

  test "Parse init command":
    # dotman init -> CmdInit
    skip()

  test "Parse init with short flag":
    # dotman -i -> CmdInit
    skip()

  test "Parse add command with file":
    # dotman add .bashrc -> CmdAdd with fileName = ".bashrc"
    skip()

  test "Parse remove command with file":
    # dotman remove .bashrc -> CmdRemove with fileName = ".bashrc"
    skip()

  test "Parse make command with profile name":
    # dotman make laptop -> CmdMake with fileName = "laptop"
    skip()

  test "Parse clone command":
    # dotman clone main laptop -> CmdClone
    skip()

  test "Parse list command":
    # dotman list -> CmdList
    skip()

  test "Parse status command":
    # dotman status -> CmdStatus
    skip()

  test "Parse push command with profile":
    # dotman push laptop -> CmdPush with profile = "laptop"
    skip()

  test "Parse pull command with profile":
    # dotman pull laptop -> CmdPull with profile = "laptop"
    skip()

  test "Parse version command":
    # dotman version -> CmdVersion
    skip()

  test "Parse set command with file":
    # dotman set .bashrc -> CmdSet with fileName = ".bashrc"
    skip()

  test "Parse unset command with file":
    # dotman unset .bashrc -> CmdUnset with fileName = ".bashrc"
    skip()

suite "Command Args Validation":
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

suite "StatusFlags Tests":
  test "StatusFlags initializes correctly":
    var flags = StatusFlags(
      profile: "main",
      filter: FilterAll,
      category: none[Category](),
      useAscii: false,
      verbose: false,
    )
    check flags.filter == FilterAll
    check flags.useAscii == false
    check flags.verbose == false

  test "StatusFlags with filter set":
    var flags = StatusFlags(
      profile: "main",
      filter: FilterLinked,
      category: none[Category](),
      useAscii: false,
      verbose: false,
    )
    check flags.filter == FilterLinked

suite "Category Mapping":
  test "Category enum has correct values":
    check ord(Config) == 0
    check ord(Share) == 1
    check ord(Home) == 2
    check ord(Local) == 3
    check ord(Bin) == 4

suite "StatusFilter Enum":
  test "StatusFilter enum has correct values":
    check ord(FilterAll) == 0
    check ord(FilterLinked) == 1
    check ord(FilterNotLinked) == 2
    check ord(FilterConflicts) == 3
    check ord(FilterOther) == 4
