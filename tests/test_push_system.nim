import std/[os, unittest, tempfiles]
import ../src/systems/push_system
import ../src/systems/profile_ops
import ../src/systems/add_system
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

suite "Push System Tests":
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

  test "pushProfile creates symlinks for all unlinked files":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    check:
      not symlinkExists(testHome / "testfile.txt")

    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / "testfile.txt")

  test "pushProfile updates existing symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "new content")
    addFile(MainProfile, "testfile.txt")

    writeFile(profileFile, "updated content")
    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / "testfile.txt")
    check:
      readFile(testHome / "testfile.txt") == "updated content"

  test "pushProfile handles directories":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")

    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config2.txt")

  test "pushProfile handles nested directories":
    let nestedDir = getDotmanDir() / MainProfile / "config" / "myapp" / "nested"
    createDir(nestedDir)
    writeFile(nestedDir / "file.txt", "deep content")

    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / ".config" / "myapp" / "nested" / "file.txt")

  test "pushProfile fails with existing file conflict":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    writeFile(testHome / "testfile.txt", "local content")

    expect ProfileError:
      pushProfile(MainProfile)

  test "pushProfile fails with existing directory conflict":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config.txt", "profile content")
    createDir(testHome / ".config" / "myapp")

    expect ProfileError:
      pushProfile(MainProfile)

  test "pushProfile fails with other profile conflict":
    createProfile("profile2")
    let file1 = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    let file2 = getDotmanDir() / "profile2" / "home" / "testfile.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "content1")
    writeFile(file2, "content2")
    addFile("profile2", "testfile.txt")

    expect ProfileError:
      pushProfile(MainProfile)

  test "pushProfile handles empty profile":
    pushProfile(MainProfile)

  test "pushProfile handles mixed states":
    let file1 = getDotmanDir() / MainProfile / "home" / "linked.txt"
    let file2 = getDotmanDir() / MainProfile / "home" / "unlinked.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "linked content")
    writeFile(file2, "unlinked content")
    addFile(MainProfile, "linked.txt")

    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / "linked.txt")
    check:
      symlinkExists(testHome / "unlinked.txt")

  test "pushProfile handles many files efficiently":
    const fileCount = 100
    for i in 0 ..< fileCount:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)

    pushProfile(MainProfile)

    for i in 0 ..< fileCount:
      check:
        symlinkExists(testHome / "file" & $i & ".txt")

  test "pushProfile handles hidden files":
    let profileFile = getDotmanDir() / MainProfile / "home" / ".hiddenfile"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "hidden content")

    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / ".hiddenfile")

  test "pushProfile works on custom profile":
    createProfile("custom")
    let profileFile = getDotmanDir() / "custom" / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")

    pushProfile("custom")
    check:
      symlinkExists(testHome / "testfile.txt")

  test "pushProfile fails on non-existent profile":
    expect ProfileError:
      pushProfile("nonexistent")

  test "pushProfile handles files with special characters":
    let profileFile = getDotmanDir() / MainProfile / "home" / "test-file_123.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")

    pushProfile(MainProfile)
    check:
      symlinkExists(testHome / "test-file_123.txt")

  test "pushProfile preserves file contents":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "original content")

    pushProfile(MainProfile)
    check:
      readFile(testHome / "testfile.txt") == "original content"

  test "pushProfile creates parent directories if needed":
    let profileFile = getDotmanDir() / MainProfile / "config" / "nested-app.conf"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "config")

    pushProfile(MainProfile)
    check:
      dirExists(testHome / ".config")
    check:
      symlinkExists(testHome / ".config" / "nested-app.conf")

  test "validatePush finds conflicts correctly":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    writeFile(testHome / "testfile.txt", "local content")

    let result = validatePush(MainProfile)
    check:
      result.hasConflicts == true
    check:
      result.count == 1

  test "validatePush returns no conflicts when clean":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")

    let result = validatePush(MainProfile)
    check:
      result.hasConflicts == false
