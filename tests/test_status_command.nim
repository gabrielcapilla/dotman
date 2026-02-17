import std/[os, osproc, strutils, tempfiles, unittest]

suite "Status Command Integration":
  setup:
    let tempDir = createTempDir("dotman_status_cmd_", "")
    let testHome = tempDir / "home"
    let originalHome = getEnv("HOME")
    let dotmanBin = getCurrentDir() / "dotman"
    createDir(testHome)
    putEnv("HOME", testHome)

  teardown:
    putEnv("HOME", originalHome)
    removeDir(tempDir)

  test "status command runs after init":
    let initRun = execCmdEx(dotmanBin.quoteShell & " init")
    check initRun.exitCode == 0

    let statusRun = execCmdEx(dotmanBin.quoteShell & " status")
    check statusRun.exitCode == 0
    check statusRun.output.contains("Status for profile")
