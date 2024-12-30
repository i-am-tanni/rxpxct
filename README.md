# rxpxct - REXPaint Export Conversion Tool

## Purpose

REXPaint by Kyzrati is a super useful tool for creating ascii art.
The problem is the exports cannot be immediately used for display 
in Multi-User Dungeons (MUDs), which often require a custom color format.

The purpose of this tool is to convert a REXPaint cp437 encoded xml export
to the unicode to the custom format a game needs for color display.

Naturally this can be extended to any scenario that requires converting
a REXPaint export to an alternative format.

## To Run

```sh
gleam run ./path/to/rexpaint_export.xml ./path/to/format.json
```

The output is saved to the xml path as a *.txt file.

## Color Formats

Several common color formats are provided for immediate use under `/formats/`:

- ansi_16
- ansi_256
- ansi_trucolor
- fansi256

And some game specific formats:

- Astaria (256)
- Lumen et Umbra (Truecolor)

Supports color formats in 16, xterm 256, and 24 Bit (Truecolor).

Adding a new format should be relatively straitforward following the examples
in the folder above.

For substitutions, repeated color symbols will add leading zeros for the final result.

## Contact

If you would like to have your game's format included in this tool,
please feel free to reach out or submit a pull request.