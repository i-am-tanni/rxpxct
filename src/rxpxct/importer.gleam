import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic, dict, field, int, string}
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import glearray.{type Array}
import rxpxct/color
import rxpxct/error.{type WrapperError, DecodeError, ImportError, WrongExtension}
import rxpxct/format.{type Format, Format16, Format256, FormatTrue}
import simplifile

pub fn import_xml(xml_path: String) -> Result(String, WrapperError) {
  case string.ends_with(xml_path, ".xml") {
    True -> {
      use error <- result.map_error(simplifile.read(xml_path))
      ImportError(error)
    }
    False -> Error(WrongExtension(expected: ".xml"))
  }
}

pub fn import_format(format_path: String) -> Result(Format, WrapperError) {
  let assert Ok(json) = simplifile.read(format_path)
  to_format(json)
}

fn to_format(json: String) -> Result(Format, WrapperError) {
  use <- result.lazy_or(to_format24_bit(json))
  use <- result.lazy_or(to_format256(json))
  to_format16(json)
}

fn to_format24_bit(json: String) -> Result(Format, WrapperError) {
  let decoder =
    dynamic.decode7(
      FormatTrue,
      field("r", of: string),
      field("g", of: string),
      field("b", of: string),
      field("foreground", of: string),
      field("background", of: string),
      field("reset", of: string),
      field("base", of: int),
    )

  use error <- result.map_error(json.decode(json, using: decoder))
  DecodeError(error)
}

fn to_format256(json: String) -> Result(Format, WrapperError) {
  let lookups256 = fn(_) {
    let lookups = [color.generate_q2c()]
    Ok(lookups)
  }

  let decoder =
    dynamic.decode6(
      Format256,
      field("symbol", of: string),
      field("foreground", of: string),
      field("background", of: string),
      field("reset", of: string),
      field("base", of: int),
      lookups256,
    )

  use error <- result.map_error(json.decode(json, using: decoder))
  DecodeError(error)
}

fn to_format16(json: String) -> Result(Format, WrapperError) {
  let lookups16 = fn(_) {
    let lookups = [color.generate_q2c(), color.generate_code256to16()]
    Ok(lookups)
  }

  let string_array = map_dynamic(dict(string, string), dict_to_array16)

  let decoder =
    dynamic.decode6(
      Format16,
      field("symbol", of: string),
      field("pattern", of: string),
      field("reset", of: string),
      field("foreground", of: string_array),
      field("background", of: string_array),
      lookups16,
    )

  use error <- result.map_error(json.decode(json, using: decoder))
  DecodeError(error)
}

fn dict_to_array16(dict: Dict(a, b)) -> Array(b) {
  dict |> dict.values() |> list.take(16) |> glearray.from_list()
}

fn map_dynamic(
  t1: fn(Dynamic) -> Result(a, dynamic.DecodeErrors),
  map_fun: fn(a) -> b,
) -> fn(Dynamic) -> Result(b, dynamic.DecodeErrors) {
  fn(dynamic) { result.map(t1(dynamic), map_fun) }
}
