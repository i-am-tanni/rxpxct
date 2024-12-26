import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import glearray
import rxpxct/color.{type Color, Color, Color16, Color256, TrueColor}
import rxpxct/format.{type Format, Format16, Format256, FormatTrue}
import rxpxct/parser.{type Token, Ascii, Background, Foreground}

pub fn run(lines: List(List(Token)), format: Format) -> List(String) {
  let reset = case format {
    FormatTrue(reset: reset, ..) -> reset
    Format256(reset: reset, ..) -> reset
    Format16(reset: reset, ..) -> reset
  }

  lines
  |> minimize_color_codes()
  |> list.flatten()
  |> to_string(format)
  |> list.prepend(reset)
  |> list.append([reset])
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
    FormatTrue(
      r: r_pattern,
      g: g_pattern,
      b: b_pattern,
      foreground: s,
      base: base,
      ..,
    ) -> {
      let assert TrueColor(red: r, green: g, blue: b) = color
      let pad_count = max_repeating(r_pattern)

      s
      |> string.replace(r_pattern, stringify(r, base, pad_count))
      |> string.replace(g_pattern, stringify(g, base, pad_count))
      |> string.replace(b_pattern, stringify(b, base, pad_count))
    }

    Format256(symbol: pattern, foreground: s, lookups: lookups, base: base, ..) -> {
      let assert [q2c] = lookups
      let assert Color256(color_code) = color.downsample256(color, with: q2c)
      let pad_count = max_repeating(pattern)
      string.replace(s, pattern, stringify(color_code, base, pad_count))
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
    FormatTrue(
      r: r_pattern,
      g: g_pattern,
      b: b_pattern,
      foreground: s,
      base: base,
      ..,
    ) -> {
      let assert TrueColor(red: r, green: g, blue: b) = color
      let pad_count = max_repeating(r_pattern)

      s
      |> string.replace(r_pattern, stringify(r, base, pad_count))
      |> string.replace(g_pattern, stringify(g, base, pad_count))
      |> string.replace(b_pattern, stringify(b, base, pad_count))
    }

    Format256(symbol: pattern, background: s, lookups: lookups, base: base, ..) -> {
      let assert [q2c] = lookups
      let assert Color256(color_code) = color.downsample256(color, with: q2c)
      let pad_count = max_repeating(pattern)
      string.replace(s, pattern, stringify(color_code, base, pad_count))
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

fn max_repeating(s: String) -> Int {
  string.to_graphemes(s)
  |> list.fold(dict.new(), fn(acc, g) {
    case dict.get(acc, g) {
      Ok(x) -> dict.insert(acc, g, x + 1)
      Error(_) -> dict.insert(acc, g, 1)
    }
  })
  |> dict.values()
  |> list.max(int.compare)
  |> result.unwrap(0)
}

fn stringify(x: Int, base: Int, pad_count: Int) -> String {
  let assert Ok(x) = int.to_base_string(x, base)
  string.pad_start(x, pad_count, "0")
}
