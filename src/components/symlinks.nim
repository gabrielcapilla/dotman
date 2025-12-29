type
  SymlinkRef* = object
    source*: string
    dest*: string

  SymlinkBatch* = object
    count*: int
    links*: seq[SymlinkRef]
