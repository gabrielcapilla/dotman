import std/strutils

type
  CellAlign* = enum
    AlignLeft
    AlignCenter
    AlignRight

  BoxGlyph = enum
    GlyphTopLeft
    GlyphTopRight
    GlyphBottomLeft
    GlyphBottomRight
    GlyphHoriz
    GlyphVert
    GlyphVertRight
    GlyphVertLeft
    GlyphHorizDown
    GlyphHorizUp
    GlyphCross

  BoxStyle* = enum
    UnicodeStyle
    AsciiStyle

  Cell* = object
    content*: string
    align*: CellAlign

const
  UnicodeGlyphs: array[BoxGlyph, string] = [
    GlyphTopLeft: "╭",
    GlyphTopRight: "╮",
    GlyphBottomLeft: "╰",
    GlyphBottomRight: "╯",
    GlyphHoriz: "─",
    GlyphVert: "│",
    GlyphVertRight: "├",
    GlyphVertLeft: "┤",
    GlyphHorizDown: "┬",
    GlyphHorizUp: "┴",
    GlyphCross: "┼",
  ]

  AsciiGlyphs: array[BoxGlyph, string] = [
    GlyphTopLeft: "+",
    GlyphTopRight: "+",
    GlyphBottomLeft: "+",
    GlyphBottomRight: "+",
    GlyphHoriz: "-",
    GlyphVert: "|",
    GlyphVertRight: "+",
    GlyphVertLeft: "+",
    GlyphHorizDown: "+",
    GlyphHorizUp: "+",
    GlyphCross: "+",
  ]

proc newCell*(content: string, align: CellAlign = AlignLeft): Cell {.inline.} =
  Cell(content: content, align: align)

func glyph(style: BoxStyle, part: BoxGlyph): string {.inline.} =
  case style
  of UnicodeStyle:
    UnicodeGlyphs[part]
  of AsciiStyle:
    AsciiGlyphs[part]

func renderLine*(
    cols: openArray[int], style: BoxStyle, left, middle, right: BoxGlyph
): string {.inline.} =
  let horiz = glyph(style, GlyphHoriz)
  let leftEdge = glyph(style, left)
  let middleEdge = glyph(style, middle)
  let rightEdge = glyph(style, right)

  result = leftEdge
  for i, col in cols:
    result.add(horiz.repeat(col))
    if i < cols.len - 1:
      result.add(middleEdge)
  result.add(rightEdge)

func renderRow*(
    cells: openArray[Cell], colWidths: openArray[int], style: BoxStyle
): string {.noSideEffect.} =
  let vertical = glyph(style, GlyphVert)
  result = vertical
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

    result.add(vertical)

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

  result.add(renderLine(colWidths, style, GlyphTopLeft, GlyphHorizDown, GlyphTopRight))
  result.add("\n")
  result.add(renderRow(headers, colWidths, style))
  result.add("\n")

  for row in rows:
    result.add(renderLine(colWidths, style, GlyphVertRight, GlyphCross, GlyphVertLeft))
    result.add("\n")
    result.add(renderRow(row, colWidths, style))
    result.add("\n")

  result.add(
    renderLine(colWidths, style, GlyphBottomLeft, GlyphHorizUp, GlyphBottomRight)
  )

func renderTable*[N: static[int]](
    headers: openArray[Cell], rows: openArray[array[N, Cell]], style: BoxStyle
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

  result.add(renderLine(colWidths, style, GlyphTopLeft, GlyphHorizDown, GlyphTopRight))
  result.add("\n")
  result.add(renderRow(headers, colWidths, style))
  result.add("\n")

  for row in rows:
    result.add(renderLine(colWidths, style, GlyphVertRight, GlyphCross, GlyphVertLeft))
    result.add("\n")
    result.add(renderRow(row, colWidths, style))
    result.add("\n")

  result.add(
    renderLine(colWidths, style, GlyphBottomLeft, GlyphHorizUp, GlyphBottomRight)
  )
