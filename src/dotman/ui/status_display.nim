import std/[tables, options]
import std/os
import ../domain/types
import ../domain/status, table_display
import ../operations/status_stats

type
  SubCategoryStats* = object
    name*: string
    linked*: int
    notLinked*: int
    conflicts*: int
    other*: int

  CategorySubStats* = object
    category*: Category
    subCategories*: seq[SubCategoryStats]

proc getCategoryName(cat: Category): string =
  case cat
  of Config:
    return "config"
  of Share:
    return "share"
  of Home:
    return "home"
  of Local:
    return "local"
  of Bin:
    return "bin"

proc collectSubCategories(
    stats: Table[int32, SubCategoryStats]
): seq[SubCategoryStats] =
  result = newSeqOfCap[SubCategoryStats](stats.len)
  for _, item in stats.pairs:
    result.add(item)

proc groupBySubCategory*(data: var StatusData): seq[CategorySubStats] =
  result = newSeqOfCap[CategorySubStats](Category.high.ord + 1)

  var subCatMaps: array[Category, Table[int32, SubCategoryStats]]
  for cat in Category:
    subCatMaps[cat] = initTable[int32, SubCategoryStats]()

  for i in 0 ..< data.count:
    let status = data.statuses[i]
    let cat = data.categories[i]
    let subCatId = data.subCategoryIds[i]

    var catStats = addr subCatMaps[cat]

    if not catStats[].hasKey(subCatId):
      catStats[][subCatId] = SubCategoryStats(
        name: data.subCategoryAt(i), linked: 0, notLinked: 0, conflicts: 0, other: 0
      )

    case status
    of Linked:
      inc(catStats[][subCatId].linked)
    of NotLinked:
      inc(catStats[][subCatId].notLinked)
    of Conflict:
      inc(catStats[][subCatId].conflicts)
    of OtherProfile:
      inc(catStats[][subCatId].other)

  for cat in Category:
    result.add(
      CategorySubStats(
        category: cat, subCategories: collectSubCategories(subCatMaps[cat])
      )
    )

proc showCategorySummary*(
    data: var StatusData,
    profile: string,
    useAscii: bool = false,
    category: Option[Category] = none(Category),
    verbose: bool = false,
) =
  echo ""
  echo "Status for profile '" & profile & "':"
  echo ""

  let style = if useAscii: AsciiStyle else: UnicodeStyle

  if verbose and category.isNone():
    let categorySubStats = groupBySubCategory(data)
    let headers = [
      newCell("Subdirectory", AlignLeft),
      newCell("Linked", AlignRight),
      newCell("NotLinked", AlignRight),
      newCell("Conflict", AlignRight),
      newCell("Other", AlignRight),
    ]

    var rows = newSeqOfCap[array[5, Cell]](data.count)
    for catStats in categorySubStats:
      let catName = getCategoryName(catStats.category)

      if catStats.subCategories.len > 0:
        rows.setLen(0)
        for subStats in catStats.subCategories:
          if subStats.linked + subStats.notLinked + subStats.conflicts + subStats.other >
              0:
            let displayName =
              if subStats.name.len == 0:
                catName & "/(root)"
              else:
                catName & "/" & subStats.name
            var row: array[5, Cell]
            row[0] = newCell(displayName, AlignLeft)
            row[1] = newCell($subStats.linked, AlignRight)
            row[2] = newCell($subStats.notLinked, AlignRight)
            row[3] = newCell($subStats.conflicts, AlignRight)
            row[4] = newCell($subStats.other, AlignRight)
            rows.add(row)

        echo renderTable(headers, rows, style)
        echo ""
  else:
    let categoryStats = groupByCategory(data)

    let headers = [
      newCell("Directory", AlignLeft),
      newCell("Linked", AlignRight),
      newCell("NotLinked", AlignRight),
      newCell("Conflict", AlignRight),
      newCell("Other", AlignRight),
    ]

    var rows =
      if category.isSome():
        newSeqOfCap[array[5, Cell]](1)
      else:
        newSeqOfCap[array[5, Cell]](5)

    if category.isSome():
      let cat = category.get()
      let stats = categoryStats[cat]
      var row: array[5, Cell]
      row[0] = newCell(getCategoryName(cat) & "/", AlignLeft)
      row[1] = newCell($stats.linked, AlignRight)
      row[2] = newCell($stats.notLinked, AlignRight)
      row[3] = newCell($stats.conflicts, AlignRight)
      row[4] = newCell($stats.other, AlignRight)
      rows.add(row)
    else:
      for cat in Category:
        let stats = categoryStats[cat]
        if stats.linked + stats.notLinked + stats.conflicts + stats.other > 0:
          var row: array[5, Cell]
          row[0] = newCell(getCategoryName(cat) & "/", AlignLeft)
          row[1] = newCell($stats.linked, AlignRight)
          row[2] = newCell($stats.notLinked, AlignRight)
          row[3] = newCell($stats.conflicts, AlignRight)
          row[4] = newCell($stats.other, AlignRight)
          rows.add(row)

    if rows.len > 0:
      echo renderTable(headers, rows, style)

    echo ""

    if category.isSome():
      let cat = category.get()
      let stats = categoryStats[cat]
      echo "Total for " & getCategoryName(cat) & ": " & $stats.linked & " linked, " &
        $stats.notLinked & " not linked, " & $stats.conflicts & " conflicts, " &
        $stats.other & " other"
    else:
      echo "Total: " & $data.linked & " linked, " & $data.notLinked & " not linked, " &
        $data.conflicts & " conflicts"
    echo ""

proc showDetailedReport*(
    data: var StatusData,
    profile: string,
    filter: StatusFilter,
    category: Option[Category] = none(Category),
) =
  echo ""
  echo "Status for profile '" & profile & "':"
  echo ""

  var linkedCount = 0
  var notLinkedCount = 0
  var conflictCount = 0
  var otherCount = 0

  for i in 0 ..< data.count:
    let status = data.statuses[i]
    let cat = data.categories[i]

    if category.isSome() and category.get() != cat:
      continue

    let matchesFilter =
      case filter
      of FilterAll:
        true
      of FilterLinked:
        status == Linked
      of FilterNotLinked:
        status == NotLinked
      of FilterConflicts:
        status == Conflict
      of FilterOther:
        status == OtherProfile

    if not matchesFilter:
      continue

    let relPath = data.relPathAt(i)
    let homePath = data.homePathAt(i, getHomeDir())

    case status
    of Linked:
      echo "  " & homePath & " → dotman/" & profile & "/" & relPath
      linkedCount += 1
    of NotLinked:
      echo "  " & relPath & " (not linked)"
      notLinkedCount += 1
    of Conflict:
      echo "  " & homePath & " (exists, but not linked)"
      conflictCount += 1
    of OtherProfile:
      echo "  " & homePath & " (conflict: linked to other profile)"
      otherCount += 1

  echo ""
  echo "Total: " & $linkedCount & " linked, " & $notLinkedCount & " not linked, " &
    $conflictCount & " conflicts, " & $otherCount & " other"
  echo ""
