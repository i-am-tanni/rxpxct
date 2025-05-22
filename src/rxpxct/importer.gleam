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
import rxpxct/format.{type Format, Format16, Format256, FormatTrue}
import simplifile

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

fn to_format(json: String) -> Result(Format, WrapperError) {
  let result = {
    use <- result.lazy_or(json.parse(json, to_format24_bit()))
    use <- result.lazy_or(json.parse(json, to_format256()))
    json.parse(json, to_format16())
  }

  result.map_error(result, fn(error) { DecodeError(error) })
}

fn to_format24_bit() -> decode.Decoder(Format) {
  use r_pattern <- decode.field("r", decode.string)
  use g_pattern <- decode.field("g", decode.string)
  use b_pattern <- decode.field("b", decode.string)
  use foreground <- decode.field("foreground", decode.string)
  use background <- decode.field("background", decode.string)
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
  use foreground <- decode.field("foreground", decode.string)
  use background <- decode.field("background", decode.string)
  use reset <- decode.field("reset", decode.string)
  use symbol <- decode.field("symbol", decode.string)
  use base <- decode.field("base", decode.int)
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
  let string_array = decode.list(decode.string)
  use foreground_codes <- decode.field("foreground_codes", string_array)
  use background_codes <- decode.field("background_codes", string_array)
  use foreground <- decode.field("foreground", decode.string)
  use background <- decode.field("background", decode.string)
  use reset <- decode.field("reset", decode.string)
  use symbol <- decode.field("symbol", decode.string)
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

fn to_array16(string_list: List(String)) -> Array(String) {
  string_list |> list.take(16) |> array.from_list()
}
