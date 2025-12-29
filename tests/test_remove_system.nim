import std/[os, unittest, tempfiles]
import ../src/systems/remove_system
import ../src/systems/add_system
import ../src/systems/profile_ops
import ../src/core/path
import ../src/core/types
import ../src/components/profiles

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
    addFile(MainProfile, "testfile.txt")
    check:
      symlinkExists(testHome / "testfile.txt")

    removeFile(MainProfile, "testfile.txt")
    check:
      not symlinkExists(testHome / "testfile.txt")
    check:
      fileExists(profileFile)

  test "removeFile removes directory symlink":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    addFile(MainProfile, "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp")

    removeFile(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      dirExists(configDir / "config1.txt")
    check:
      dirExists(configDir / "config2.txt")

  test "removeFile handles nested directories":
    let nestedDir = getDotmanDir() / MainProfile / "config" / "myapp" / "nested"
    createDir(nestedDir)
    writeFile(nestedDir / "deep.txt", "deep content")
    addFile(MainProfile, "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp")

    removeFile(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      dirExists(nestedDir / "deep.txt")

  test "removeFile handles files in bin":
    let binDir = getDotmanDir() / MainProfile / "bin"
    createDir(binDir)
    writeFile(binDir / "mytool", "tool content")
    addFile(MainProfile, "mytool")
    check:
      symlinkExists(testHome / ".local" / "bin" / "mytool")

    removeFile(MainProfile, "mytool")
    check:
      not symlinkExists(testHome / ".local" / "bin" / "mytool")

  test "removeFile handles files in share":
    let shareDir = getDotmanDir() / MainProfile / "share"
    createDir(shareDir)
    writeFile(shareDir / "data.txt", "data")
    addFile(MainProfile, "data.txt")
    check:
      symlinkExists(testHome / ".local" / "share" / "data.txt")

    removeFile(MainProfile, "data.txt")
    check:
      not symlinkExists(testHome / ".local" / "share" / "data.txt")

  test "removeFile handles hidden files":
    let profileFile = getDotmanDir() / MainProfile / "home" / ".hiddenfile"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "hidden content")
    addFile(MainProfile, ".hiddenfile")
    check:
      symlinkExists(testHome / ".hiddenfile")

    removeFile(MainProfile, ".hiddenfile")
    check:
      not symlinkExists(testHome / ".hiddenfile")

  test "removeFile fails if profile not found":
    expect ProfileError:
      removeFile("nonexistent", "testfile.txt")

  test "removeFile fails if file not found in profile":
    expect ProfileError:
      removeFile(MainProfile, "nonexistent.txt")

  test "removeFile handles directory with special characters":
    let configDir = getDotmanDir() / MainProfile / "config" / "my-app_123"
    createDir(configDir)
    writeFile(configDir / "config.txt", "content")
    addFile(MainProfile, "my-app_123")
    check:
      symlinkExists(testHome / ".config" / "my-app_123")

    removeFile(MainProfile, "my-app_123")
    check:
      not symlinkExists(testHome / ".config" / "my-app_123")
    check:
      dirExists(configDir / "config.txt")

  test "removeFile does not affect other symlinks":
    let file1 = getDotmanDir() / MainProfile / "home" / "file1.txt"
    let file2 = getDotmanDir() / MainProfile / "home" / "file2.txt"
    createDir(parentDir(file1))
    createDir(parentDir(file2))
    writeFile(file1, "content1")
    writeFile(file2, "content2")
    addFile(MainProfile, "file1.txt")
    addFile(MainProfile, "file2.txt")

    removeFile(MainProfile, "file1.txt")
    check:
      not symlinkExists(testHome / "file1.txt")
    check:
      symlinkExists(testHome / "file2.txt")

  test "removeFile can be called multiple times":
    let profileFile = getDotmanDir() / MainProfile / "home" / "testfile.txt"
    createDir(parentDir(profileFile))
    writeFile(profileFile, "content")
    addFile(MainProfile, "testfile.txt")

    removeFile(MainProfile, "testfile.txt")
    check:
      not symlinkExists(testHome / "testfile.txt")
    removeFile(MainProfile, "testfile.txt")

  test "removeFile removes individual symlinks when directory exists":
    let configDir = getDotmanDir() / MainProfile / "config" / "myapp"
    createDir(configDir)
    writeFile(configDir / "config1.txt", "content1")
    writeFile(configDir / "config2.txt", "content2")
    createDir(testHome / ".config" / "myapp")
    addFile(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      symlinkExists(testHome / ".config" / "myapp" / "config2.txt")

    removeFile(MainProfile, "myapp")
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "config1.txt")
    check:
      not symlinkExists(testHome / ".config" / "myapp" / "config2.txt")
    check:
      dirExists(testHome / ".config" / "myapp")
