import std/tables

type PathPool* = object
  count*: int
  capacity*: int
  values*: seq[string]
  index*: Table[string, int32]

proc initPathPool*(capacity: int = 1024): PathPool =
  PathPool(
    count: 0,
    capacity: capacity,
    values: newSeq[string](capacity),
    index: initTable[string, int32](capacity),
  )

proc internPath*(pool: var PathPool, path: string): int32 =
  if path in pool.index:
    return pool.index[path]

  if pool.count >= pool.capacity:
    let newCap = pool.capacity * 2
    pool.values.setLen(newCap)
    pool.capacity = newCap

  let id = int32(pool.count)
  pool.values[pool.count] = path
  pool.index[path] = id
  pool.count += 1
  id

proc getPath*(pool: PathPool, id: int32): string {.inline.} =
  pool.values[id]
