import glearray.{type Array}

pub type Format {
  Format256(
    symbol: String,
    foreground: String,
    background: String,
    reset: String,
    base: Int,
    lookups: List(Array(Int)),
  )

  FormatTrue(
    r: String,
    g: String,
    b: String,
    foreground: String,
    background: String,
    reset: String,
    base: Int,
  )

  Format16(
    symbol: String,
    pattern: String,
    reset: String,
    foreground: Array(String),
    background: Array(String),
    lookups: List(Array(Int)),
  )
}
