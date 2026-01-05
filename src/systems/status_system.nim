import std/[os, tables, options, strutils]
import ../core/path
import ../components/profiles
import ../components/status
import ../components/table_display
import scan_system

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

proc groupByCategory*(data: StatusData): Table[Category, CategoryStats] =
  result = initTable[Category, CategoryStats]()

  for cat in Category:
    result[cat] = CategoryStats(linked: 0, notLinked: 0, conflicts: 0, other: 0)

  for i in 0 ..< data.count:
    let relPath = data.relPaths[i]
    let status = data.statuses[i]
    let cat = getCategory(relPath)

    case status
    of Linked:
      inc(result[cat].linked)
    of NotLinked:
      inc(result[cat].notLinked)
    of Conflict:
      inc(result[cat].conflicts)
    of OtherProfile:
      inc(result[cat].other)

proc groupBySubCategory*(data: StatusData): seq[CategorySubStats] =
  result = @[]

  var subCatMap: Table[string, Table[string, SubCategoryStats]]
  subCatMap = initTable[string, Table[string, SubCategoryStats]]()

  for i in 0 ..< data.count:
    let relPath = data.relPaths[i]
    let status = data.statuses[i]
    let cat = getCategory(relPath)
    let catName =
      case cat
      of Config: "config"
      of Share: "share"
      of Home: "home"
      of Local: "local"
      of Bin: "bin"

    if not subCatMap.hasKey(catName):
      subCatMap[catName] = initTable[string, SubCategoryStats]()

    let parts = relPath.split("/")
    let subCatName =
      if parts.len > 1:
        parts[1]
      else:
        ""

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
    var subCats: seq[SubCategoryStats] = @[]

    if subCatMap.hasKey(catName):
      for name, stats in subCatMap[catName].pairs:
        subCats.add(stats)

    result.add(CategorySubStats(category: cat, subCategories: subCats))

proc filterData*(
    data: StatusData, filter: StatusFilter, category: Option[Category] = none(Category)
): seq[int] =
  result = @[]

  for i in 0 ..< data.count:
    let status = data.statuses[i]
    let cat = getCategory(data.relPaths[i])

    case filter
    of FilterAll:
      if category.isNone() or category.get() == cat:
        result.add(i)
    of FilterLinked:
      if status == Linked and (category.isNone() or category.get() == cat):
        result.add(i)
    of FilterNotLinked:
      if status == NotLinked and (category.isNone() or category.get() == cat):
        result.add(i)
    of FilterConflicts:
      if status == Conflict and (category.isNone() or category.get() == cat):
        result.add(i)
    of FilterOther:
      if status == OtherProfile and (category.isNone() or category.get() == cat):
        result.add(i)

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

    for catStats in categorySubStats:
      let catName = getCategoryName(catStats.category)

      if catStats.subCategories.len > 0:
        var headers: seq[Cell] =
          @[
            newCell("Subdirectory", AlignLeft),
            newCell("Linked", AlignRight),
            newCell("NotLinked", AlignRight),
            newCell("Conflict", AlignRight),
            newCell("Other", AlignRight),
          ]

        var rows: seq[seq[Cell]] = @[]
        for subStats in catStats.subCategories:
          if subStats.linked + subStats.notLinked + subStats.conflicts + subStats.other >
              0:
            let displayName =
              if subStats.name.len == 0:
                catName & "/(root)"
              else:
                catName & "/" & subStats.name
            rows.add(
              @[
                newCell(displayName, AlignLeft),
                newCell($subStats.linked, AlignRight),
                newCell($subStats.notLinked, AlignRight),
                newCell($subStats.conflicts, AlignRight),
                newCell($subStats.other, AlignRight),
              ]
            )

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

    var rows: seq[seq[Cell]] = @[]

    if category.isSome():
      let cat = category.get()
      let stats = categoryStats[cat]
      rows.add(
        @[
          newCell(getCategoryName(cat) & "/", AlignLeft),
          newCell($stats.linked, AlignRight),
          newCell($stats.notLinked, AlignRight),
          newCell($stats.conflicts, AlignRight),
          newCell($stats.other, AlignRight),
        ]
      )
    else:
      for cat in Category:
        let stats = categoryStats[cat]
        if stats.linked + stats.notLinked + stats.conflicts + stats.other > 0:
          rows.add(
            @[
              newCell(getCategoryName(cat) & "/", AlignLeft),
              newCell($stats.linked, AlignRight),
              newCell($stats.notLinked, AlignRight),
              newCell($stats.conflicts, AlignRight),
              newCell($stats.other, AlignRight),
            ]
          )

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

  let indices = filterData(data, filter, category)
  var linkedCount = 0
  var notLinkedCount = 0
  var conflictCount = 0
  var otherCount = 0

  for idx in indices:
    let relPath = data.relPaths[idx]
    let homePath = data.homePaths[idx]
    let status = data.statuses[idx]

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

proc showStatus*(profile: string, filter: StatusFilter = FilterAll) =
  let profileDir = getDotmanDir() / profile

  if not dirExists(profileDir):
    raise ProfileError(msg: "Profile not found: " & profile)

  let data = scanProfileSimple(profileDir)

  if filter == FilterAll:
    showCategorySummary(data, profile)
  else:
    showDetailedReport(data, profile, filter)
