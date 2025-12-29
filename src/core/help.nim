proc showHelp*() =
  echo "Profile commands:"
  echo "  dotman init"
  echo "  dotman make <name>"
  echo "  dotman clone <src> <dest>"
  echo "  dotman list"
  echo ""
  echo "Manage commands:"
  echo "  dotman set <file>"
  echo "  dotman unset <file>"
  echo ""
  echo "Link commands:"
  echo "  dotman add <file>"
  echo "  dotman remove <file>"
  echo ""
  echo "Misc commands:"
  echo "  dotman status"
  echo "  dotman push <profile>"
  echo "  dotman pull <profile>"
  echo ""
  echo "Options:"
  echo "  dotman --profile <name>"
  echo "  dotman version"
  echo "  dotman help"
  quit(0)

proc showVersion*() =
  echo "dotman 0.1.0"
  quit(0)
