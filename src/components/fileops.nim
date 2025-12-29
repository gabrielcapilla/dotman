type
  FileMoveRef* = object
    source*: string
    dest*: string

  SetBatch* = object
    count*: int
    moves*: seq[FileMoveRef]
