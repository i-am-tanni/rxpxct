import argv
import gleam/io
import gleam/result
import gleam/string
import rxpxct/converter
import rxpxct/error
import rxpxct/importer
import rxpxct/tokens
import simplifile

pub fn main() {
  case argv.load().arguments {
    [xml_path, format_path] -> {
      case run(xml_path, format_path) {
        Ok(save_path) -> io.println("Done! Saved to " <> save_path)
        Error(e) -> io.println_error(error.to_string(e))
      }
    }

    _ -> {
      io.println("To run this conversion tool type:")
      io.println(
        "  `gleam run <.path/to/rexpaint_export.xml> <.path/to/format.json>`",
      )
    }
  }
}

pub fn run(arg1: String, arg2: String) -> Result(String, error.WrapperError) {
  use xml_data <- result.try(importer.import_xml(arg1))
  use format <- result.try(importer.import_format(arg2))
  use parsed_data <- result.try(tokens.from_string(xml_data))
  let formatted_data = converter.run(parsed_data, format)
  let save_path = string.drop_end(arg1, 4) |> string.append(".txt")
  simplifile.write(to: save_path, contents: formatted_data)
  |> result.map(fn(_) { save_path })
  |> result.map_error(fn(e) { error.SaveError(e) })
}
