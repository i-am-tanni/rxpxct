//// Code for converting parsed data to strings

import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import glearray
import rxpxct/color.{type Color, Color, Color16, Color256, TrueColor}
import rxpxct/format.{type Format, Format16, Format256, FormatTrue}
import rxpxct/token.{type Token}

pub fn run(lines: List(List(Token)), format: Format) -> List(String) {
  let reset = format.reset

  lines
  |> minimize_color_codes()
  |> list.flatten()
  |> to_string(format)
  |> list.prepend(reset)
  |> list.append([reset])
}

/// eliminates redundant color codes
fn minimize_color_codes(tokens: List(List(Token))) -> List(List(Token)) {
  list.map_fold(tokens, #(Color, Color), fn(acc, chunk) {
    let #(last_fgd, last_bkg) = acc
    case chunk {
      [token.Foreground(fgd), token.Background(bkg), ascii] -> {
        case fgd == last_fgd, bkg == last_bkg {
          True, True -> {
            #(acc, [ascii])
          }

          True, False -> {
            let acc = #(last_fgd, bkg)
            #(acc, [token.Background(bkg), ascii])
          }

          False, True -> {
            let acc = #(fgd, last_bkg)
            #(acc, [token.Foreground(fgd), ascii])
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
      token.Ascii(ascii) -> ascii_to_string(ascii)
      token.Foreground(foreground) -> foreground_to_string(foreground, format)
      token.Background(background) -> background_to_string(background, format)
      token.Newline -> "\r\n"
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
      |> string.replace(r_pattern, stringify_color_code(r, base, pad_count))
      |> string.replace(g_pattern, stringify_color_code(g, base, pad_count))
      |> string.replace(b_pattern, stringify_color_code(b, base, pad_count))
    }

    Format256(symbol: pattern, foreground: s, lookups: lookups, base: base, ..) -> {
      let assert [q2c] = lookups
      let assert Color256(color_code) = color.downsample256(color, with: q2c)
      let pad_count = max_repeating(pattern)
      string.replace(
        s,
        pattern,
        stringify_color_code(color_code, base, pad_count),
      )
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
      |> string.replace(r_pattern, stringify_color_code(r, base, pad_count))
      |> string.replace(g_pattern, stringify_color_code(g, base, pad_count))
      |> string.replace(b_pattern, stringify_color_code(b, base, pad_count))
    }

    Format256(symbol: pattern, background: s, lookups: lookups, base: base, ..) -> {
      let assert [q2c] = lookups
      let assert Color256(color_code) = color.downsample256(color, with: q2c)
      let pad_count = max_repeating(pattern)
      string.replace(
        s,
        pattern,
        stringify_color_code(color_code, base, pad_count),
      )
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

fn ascii_to_string(x: Int) -> String {
  let assert Ok(cp) = {
    use val <- result.try(cp437_to_unicode(x))
    string.utf_codepoint(val)
  }

  list.wrap(cp)
  |> string.from_utf_codepoints()
}

fn stringify_color_code(color_code: Int, base: Int, pad_count: Int) -> String {
  let assert Ok(x) = int.to_base_string(color_code, base)
  string.pad_start(x, pad_count, "0")
}

fn cp437_to_unicode(code: Int) -> Result(Int, Nil) {
  case code {
    x if x >= 0 && x < 0x80 -> Ok(x)
    0x80 -> Ok(0x00c7)
    0x81 -> Ok(0x00fc)
    0x82 -> Ok(0x00e9)
    0x83 -> Ok(0x00e2)
    0x84 -> Ok(0x00e4)
    0x85 -> Ok(0x00e0)
    0x86 -> Ok(0x00e5)
    0x87 -> Ok(0x00e7)
    0x88 -> Ok(0x00ea)
    0x89 -> Ok(0x00eb)
    0x8a -> Ok(0x00e8)
    0x8b -> Ok(0x00ef)
    0x8c -> Ok(0x00ee)
    0x8d -> Ok(0x00ec)
    0x8e -> Ok(0x00c4)
    0x8f -> Ok(0x00c5)
    0x90 -> Ok(0x00c9)
    0x91 -> Ok(0x00e6)
    0x92 -> Ok(0x00c6)
    0x93 -> Ok(0x00f4)
    0x94 -> Ok(0x00f6)
    0x95 -> Ok(0x00f2)
    0x96 -> Ok(0x00fb)
    0x97 -> Ok(0x00f9)
    0x98 -> Ok(0x00ff)
    0x99 -> Ok(0x00d6)
    0x9a -> Ok(0x00dc)
    0x9b -> Ok(0x00a2)
    0x9c -> Ok(0x00a3)
    0x9d -> Ok(0x00a5)
    0x9e -> Ok(0x20a7)
    0x9f -> Ok(0x0192)
    0xa0 -> Ok(0x00e1)
    0xa1 -> Ok(0x00ed)
    0xa2 -> Ok(0x00f3)
    0xa3 -> Ok(0x00fa)
    0xa4 -> Ok(0x00f1)
    0xa5 -> Ok(0x00d1)
    0xa6 -> Ok(0x00aa)
    0xa7 -> Ok(0x00ba)
    0xa8 -> Ok(0x00bf)
    0xa9 -> Ok(0x2310)
    0xaa -> Ok(0x00ac)
    0xab -> Ok(0x00bd)
    0xac -> Ok(0x00bc)
    0xad -> Ok(0x00a1)
    0xae -> Ok(0x00ab)
    0xaf -> Ok(0x00bb)
    0xb0 -> Ok(0x2591)
    0xb1 -> Ok(0x2592)
    0xb2 -> Ok(0x2593)
    0xb3 -> Ok(0x2502)
    0xb4 -> Ok(0x2524)
    0xb5 -> Ok(0x2561)
    0xb6 -> Ok(0x2562)
    0xb7 -> Ok(0x2556)
    0xb8 -> Ok(0x2555)
    0xb9 -> Ok(0x2563)
    0xba -> Ok(0x2551)
    0xbb -> Ok(0x2557)
    0xbc -> Ok(0x255d)
    0xbd -> Ok(0x255c)
    0xbe -> Ok(0x255b)
    0xbf -> Ok(0x2510)
    0xc0 -> Ok(0x2514)
    0xc1 -> Ok(0x2534)
    0xc2 -> Ok(0x252c)
    0xc3 -> Ok(0x251c)
    0xc4 -> Ok(0x2500)
    0xc5 -> Ok(0x253c)
    0xc6 -> Ok(0x255e)
    0xc7 -> Ok(0x255f)
    0xc8 -> Ok(0x255a)
    0xc9 -> Ok(0x2554)
    0xca -> Ok(0x2569)
    0xcb -> Ok(0x2566)
    0xcc -> Ok(0x2560)
    0xcd -> Ok(0x2550)
    0xce -> Ok(0x256c)
    0xcf -> Ok(0x2567)
    0xd0 -> Ok(0x2568)
    0xd1 -> Ok(0x2564)
    0xd2 -> Ok(0x2565)
    0xd3 -> Ok(0x2559)
    0xd4 -> Ok(0x2558)
    0xd5 -> Ok(0x2552)
    0xd6 -> Ok(0x2553)
    0xd7 -> Ok(0x256b)
    0xd8 -> Ok(0x256a)
    0xd9 -> Ok(0x2518)
    0xda -> Ok(0x250c)
    0xdb -> Ok(0x2588)
    0xdc -> Ok(0x2584)
    0xdd -> Ok(0x258c)
    0xde -> Ok(0x2590)
    0xdf -> Ok(0x2580)
    0xe0 -> Ok(0x03b1)
    0xe1 -> Ok(0x00df)
    0xe2 -> Ok(0x0393)
    0xe3 -> Ok(0x03c0)
    0xe4 -> Ok(0x03a3)
    0xe5 -> Ok(0x03c3)
    0xe6 -> Ok(0x00b5)
    0xe7 -> Ok(0x03c4)
    0xe8 -> Ok(0x03a6)
    0xe9 -> Ok(0x0398)
    0xea -> Ok(0x03a9)
    0xeb -> Ok(0x03b4)
    0xec -> Ok(0x221e)
    0xed -> Ok(0x03c6)
    0xee -> Ok(0x03b5)
    0xef -> Ok(0x2229)
    0xf0 -> Ok(0x2261)
    0xf1 -> Ok(0x00b1)
    0xf2 -> Ok(0x2265)
    0xf3 -> Ok(0x2264)
    0xf4 -> Ok(0x2320)
    0xf5 -> Ok(0x2321)
    0xf6 -> Ok(0x00f7)
    0xf7 -> Ok(0x2248)
    0xf8 -> Ok(0x00b0)
    0xf9 -> Ok(0x2219)
    0xfa -> Ok(0x00b7)
    0xfb -> Ok(0x221a)
    0xfc -> Ok(0x207f)
    0xfd -> Ok(0x00b2)
    0xfe -> Ok(0x25a0)
    0xff -> Ok(0x00a0)
    _ -> Error(Nil)
  }
}
