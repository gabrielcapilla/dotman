import std/[os, unittest, tempfiles]
import ../src/systems/status_system
import ../src/systems/scan_system
import ../src/systems/profile_ops
import ../src/systems/add_system
import ../src/systems/execution_engine
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles
import ../src/components/status

# Helper wrapper to adapt tests to new API
proc addFileWrapper(profileName: string, fileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = add_system.planAddFile(profiles, pid, fileName)
  discard executePlan(plan, verbose = false)

proc scanProfileSimpleWrapper(profileName: string): StatusData =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  scan_system.scanProfileSimple(profiles, pid)

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
    let report = scanProfileSimpleWrapper(MainProfile)
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
    let report = scanProfileSimpleWrapper(MainProfile)
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
    addFileWrapper(MainProfile, "testfile.txt")
    let report = scanProfileSimpleWrapper(MainProfile)
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
    let report = scanProfileSimpleWrapper(MainProfile)
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
    addFileWrapper("profile2", "testfile.txt")
    let report = scanProfileSimpleWrapper(MainProfile)
    check:
      report.count == 1
    check:
      report.conflicts == 1

  test "scanProfileSimple handles multiple files":
    for i in 1 .. 5:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)

    let report = scanProfileSimpleWrapper(MainProfile)
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
    addFileWrapper(MainProfile, "linked.txt")

    let report = scanProfileSimpleWrapper(MainProfile)
    check:
      report.count == 2
    check:
      report.linked == 1
    check:
      report.notLinked == 1

  test "scanProfileSimple counts correctly with many files":
    const fileCount = 100
    for i in 0 ..< fileCount:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)

    let report = scanProfileSimpleWrapper(MainProfile)
    check:
      report.count == fileCount
    check:
      report.notLinked == fileCount

  test "scanProfileSimple preserves relative paths":
    let profileFile = getDotmanDir() / MainProfile / "config" / "myapp.conf"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFileWrapper(MainProfile, "myapp.conf")

    let report = scanProfileSimpleWrapper(MainProfile)
    var found = false
    for i in 0 ..< report.count:
      if report.relPathAt(i) == "config/myapp.conf":
        found = true
        break
    check:
      found
