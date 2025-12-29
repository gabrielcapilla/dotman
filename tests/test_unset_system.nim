import std/[os, unittest, tempfiles]
import ../src/systems/unset_system
import ../src/systems/set_system
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

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
    moveFileToProfile(MainProfile, testFile)
    check:
      symlinkExists(testFile)

    unsetFile(MainProfile, "testfile.txt")
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
    moveFileToProfile(MainProfile, configDir)
    check:
      symlinkExists(configDir)

    unsetFile(MainProfile, "myapp")
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
      unsetFile(MainProfile, "testfile.txt")

  test "unsetFile fails if file not managed by dotman":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    expect ProfileError:
      unsetFile(MainProfile, "testfile.txt")

  test "isDotmanManaged returns true for managed symlink":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    moveFileToProfile(MainProfile, testFile)
    check:
      isDotmanManaged(testFile, getDotmanDir() / MainProfile)

  test "isDotmanManaged returns false for non-symlink":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    check:
      not isDotmanManaged(testFile, getDotmanDir() / MainProfile)

  test "isDotmanManaged returns false for external symlink":
    let testFile = testHome / "testfile.txt"
    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    createSymlink(externalFile, testFile)
    check:
      not isDotmanManaged(testFile, getDotmanDir() / MainProfile)
