when isMainModule:
  import completion

  echo "Generating completions..."

  echo "\n" & "=".repeat(60) & "\n"
  echo "Bash Completion:\n"
  echo "=".repeat(60) & "\n"
  printCompletion(BashCompletion)

  echo "\n" & "=".repeat(60) & "\n"
  echo "Zsh Completion:\n"
  echo "=".repeat(60) & "\n"
  printCompletion(ZshCompletion)
