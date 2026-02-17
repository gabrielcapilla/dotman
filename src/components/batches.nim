import ../core/path_pool

type FileBatch* = object
  count*: int
  capacity*: int
  sourceIds*: seq[int32]
  destinationIds*: seq[int32]
  pathPool*: PathPool

proc initFileBatch*(capacity: int = 1024): FileBatch =
  FileBatch(
    count: 0,
    capacity: capacity,
    sourceIds: newSeq[int32](capacity),
    destinationIds: newSeq[int32](capacity),
    pathPool: initPathPool(capacity * 2),
  )

proc addToFileBatch*(batch: var FileBatch, source, dest: string) =
  if batch.count >= batch.capacity:
    let newCap = batch.capacity * 2
    batch.sourceIds.setLen(newCap)
    batch.destinationIds.setLen(newCap)
    batch.capacity = newCap

  batch.sourceIds[batch.count] = batch.pathPool.internPath(source)
  batch.destinationIds[batch.count] = batch.pathPool.internPath(dest)
  batch.count += 1

proc sourceAt*(batch: FileBatch, index: int): string {.inline.} =
  batch.pathPool.getPath(batch.sourceIds[index])

proc destinationAt*(batch: FileBatch, index: int): string {.inline.} =
  batch.pathPool.getPath(batch.destinationIds[index])

proc removeIndex*(batch: var FileBatch, index: int) =
  if index < 0 or index >= batch.count:
    raise newException(IndexDefect, "Index out of bounds")

  let last = batch.count - 1

  if index != last:
    batch.sourceIds[index] = batch.sourceIds[last]
    batch.destinationIds[index] = batch.destinationIds[last]

  batch.count -= 1

proc clearBatch*(batch: var FileBatch) =
  batch.count = 0

proc ensureCapacity*(batch: var FileBatch, minCapacity: int) =
  if batch.capacity < minCapacity:
    let newCap = max(minCapacity, batch.capacity * 2)
    batch.sourceIds.setLen(newCap)
    batch.destinationIds.setLen(newCap)
    batch.capacity = newCap
