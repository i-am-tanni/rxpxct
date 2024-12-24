import gleam/io
import gleam/result
import gleam/string
import rxpxct/converter
import rxpxct/error
import rxpxct/importer
import rxpxct/parser
import simplifile

pub fn main() {
  let arg1 = "./sample/sample.xml"
  let arg2 = "./formats/ansi_truecolor.json"
  case run(arg1, arg2) {
    Ok(_) -> io.println("Done!")
    Error(e) -> io.println_error(error.to_string(e))
  }
}

fn run(arg1: String, arg2: String) -> Result(Nil, error.WrapperError) {
  use xml_data <- result.try(importer.import_xml(arg1))
  use format <- result.try(importer.import_format(arg2))
  use parsed_data <- result.try(parser.run(xml_data))
  let formatted_data = converter.run(parsed_data, format)
  let save_path = string.drop_end(arg1, 4) |> string.append(".txt")
  simplifile.write(to: save_path, contents: string.concat(formatted_data))
  |> result.map_error(fn(e) { error.SaveError(e) })
}
