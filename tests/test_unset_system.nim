import std/[os, unittest, tempfiles]
import ../src/systems/unset_system
import ../src/systems/add_system
import ../src/systems/set_system
import ../src/systems/execution_engine
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles

# Helper wrappers to adapt tests to new API
proc addFileWrapper(profileName: string, fileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = add_system.planAddFile(profiles, pid, fileName)
  discard executePlan(plan, verbose = false)

proc unsetFileWrapper(profileName: string, fileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = unset_system.planUnsetFile(profiles, pid, fileName)
  discard executePlan(plan, verbose = false)

proc moveFileToProfileWrapper(profileName: string, homePath: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = set_system.planMoveFileToProfile(profiles, pid, homePath)
  discard executePlan(plan, verbose = false)

proc isDotmanManaged(linkPath: string, profileName: string): bool =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    return false
  let path = profiles.getProfilePath(pid)
  unset_system.isDotmanManaged(linkPath, path)

suite "Unset System Tests":
  setup:
    let tempDir = createTempDir("dotman_test_", "")
    let testHome = tempDir / "home"
    let testDotman = tempDir / "dotman"
    let originalHome = getEnv("HOME")

    createDir(testHome)
    createDir(testDotman)
    putEnv("HOME", testHome)
    initDotfiles()

  teardown:
    putEnv("HOME", originalHome)
    removeDir(tempDir)

  test "unsetFile removes symlink and restores file":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "test content")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      symlinkExists(testFile)

    unsetFileWrapper(MainProfile, "testfile.txt")
    check:
      not symlinkExists(testFile)
    check:
      fileExists(testFile)
    check:
      readFile(testFile) == "test content"

  test "unsetFile removes symlink and restores directory":
    let configDir = testHome / ".config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    moveFileToProfileWrapper(MainProfile, configDir)
    check:
      symlinkExists(configDir)

    unsetFileWrapper(MainProfile, "myapp")
    check:
      not symlinkExists(configDir)
    check:
      dirExists(configDir)
    check:
      fileExists(configDir / "config1.txt")
    check:
      fileExists(configDir / "config2.txt")

  test "unsetFile fails if file not in profile":
    expect ProfileError:
      unsetFileWrapper(MainProfile, "testfile.txt")

  test "unsetFile fails if file not managed by dotman":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    expect ProfileError:
      unsetFileWrapper(MainProfile, "testfile.txt")

  test "isDotmanManaged returns true for managed symlink":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      isDotmanManaged(testFile, MainProfile)

  test "isDotmanManaged returns false for non-symlink":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    check:
      not isDotmanManaged(testFile, MainProfile)

  test "isDotmanManaged returns false for external symlink":
    let testFile = testHome / "testfile.txt"
    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    createSymlink(externalFile, testFile)
    check:
      not isDotmanManaged(testFile, MainProfile)

  test "isDotmanManaged rejects profile prefix confusion":
    let profileDir = getDotmanDir() / MainProfile
    let fakeProfileDir = profileDir & "_other"
    createDir(fakeProfileDir)
    let fakeTarget = fakeProfileDir / "file.txt"
    writeFile(fakeTarget, "x")
    let linkPath = testHome / "prefix-link.txt"
    createSymlink(fakeTarget, linkPath)
    check:
      not unset_system.isDotmanManaged(linkPath, profileDir)

  test "unsetFile handles deep paths":
    let fontsDir = testHome / ".local" / "share" / "fonts"
    let deepDir = fontsDir / "Monaspace"
    createDir(deepDir)
    let testFile = deepDir / "font.ttf"
    writeFile(testFile, "font data")

    moveFileToProfileWrapper(MainProfile, deepDir)
    check:
      symlinkExists(deepDir)

    unsetFileWrapper(MainProfile, "Monaspace")

    check:
      not symlinkExists(deepDir)
    check:
      dirExists(deepDir)
    check:
      fileExists(testFile)
    check:
      readFile(testFile) == "font data"
