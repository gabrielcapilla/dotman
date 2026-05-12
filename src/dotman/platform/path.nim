import std/os

proc getDotmanDir*(): string {.inline, noSideEffect.} =
  getHomeDir() / ".dotfiles"
