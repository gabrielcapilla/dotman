import std/[tables, options, strutils]
import ../core/types
import ../components/[status, table_display]
import status_system

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

proc groupBySubCategory*(data: StatusData): seq[CategorySubStats] =
  result = newSeqOfCap[CategorySubStats](5)

  var subCatMap: Table[string, Table[string, SubCategoryStats]]
  subCatMap = initTable[string, Table[string, SubCategoryStats]]()

  for i in 0 ..< data.count:
    let relPath = data.relPathAt(i)
    let status = data.statuses[i]
    let cat = data.categories[i]
    let catName =
      case cat
      of Config: "config"
      of Share: "share"
      of Home: "home"
      of Local: "local"
      of Bin: "bin"

    if not subCatMap.hasKey(catName):
      subCatMap[catName] = initTable[string, SubCategoryStats]()

    let firstSep = relPath.find('/')
    let subCatName =
      if firstSep < 0:
        ""
      else:
        let nextSep = relPath.find('/', firstSep + 1)
        if nextSep < 0:
          relPath[firstSep + 1 ..^ 1]
        else:
          relPath[firstSep + 1 ..< nextSep]

    if not subCatMap[catName].hasKey(subCatName):
      subCatMap[catName][subCatName] = SubCategoryStats(
        name: subCatName, linked: 0, notLinked: 0, conflicts: 0, other: 0
      )

    case status
    of Linked:
      inc(subCatMap[catName][subCatName].linked)
    of NotLinked:
      inc(subCatMap[catName][subCatName].notLinked)
    of Conflict:
      inc(subCatMap[catName][subCatName].conflicts)
    of OtherProfile:
      inc(subCatMap[catName][subCatName].other)

  for cat in Category:
    let catName = getCategoryName(cat)
    var subCats: seq[SubCategoryStats]

    if subCatMap.hasKey(catName):
      subCats = newSeqOfCap[SubCategoryStats](subCatMap[catName].len)
      for _, stats in subCatMap[catName].pairs:
        subCats.add(stats)
    else:
      subCats = @[]

    result.add(CategorySubStats(category: cat, subCategories: subCats))

proc showCategorySummary*(
    data: StatusData,
    profile: string,
    useAscii: bool = false,
    category: Option[Category] = none(Category),
    verbose: bool = false,
) =
  echo ""
  echo "Status for profile '" & profile & "':"
  echo ""

  if verbose and category.isNone():
    let categorySubStats = groupBySubCategory(data)
    let headers =
      @[
        newCell("Subdirectory", AlignLeft),
        newCell("Linked", AlignRight),
        newCell("NotLinked", AlignRight),
        newCell("Conflict", AlignRight),
        newCell("Other", AlignRight),
      ]

    for catStats in categorySubStats:
      let catName = getCategoryName(catStats.category)

      if catStats.subCategories.len > 0:
        var rows = newSeqOfCap[seq[Cell]](catStats.subCategories.len)
        for subStats in catStats.subCategories:
          if subStats.linked + subStats.notLinked + subStats.conflicts + subStats.other >
              0:
            let displayName =
              if subStats.name.len == 0:
                catName & "/(root)"
              else:
                catName & "/" & subStats.name
            var row = newSeq[Cell](5)
            row[0] = newCell(displayName, AlignLeft)
            row[1] = newCell($subStats.linked, AlignRight)
            row[2] = newCell($subStats.notLinked, AlignRight)
            row[3] = newCell($subStats.conflicts, AlignRight)
            row[4] = newCell($subStats.other, AlignRight)
            rows.add(row)

        let style = if useAscii: AsciiStyle else: UnicodeStyle
        echo renderTable(headers, rows, style)
        echo ""
  else:
    let categoryStats = groupByCategory(data)

    var headers: seq[Cell] =
      @[
        newCell("Directory", AlignLeft),
        newCell("Linked", AlignRight),
        newCell("NotLinked", AlignRight),
        newCell("Conflict", AlignRight),
        newCell("Other", AlignRight),
      ]

    var rows =
      if category.isSome():
        newSeqOfCap[seq[Cell]](1)
      else:
        newSeqOfCap[seq[Cell]](5)

    if category.isSome():
      let cat = category.get()
      let stats = categoryStats[cat]
      var row = newSeq[Cell](5)
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
          var row = newSeq[Cell](5)
          row[0] = newCell(getCategoryName(cat) & "/", AlignLeft)
          row[1] = newCell($stats.linked, AlignRight)
          row[2] = newCell($stats.notLinked, AlignRight)
          row[3] = newCell($stats.conflicts, AlignRight)
          row[4] = newCell($stats.other, AlignRight)
          rows.add(row)

    let style = if useAscii: AsciiStyle else: UnicodeStyle
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
    data: StatusData,
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
    let homePath = data.homePathAt(i)

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
