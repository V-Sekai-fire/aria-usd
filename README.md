# AriaUsd

Standalone Elixir module for USD operations using Pythonx for AOUSD (Alliance for OpenUSD) operations via pxr.

## Overview

AriaUsd provides USD functionality for:
- Creating and modifying USD prims and attributes
- Composing USD layers
- VRM to USD conversion (with VRM schema support)
- USD to TSCN conversion
- TSCN to USD conversion
- Unity package import and conversion

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

# Convert VRM to USD
AriaUsd.vrm_to_usd("model.vrm", "output.usd", 
  vrm_extensions: extensions,
  vrm_metadata: metadata
)

# Convert USD to TSCN
AriaUsd.usd_to_tscn("model.usd", "output.tscn")
```

## USD Schema Plugin

The module includes a USD schema plugin for preserving VRM-specific data in USD files. The plugin is located at `priv/plugins/dcc_mcp_vrm/` and provides the `VrmAPI` schema for storing VRM extensions and metadata.

## Requirements

- Elixir ~> 1.18
- Pythonx ~> 0.4.0 (for Python/USD integration)
- USD Python bindings (pxr)

## License

MIT

