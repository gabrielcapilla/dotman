type FileBatch* = object
  count*: int
  capacity*: int
  sources*: seq[string]
  destinations*: seq[string]

proc initFileBatch*(capacity: int = 1024): FileBatch =
  FileBatch(
    count: 0,
    capacity: capacity,
    sources: newSeq[string](capacity),
    destinations: newSeq[string](capacity),
  )

proc addToFileBatch*(batch: var FileBatch, source, dest: string) =
  if batch.count >= batch.capacity:
    let newCap = batch.capacity * 2
    batch.sources.setLen(newCap)
    batch.destinations.setLen(newCap)
    batch.capacity = newCap

  batch.sources[batch.count] = source
  batch.destinations[batch.count] = dest
  batch.count += 1

proc clearBatch*(batch: var FileBatch) =
  batch.count = 0

proc ensureCapacity*(batch: var FileBatch, minCapacity: int) =
  if batch.capacity < minCapacity:
    let newCap = max(minCapacity, batch.capacity * 2)
    batch.sources.setLen(newCap)
    batch.destinations.setLen(newCap)
    batch.capacity = newCap
