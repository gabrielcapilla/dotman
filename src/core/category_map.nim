import std/os

type Category* = distinct string

proc getDestPath*(category: string, home: string, filename: string): string =
  if category == "home":
    result = home / filename
  elif category == "config":
    result = home / ".config" / filename
  elif category == "local":
    result = home / ".local" / filename
  elif category == "bin":
    result = home / ".local" / "bin" / filename
  elif category == "share":
    result = home / ".local" / "share" / filename
  else:
    result = home / "." & category / filename
