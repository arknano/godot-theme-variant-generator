# Theme Variant Generator
[![Licence](https://img.shields.io/badge/license-MIT-red.svg)](https://github.com/arknano/godot-theme-variant-generator/blob/main/LICENSE)
[![Godot version](https://img.shields.io/badge/Godot%20Engine-4.5.1-blue.svg)](https://github.com/godotengine/godot/)

Godot editor plugin for generating theme variants from a template by grabbing unique colours and replacing them with new colours.

It is aimed at workflows where you already have a hand-authored theme resource and want to create alternate colourways without manually editing every repeated colour entry.

<img width="491" height="653" alt="{A6403AC2-7B8D-4A8B-8334-F999F2B57DFF}" src="https://github.com/user-attachments/assets/2d924119-e3c3-4224-a365-66f7dddd2e9b" />


## Features

- Scans a theme file for unique colours
- Shows each discovered source colour in an editor dock
- Lets you assign replacement colours to create a variant
- Writes a new variant theme file with every matching colour replaced
- Can load colours back from an existing variant to reuse a palette


## Installation

1. Copy the `theme_generator` addon folder into your project under `addons/`.
2. In Godot, open `Project > Project Settings > Plugins`.
3. Enable `Theme Variant Generator`.

After enabling, the plugin appears as a dock on the right side of the editor.

## Usage

1. Set `Theme Template File` to the source theme resource you want to scan.
2. Click `Scan Colours`.
3. Adjust the replacement colours shown in the dock.
4. Set `Target Theme Variant File` to the output path.
5. Click `Generate Variant`.

If you already have a generated variant and want to reuse its palette:

1. Scan the original template first.
2. Set `Target Theme Variant File` to the existing variant.
3. Click `Load Colours from Variant`.
