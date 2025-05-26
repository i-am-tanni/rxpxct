import gleam/list
import gleeunit
import gleeunit/should
import rxpxct
import simplifile

pub fn main() {
  gleeunit.main()
}

const sample_xml_path = "./sample/sample.xml"

pub fn conversion_test() {
  should.be_ok(simplifile.get_files("./formats"))
  |> list.each(fn(format_path) {
    should.be_ok(rxpxct.run(sample_xml_path, format_path))
  })
  should.be_ok(simplifile.delete("./sample/sample.txt"))
}
