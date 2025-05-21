//// Defines color types and functions for converting color types to
//// downsampled color types.
//// 

import gleam/bool
import rxpxct/array.{type Array}

pub type Color {
  TrueColor(red: Int, green: Int, blue: Int)
  Color256(Int)
  Color16(Int)
  Color
}

/// lookup table for downsampling 24 bit truecolor to 256 colors
pub fn generate_q2c() -> Array(Int) {
  [0x00, 0x5f, 0x87, 0xaf, 0xd7, 0xff]
  |> array.from_list()
}

/// lookup table for downsampling xterm 256 colors to 16 colors
pub fn generate_code256to16() -> Array(Int) {
  [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0, 4, 4, 4, 12, 12, 2,
    6, 4, 4, 12, 12, 2, 2, 6, 4, 12, 12, 2, 2, 2, 6, 12, 12, 10, 10, 10, 10, 14,
    12, 10, 10, 10, 10, 10, 14, 1, 5, 4, 4, 12, 12, 3, 8, 4, 4, 12, 12, 2, 2, 6,
    4, 12, 12, 2, 2, 2, 6, 12, 12, 10, 10, 10, 10, 14, 12, 10, 10, 10, 10, 10,
    14, 1, 1, 5, 4, 12, 12, 1, 1, 5, 4, 12, 12, 3, 3, 8, 4, 12, 12, 2, 2, 2, 6,
    12, 12, 10, 10, 10, 10, 14, 12, 10, 10, 10, 10, 10, 14, 1, 1, 1, 5, 12, 12,
    1, 1, 1, 5, 12, 12, 1, 1, 1, 5, 12, 12, 3, 3, 3, 7, 12, 12, 10, 10, 10, 10,
    14, 12, 10, 10, 10, 10, 10, 14, 9, 9, 9, 9, 13, 12, 9, 9, 9, 9, 13, 12, 9, 9,
    9, 9, 13, 12, 9, 9, 9, 9, 13, 12, 11, 11, 11, 11, 7, 12, 10, 10, 10, 10, 10,
    14, 9, 9, 9, 9, 9, 13, 9, 9, 9, 9, 9, 13, 9, 9, 9, 9, 9, 13, 9, 9, 9, 9, 9,
    13, 9, 9, 9, 9, 9, 13, 11, 11, 11, 11, 11, 15, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8,
    8, 8, 7, 7, 7, 7, 7, 7, 15, 15, 15, 15, 15, 15,
  ]
  |> array.from_list()
}

pub fn downsample256(color: Color, with q2c: Array(Int)) -> Color {
  let assert TrueColor(red: r, green: g, blue: b) = color
  let code256 = rgb_to_color256(r, g, b, with: q2c)
  Color256(code256)
}

pub fn downsample16(color: Color, with code256to16: Array(Int)) -> Color {
  let assert Color256(code256) = color
  let assert Ok(code16) = array.get(code256to16, code256)
  Color16(code16)
}

fn rgb_to_color256(r: Int, g: Int, b: Int, with q2c: Array(Int)) -> Int {
  let qr = color_to_6cube(r)
  let assert Ok(cr) = array.get(q2c, qr)
  let qg = color_to_6cube(g)
  let assert Ok(cg) = array.get(q2c, qg)
  let qb = color_to_6cube(b)
  let assert Ok(cb) = array.get(q2c, qb)

  case cr == r && cg == g && cb == b {
    True -> 16 + { 36 * qr } + { 6 * qg } + qb
    False -> {
      let grey_avg: Int = { r + g + b } / 3
      let grey_idx = case grey_avg > 238 {
        True -> 23
        False -> { grey_avg - 3 } / 10
      }
      let grey = 8 + { 10 * grey_idx }

      // Is grey or 6x6x6 colour closest?
      let d = color_dist_sq(cr, cg, cb, r, g, b)
      let idx = case color_dist_sq(grey, grey, grey, r, g, b) < d {
        True -> 232 + grey_idx
        False -> 16 + { 36 * qr } + { 6 * qg } + qb
      }
      idx
    }
  }
}

fn color_to_6cube(v: Int) -> Int {
  use <- bool.guard(v < 48, 0)
  use <- bool.guard(v < 114, 1)
  { v - 35 } / 40
}

fn color_dist_sq(r1: Int, g1: Int, b1: Int, r2: Int, g2: Int, b2: Int) -> Int {
  { r1 - r2 }
  * { r1 - r2 }
  + { g1 - g2 }
  * { g1 - g2 }
  + { b1 - b2 }
  * { b1 - b2 }
}
