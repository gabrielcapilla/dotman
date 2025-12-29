import std/os

proc getDotmanDir*(): string =
  getHomeDir() / "dotman"
