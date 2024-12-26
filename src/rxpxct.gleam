import argv
import gleam/io
import gleam/result
import gleam/string
import rxpxct/converter
import rxpxct/error
import rxpxct/importer
import rxpxct/parser
import simplifile

pub fn main() {
  case argv.load().arguments {
    [xml_path, format_path] -> {
      case run(xml_path, format_path) {
        Ok(_) -> io.println("Done!")
        Error(e) -> io.println_error(error.to_string(e))
      }
    }

    _ -> {
      let argv_error =
        "To run this conversion tool, type `gleam run <xml_path> <format_path>`"
      io.println(argv_error)
    }
  }
}

pub fn run(arg1: String, arg2: String) -> Result(Nil, error.WrapperError) {
  use xml_data <- result.try(importer.import_xml(arg1))
  use format <- result.try(importer.import_format(arg2))
  use parsed_data <- result.try(parser.run(xml_data))
  let formatted_data = converter.run(parsed_data, format)
  let save_path = string.drop_end(arg1, 4) |> string.append(".txt")
  simplifile.write(to: save_path, contents: string.concat(formatted_data))
  |> result.map_error(fn(e) { error.SaveError(e) })
}
