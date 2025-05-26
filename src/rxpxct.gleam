import argv
import gleam/io
import gleam/result
import gleam/string
import rxpxct/converter
import rxpxct/error.{type WrapperError, BadArgs}
import rxpxct/importer
import rxpxct/tokens
import simplifile

pub fn main() {
  let convert = {
    use #(xml_path, format_path) <- result.try(get_args())
    run(xml_path, format_path)
  }

  case convert {
    Ok(save_path) -> io.println("Done! Saved to " <> save_path)
    Error(e) -> io.println_error(error.to_string(e))
  }
}

pub fn run(
  xml_path: String,
  format_path: String,
) -> Result(String, error.WrapperError) {
  use xml_data <- result.try(importer.import_xml(xml_path))
  use format <- result.try(importer.import_format(format_path))
  use parsed_data <- result.try(tokens.from_string(xml_data))
  let formatted_data = converter.run(parsed_data, format)
  let save_path = string.drop_end(xml_path, 4) |> string.append(".txt")
  simplifile.write(to: save_path, contents: formatted_data)
  |> result.map(fn(_) { save_path })
  |> result.map_error(fn(e) { error.SaveError(e) })
}

fn get_args() -> Result(#(String, String), WrapperError) {
  case argv.load().arguments {
    [xml_path, format_path] -> Ok(#(xml_path, format_path))
    _ -> Error(BadArgs)
  }
}
