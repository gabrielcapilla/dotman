import std/[os, unittest, tempfiles]
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles

suite "Profile Operations Tests":
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

  test "initDotfiles creates main profile":
    initDotfiles()
    check:
      dirExists(getDotmanDir())
    check:
      dirExists(getDotmanDir() / MainProfile)

  test "initDotfiles fails if already exists":
    initDotfiles()
    expect ProfileError:
      initDotfiles()

  test "createProfile creates new profile directory":
    initDotfiles()
    createProfile("test-profile")
    check:
      dirExists(getDotmanDir() / "test-profile")
    removeDir(getDotmanDir() / "test-profile")

  test "createProfile fails without init":
    expect ProfileError:
      createProfile("test-profile")

  test "createProfile fails if profile exists":
    initDotfiles()
    createProfile("test-profile")
    expect ProfileError:
      createProfile("test-profile")
    removeDir(getDotmanDir() / "test-profile")

  test "cloneProfile copies entire directory":
    initDotfiles()
    let sourcePath = getDotmanDir() / MainProfile
    writeFile(sourcePath / "file1.txt", "content1")
    writeFile(sourcePath / "file2.txt", "content2")
    cloneProfile(MainProfile, "cloned")
    check:
      dirExists(getDotmanDir() / "cloned")
    check:
      fileExists(getDotmanDir() / "cloned" / "file1.txt")
    check:
      fileExists(getDotmanDir() / "cloned" / "file2.txt")
    removeFile(sourcePath / "file1.txt")
    removeFile(sourcePath / "file2.txt")
    removeDir(getDotmanDir() / "cloned")

  test "cloneProfile fails if source not found":
    initDotfiles()
    expect ProfileError:
      cloneProfile("nonexistent", "dest")

  test "cloneProfile fails if dest exists":
    initDotfiles()
    createProfile("dest")
    expect ProfileError:
      cloneProfile(MainProfile, "dest")

  test "removeProfile deletes profile directory":
    initDotfiles()
    createProfile("test-profile")
    removeProfile("test-profile")
    check:
      not dirExists(getDotmanDir() / "test-profile")

  test "removeProfile fails for main profile":
    initDotfiles()
    expect ProfileError:
      removeProfile(MainProfile)

  test "removeProfile fails if profile not found":
    initDotfiles()
    expect ProfileError:
      removeProfile("nonexistent")

  test "listProfiles returns empty list when no profiles":
    initDotfiles()
    let profiles = listProfiles()
    check:
      profiles.len == 1
    check:
      "main" in profiles

  test "listProfiles returns all profiles":
    initDotfiles()
    createProfile("profile1")
    createProfile("profile2")
    createProfile("profile3")
    let profiles = listProfiles()
    check:
      profiles.len == 4
    check:
      "main" in profiles
    check:
      "profile1" in profiles
    check:
      "profile2" in profiles
    check:
      "profile3" in profiles
    removeDir(getDotmanDir() / "profile1")
    removeDir(getDotmanDir() / "profile2")
    removeDir(getDotmanDir() / "profile3")

  test "listProfiles returns empty without init":
    let profiles = listProfiles()
    check:
      profiles.len == 0
