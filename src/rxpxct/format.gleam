import rxpxct/array.{type Array}

/// Color formatting information decoded from a json format specifier file.
/// See templates in /formats/.
/// 
pub type Format {
  /// True Color aka 24bit Color. REXpaint outputs this color format natively.
  /// 
  FormatTrue(
    foreground: String,
    background: String,
    reset: String,
    r_pattern: String,
    g_pattern: String,
    b_pattern: String,
    base: Int,
  )

  /// xterm 256 colors. This will be downsampled from true color.
  /// 
  Format256(
    foreground: String,
    background: String,
    reset: String,
    symbol: String,
    base: Int,
    lookups: List(Array(Int)),
  )

  /// 16 Colors. This will be downsampled from 256 colors.
  /// 
  Format16(
    foreground: String,
    background: String,
    reset: String,
    symbol: String,
    foreground_codes: Array(String),
    background_codes: Array(String),
    lookups: List(Array(Int)),
  )
}
