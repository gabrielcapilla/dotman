import std/[os, unittest, tempfiles]
import ../src/systems/cli_ops
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles

suite "CLI Operations Tests":
  setup:
    let tempDir = createTempDir("dotman_test_", "")
    let testHome = tempDir / "home"
    let testDotman = tempDir / "dotman"
    let originalHome = getEnv("HOME")

    createDir(testHome)
    createDir(testDotman)
    putEnv("HOME", testHome)

  teardown:
    putEnv("HOME", originalHome)
    removeDir(tempDir)

  test "runInit creates dotman directory":
    runInit()
    check:
      dirExists(getDotmanDir())
    check:
      dirExists(getDotmanDir() / MainProfile)

  test "runInit fails if already initialized":
    runInit()
    expect ProfileError:
      runInit()

  test "runProfileCreate creates new profile":
    runInit()
    runProfileCreate("test-profile")
    check:
      dirExists(getDotmanDir() / "test-profile")

  test "runProfileCreate fails without init":
    expect ProfileError:
      runProfileCreate("test-profile")

  test "runProfileClone copies profile":
    runInit()
    let sourcePath = getDotmanDir() / MainProfile
    writeFile(sourcePath / "test.txt", "test content")
    runProfileClone(MainProfile, "cloned-profile")
    check:
      dirExists(getDotmanDir() / "cloned-profile")
    check:
      fileExists(getDotmanDir() / "cloned-profile" / "test.txt")

  test "runProfileRemove deletes profile":
    runInit()
    runProfileCreate("test-profile")
    runProfileRemove("test-profile")
    check:
      not dirExists(getDotmanDir() / "test-profile")

  test "runProfileRemove fails for main profile":
    runInit()
    expect ProfileError:
      runProfileRemove(MainProfile)

  test "runProfileList lists profiles":
    runInit()
    runProfileCreate("profile1")
    runProfileCreate("profile2")
    runProfileList()
