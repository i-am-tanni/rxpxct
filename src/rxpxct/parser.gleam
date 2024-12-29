import gleam/int
import gleam/list
import gleam/result
import party.{
  type ParseError, type Parser, alphanum, between, char, choice, digits, do,
  drop, many1, many1_concat, many_concat, map, satisfy, seq, string,
}
import rxpxct/color.{type Color, TrueColor}
import rxpxct/error.{type WrapperError}
import rxpxct/token.{type Token, Ascii, Background, Foreground, Newline}

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
  between(
    string("<row>"),
    many1(seq(whitespace(), cell())),
    seq(whitespace(), string("</row>")),
  )
  |> map(list.append(_, [[Newline]]))
}

fn cell() -> Parser(List(Token), ParseError(String)) {
  // not sure what to do about non-printable characters 
  //   other than default to spaces
  let ascii = {
    use string <- do(digits())
    int.parse(string)
    |> result.unwrap(-1)
    |> int.max(32)
    |> party.return()
  }

  let ascii = between(string("<ascii>"), ascii, string("</ascii>"))
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

/// Parse zero or more whitespace characters.
pub fn whitespace() -> Parser(String, e) {
  many_concat(choice([char(" "), char("\t"), char("\r\n"), char("\n")]))
}

/// Parse one or more whitespace characters.
pub fn whitespace1() -> Parser(String, e) {
  many1_concat(choice([char(" "), char("\t"), char("\r\n"), char("\n")]))
}
