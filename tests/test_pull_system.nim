import std/[os, unittest, tempfiles]
import ../src/systems/pull_system
import ../src/systems/profile_ops
import ../src/systems/add_system
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

suite "Pull System Tests":
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

  test "pullProfile removes all managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    addFile(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / "testfile.txt")

  test "pullProfile removes directory symlinks":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    addFile(MainProfile, "myapp")

    check:
      symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "config2.txt")

  test "pullProfile handles nested directories":
    let nestedDir = getDotmanDir() / MainProfile / "config" / "myapp" / "nested"
    createDir(nestedDir)
    writeFile(nestedDir / "file.txt", "deep content")
    addFile(MainProfile, "myapp")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "nested" / "file.txt")

  test "pullProfile does not remove non-managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "managed.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "managed content")
    addFile(MainProfile, "managed.txt")

    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    let externalLink = testHome / "external_link.txt"
    createSymlink(externalFile, externalLink)

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / "managed.txt")
    check:
      symlinkExists(externalLink)

  test "pullProfile handles mixed managed and non-managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "managed.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "managed content")
    addFile(MainProfile, "managed.txt")

    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    let externalLink = testHome / "external_link.txt"
    createSymlink(externalFile, externalLink)

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / "managed.txt")
    check:
      symlinkExists(externalLink)

  test "pullProfile handles empty profile":
    pullProfile(MainProfile)

  test "pullProfile handles profile with unlinked files":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")

    pullProfile(MainProfile)
    check:
      fileExists(profileFile)

  test "pullProfile removes all symlinks in profile":
    const fileCount = 10
    for i in 0 ..< fileCount:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)
      addFile(MainProfile, "file" & $i & ".txt")

    for i in 0 ..< fileCount:
      check:
        symlinkExists(testHome / "file" & $i & ".txt")

    pullProfile(MainProfile)

    for i in 0 ..< fileCount:
      check:
        not symlinkExists(testHome / "file" & $i & ".txt")

  test "pullProfile handles hidden files":
    let profileFile = getDotmanDir() / MainProfile / "home" / ".hiddenfile"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "hidden content")
    addFile(MainProfile, ".hiddenfile")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / ".hiddenfile")

  test "pullProfile works on custom profile":
    createProfile("custom")
    let profileFile = getDotmanDir() / "custom" / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile("custom", "testfile.txt")

    pullProfile("custom")
    check:
      not symlinkExists(testHome / "testfile.txt")

  test "pullProfile fails on non-existent profile":
    expect ProfileError:
      pullProfile("nonexistent")

  test "pullProfile does not affect other profile symlinks":
    createProfile("profile2")
    let file1 = getDotmanDir() / MainProfile / "home" / "file1.txt"
    let file2 = getDotmanDir() / "profile2" / "home" / "file2.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "content1")
    writeFile(file2, "content2")
    addFile(MainProfile, "file1.txt")
    addFile("profile2", "file2.txt")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / "file1.txt")
    check:
      symlinkExists(testHome / "file2.txt")

  test "pullProfile handles files with special characters":
    let profileFile = getDotmanDir() / MainProfile / "home" / "test-file_123.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile(MainProfile, "test-file_123.txt")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / "test-file_123.txt")

  test "pullProfile can be called multiple times":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile(MainProfile, "testfile.txt")

    pullProfile(MainProfile)
    pullProfile(MainProfile)

  test "validatePull finds all managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    addFile(MainProfile, "testfile.txt")

    let result = validatePull(MainProfile)
    check:
      result.count == 1
    check:
      result.capacity >= 1

  test "validatePull returns empty when no symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")

    let result = validatePull(MainProfile)
    check:
      result.count == 0

  test "validatePull ignores non-managed symlinks":
    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    let externalLink = testHome / "external_link.txt"
    createSymlink(externalFile, externalLink)

    let result = validatePull(MainProfile)
    check:
      result.count == 0

  test "pullProfile handles bin directory":
    let binDir = getDotmanDir() / MainProfile / "bin"
    createDir(binDir)
    writeFile(binDir / "mytool", "tool content")
    addFile(MainProfile, "mytool")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / ".local" / "bin" / "mytool")

  test "pullProfile handles share directory":
    let shareDir = getDotmanDir() / MainProfile / "share"
    createDir(shareDir)
    writeFile(shareDir / "data.txt", "data")
    addFile(MainProfile, "data.txt")

    pullProfile(MainProfile)
    check:
      not symlinkExists(testHome / ".local" / "share" / "data.txt")
