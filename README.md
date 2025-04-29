# rxpxct - REXPaint Export Conversion Tool

## Purpose

REXPaint by Kyzrati is an app for creating ascii art.
This is a tool for converting REXPaint CP437 encoded xml exports
into unicode encoded text with the color format used by your game. 
The color format is defined in json. Color templates are provided under `/formats/`.

## To Run
```sh
gleam run ./path/to/rexpaint_export.xml ./path/to/format.json
```

The converted output is saved to the xml path as a '.txt' file.

## Color Formats

Several common color formats are provided for immediate use under `/formats/`:

- ansi_16
- ansi_256
- ansi_truecolor (rgb)
- fansi256

And some game specific formats:

- Astaria (256)
- Lumen et Umbra (Truecolor)
- Dei delle Ere (16 colors and 256)

Supports color formats in 16, xterm 256, and 24 Bit (Truecolor) wtih downsampling.

Adding a new format should be relatively straitforward following the examples
in the folder above.

For substitutions, repeated color symbols will add leading zeros to the final result.