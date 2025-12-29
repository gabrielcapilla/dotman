import std/[os, unittest, tempfiles]
import ../src/systems/set_system
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

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
    moveFileToProfile(MainProfile, testFile)
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
    moveFileToProfile(MainProfile, testFile)
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
    moveFileToProfile(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) == (getDotmanDir() / MainProfile / "bin" / "mytool")

  test "moveFileToProfile moves file to local/share":
    let shareDir = testHome / ".local" / "share"
    createDir(shareDir)
    let testFile = shareDir / "data.txt"
    writeFile(testFile, "data")
    moveFileToProfile(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      expandSymlink(testFile) == (getDotmanDir() / MainProfile / "share" / "data.txt")

  test "moveFileToProfile moves directory":
    let configDir = testHome / ".config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    moveFileToProfile(MainProfile, configDir)
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
    moveFileToProfile(MainProfile, testFile)
    expect ProfileError:
      moveFileToProfile(MainProfile, testFile)

  test "moveFileToProfile fails if file not found":
    let testFile = testHome / "nonexistent.txt"
    expect ProfileError:
      moveFileToProfile(MainProfile, testFile)

  test "moveFileToProfile fails if profile not found":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content")
    expect ProfileError:
      moveFileToProfile("nonexistent", testFile)

  test "moveFileToProfile fails if already exists in profile":
    let testFile = testHome / "testfile.txt"
    writeFile(testFile, "content1")
    moveFileToProfile(MainProfile, testFile)
    writeFile(testFile, "content2")
    expect ProfileError:
      moveFileToProfile(MainProfile, testFile)

  test "moveFileToProfile fails if file not in HOME":
    let testFile = "/tmp/testfile.txt"
    writeFile(testFile, "content")
    expect ProfileError:
      moveFileToProfile(MainProfile, testFile)
    removeFile(testFile)

  test "moveFileToProfile fails if source file not found":
    let testFile = testHome / "nonexistent.txt"
    expect ProfileError:
      moveFileToProfile(MainProfile, testFile)

  test "moveFileToProfile handles .hidden directories in home":
    let testFile = testHome / ".hiddenfile"
    writeFile(testFile, "content")
    moveFileToProfile(MainProfile, testFile)
    check:
      symlinkExists(testFile)
    check:
      fileExists(getDotmanDir() / MainProfile / "home" / ".hiddenfile")
