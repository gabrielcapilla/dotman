type
  LinkStatus* = enum
    Linked
    NotLinked
    Conflict
    OtherProfile

  FileStatus* = object
    relPath*: string
    homePath*: string
    status*: LinkStatus

  StatusReport* = object
    linked*: int
    notLinked*: int
    conflicts*: int
    files*: seq[FileStatus]
