import std/[tables, options]
import ../core/types
import ../components/status

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
