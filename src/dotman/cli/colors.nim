import std/[strformat, strutils]

const
  reset* = "\e[0m"
  red* = "\e[31m"
  green* = "\e[32m"
  yellow* = "\e[33m"
  blue* = "\e[34m"
  magenta* = "\e[35m"
  cyan* = "\e[36m"
  white* = "\e[37m"
  bold* = "\e[1m"

func stripAnsi*(s: string): string =
  result = newStringOfCap(s.len)
  var i = 0
  while i < s.len:
    if s[i] == '\e' and i + 1 < s.len and s[i + 1] == '[':
      i += 2
      while i < s.len and s[i] notin {'m', 'K', 'H', 'f'}:
        i += 1
      if i < s.len:
        i += 1
    else:
      result.add(s[i])
      i += 1

func pad*(cmd: string, desc: string, column: int): string =
  let padding = max(0, column - stripAnsi(cmd).len)
  cmd & " ".repeat(padding) & (if desc.len > 0: " " & desc else: desc)

proc actionSuccess*(msg: string) =
  echo fmt"{green}::{reset} {msg}"

proc actionWarning*(msg: string) =
  echo fmt"{yellow}::{reset} {msg}"

proc actionError*(msg: string) =
  echo fmt"{red}::{reset} {msg}"
