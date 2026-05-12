version = "0.4.0"
author = "Gabriel Capilla"
description = "Modern Dotfiles Manager"
license = "MIT"
srcDir = "src"
bin = @["dotman"]

requires "nim >= 2.2.0"

const
  BaselineFlags =
    "--passC:-march=x86-64 --passC:-mtune=generic " &
    "--passC:-mno-avx --passC:-mno-avx2 --passC:-mno-bmi --passC:-mno-bmi2 " &
    "--passC:-mno-fma --passC:-mno-lzcnt --passC:-mno-popcnt " &
    "--passC:-Wa,-mx86-used-note=no " &
    "--passL:-march=x86-64 --passL:-mtune=generic " &
    "--passL:-mno-avx --passL:-mno-avx2 --passL:-mno-bmi --passL:-mno-bmi2 " &
    "--passL:-mno-fma --passL:-mno-lzcnt --passL:-mno-popcnt " &
    "--passL:-Wa,-mx86-used-note=no"

proc requireTool(tool: string) =
  if gorgeEx("command -v " & tool).exitCode != 0:
    quit("ERROR: required tool not found: " & tool, 1)

proc stripGnuProperty(binaryPath: string) =
  requireTool("objcopy")
  exec "objcopy --remove-section .note.gnu.property " & binaryPath

proc assertBaselineX8664(binaryPath: string) =
  requireTool("readelf")
  requireTool("objdump")

  let notes = gorge("readelf -n " & binaryPath)
  if notes.contains("x86-64-v2") or notes.contains("x86-64-v3") or
      notes.contains("x86-64-v4"):
    quit("ERROR: " & binaryPath & " requires a non-baseline x86-64 ISA.", 1)

  let disassembly = gorge("objdump -d " & binaryPath)
  for token in ["%ymm", "%zmm", "\tv", "\tmulx", "\tpdep", "\tpext"]:
    if disassembly.contains(token):
      quit("ERROR: " & binaryPath & " contains non-baseline x86 instructions.", 1)

task release, "Build the default release binary":
  exec "nimble build -d:release"

task native, "Build an optimized binary for the current machine":
  mkDir "bin"
  exec "nim c -d:release --passC:-march=native -o:bin/dotman-native src/dotman.nim"

task baseline_x86_64, "Build portable x86-64 binary for older CPUs":
  mkDir "bin"
  exec "nim c -d:release " & BaselineFlags &
    " -o:bin/dotman-linux-x86_64 src/dotman.nim"
  stripGnuProperty("bin/dotman-linux-x86_64")
  assertBaselineX8664("bin/dotman-linux-x86_64")
  echo "OK: bin/dotman-linux-x86_64 is baseline x86-64 compatible."

task baseline_x86_64_v3, "Build optimized x86-64-v3 release binary":
  mkDir "bin"
  exec "nim c -d:release --passC:-march=x86-64-v3 --passL:-march=x86-64-v3 " &
    "-o:bin/dotman-linux-x86_64-v3 src/dotman.nim"

task releaseAssets, "Build both GitHub release assets":
  exec "nimble baseline_x86_64"
  exec "nimble baseline_x86_64_v3"
