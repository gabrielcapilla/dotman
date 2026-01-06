import std/[os, unittest, tempfiles]
import ../src/systems/remove_system
import ../src/systems/add_system
import ../src/systems/execution_engine
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/core/result
import ../src/components/profiles

# Helper wrappers to adapt tests to new API
proc addFileWrapper(profileName: string, fileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = add_system.planAddFile(profiles, pid, fileName)
  discard executePlan(plan, verbose = false)

proc removeFileWrapper(profileName: string, fileName: string) =
  var profiles = loadProfiles()
  let pid = profiles.findProfileId(profileName)
  if pid == ProfileIdInvalid:
    raise ProfileError(msg: "Profile not found: " & profileName)
  let plan = remove_system.planRemoveFile(profiles, pid, fileName)
  discard executePlan(plan, verbose = false)

suite "Remove System Tests":
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

  test "removeFile removes single symlink":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    addFileWrapper(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")

    removeFileWrapper(MainProfile, "testfile.txt")
    check:
      not symlinkExists(testHome / "testfile.txt")
    check:
      fileExists(profileFile)

  test "removeFile removes directory symlink":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    addFileWrapper(MainProfile, "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp")

    removeFileWrapper(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      fileExists(configDir / "config1.txt")
    check:
      fileExists(configDir / "config2.txt")

  test "removeFile handles nested directories":
    let nestedDir = getDotmanDir() / MainProfile / "config" / "myapp" / "nested"
    createDir(nestedDir)
    writeFile(nestedDir / "deep.txt", "deep content")
    addFileWrapper(MainProfile, "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp")

    removeFileWrapper(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      fileExists(nestedDir / "deep.txt")

  test "removeFile handles files in bin":
    let binDir = getDotmanDir() / MainProfile / "bin"
    createDir(binDir)
    writeFile(binDir / "mytool", "tool content")
    addFileWrapper(MainProfile, "mytool")
    check:
      symlinkExists(testHome / ".local" / "bin" / "mytool")

    removeFileWrapper(MainProfile, "mytool")
    check:
      not symlinkExists(testHome / ".local" / "bin" / "mytool")

  test "removeFile handles files in share":
    let shareDir = getDotmanDir() / MainProfile / "share"
    createDir(shareDir)
    writeFile(shareDir / "data.txt", "data")
    addFileWrapper(MainProfile, "data.txt")
    check:
      symlinkExists(testHome / ".local" / "share" / "data.txt")

    removeFileWrapper(MainProfile, "data.txt")
    check:
      not symlinkExists(testHome / ".local" / "share" / "data.txt")

  test "removeFile handles hidden files":
    let profileFile = getDotmanDir() / MainProfile / "home" / ".hiddenfile"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "hidden content")
    addFileWrapper(MainProfile, ".hiddenfile")
    check:
      symlinkExists(testHome / ".hiddenfile")

    removeFileWrapper(MainProfile, ".hiddenfile")
    check:
      not symlinkExists(testHome / ".hiddenfile")

  test "removeFile fails if profile not found":
    expect ProfileError:
      removeFileWrapper("nonexistent", "testfile.txt")

  test "removeFile fails if file not found in profile":
    expect ProfileError:
      removeFileWrapper(MainProfile, "nonexistent.txt")

  test "removeFile handles directory with special characters":
    let configDir = getDotmanDir() / MainProfile / "config" / "my-app_123"
    createDir(configDir)
    writeFile(configDir / "config.txt", "content")
    addFileWrapper(MainProfile, "my-app_123")
    check:
      symlinkExists(testHome / ".config" / "my-app_123")

    removeFileWrapper(MainProfile, "my-app_123")
    check:
      not symlinkExists(testHome / ".config" / "my-app_123")
    check:
      fileExists(configDir / "config.txt")

  test "removeFile does not affect other symlinks":
    let file1 = getDotmanDir() / MainProfile / "home" / "file1.txt"
    let file2 = getDotmanDir() / MainProfile / "home" / "file2.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "content1")
    writeFile(file2, "content2")
    addFileWrapper(MainProfile, "file1.txt")
    addFileWrapper(MainProfile, "file2.txt")

    removeFileWrapper(MainProfile, "file1.txt")
    check:
      not symlinkExists(testHome / "file1.txt")
    check:
      symlinkExists(testHome / "file2.txt")

  test "removeFile can be called multiple times":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFileWrapper(MainProfile, "testfile.txt")

    removeFileWrapper(MainProfile, "testfile.txt")
    check:
      not symlinkExists(testHome / "testfile.txt")
    removeFileWrapper(MainProfile, "testfile.txt")

  test "removeFile removes individual symlinks when directory exists":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    createDir(testHome / ".config" / "myapp")
    addFileWrapper(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config2.txt")

    removeFileWrapper(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "config2.txt")
    check:
      dirExists(testHome / ".config" / "myapp")
