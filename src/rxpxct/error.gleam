import gleam/json
import gleam/string
import party
import simplifile

pub type WrapperError {
  ImportError(simplifile.FileError)
  DecodeError(json.DecodeError)
  WrongExtension(expected: String)
  ParseError(party.ParseError(party.ParseError(String)))
  SaveError(simplifile.FileError)
}

pub fn to_string(e: WrapperError) -> String {
  string.inspect(e)
}
