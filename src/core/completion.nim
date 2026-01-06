import std/[strutils, sequtils, tables]

type
  CompletionType* = enum
    BashCompletion
    ZshCompletion
    FishCompletion

  CommandMetadata* = object
    command*: string
    shortFlag*: string
    description*: string
    takesArgument*: bool
    argumentType*: string

const
  CommandDescriptions*: Table[string, string] = {
    "init": "Initialize dotman in home directory",
    "make": "Create a new profile",
    "clone": "Clone an existing profile",
    "add": "Add/link files from profile to home",
    "remove": "Remove/unlink files from home",
    "set": "Move file to profile and link it",
    "unset": "Unlink file and keep local copy",
    "list": "List all profiles",
    "status": "Show status of linked files",
    "push": "Link all files from profile to home",
    "pull": "Unlink all files from profile",
    "help": "Show help message",
    "version": "Show version information",
  }.toTable

  ShortFlags*: Table[string, string] = {
    "i": "init",
    "m": "make",
    "c": "clone",
    "r": "remove",
    "l": "list",
    "a": "add",
    "s": "set",
    "u": "unset",
    "h": "help",
    "v": "version",
  }.toTable

  LongFlags*: Table[string, string] = {
    "init": "Initialize dotman",
    "make": "Create profile",
    "clone": "Clone profile",
    "remove": "Remove file",
    "list": "List profiles",
    "add": "Add file",
    "set": "Set file",
    "unset": "Unset file",
    "status": "Show status",
    "push": "Push profile",
    "pull": "Pull profile",
    "help": "Show help",
    "version": "Show version",
    "profile": "Select profile",
    "delete-profile": "Delete profile",
  }.toTable

proc generateBashCompletion*(): string =
  result =
    """
# Bash completion for dotman

_dotman_completion() {
    local cur prev words cword
    _init_completion || return

    local commands=""

"""

  let commandsList = CommandDescriptions.keys.toSeq()
  result &= "    commands=\"" & commandsList.join(" ") & "\"\n\n"

  result &= "    case ${prev} in\n"
  result &= "        dotman)\n"
  result &= "            COMPREPLY=($(compgen -W \"$commands\" -- \"${cur}\"))\n"
  result &= "            return\n"
  result &= "            ;;\n\n"

  result &= "        --profile)\n"
  result &= "            _dotman_complete_profiles\n"
  result &= "            return\n"
  result &= "            ;;\n\n"

  for short, long in ShortFlags.pairs:
    result &= "        -" & short & ")\n"
    result &= "            COMPREPLY=($(compgen -W \"\" -- \"${cur}\"))\n"
    result &= "            ;;\n"

  result &= "        add|remove|set|unset)\n"
  result &= "            _filedir\n"
  result &= "            return\n"
  result &= "            ;;\n\n"

  result &= "        push|pull)\n"
  result &= "            _dotman_complete_profiles\n"
  result &= "            return\n"
  result &= "            ;;\n\n"

  result &= "        status)\n"
  result &= "            case ${prev} in\n"
  result &= "                --category)\n"
  result &=
    "                    COMPREPLY=($(compgen -W \"config share home local bin\" -- \"${cur}\"))\n"
  result &= "                    return\n"
  result &= "                    ;;\n"
  result &= "                --filter)\n"
  result &=
    "                    COMPREPLY=($(compgen -W \"linked not-linked conflicts other\" -- \"${cur}\"))\n"
  result &= "                    return\n"
  result &= "                    ;;\n"
  result &= "            esac\n\n"
  result &= "            _dotman_complete_profiles\n"
  result &= "            ;;\n\n"

  result &= "    esac\n\n"
  result &= "    # Default: show all commands\n"
  result &= "    COMPREPLY=($(compgen -W \"$commands\" -- \"${cur}\"))\n"
  result &= "}\n\n"

  result &= "_dotman_complete_profiles() {\n"
  result &= "    local profiles\n"
  result &= "    profiles=$(dotman list 2>/dev/null | grep -v '^$' | tr '\\n' ' ')\n"
  result &= "    COMPREPLY=($(compgen -W \"$profiles\" -- \"${cur}\"))\n"
  result &= "}\n\n"

  result &= "complete -F _dotman_completion dotman\n"

proc generateZshCompletion*(): string =
  result =
    """#compdef dotman

_dotman() {
    local -a commands
    commands=(
"""

  for cmd, desc in CommandDescriptions.pairs:
    result &= "        '" & cmd & ":" & desc & "'\n"

  result &= "    )\n\n"

  result &= "    local -a subcommands\n"
  result &= "    subcommands=(\n"

  result &= "        'add:Add file to profile:file'\n"
  result &= "        'remove:Remove file from profile:file'\n"
  result &= "        'set:Set file in profile:file'\n"
  result &= "        'unset:Unset file from profile:file'\n"
  result &= "        'push:Push profile to home:profile'\n"
  result &= "        'pull:Pull profile from home:profile'\n"
  result &= "        'clone:Clone profile:profile'\n"
  result &= "        'make:Make new profile:profile'\n"
  result &= "        'init:Initialize dotfiles: :none'\n"
  result &= "        'list:List all profiles: :none'\n"
  result &= "        'status:Show status: :none'\n"
  result &= "        'help:Show help: :none'\n"
  result &= "        'version:Show version: :none'\n"
  result &= "    )\n\n"

  result &= "    if (( CURRENT == 2 )); then\n"
  result &= "        _describe 'command' commands\n"
  result &= "    elif (( CURRENT == 3 )); then\n"
  result &= "        case $words[2] in\n"

  result &= "            add|remove|set|unset)\n"
  result &= "                _files\n"
  result &= "                ;;\n\n"

  result &= "            push|pull)\n"
  result &= "                _dotman_complete_profiles\n"
  result &= "                ;;\n\n"

  result &= "            clone)\n"
  result &= "                _dotman_complete_profiles\n"
  result &= "                _files\n"
  result &= "                ;;\n\n"

  result &= "            make)\n"
  result &= "                _message 'profile name'\n"
  result &= "                ;;\n\n"

  result &= "            status)\n"
  result &= "                _arguments -S \\\n"
  result &=
    "                    '--profile[Select profile]:profile:_dotman_complete_profiles' \\\n"
  result &=
    "                    '--category[Filter by category]:category:(config share home local bin)' \\\n"
  result &= "                    '--conflicts[Show only conflicts]' \\\n"
  result &= "                    '--linked[Show only linked files]' \\\n"
  result &= "                    '--not-linked[Show only not linked files]' \\\n"
  result &= "                    '--other[Show other profile files]' \\\n"
  result &= "                    '--ascii[Use ASCII instead of Unicode]' \\\n"
  result &= "                    '--verbose[Show detailed output]' \\\n"
  result &= "                    {-h,--help}'[Show help]' \\\n"
  result &= "                    {-v,--verbose}'[Show version]'\n"
  result &= "                ;;\n\n"

  result &= "            *)\n"
  result &= "                _files\n"
  result &= "                ;;\n"
  result &= "        esac\n"
  result &= "    elif (( CURRENT == 4 )); then\n"
  result &= "        case $words[2] in\n"
  result &= "            clone)\n"
  result &= "                _dotman_complete_profiles\n"
  result &= "                ;;\n"
  result &= "        esac\n"
  result &= "    fi\n"
  result &= "}\n\n"

  result &= "_dotman_complete_profiles() {\n"
  result &= "    local profiles\n"
  result &= "    profiles=(${(f)\"$(dotman list 2>/dev/null)\"})\n"
  result &= "    _describe 'profile' profiles\n"
  result &= "}\n"

proc generateFishCompletion*(): string =
  result =
    """# Fish completion for dotman

"""

  for cmd, desc in CommandDescriptions.pairs:
    result &=
      "complete -c dotman -f -n '__fish_use_subcommand' -a '" & cmd & "' -d '" & desc &
      "'\n"

  result &= "\n# Short flags\n"
  for short, long in ShortFlags.pairs:
    result &= "complete -c dotman -f -s " & short & " -d '" & LongFlags[long] & "'\n"

  result &= "\n# Long flags\n"
  for flag, desc in LongFlags.pairs:
    result &= "complete -c dotman -f -l '" & flag & "' -d '" & desc & "'\n"

  result &= "\n# File argument completions\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from add remove set unset' -a '(__fish_complete_path)'\n"

  result &= "\n# Profile completions\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from push pull' -a '(dotman list)'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from clone; and __fish_is_nth_token 3' -a '(dotman list)'\n"

  result &= "\n# Status command flags\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l profile -d 'Select profile' -a '(dotman list)'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l category -d 'Filter by category' -a 'config share home local bin'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l conflicts -d 'Show only conflicts'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l linked -d 'Show only linked files'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l not-linked -d 'Show only not linked files'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l other -d 'Show other profile files'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l ascii -d 'Use ASCII instead of Unicode'\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from status' -l verbose -d 'Show detailed output'\n"

  result &= "\n# Make command\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from make' -a '(command -s \"profile name\")'\n"

  result &= "\n# Clone command - second argument is destination\n"
  result &=
    "complete -c dotman -f -n '__fish_seen_subcommand_from clone; and __fish_is_nth_token 4' -a '(command -s \"destination profile\")'\n"

proc generateCompletion*(kind: CompletionType): string =
  case kind
  of BashCompletion:
    return generateBashCompletion()
  of ZshCompletion:
    return generateZshCompletion()
  of FishCompletion:
    return generateFishCompletion()

proc printCompletion*(kind: CompletionType) =
  echo generateCompletion(kind)

when isMainModule:
  import std/parseopt
  import std/os

  var kind = BashCompletion
  var outputFile = ""

  for kind, key, val in getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case key
      of "bash":
        kind = BashCompletion
      of "zsh":
        kind = ZshCompletion
      of "fish":
        kind = FishCompletion
      of "output", "o":
        outputFile = val
      of "help", "h":
        echo "Usage: completion_generator [options]"
        echo ""
        echo "Options:"
        echo "  --bash, -b          Generate bash completion (default)"
        echo "  --zsh, -z           Generate zsh completion"
        echo "  --fish, -f          Generate fish completion"
        echo "  --output, -o FILE    Write to file instead of stdout"
        echo "  --help, -h           Show this help"
        quit(0)
    else:
      discard

  let script = generateCompletion(kind)

  if outputFile.len > 0:
    writeFile(outputFile, script)
    let kindStr =
      case kind
      of BashCompletion: "bash"
      of ZshCompletion: "zsh"
      of FishCompletion: "fish"
    echo "✓ Generated " & kindStr & " completion: " & outputFile
  else:
    echo script
