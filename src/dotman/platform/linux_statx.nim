type FastFileKind* = enum
  ffMissing
  ffOther
  ffFile
  ffDir
  ffSymlink

type FastFileInfo* = object
  kind*: FastFileKind
  size*: int

type LinkTargetMatch* = enum
  ltmUnreadable
  ltmMissing
  ltmExact
  ltmWithinRoot
  ltmOther

proc expectedJoinedLen(base, rel: string): int {.inline.} =
  result = base.len + rel.len
  if rel.len > 0 and base.len > 0 and base[^1] != '/':
    inc result

proc bytesEqualString(
    buf: string, count: int, offset: int, value: string
): bool {.inline.} =
  if offset + value.len > count:
    return false
  for i in 0 ..< value.len:
    if buf[offset + i] != value[i]:
      return false
  true

proc targetEqualsJoined(buf: string, count: int, base, rel: string): bool =
  if count != expectedJoinedLen(base, rel):
    return false
  if not bytesEqualString(buf, count, 0, base):
    return false
  var offset = base.len
  if rel.len > 0 and base.len > 0 and base[^1] != '/':
    if offset >= count or buf[offset] != '/':
      return false
    inc offset
  bytesEqualString(buf, count, offset, rel)

proc targetWithinRoot(buf: string, count: int, root: string): bool =
  if root.len == 0 or count < root.len:
    return false
  if not bytesEqualString(buf, count, 0, root):
    return false
  count == root.len or root[^1] == '/' or buf[root.len] == '/'

when defined(linux):
  import std/posix

  const
    AT_FDCWD = -100
    AT_SYMLINK_NOFOLLOW = 0x100
    STATX_TYPE = 0x00000001'u32
    STATX_MODE = 0x00000002'u32
    STATX_SIZE = 0x00000200'u32
    S_IFMT = 0o170000
    S_IFREG = 0o100000
    S_IFDIR = 0o040000
    S_IFLNK = 0o120000
    ENOENT = 2

  type
    StatxTimestamp {.importc: "struct statx_timestamp", header: "<linux/stat.h>".} = object
      tv_sec*: int64
      tv_nsec*: uint32
      reserved*: int32

    Statx {.importc: "struct statx", header: "<linux/stat.h>".} = object
      stx_mask*: uint32
      stx_blksize*: uint32
      stx_attributes*: uint64
      stx_nlink*: uint32
      stx_uid*: uint32
      stx_gid*: uint32
      stx_mode*: uint16
      spare0*: array[1, uint16]
      stx_ino*: uint64
      stx_size*: uint64
      stx_blocks*: uint64
      stx_attributes_mask*: uint64
      stx_atime*: StatxTimestamp
      stx_btime*: StatxTimestamp
      stx_ctime*: StatxTimestamp
      stx_mtime*: StatxTimestamp
      stx_rdev_major*: uint32
      stx_rdev_minor*: uint32
      stx_dev_major*: uint32
      stx_dev_minor*: uint32
      stx_mnt_id*: uint64
      stx_dio_mem_align*: uint32
      stx_dio_offset_align*: uint32
      stx_subvol*: uint64
      stx_atomic_write_unit_min*: uint32
      stx_atomic_write_unit_max*: uint32
      stx_atomic_write_segments_max*: uint32
      stx_dio_read_offset_align*: uint32
      stx_atomic_write_unit_max_opt*: uint32
      spare2*: array[1, uint32]
      spare3*: array[8, uint64]

  proc c_statx(
    dirfd: cint, pathname: cstring, flags: cint, mask: cuint, statxbuf: ptr Statx
  ): cint {.importc: "statx", header: "<sys/stat.h>".}

  proc c_readlink(
    pathname: cstring, buf: pointer, bufsiz: csize_t
  ): clong {.importc: "readlink", header: "<unistd.h>".}

  proc errnoLocation(): ptr cint {.importc: "__errno_location", header: "<errno.h>".}

  proc fastFileInfo*(path: string): FastFileInfo =
    var st: Statx
    if c_statx(
      AT_FDCWD.cint,
      path.cstring,
      AT_SYMLINK_NOFOLLOW.cint,
      cuint(STATX_TYPE or STATX_MODE or STATX_SIZE),
      addr st,
    ) != 0:
      return FastFileInfo(kind: ffMissing, size: 0)

    let mode = int(st.stx_mode) and S_IFMT
    result.size =
      if st.stx_size > uint64(high(int)):
        high(int)
      else:
        int(st.stx_size)
    result.kind =
      case mode
      of S_IFREG: ffFile
      of S_IFDIR: ffDir
      of S_IFLNK: ffSymlink
      else: ffOther

  proc readLinkInto*(path: string, expectedSize: int, scratch: var string): bool =
    let capacity = max(expectedSize + 1, 256)
    scratch.setLen(capacity)
    let readLen = c_readlink(path.cstring, addr scratch[0], csize_t(scratch.len))
    if readLen < 0:
      scratch.setLen(0)
      return false

    scratch.setLen(int(readLen))
    true

  proc classifyLinkTarget*(
      path, expectedBase, expectedRel, profileRoot: string,
      expectedSize: int,
      scratch: var string,
  ): LinkTargetMatch =
    let capacity = max(max(expectedSize + 1, profileRoot.len + 1), 256)
    if scratch.len < capacity:
      scratch.setLen(capacity)
    let readLen = c_readlink(path.cstring, addr scratch[0], csize_t(scratch.len))
    if readLen < 0:
      if errnoLocation()[] == ENOENT:
        return ltmMissing
      return ltmUnreadable

    let count = int(readLen)
    if targetEqualsJoined(scratch, count, expectedBase, expectedRel):
      return ltmExact
    if targetWithinRoot(scratch, count, profileRoot):
      return ltmWithinRoot
    ltmOther

else:
  import std/os

  proc fastFileInfo*(path: string): FastFileInfo =
    try:
      case getFileInfo(path, followSymlink = false).kind
      of pcFile:
        FastFileInfo(kind: ffFile, size: 0)
      of pcDir:
        FastFileInfo(kind: ffDir, size: 0)
      of pcLinkToFile, pcLinkToDir:
        FastFileInfo(kind: ffSymlink, size: 0)
      else:
        FastFileInfo(kind: ffOther, size: 0)
    except OSError:
      FastFileInfo(kind: ffMissing, size: 0)

  proc readLinkInto*(path: string, expectedSize: int, scratch: var string): bool =
    try:
      scratch = expandSymlink(path)
      true
    except OSError:
      scratch.setLen(0)
      false

  proc classifyLinkTarget*(
      path, expectedBase, expectedRel, profileRoot: string,
      expectedSize: int,
      scratch: var string,
  ): LinkTargetMatch =
    try:
      let target = expandSymlink(path)
      let expected =
        if expectedRel.len == 0:
          expectedBase
        else:
          expectedBase / expectedRel
      if target == expected:
        return ltmExact
      if target == profileRoot or target.startsWith(profileRoot / ""):
        return ltmWithinRoot
      ltmOther
    except OSError:
      if not fileExists(path) and not symlinkExists(path): ltmMissing else: ltmUnreadable
