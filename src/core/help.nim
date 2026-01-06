import std/[strformat, os]
import colors

proc getAppName*(): string =
  result = extractFilename(getAppFilename())
  if result == "":
    result = "dotman"

proc showHelp*() =
  let binName = getAppName()

  echo pad(fmt"{yellow}Usage:{reset} {binName} [options] {blue}<command>{reset}", "", 0)

  echo ""
  echo "Dotfile Manager - Manage your dotfiles with profiles and symlinks."

  echo ""
  echo pad(fmt"{yellow}Profile Commands:{reset}", "", 0)
  echo pad(fmt"{green}  init, -i{reset}", "Initialize dotman in current directory.", 28)
  echo pad(
    fmt"{green}  make, -m{reset}{blue} <name>{reset}", "Create a new profile.", 28
  )
  echo pad(
    fmt"{green}  clone, -c{reset}{blue} <src> <dest>{reset}",
    "Clone an existing profile.",
    28,
  )
  echo pad(fmt"{green}  list, -l{reset}", "List all profiles.", 28)

  echo ""
  echo pad(fmt"{yellow}Manage Commands:{reset}", "", 0)
  echo pad(
    fmt"{green}  set, -s{reset}{blue} <file>{reset}",
    "Move file to profile and create symlink.",
    28,
  )
  echo pad(
    fmt"{green}  unset, -u{reset}{blue} <file>{reset}",
    "Unset file from profile (restore original).",
    28,
  )

  echo ""
  echo pad(fmt"{yellow}Link Commands:{reset}", "", 0)
  echo pad(
    fmt"{green}  add, -a{reset}{blue} <file>{reset}",
    "Add file (create symlink from existing).",
    28,
  )
  echo pad(fmt"{green}  remove, -r{reset}{blue} <file>{reset}", "Remove symlink.", 28)

  echo ""
  echo pad(fmt"{yellow}Status Commands:{reset}", "", 0)
  echo pad(fmt"{green}  status{reset}", "Show profile status.", 28)
  echo pad(
    fmt"{cyan}    --category{reset}{blue} <cat>{reset}",
    "Filter by category (config, share, home, local, bin).",
    28,
  )
  echo pad(fmt"{cyan}    --conflicts{reset}", "Show conflicting files only.", 28)
  echo pad(fmt"{cyan}    --linked{reset}", "Show linked files only.", 28)
  echo pad(fmt"{cyan}    --not-linked{reset}", "Show unlinked files only.", 28)
  echo pad(fmt"{cyan}    --other{reset}", "Show other files in profile.", 28)
  echo pad(fmt"{cyan}    --ascii{reset}", "Use ASCII characters in table.", 28)
  echo pad(fmt"{cyan}    --verbose, -v{reset}", "Show detailed information.", 28)

  echo ""
  echo pad(fmt"{yellow}Sync Commands:{reset}", "", 0)
  echo pad(
    fmt"{green}  push{reset}{blue} <profile>{reset}",
    "Push changes from home to profile.",
    28,
  )
  echo pad(
    fmt"{green}  pull{reset}{blue} <profile>{reset}",
    "Pull changes from profile to home.",
    28,
  )

  echo ""
  echo pad(fmt"{yellow}Options:{reset}", "", 0)
  echo pad(
    fmt"{cyan}  --profile{reset}{blue} <name>{reset}",
    "Set active profile (default: main).",
    28,
  )
  echo pad(
    fmt"{cyan}  --delete-profile{reset}{blue} <name>{reset}",
    "Delete an existing profile.",
    28,
  )
  echo pad(fmt"{cyan}  --help, -h{reset}", "Show this help message.", 28)
  echo pad(fmt"{cyan}  --version, -v{reset}", "Show version information.", 28)

  quit(0)

proc showVersion*() =
  let binName = getAppName()
  echo fmt"{green}{binName}{reset} 0.2.0"
  quit(0)
