import std/[os, unittest, tempfiles]
import ../src/systems/pull_system
import ../src/systems/profile_ops
import ../src/systems/add_system
import ../src/systems/execution_engine
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles
import ../src/components/batches

# Helper wrappers to adapt tests to new API
proc addFileWrapper(profileName: string, fileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = add_system.planAddFile(profiles, pid, fileName)
  discard executePlan(plan, verbose = false)

proc pullProfileWrapper(profileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = pull_system.planPullProfile(profiles, pid)
  discard executePlan(plan, verbose = false)

proc validatePullWrapper(profileName: string): FileBatch =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  pull_system.validatePull(profiles, pid)

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
    addFileWrapper(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / "testfile.txt")

  test "pullProfile removes directory symlinks":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    addFileWrapper(MainProfile, "myapp")

    check:
      symlinkExists(testHome / ".config" / "myapp")
    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / ".config" / "myapp")

  test "pullProfile handles nested directories":
    let nestedDir = getDotmanDir() / MainProfile / "config" / "myapp" / "nested"
    createDir(nestedDir)
    writeFile(nestedDir / "file.txt", "deep content")
    addFileWrapper(MainProfile, "myapp")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "nested" / "file.txt")

  test "pullProfile does not remove non-managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "managed.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "managed content")
    addFileWrapper(MainProfile, "managed.txt")

    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    let externalLink = testHome / "external_link.txt"
    createSymlink(externalFile, externalLink)

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / "managed.txt")
    check:
      symlinkExists(externalLink)

  test "pullProfile handles mixed managed and non-managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "managed.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "managed content")
    addFileWrapper(MainProfile, "managed.txt")

    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    let externalLink = testHome / "external_link.txt"
    createSymlink(externalFile, externalLink)

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / "managed.txt")
    check:
      symlinkExists(externalLink)

  test "pullProfile handles empty profile":
    expect ProfileError:
      pullProfileWrapper(MainProfile)

  test "pullProfile handles profile with unlinked files":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")

    expect ProfileError:
      pullProfileWrapper(MainProfile)
    check:
      fileExists(profileFile)

  test "pullProfile removes all symlinks in profile":
    const fileCount = 10
    for i in 0 ..< fileCount:
      let profileFile = getDotmanDir() / MainProfile / "home" / "file" & $i & ".txt"
      createDir(parentDir(profileFile))
      writeFile(profileFile, "content" & $i)
      addFileWrapper(MainProfile, "file" & $i & ".txt")

    for i in 0 ..< fileCount:
      check:
        symlinkExists(testHome / "file" & $i & ".txt")

    pullProfileWrapper(MainProfile)

    for i in 0 ..< fileCount:
      check:
        not symlinkExists(testHome / "file" & $i & ".txt")

  test "pullProfile handles hidden files":
    let profileFile = getDotmanDir() / MainProfile / "home" / ".hiddenfile"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "hidden content")
    addFileWrapper(MainProfile, ".hiddenfile")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / ".hiddenfile")

  test "pullProfile works on custom profile":
    createProfile("custom")
    let profileFile = getDotmanDir() / "custom" / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFileWrapper("custom", "testfile.txt")

    pullProfileWrapper("custom")
    check:
      not symlinkExists(testHome / "testfile.txt")

  test "pullProfile fails on non-existent profile":
    expect ProfileError:
      pullProfileWrapper("nonexistent")

  test "pullProfile does not affect other profile symlinks":
    createProfile("profile2")
    let file1 = getDotmanDir() / MainProfile / "home" / "file1.txt"
    let file2 = getDotmanDir() / "profile2" / "home" / "file2.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "content1")
    writeFile(file2, "content2")
    addFileWrapper(MainProfile, "file1.txt")
    addFileWrapper("profile2", "file2.txt")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / "file1.txt")
    check:
      symlinkExists(testHome / "file2.txt")

  test "pullProfile handles files with special characters":
    let profileFile = getDotmanDir() / MainProfile / "home" / "test-file_123.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFileWrapper(MainProfile, "test-file_123.txt")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / "test-file_123.txt")

  test "pullProfile can be called multiple times":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFileWrapper(MainProfile, "testfile.txt")

    pullProfileWrapper(MainProfile)
    expect ProfileError:
      pullProfileWrapper(MainProfile)

  test "validatePull finds all managed symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    addFileWrapper(MainProfile, "testfile.txt")

    let result = validatePullWrapper(MainProfile)
    check:
      result.count == 1
    check:
      result.capacity >= 1

  test "validatePull returns empty when no symlinks":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")

    let result = validatePullWrapper(MainProfile)
    check:
      result.count == 0

  test "validatePull ignores non-managed symlinks":
    let externalFile = testHome / "external.txt"
    writeFile(externalFile, "external")
    let externalLink = testHome / "external_link.txt"
    createSymlink(externalFile, externalLink)

    let result = validatePullWrapper(MainProfile)
    check:
      result.count == 0

  test "pullProfile handles bin directory":
    let binDir = getDotmanDir() / MainProfile / "bin"
    createDir(binDir)
    writeFile(binDir / "mytool", "tool content")
    addFileWrapper(MainProfile, "mytool")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / ".local" / "bin" / "mytool")

  test "pullProfile handles share directory":
    let shareDir = getDotmanDir() / MainProfile / "share"
    createDir(shareDir)
    writeFile(shareDir / "data.txt", "data")
    addFileWrapper(MainProfile, "data.txt")

    pullProfileWrapper(MainProfile)
    check:
      not symlinkExists(testHome / ".local" / "share" / "data.txt")
