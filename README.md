# AriaUsd

Standalone Elixir module for USD operations using Pythonx for AOUSD (Alliance for OpenUSD) operations via pxr.

## Overview

AriaUsd provides core USD functionality for:
- Creating and modifying USD prims and attributes
- Composing USD layers
- Stage operations (create, open, save)
- Mesh primitive operations
- Variant set management

Format conversion modules (VRM, TSCN, Unity) are available as separate packages:
- `aria_usd_vrm` - VRM to USD conversion
- `aria_usd_tscn` - TSCN ↔ USD conversion  
- `aria_usd_unity` - Unity ↔ USD conversion

## Installation

Add `aria_usd` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_usd, git: "https://github.com/V-Sekai-fire/aria-usd.git"}
  ]
end
```

Or use a local path dependency:

```elixir
def deps do
  [
    {:aria_usd, path: "/path/to/aria_usd"}
  ]
end
```

## Usage

```elixir
# Create a prim
AriaUsd.create_prim("stage.usd", "/MyPrim", "Xform")

# Create a mesh primitive
AriaUsd.create_mesh("stage.usd", "/MyMesh")

# Set mesh points
AriaUsd.set_mesh_points("stage.usd", "/MyMesh", [{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}])

# Create variant set
AriaUsd.create_variant_set("stage.usd", "/Root", "meshTopology")
```

## Format Conversion Packages

Format conversion modules have been extracted into separate packages:
- **aria_usd_vrm** - VRM to USD conversion (includes VRM schema plugin)
- **aria_usd_tscn** - TSCN ↔ USD conversion for Godot integration
- **aria_usd_unity** - Unity ↔ USD conversion

These packages depend on `aria_usd` for core USD operations.

## Requirements

- Elixir ~> 1.18
- Pythonx ~> 0.4.0 (for Python/USD integration)
- USD Python bindings (pxr)

## License

MIT

