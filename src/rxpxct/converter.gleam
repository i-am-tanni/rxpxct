import gleam/int
import gleam/list
import gleam/pair
import gleam/string
import glearray
import rxpxct/color.{type Color, Color, Color16, Color256, TrueColor}
import rxpxct/format.{type Format, Format16, Format256, FormatTrue}
import rxpxct/parser.{type Token, Ascii, Background, Foreground}

pub fn run(lines: List(List(Token)), format: Format) -> List(String) {
  lines
  |> minimize_color_codes()
  |> list.flatten()
  |> to_string(format)
}

fn minimize_color_codes(tokens: List(List(Token))) -> List(List(Token)) {
  list.map_fold(tokens, #(Color, Color), fn(acc, chunk) {
    let #(last_fgd, last_bkg) = acc
    case chunk {
      [Foreground(fgd), Background(bkg), ascii] -> {
        case fgd == last_fgd, bkg == last_bkg {
          True, True -> {
            #(acc, [ascii])
          }

          True, False -> {
            let acc = #(last_fgd, bkg)
            #(acc, [Background(bkg), ascii])
          }

          False, True -> {
            let acc = #(fgd, last_bkg)
            #(acc, [Foreground(fgd), ascii])
          }

          False, False -> {
            let acc = #(fgd, bkg)
            #(acc, chunk)
          }
        }
      }
      no_change -> #(acc, no_change)
    }
  })
  |> pair.second()
}

fn to_string(tokens: List(Token), format: Format) -> List(String) {
  list.map(tokens, fn(token) {
    case token {
      Ascii(ascii) -> string.from_utf_codepoints([ascii])
      Foreground(foreground) -> foreground_to_string(foreground, format)
      Background(background) -> background_to_string(background, format)
    }
  })
}

fn foreground_to_string(color: Color, format: Format) -> String {
  case format {
    FormatTrue(r: r_pattern, g: g_pattern, b: b_pattern, foreground: s, ..) -> {
      let assert TrueColor(red: r, green: g, blue: b) = color

      s
      |> string.replace(r_pattern, int.to_string(r))
      |> string.replace(g_pattern, int.to_string(g))
      |> string.replace(b_pattern, int.to_string(b))
    }

    Format256(symbol: pattern, foreground: s, lookups: lookups, ..) -> {
      let assert [q2c] = lookups
      let assert Color256(color_code) = color.downsample256(color, with: q2c)
      string.replace(s, pattern, int.to_string(color_code))
    }

    Format16(
      symbol: pattern,
      pattern: s,
      foreground: foreground_codes,
      lookups: lookups,
      ..,
    ) -> {
      let assert [q2c, code256to16] = lookups
      let assert Color16(code16) =
        color
        |> color.downsample256(with: q2c)
        |> color.downsample16(with: code256to16)

      let assert Ok(replacement) = glearray.get(foreground_codes, code16)
      string.replace(s, pattern, replacement)
    }
  }
}

fn background_to_string(color: Color, format: Format) -> String {
  case format {
    FormatTrue(r: r_pattern, g: g_pattern, b: b_pattern, foreground: s, ..) -> {
      let assert TrueColor(red: r, green: g, blue: b) = color

      s
      |> string.replace(r_pattern, int.to_string(r))
      |> string.replace(g_pattern, int.to_string(g))
      |> string.replace(b_pattern, int.to_string(b))
    }

    Format256(symbol: pattern, background: s, lookups: lookups, ..) -> {
      let assert [q2c] = lookups
      let assert Color256(color_code) = color.downsample256(color, with: q2c)
      string.replace(s, pattern, int.to_string(color_code))
    }

    Format16(
      symbol: pattern,
      pattern: s,
      background: background_codes,
      lookups: lookups,
      ..,
    ) -> {
      let assert [q2c, code256to16] = lookups
      let assert Color16(code16) =
        color
        |> color.downsample256(with: q2c)
        |> color.downsample16(with: code256to16)

      let assert Ok(replacement) = glearray.get(background_codes, code16)
      string.replace(s, pattern, replacement)
    }
  }
}
