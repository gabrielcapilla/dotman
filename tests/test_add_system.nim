import std/[os, unittest, tempfiles]
import ../src/systems/add_system
import ../src/systems/profile_ops
import ../src/systems/set_system
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

suite "Add System Tests":
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

  test "addFile creates symlink for file in home":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    addFile(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")

  test "addFile creates symlink for file in config":
    let profileFile = getDotmanDir() / MainProfile / "config" / "myapp.conf"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "config content")
    addFile(MainProfile, "myapp.conf")
    check:
      symlinkExists(testHome / ".config" / "myapp.conf")

  test "addFile creates symlinks for directory contents":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    addFile(MainProfile, "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp")
    check:
      dirExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      dirExists(testHome / ".config" / "myapp" / "config2.txt")

  test "addFile handles nested directory structure":
    let nestedDir =
      getDotmanDir() / MainProfile / "config" / "myapp" / "nested" / "deep"
    createDir(nestedDir)
    writeFile(nestedDir / "file.txt", "deep content")
    addFile(MainProfile, "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp")
    check:
      dirExists(testHome / ".config" / "myapp" / "nested" / "deep" / "file.txt")

  test "addFile creates symlinks for files in bin":
    let binDir = getDotmanDir() / MainProfile / "bin"
    createDir(binDir)
    writeFile(binDir / "mytool", "#!/bin/bash\necho test")
    addFile(MainProfile, "mytool")
    check:
      symlinkExists(testHome / ".local" / "bin" / "mytool")

  test "addFile creates symlinks for files in share":
    let shareDir = getDotmanDir() / MainProfile / "share"
    createDir(shareDir)
    writeFile(shareDir / "data.txt", "data")
    addFile(MainProfile, "data.txt")
    check:
      symlinkExists(testHome / ".local" / "share" / "data.txt")

  test "addFile fails if profile not found":
    expect ProfileError:
      addFile("nonexistent", "testfile.txt")

  test "addFile fails if file not found in profile":
    expect ProfileError:
      addFile(MainProfile, "nonexistent.txt")

  test "addFile fails if destination file exists":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "profile content")
    writeFile(testHome / "testfile.txt", "local content")
    expect ProfileError:
      addFile(MainProfile, "testfile.txt")

  test "addFile creates symlinks in existing directory":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    createDir(testHome / ".config" / "myapp")
    addFile(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      dirExists(testHome / ".config" / "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config2.txt")

  test "addFile handles empty directory":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    addFile(MainProfile, "myapp")

  test "addFile handles hidden files":
    let profileFile = getDotmanDir() / MainProfile / "home" / ".hiddenfile"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "hidden content")
    addFile(MainProfile, ".hiddenfile")
    check:
      symlinkExists(testHome / ".hiddenfile")

  test "findFileInProfile finds file by name":
    let profileFile = getDotmanDir() / MainProfile / "home" / "test.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    let result = findFileInProfile(MainProfile, "test.txt")
    check:
      result == "home/test.txt"

  test "findFileInProfile finds directory by name":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    let result = findFileInProfile(MainProfile, "myapp")
    check:
      result == "config/myapp"

  test "findFileInProfile fails if not found":
    expect ProfileError:
      discard findFileInProfile(MainProfile, "nonexistent")

  test "addFile can add same file after remove":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")
    removeFile(testHome / "testfile.txt")
    addFile(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")
