import std/[os, unittest, tempfiles]
import ../src/systems/set_system
import ../src/systems/profile_ops
import ../src/systems/execution_engine
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles

# Helper wrapper to adapt tests to new API
proc moveFileToProfileWrapper(profileName: string, homePath: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = set_system.planMoveFileToProfile(profiles, pid, homePath)
  discard executePlan(plan, verbose = false)

suite "Set System Tests":
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

  test "moveFileToProfile moves file to home category":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "test content")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) == (
        getDotmanDir() / MainProfile / "home" / "testfile.txt"
      )

  test "moveFileToProfile moves file to config category":
    let configDir = testHome / ".config"
    createDir(configDir)
    let testFile = configDir / "myapp.conf"
    writeFile(testFile, "config content")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) == (
        getDotmanDir() / MainProfile / "config" / "myapp.conf"
      )

  test "moveFileToProfile moves file to local/bin":
    let binDir = testHome / ".local" / "bin"
    createDir(binDir)
    let testFile = binDir / "mytool"
    writeFile(testFile, "#!/bin/bash\necho test")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) == (getDotmanDir() / MainProfile / "bin" / "mytool")

  test "moveFileToProfile moves file to local/share":
    let shareDir = testHome / ".local" / "share"
    createDir(shareDir)
    let testFile = shareDir / "data.txt"
    writeFile(testFile, "data")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) == (getDotmanDir() / MainProfile / "share" / "data.txt")

  test "moveFileToProfile moves directory":
    let configDir = testHome / ".config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    moveFileToProfileWrapper(MainProfile, configDir)
    check:
      symlinkExists(configDir)
    check:
      expandSymlink(configDir) == (getDotmanDir() / MainProfile / "config" / "myapp")
    check:
      fileExists(getDotmanDir() / MainProfile / "config" / "myapp" / "config1.txt")
    check:
      fileExists(getDotmanDir() / MainProfile / "config" / "myapp" / "config2.txt")

  test "moveFileToProfile fails with existing symlink":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "original")
    moveFileToProfileWrapper(MainProfile, testFile)
    expect ProfileError:
      moveFileToProfileWrapper(MainProfile, testFile)

  test "moveFileToProfile fails if file not found":
    let testFile = testHome / "nonexistent.txt"
    expect ProfileError:
      moveFileToProfileWrapper(MainProfile, testFile)

  test "moveFileToProfile fails if profile not found":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    expect ProfileError:
      moveFileToProfileWrapper("nonexistent", testFile)

  test "moveFileToProfile fails if already exists in profile":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content1")
    moveFileToProfileWrapper(MainProfile, testFile)
    writeFile(testFile, "content2")
    expect ProfileError:
      moveFileToProfileWrapper(MainProfile, testFile)

  test "moveFileToProfile fails if file not in HOME":
    let testFile = "/tmp/testfile.txt"
    writeFile(testFile, "content")
    expect ProfileError:
      moveFileToProfileWrapper(MainProfile, testFile)
    removeFile(testFile)

  test "moveFileToProfile fails if source file not found":
    let testFile = testHome / "nonexistent.txt"
    expect ProfileError:
      moveFileToProfileWrapper(MainProfile, testFile)

  test "moveFileToProfile handles .hidden directories in home":
    let testFile = testHome / ".hiddenfile"
    writeFile(testFile, "content")
    moveFileToProfileWrapper(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      fileExists(getDotmanDir() / MainProfile / "home" / ".hiddenfile")

  test "moveFileToProfile handles deep paths in category":
    let deepDir = testHome / ".local" / "share" / "fonts"
    createDir(deepDir)
    let testFile = deepDir / "Monaspace"
    writeFile(testFile, "font data")

    moveFileToProfileWrapper(MainProfile, testFile)

    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) ==
        (getDotmanDir() / MainProfile / "share" / "fonts" / "Monaspace")
