//// Reads in format data to Format type. Reads in xml data.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic, dict, field, int, string}
import gleam/int
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
    True -> read(xml_path)
    False -> Error(WrongExtension(expected: ".xml", path: xml_path))
  }
}

pub fn import_format(format_path: String) -> Result(Format, WrapperError) {
  use json <- result.try(read(format_path))
  to_format(json)
}

fn read(path: String) -> Result(String, WrapperError) {
  use error <- result.map_error(simplifile.read(path))
  ImportError(path: path, error: error)
}

fn to_format(json_string: String) -> Result(Format, WrapperError) {
  // one decoder rather than three would likely be more efficient here 
  //  since then the json_string would not be converted to a dict three times 
  //  in the worst case scenario
  use <- result.lazy_or(to_format24_bit(json_string))
  use <- result.lazy_or(to_format256(json_string))
  to_format16(json_string)
}

fn to_format24_bit(json: String) -> Result(Format, WrapperError) {
  let decoder =
    dynamic.decode7(
      FormatTrue,
      field("reset", of: string),
      field("r", of: string),
      field("g", of: string),
      field("b", of: string),
      field("foreground", of: string),
      field("background", of: string),
      field("base", of: base),
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
      field("reset", of: string),
      field("symbol", of: string),
      field("foreground", of: string),
      field("background", of: string),
      field("base", of: base),
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
      field("reset", of: string),
      field("symbol", of: string),
      field("pattern", of: string),
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

fn base(dynamic: Dynamic) -> Result(Int, dynamic.DecodeErrors) {
  use x <- result.try(int(dynamic))
  case x >= 2 && x <= 32 {
    True -> Ok(x)
    False -> {
      let x = int.to_string(x)
      let path = ["base:", x]
      dynamic.DecodeError(expected: "Int >= 2 and <= 32", found: x, path: path)
      |> list.wrap()
      |> Error()
    }
  }
}

fn map_dynamic(
  t1: fn(Dynamic) -> Result(a, dynamic.DecodeErrors),
  map_fun: fn(a) -> b,
) -> fn(Dynamic) -> Result(b, dynamic.DecodeErrors) {
  fn(dynamic) { result.map(t1(dynamic), map_fun) }
}
