import std/os

type Category* = distinct string

proc getDestRoot*(category: string, home: string): string {.noSideEffect.} =
  if category == "home":
    result = home
  elif category == "config":
    result = home / ".config"
  elif category == "local":
    result = home / ".local"
  elif category == "bin":
    result = home / ".local" / "bin"
  elif category == "share":
    result = home / ".local" / "share"
  else:
    result = home / "." & category

proc getDestPath*(
    category: string, home: string, filename: string
): string {.noSideEffect.} =
  getDestRoot(category, home) / filename
