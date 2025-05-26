import gleam/json
import gleam/string
import party
import simplifile

pub type WrapperError {
  ImportError(path: String, error: simplifile.FileError)
  DecodeError(json.DecodeError)
  WrongExtension(expected: String, path: String)
  ParseError(party.ParseError(party.ParseError(String)))
  SaveError(simplifile.FileError)
  BadArgs
}

pub fn to_string(e: WrapperError) -> String {
  case e {
    WrongExtension(path: path, ..) ->
      "Error: Wrong Extension. Expected .xml file and got: '" <> path <> "'"
    BadArgs ->
      "To run this conversion tool type:
    `gleam run <.path/to/rexpaint_export.xml> <.path/to/format.json>`"
    _ -> string.inspect(e)
  }
}
