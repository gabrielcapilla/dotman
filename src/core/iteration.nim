import std/macros

template forEachActive*(count: int, active: openArray[bool], body: untyped) =
  for i in 0 ..< count:
    if active[i]:
      body

template forEachIndex*(count: int, body: untyped) =
  for i in 0 ..< count:
    body

macro forBatch*(batchCount: int, body: untyped): untyped =
  result = newStmtList()
  let forLoop = newNimNode(nnkForStmt)
  let i = ident("i")
  forLoop.add(i)

  let rangeExpr = newNimNode(nnkInfix)
  rangeExpr.add(ident("..<"))
  rangeExpr.add(newLit(0))
  rangeExpr.add(batchCount)

  forLoop.add(rangeExpr)
  forLoop.add(body)

  result.add(forLoop)
