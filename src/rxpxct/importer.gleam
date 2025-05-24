//// Read in a REXpaint xml file and format type, then tokenize
//// 

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import rxpxct/array.{type Array}
import rxpxct/color
import rxpxct/error.{type WrapperError, DecodeError, ImportError, WrongExtension}
import simplifile

/// Color formatting information decoded from a json format specifier file.
/// See templates in /formats/.
/// 
pub type Format {
  /// True Color aka 24bit Color. REXpaint outputs this color format natively.
  /// 
  FormatTrue(
    foreground: String,
    background: String,
    reset: String,
    r_pattern: String,
    g_pattern: String,
    b_pattern: String,
    base: Int,
  )

  /// xterm 256 colors. This will be downsampled from true color.
  /// 
  Format256(
    foreground: String,
    background: String,
    reset: String,
    symbol: String,
    base: Int,
    lookups: List(Array(Int)),
  )

  /// 16 Colors. This will be downsampled from 256 colors.
  /// 
  Format16(
    foreground: String,
    background: String,
    reset: String,
    symbol: String,
    foreground_codes: Array(String),
    background_codes: Array(String),
    lookups: List(Array(Int)),
  )
}

/// Read in a REXpaint xml file
/// 
pub fn import_xml(xml_path: String) -> Result(String, WrapperError) {
  case string.ends_with(xml_path, ".xml") {
    True -> read_file(xml_path)
    False -> Error(WrongExtension(expected: ".xml", path: xml_path))
  }
}

/// Read in a json color format definition. See /formats/ for templates.
/// 
pub fn import_format(format_path: String) -> Result(Format, WrapperError) {
  use json <- result.try(read_file(format_path))
  to_format(json)
}

fn read_file(path: String) -> Result(String, WrapperError) {
  result.map_error(simplifile.read(path), ImportError(path: path, error: _))
}

/// Convert json to a color Format
/// 
pub fn to_format(json: String) -> Result(Format, WrapperError) {
  let decoder =
    decode.one_of(to_format24_bit(), [to_format256(), to_format16()])

  json.parse(json, decoder)
  |> result.map_error(fn(error) { DecodeError(error) })
}

fn to_format24_bit() -> decode.Decoder(Format) {
  use _ <- decode.field("color_mode", decode_string_matches("truecolor"))
  use foreground <- decode.field("foreground", decode.string)
  use background <- decode.field("background", decode.string)
  use r_pattern <- decode.field("r", decode.string)
  use g_pattern <- decode.field("g", decode.string)
  use b_pattern <- decode.field("b", decode.string)
  use reset <- decode.field("reset", decode.string)
  use base <- decode.field("base", decode.int)
  FormatTrue(
    foreground: foreground,
    background: background,
    reset: reset,
    r_pattern: r_pattern,
    g_pattern: g_pattern,
    b_pattern: b_pattern,
    base: base,
  )
  |> decode.success
}

fn to_format256() -> decode.Decoder(Format) {
  use _ <- decode.field("color_mode", decode_string_matches("256"))
  use foreground <- decode.field("foreground", decode.string)
  use background <- decode.field("background", decode.string)
  use reset <- decode.field("reset", decode.string)
  use symbol <- decode.field("symbol", decode.string)
  use base <- decode.field("base", decode_base())
  Format256(
    base: base,
    foreground: foreground,
    background: background,
    reset: reset,
    symbol: symbol,
    lookups: [color.generate_q2c()],
  )
  |> decode.success
}

fn to_format16() -> decode.Decoder(Format) {
  use _ <- decode.field("color_mode", decode_string_matches("16"))
  let string_array = decode.list(decode.string)
  use foreground <- decode.field("foreground", decode.string)
  use background <- decode.field("background", decode.string)
  use reset <- decode.field("reset", decode.string)
  use symbol <- decode.field("symbol", decode.string)
  use foreground_codes <- decode.field("foreground_codes", string_array)
  use background_codes <- decode.field("background_codes", string_array)
  Format16(
    foreground: foreground,
    background: background,
    reset: reset,
    symbol: symbol,
    foreground_codes: foreground_codes |> to_array16(),
    background_codes: background_codes |> to_array16(),
    lookups: [color.generate_q2c(), color.generate_code256to16()],
  )
  |> decode.success
}

fn decode_string_matches(s: String) -> decode.Decoder(String) {
  use decoded_string <- decode.then(decode.string)
  case decoded_string == s {
    True -> decode.success(s)
    False -> decode.failure(s, "Unknown color mode: " <> decoded_string)
  }
}

// decode the base that the color codes are expressed in
// e.g. hex codes or decimal
fn decode_base() -> decode.Decoder(Int) {
  use decoded_int <- decode.then(decode.int)
  case decoded_int >= 10 && decoded_int <= 32 {
    True -> decode.success(decoded_int)
    False -> decode.failure(decoded_int, "Base must be >= 10 and <= 32")
  }
}

fn to_array16(string_list: List(String)) -> Array(String) {
  string_list |> list.take(16) |> array.from_list()
}
