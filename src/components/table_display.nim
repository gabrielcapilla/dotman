import std/strutils

type
  CellAlign* = enum
    AlignLeft
    AlignCenter
    AlignRight

  Cell* = object
    content*: string
    align*: CellAlign

  BoxStyle* = object
    topLeft*: string
    topRight*: string
    bottomLeft*: string
    bottomRight*: string
    horiz*: string
    vert*: string
    vertRight*: string
    vertLeft*: string
    horizDown*: string
    horizUp*: string
    cross*: string

const
  UnicodeStyle* = BoxStyle(
    topLeft: "╭",
    topRight: "╮",
    bottomLeft: "╰",
    bottomRight: "╯",
    horiz: "─",
    vert: "│",
    vertRight: "├",
    vertLeft: "┤",
    horizDown: "┬",
    horizUp: "┴",
    cross: "┼",
  )

  AsciiStyle* = BoxStyle(
    topLeft: "+",
    topRight: "+",
    bottomLeft: "+",
    bottomRight: "+",
    horiz: "-",
    vert: "|",
    horizDown: "+",
    horizUp: "+",
    cross: "+",
  )

proc newCell*(content: string, align: CellAlign = AlignLeft): Cell {.inline.} =
  Cell(content: content, align: align)

func renderLine*(
    cols: openArray[int], style: BoxStyle, left: string, middle: string, right: string
): string {.inline.} =
  result = left
  for i, col in cols:
    result.add(style.horiz.repeat(col))
    if i < cols.len - 1:
      result.add(middle)
  result.add(right)

func renderRow*(
    cells: openArray[Cell], colWidths: openArray[int], style: BoxStyle
): string {.noSideEffect.} =
  result = style.vert
  for i, cell in cells:
    let width = colWidths[i]
    let contentLen = cell.content.len

    case cell.align
    of AlignLeft:
      result.add(" " & cell.content & " ".repeat(width - contentLen - 1))
    of AlignRight:
      result.add(" ".repeat(width - contentLen - 1) & cell.content & " ")
    of AlignCenter:
      let padding = width - contentLen - 2
      let leftPad = padding div 2
      let rightPad = padding - leftPad
      result.add(" ".repeat(leftPad) & cell.content & " ".repeat(rightPad + 1))

    result.add(style.vert)

func calculateColumnWidths*(rows: openArray[seq[Cell]]): seq[int] {.noSideEffect.} =
  let colCount = rows[0].len
  result = newSeq[int](colCount)

  for row in rows:
    for i, cell in row:
      let cellWidth = cell.content.len + 2
      if cellWidth > result[i]:
        result[i] = cellWidth

func renderTable*(
    headers: openArray[Cell], rows: openArray[seq[Cell]], style: BoxStyle
): string =
  let colCount = headers.len
  var colWidths = newSeq[int](colCount)

  for i, cell in headers:
    colWidths[i] = cell.content.len + 2

  for row in rows:
    for i, cell in row:
      let cellWidth = cell.content.len + 2
      if cellWidth > colWidths[i]:
        colWidths[i] = cellWidth

  var rowWidth = 1
  for w in colWidths:
    rowWidth += w + 1
  let lineCount = rows.len * 2 + 3
  result = newStringOfCap(lineCount * (rowWidth + 1))

  result.add(
    renderLine(colWidths, style, style.topLeft, style.horizDown, style.topRight)
  )
  result.add("\n")
  result.add(renderRow(headers, colWidths, style))
  result.add("\n")

  for row in rows:
    result.add(
      renderLine(colWidths, style, style.vertRight, style.cross, style.vertLeft)
    )
    result.add("\n")
    result.add(renderRow(row, colWidths, style))
    result.add("\n")

  result.add(
    renderLine(colWidths, style, style.bottomLeft, style.horizUp, style.bottomRight)
  )
