import gleam/int
import gleam/list
import gleam/result
import gleam/string
import party.{
  type ParseError, type Parser, alphanum, between, choice, digits, do, drop,
  many1, many1_concat, map, satisfy, seq, string, whitespace, whitespace1,
}
import rxpxct/color.{type Color, TrueColor}
import rxpxct/error.{type WrapperError}

pub type Token {
  Foreground(Color)
  Background(Color)
  Ascii(UtfCodepoint)
}

pub fn run(s: String) -> Result(List(List(Token)), WrapperError) {
  party.go(xml_parser(), s)
  |> result.map_error(fn(e) { error.ParseError(e) })
}

fn xml_parser() -> Parser(List(List(Token)), ParseError(String)) {
  between(
    string("<image>"),
    seq(header(), data()),
    seq(whitespace(), string("</image>")),
  )
}

fn header() -> Parser(List(String), ParseError(e)) {
  let text = many1_concat(satisfy(fn(c) { c != "<" }))
  let name = between(string("<name>"), text, string("</name>"))
  let height = between(string("<height>"), text, string("</height>"))
  let width = between(string("<width>"), text, string("</width>"))
  many1(choice([name, height, width, whitespace1()]))
}

fn data() -> Parser(List(List(Token)), ParseError(String)) {
  between(
    string("<data>"),
    many1(seq(whitespace(), row())),
    seq(whitespace(), string("</data>")),
  )
  |> map(list.flatten)
}

fn row() -> Parser(List(List(Token)), ParseError(String)) {
  let assert Ok(newline_cp) = string.utf_codepoint(10)

  between(
    string("<row>"),
    many1(
      choice([seq(whitespace(), wrap(blank_cell())), seq(whitespace(), cell())]),
    ),
    seq(whitespace(), string("</row>")),
  )
  |> map(list.append(_, [[Ascii(newline_cp)]]))
}

fn blank_cell() -> Parser(Token, ParseError(String)) {
  let assert Ok(whitespace_cp) = string.utf_codepoint(32)
  string("<cell><ascii>32</ascii><fgd>#000000</fgd><bkg>#000000</bkg></cell>")
  |> map(fn(_) { Ascii(whitespace_cp) })
}

fn cell() -> Parser(List(Token), ParseError(String)) {
  let ascii = between(string("<ascii>"), utf_codepoint(), string("</ascii>"))
  let foreground = between(string("<fgd>"), rgb(), string("</fgd>"))
  let background = between(string("<bkg>"), rgb(), string("</bkg>"))

  let cell = {
    use ascii <- do(ascii)
    use fgd <- do(foreground)
    use bkg <- do(background)
    party.return([Foreground(fgd), Background(bkg), Ascii(ascii)])
  }

  between(string("<cell>"), cell, string("</cell>"))
}

fn utf_codepoint() -> Parser(UtfCodepoint, ParseError(String)) {
  use pos <- do(party.pos())
  use string <- do(digits())
  let result = {
    use val <- result.try(int.parse(string))
    string.utf_codepoint(val)
  }
  case result {
    Ok(val) -> party.return(val)
    Error(_) ->
      party.error_map(party.fail(), fn(_) {
        party.Unexpected(pos: pos, error: "Expected utf codepoint")
      })
  }
}

fn rgb() -> Parser(Color, ParseError(String)) {
  use <- drop(string("#"))
  use r <- do(hex256())
  use g <- do(hex256())
  use b <- do(hex256())
  party.return(TrueColor(red: r, green: g, blue: b))
}

fn hex256() -> Parser(Int, ParseError(String)) {
  use pos <- do(party.pos())
  use a <- do(alphanum())
  use b <- do(alphanum())
  case int.base_parse(a <> b, 16) {
    Ok(val) -> party.return(val)
    Error(Nil) -> {
      use _ <- party.error_map(party.fail())
      party.Unexpected(pos: pos, error: "Expected two digit base16 number")
    }
  }
}

fn wrap(p: Parser(a, e)) -> Parser(List(a), e) {
  use x <- map(p)
  [x]
}
