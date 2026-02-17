import ../core/types
import ../components/status

proc groupByCategory*(data: StatusData): array[Category, CategoryStats] =
  for cat in Category:
    result[cat] = CategoryStats(linked: 0, notLinked: 0, conflicts: 0, other: 0)

  for i in 0 ..< data.count:
    let status = data.statuses[i]
    let cat = data.categories[i]

    case status
    of Linked:
      inc(result[cat].linked)
    of NotLinked:
      inc(result[cat].notLinked)
    of Conflict:
      inc(result[cat].conflicts)
    of OtherProfile:
      inc(result[cat].other)
