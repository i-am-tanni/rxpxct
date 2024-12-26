import gleeunit
import gleeunit/should
import rxpxct
import simplifile

pub fn main() {
  gleeunit.main()
}

const sample_xml_path = "./sample/sample.xml"

const sample_format_path = "./formats/fansi256.json"

// gleeunit test functions end in `_test`
pub fn conversion_test() {
  should.be_ok(rxpxct.run(sample_xml_path, sample_format_path))
  simplifile.delete("./sample/sample.txt")
}
