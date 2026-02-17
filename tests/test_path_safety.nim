import std/unittest
import ../src/core/[path_safety, result]
import ../src/systems/path_resolution

suite "Path Safety Tests":
  test "isWithinPath requires boundary match":
    check isWithinPath("/tmp/root/file", "/tmp/root")
    check not isWithinPath("/tmp/root_other/file", "/tmp/root")

  test "safeRelativePath rejects traversal and empty":
    check safeRelativePath("config/app/settings.toml")
    check not safeRelativePath("")
    check not safeRelativePath("../escape")
    check not safeRelativePath("config/../escape")
    check not safeRelativePath("/absolute/path")
    check not safeRelativePath("./dot")

  test "resolveDestPath rejects invalid relative path":
    expect ProfileError:
      discard resolveDestPath("", "../escape")
    expect ProfileError:
      discard resolveDestPath("", "config/../escape")
