type
  OperationType* = enum
    OpCreateSymlink
    OpRemoveSymlink
    OpMoveFile
    OpMoveDir
    OpCreateDir
    OpRemoveFile
    OpRemoveDir

  Operation* = object
    opType*: OperationType
    source*: string
    dest*: string

  ExecutionPlan* = object
    count*: int
    capacity*: int
    opTypes*: seq[OperationType]
    sources*: seq[string]
    dests*: seq[string]

proc initExecutionPlan*(capacity: int = 1024): ExecutionPlan =
  ExecutionPlan(
    count: 0,
    capacity: capacity,
    opTypes: newSeq[OperationType](capacity),
    sources: newSeq[string](capacity),
    dests: newSeq[string](capacity),
  )

proc addOperation*(
    plan: var ExecutionPlan, opType: OperationType, source, dest: string
) =
  if plan.count >= plan.capacity:
    let newCap = plan.capacity * 2
    plan.opTypes.setLen(newCap)
    plan.sources.setLen(newCap)
    plan.dests.setLen(newCap)
    plan.capacity = newCap

  plan.opTypes[plan.count] = opType
  plan.sources[plan.count] = source
  plan.dests[plan.count] = dest
  plan.count += 1

proc addCreateSymlink*(plan: var ExecutionPlan, source, dest: string) =
  plan.addOperation(OpCreateSymlink, source, dest)

proc addRemoveSymlink*(plan: var ExecutionPlan, path: string) =
  plan.addOperation(OpRemoveSymlink, path, path)

proc addMoveFile*(plan: var ExecutionPlan, source, dest: string) =
  plan.addOperation(OpMoveFile, source, dest)

proc addMoveDir*(plan: var ExecutionPlan, source, dest: string) =
  plan.addOperation(OpMoveDir, source, dest)

proc addCreateDir*(plan: var ExecutionPlan, path: string) =
  plan.addOperation(OpCreateDir, "", path)

proc addRemoveFile*(plan: var ExecutionPlan, path: string) =
  plan.addOperation(OpRemoveFile, "", path)

proc addRemoveDir*(plan: var ExecutionPlan, path: string) =
  plan.addOperation(OpRemoveDir, "", path)

proc getOperation*(plan: ExecutionPlan, index: int): Operation =
  if index < 0 or index >= plan.count:
    raise newException(IndexDefect, "Operation index out of bounds")

  Operation(
    opType: plan.opTypes[index], source: plan.sources[index], dest: plan.dests[index]
  )

proc clear*(plan: var ExecutionPlan) =
  plan.count = 0

proc getOperationCountByType*(
    plan: ExecutionPlan, opType: OperationType
): int {.noSideEffect.} =
  result = 0
  for i in 0 ..< plan.count:
    if plan.opTypes[i] == opType:
      result += 1

proc getSummary*(plan: ExecutionPlan): string {.noSideEffect.} =
  let creates = plan.getOperationCountByType(OpCreateSymlink)
  let removes = plan.getOperationCountByType(OpRemoveSymlink)
  let movesFile = plan.getOperationCountByType(OpMoveFile)
  let movesDir = plan.getOperationCountByType(OpMoveDir)
  let createsDir = plan.getOperationCountByType(OpCreateDir)
  let removesFile = plan.getOperationCountByType(OpRemoveFile)
  let removesDir = plan.getOperationCountByType(OpRemoveDir)

  result = "Operations: " & $plan.count & "\n"
  if creates > 0:
    result &= "  Create symlinks: " & $creates & "\n"
  if removes > 0:
    result &= "  Remove symlinks: " & $removes & "\n"
  if movesFile > 0:
    result &= "  Move files: " & $movesFile & "\n"
  if movesDir > 0:
    result &= "  Move directories: " & $movesDir & "\n"
  if createsDir > 0:
    result &= "  Create directories: " & $createsDir & "\n"
  if removesFile > 0:
    result &= "  Remove files: " & $removesFile & "\n"
  if removesDir > 0:
    result &= "  Remove directories: " & $removesDir & "\n"
