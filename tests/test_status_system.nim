import std/[os, unittest, tempfiles]
import ../src/systems/status_system
import ../src/systems/scan_system
import ../src/systems/profile_ops
import ../src/systems/add_system
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

suite "Status System Tests":
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

  test "scanProfileSimple returns empty for empty profile":
    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 0
    check:
      report.linked == 0
    check:
      report.notLinked == 0
    check:
      report.conflicts == 0

  test "scanProfileSimple finds unlinked file":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 1
    check:
      report.notLinked == 1
    check:
      report.linked == 0

  test "scanProfileSimple finds linked file":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile(MainProfile, "testfile.txt")
    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 1
    check:
      report.linked == 1
    check:
      report.notLinked == 0

  test "scanProfileSimple detects conflict with existing file":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    writeFile(testHome / "testfile.txt", "local content")
    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 1
    check:
      report.conflicts == 1
    check:
      report.linked == 0

  test "scanProfileSimple detects conflict with other profile":
    createProfile("profile2")
    let file1 = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    let file2 = getDotmanDir() / "profile2" / "home" / "testfile.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "content1")
    writeFile(file2, "content2")
    addFile("profile2", "testfile.txt")
    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 1
    check:
      report.conflicts == 1

  test "scanProfileSimple handles multiple files":
    for i in 1 .. 5:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)

    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 5
    check:
      report.notLinked == 5

  test "scanProfileSimple handles mixed states":
    let file1 = getDotmanDir() / MainProfile / "home" / "linked.txt"
    let file2 = getDotmanDir() / MainProfile / "home" / "unlinked.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "linked content")
    writeFile(file2, "unlinked content")
    addFile(MainProfile, "linked.txt")

    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == 2
    check:
      report.linked == 1
    check:
      report.notLinked == 1

  test "showStatus works on existing profile":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    showStatus(MainProfile)

  test "showStatus fails on non-existent profile":
    expect ProfileError:
      showStatus("nonexistent")

  test "scanProfileSimple counts correctly with many files":
    const fileCount = 100
    for i in 0 ..< fileCount:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)

    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      report.count == fileCount
    check:
      report.notLinked == fileCount

  test "scanProfileSimple preserves relative paths":
    let profileFile = getDotmanDir() / MainProfile / "config" / "myapp.conf"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile(MainProfile, "myapp.conf")

    let report = scanProfileSimple(getDotmanDir() / MainProfile)
    check:
      "config/myapp.conf" in report.relPaths
