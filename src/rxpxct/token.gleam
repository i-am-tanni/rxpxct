import rxpxct/color.{type Color}

pub type Token {
  Foreground(Color)
  Background(Color)
  Ascii(Int)
  Newline
}
