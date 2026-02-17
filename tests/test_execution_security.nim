import std/[os, unittest, tempfiles]
import ../src/systems/execution_engine
import ../src/core/[execution, path]

suite "Execution Security Tests":
  setup:
    let tempDir = createTempDir("dotman_exec_security_", "")
    let testHome = tempDir / "home"
    let originalHome = getEnv("HOME")
    createDir(testHome)
    putEnv("HOME", testHome)
    createDir(getDotmanDir() / "main" / "home")

  teardown:
    putEnv("HOME", originalHome)
    removeDir(tempDir)

  test "rejects symlink creation outside home destination":
    let source = getDotmanDir() / "main" / "home" / "test.txt"
    writeFile(source, "x")
    var plan = initExecutionPlan(1)
    plan.addCreateSymlink(source, "/tmp/forbidden-link")
    let result = executePlan(plan, verbose = false)
    check result.success == false
    check result.failed == 1

  test "rejects move that does not cross roots":
    let src = getHomeDir() / "a.txt"
    let dst = getHomeDir() / "b.txt"
    writeFile(src, "x")
    var plan = initExecutionPlan(1)
    plan.addMoveFile(src, dst)
    let result = executePlan(plan, verbose = false)
    check result.success == false
    check result.failed == 1

  test "allows managed home-to-dotman move":
    let src = getHomeDir() / "a.txt"
    let dst = getDotmanDir() / "main" / "home" / "a.txt"
    writeFile(src, "x")
    var plan = initExecutionPlan(1)
    plan.addMoveFile(src, dst)
    let result = executePlan(plan, verbose = false)
    check result.success == true
    check fileExists(dst)
