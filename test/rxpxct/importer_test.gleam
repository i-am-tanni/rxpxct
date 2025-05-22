import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import rxpxct/importer

pub fn main() {
  gleeunit.main()
}

pub fn base_parsing_failed_test() {
  let json =
    "{
    \"color_mode\": \"256\",
    \"symbol\": \"{ccc}\",
    \"foreground\": \"&{ccc}\",
    \"background\": \"{{ccc}\",
    \"reset\": \"0;\",
    \"base\": 33
  }
  "
  echo importer.to_format(json)
  should.be_error(importer.to_format(json))
}

pub fn color_mode_missing_test() {
  let json =
    "{
    \"symbol\": \"{ccc}\",
    \"foreground\": \"&{ccc}\",
    \"background\": \"{{ccc}\",
    \"reset\": \"0;\",
    \"base\": 10
  }
  "
  echo importer.to_format(json)
  should.be_error(importer.to_format(json))
}

pub fn color_mode_invalid_test() {
  let json =
    "{
    \"color_mode\": \"Truecolor\",
    \"symbol\": \"{ccc}\",
    \"foreground\": \"&{ccc}\",
    \"background\": \"{{ccc}\",
    \"reset\": \"0;\",
    \"base\": 10
  }
  "
  echo importer.to_format(json)
  should.be_error(importer.to_format(json))
}
