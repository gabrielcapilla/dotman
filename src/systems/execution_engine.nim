import std/os
import ../core/[execution, result]
import symlink_ops

type ExecutionResult* = object
  success*: bool
  executed*: int
  failed*: int
  errors*: seq[string]

proc initExecutionResult*(): ExecutionResult =
  ExecutionResult(success: true, executed: 0, failed: 0, errors: newSeq[string](0))

proc executeCreateSymlink*(op: Operation): string =
  try:
    symlink_ops.createLink(op.source, op.dest)
    return ""
  except ProfileError as e:
    return e.msg
  except Exception as e:
    return "Failed to create symlink: " & e.msg

proc executeRemoveSymlink*(op: Operation): string =
  try:
    if symlinkExists(op.dest):
      removeFile(op.dest)
    return ""
  except Exception as e:
    return "Failed to remove symlink: " & e.msg

proc executeMoveFile*(op: Operation): string =
  try:
    if fileExists(op.source):
      createDir(op.dest.parentDir)
      moveFile(op.source, op.dest)
    return ""
  except Exception as e:
    return "Failed to move file: " & e.msg

proc executeMoveDir*(op: Operation): string =
  try:
    if dirExists(op.source):
      createDir(op.dest.parentDir)
      moveDir(op.source, op.dest)
    return ""
  except Exception as e:
    return "Failed to move directory: " & e.msg

proc executeCreateDir*(op: Operation): string =
  try:
    if not dirExists(op.dest):
      createDir(op.dest)
    return ""
  except Exception as e:
    return "Failed to create directory: " & e.msg

proc executeRemoveFile*(op: Operation): string =
  try:
    if fileExists(op.dest):
      removeFile(op.dest)
    return ""
  except Exception as e:
    return "Failed to remove file: " & e.msg

proc executeRemoveDir*(op: Operation): string =
  try:
    if dirExists(op.dest):
      removeDir(op.dest)
    return ""
  except Exception as e:
    return "Failed to remove directory: " & e.msg

proc previewPlan*(plan: ExecutionPlan) =
  echo ""
  echo "Execution Plan Preview"
  echo plan.getSummary()
  echo "Operations to execute:"
  for i in 0 ..< plan.count:
    let op = plan.getOperation(i)
    case op.opType
    of OpCreateSymlink:
      echo "  " & $(i + 1) & "/" & $plan.count & " Create symlink: " & op.dest & " → " &
        op.source
    of OpRemoveSymlink:
      echo "  " & $(i + 1) & "/" & $plan.count & " Remove symlink: " & op.dest
    of OpMoveFile:
      echo "  " & $(i + 1) & "/" & $plan.count & " Move file: " & op.source & " → " &
        op.dest
    of OpMoveDir:
      echo "  " & $(i + 1) & "/" & $plan.count & " Move dir: " & op.source & " → " &
        op.dest
    of OpCreateDir:
      echo "  " & $(i + 1) & "/" & $plan.count & " Create dir: " & op.dest
    of OpRemoveFile:
      echo "  " & $(i + 1) & "/" & $plan.count & " Remove file: " & op.dest
    of OpRemoveDir:
      echo "  " & $(i + 1) & "/" & $plan.count & " Remove dir: " & op.dest
  echo ""

proc executePlan*(plan: ExecutionPlan, verbose: bool = true): ExecutionResult =
  result = initExecutionResult()

  if plan.count == 0:
    if verbose:
      echo "No operations to execute."
    return result

  if verbose:
    echo "Executing " & $plan.count & " operations..."

  for i in 0 ..< plan.count:
    let op = plan.getOperation(i)
    var errorMsg = ""

    case op.opType
    of OpCreateSymlink:
      errorMsg = executeCreateSymlink(op)
    of OpRemoveSymlink:
      errorMsg = executeRemoveSymlink(op)
    of OpMoveFile:
      errorMsg = executeMoveFile(op)
    of OpMoveDir:
      errorMsg = executeMoveDir(op)
    of OpCreateDir:
      errorMsg = executeCreateDir(op)
    of OpRemoveFile:
      errorMsg = executeRemoveFile(op)
    of OpRemoveDir:
      errorMsg = executeRemoveDir(op)

    if errorMsg.len > 0:
      result.failed += 1
      result.success = false
      result.errors.add(errorMsg)
      if verbose:
        echo "  Error: " & errorMsg
    else:
      result.executed += 1
      if verbose and (plan.count <= 20 or i mod 10 == 9):
        let progress = $((i + 1) * 100 div plan.count) & "%"
        case op.opType
        of OpCreateSymlink:
          echo "  [" & progress & "] Linked " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest
        of OpRemoveSymlink:
          echo "  [" & progress & "] Removed " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest
        of OpMoveFile:
          echo "  [" & progress & "] Moved " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest
        of OpMoveDir:
          echo "  [" & progress & "] Moved " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest
        of OpCreateDir:
          echo "  [" & progress & "] Created " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest
        of OpRemoveFile:
          echo "  [" & progress & "] Removed " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest
        of OpRemoveDir:
          echo "  [" & progress & "] Removed " & $(i + 1) & "/" & $plan.count & ": " &
            op.dest

  if verbose:
    echo ""
    if result.failed == 0:
      echo "Done! " & $result.executed & " operations executed successfully."
    else:
      echo "Completed with errors: " & $result.executed & " succeeded, " & $result.failed &
        " failed."
      for error in result.errors:
        echo "  - " & error
