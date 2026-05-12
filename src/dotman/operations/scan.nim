import std/[os, tables]
import ../platform/[linux_statx, path_safety], ../domain/types
import ../domain/[status, profiles]
import paths

type ScanConfig* = object
  maxFiles*: int
  storeHomePaths*: bool

type ParentPathInfo = object
  canContainFiles: bool
  symlinkedToProfile: bool

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

proc isParentDirSymlinked(homeParent, fullParent, profileDir, homeDir: string): bool =
  var currentHome = homeParent
  var currentFull = fullParent

  while currentHome != homeDir and currentFull != profileDir:
    if symlinkExists(currentHome):
      let target = expandSymlink(currentHome)
      if target == currentFull:
        return true
      elif isWithinPath(target, profileDir):
        return true
    currentHome = currentHome.parentDir
    currentFull = currentFull.parentDir

  return false

proc isParentSymlinked*(fullPath, homePath, profileDir: string): bool =
  isParentDirSymlinked(homePath.parentDir, fullPath.parentDir, profileDir, getHomeDir())

proc joinKnownRelative(base, rel: string): string {.inline.} =
  if rel.len == 0:
    return base

  result = newStringOfCap(base.len + rel.len + 1)
  result.add(base)
  if base.len > 0 and base[^1] != DirSep:
    result.add(DirSep)
  result.add(rel)

proc relativeParent(path: string): string {.inline.} =
  result = path.parentDir
  if result == ".":
    result = ""

proc parentPathInfo(
    homePath, catDir, itemPath, profileDir, homeDir: string,
    cache: var Table[string, ParentPathInfo],
): ParentPathInfo =
  let parent = homePath.parentDir
  if parent in cache:
    return cache[parent]

  case fastFileInfo(parent).kind
  of ffDir, ffSymlink:
    result.canContainFiles = true
  else:
    result.canContainFiles = false

  if result.canContainFiles:
    result.symlinkedToProfile = isParentDirSymlinked(
      parent, joinKnownRelative(catDir, itemPath.relativeParent), profileDir, homeDir
    )
  cache[parent] = result

proc determineStatus*(
    catDir, itemPath, homePath, profileDir, homeDir: string,
    parentCache: var Table[string, ParentPathInfo],
    linkScratch: var string,
): LinkStatus =
  case classifyLinkTarget(homePath, catDir, itemPath, profileDir, -1, linkScratch)
  of ltmExact:
    return Linked
  of ltmWithinRoot:
    return OtherProfile
  of ltmOther:
    return Conflict
  of ltmMissing:
    return NotLinked
  of ltmUnreadable:
    discard

  let parentInfo =
    parentPathInfo(homePath, catDir, itemPath, profileDir, homeDir, parentCache)
  if not parentInfo.canContainFiles:
    return NotLinked

  let homeInfo = fastFileInfo(homePath)

  case homeInfo.kind
  of ffSymlink:
    let expectedLen = catDir.len + itemPath.len + 1
    if homeInfo.size != expectedLen and homeInfo.size < profileDir.len:
      return Conflict
    case classifyLinkTarget(
      homePath, catDir, itemPath, profileDir, homeInfo.size, linkScratch
    )
    of ltmUnreadable:
      return Conflict
    of ltmMissing:
      return NotLinked
    of ltmExact:
      return Linked
    of ltmWithinRoot:
      return OtherProfile
    of ltmOther:
      return Conflict
  of ffFile, ffDir:
    if parentInfo.symlinkedToProfile:
      return Linked
    return Conflict
  else:
    return NotLinked

proc scanProfile*(
    profiles: var ProfileData, profileId: ProfileId, config: ScanConfig
): StatusData =
  let profileDir = profiles.getProfilePath(profileId)
  let homeDir = getHomeDir()
  let estimatedFiles = estimateFileCount(profileDir)
  result = initStatusData(estimatedFiles)

  var fileCount = 0
  var parentCache = initTable[string, ParentPathInfo](estimatedFiles div 8 + 1)
  var linkScratch = newStringOfCap(256)
  for kind, categoryPath in walkDir(profileDir, relative = true):
    if fileCount >= config.maxFiles:
      break

    if kind == pcDir:
      let category = getCategory(categoryPath)
      let catDir = profileDir / categoryPath
      let destRoot = resolveDestRoot(categoryPath, homeDir)

      for itemPath in walkDirRec(catDir, relative = true):
        if fileCount >= config.maxFiles:
          break

        let homePath = joinKnownRelative(destRoot, itemPath)
        let status = determineStatus(
          catDir, itemPath, homePath, profileDir, homeDir, parentCache, linkScratch
        )
        result.addStatusEntry(itemPath, category, status)
        fileCount += 1

proc scanProfileSimple*(profiles: var ProfileData, profileId: ProfileId): StatusData =
  let config = ScanConfig(maxFiles: 8192, storeHomePaths: true)
  scanProfile(profiles, profileId, config)
