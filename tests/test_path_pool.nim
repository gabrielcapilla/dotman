import std/[unittest, tables]
import ../src/core/path_pool

suite "Path Pool Tests":
  test "internPath deduplicates and keeps stable IDs":
    var pool = initPathPool(4)
    let a1 = pool.internPath("/a")
    let a2 = pool.internPath("/a")
    let b = pool.internPath("/b")
    check a1 == a2
    check a1 != b
    check pool.getPath(a1) == "/a"
    check pool.getPath(b) == "/b"

  test "insertion order IDs remain stable after growth":
    var pool = initPathPool(2)
    var ids: seq[int32] = @[]
    for i in 0 ..< 100:
      ids.add(pool.internPath("/p/" & $i))
    for i in 0 ..< 100:
      check ids[i] == int32(i)
      check pool.getPath(ids[i]) == "/p/" & $i

  test "property-style uniqueness count matches table-based unique count":
    var pool = initPathPool(8)
    var unique = initTable[string, bool]()

    for i in 0 ..< 500:
      let p = "/root/" & $((i * 37) mod 73) & "/file" & $((i * 17) mod 91)
      discard pool.internPath(p)
      unique[p] = true

    check pool.count == unique.len
