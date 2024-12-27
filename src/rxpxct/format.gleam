import glearray.{type Array}

pub type Format {
  Format256(
    reset: String,
    symbol: String,
    foreground: String,
    background: String,
    base: Int,
    lookups: List(Array(Int)),
  )

  FormatTrue(
    reset: String,
    r: String,
    g: String,
    b: String,
    foreground: String,
    background: String,
    base: Int,
  )

  Format16(
    reset: String,
    symbol: String,
    pattern: String,
    foreground: Array(String),
    background: Array(String),
    lookups: List(Array(Int)),
  )
}
