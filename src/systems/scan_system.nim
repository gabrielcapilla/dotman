import std/[os, strutils]
import ../components/status
import path_resolution

type ScanConfig* = object
  maxDepth*: int
  maxFiles*: int

proc estimateFileCount*(dir: string): int =
  try:
    result = 0
    for kind, _ in walkDir(dir):
      if kind == pcDir:
        result += 64
        if result > 8192:
          return 8192
  except:
    return 1024

proc isParentSymlinked*(fullPath, homePath, profileDir: string): bool =
  var currentHome = homePath.parentDir
  var currentFull = fullPath.parentDir

  while currentHome != getHomeDir() and currentFull != profileDir:
    if symlinkExists(currentHome):
      let target = expandSymlink(currentHome)
      if target == currentFull:
        return true
      elif target.startsWith(profileDir):
        return true
    currentHome = currentHome.parentDir
    currentFull = currentFull.parentDir

  return false

proc determineStatus*(fullPath, homePath, profileDir: string): LinkStatus =
  if symlinkExists(homePath):
    let target = expandSymlink(homePath)
    if target == fullPath:
      return Linked
    elif target.startsWith(profileDir):
      return OtherProfile
    return Conflict
  elif fileExists(homePath) or dirExists(homePath):
    if isParentSymlinked(fullPath, homePath, profileDir):
      return Linked
    return Conflict
  return NotLinked

proc scanProfile*(profileDir: string, config: ScanConfig): StatusData =
  let estimatedFiles = estimateFileCount(profileDir)
  result = initStatusData(estimatedFiles)

  var fileCount = 0
  for kind, categoryPath in walkDir(profileDir, relative = true):
    if kind == pcDir:
      let catDir = profileDir / categoryPath

      for itemPath in walkDirRec(catDir, relative = true):
        if fileCount >= config.maxFiles:
          break

        let fullPath = catDir / itemPath
        let relPath = categoryPath / itemPath

        if dirExists(fullPath) or fileExists(fullPath):
          let homePath = resolveDestPath(profileDir, relPath)
          let status = determineStatus(fullPath, homePath, profileDir)

          result.addStatusEntry(relPath, homePath, status)
          fileCount += 1

proc scanProfileSimple*(profileDir: string): StatusData =
  let config = ScanConfig(maxDepth: 10, maxFiles: 8192)
  scanProfile(profileDir, config)
