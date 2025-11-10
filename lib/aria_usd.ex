# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd do
  @moduledoc """
  Standalone Elixir module for USD operations using Pythonx for AOUSD (Alliance for OpenUSD) operations via pxr.

  This module provides USD functionality for:
  - Creating and modifying USD prims and attributes
  - Composing USD layers
  - VRM to USD conversion (with VRM schema support)
  - USD to TSCN conversion
  - TSCN to USD conversion
  - Unity package import and conversion

  This module delegates to specialized sub-modules following the Single Responsibility Principle:
  - `AriaUsd.Pythonx` - Pythonx availability checking
  - `AriaUsd.Prim` - Prim operations (create, set_attribute, remove)
  - `AriaUsd.Layer` - Layer composition
  - `AriaUsd.Vrm` - VRM conversion
  - `AriaUsd.Tscn` - TSCN conversion
  - `AriaUsd.Unity` - Unity conversion
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

  # Delegate to Pythonx module
  @doc """
  Checks if Pythonx is available and working.
  Returns :ok if available, :mock if not.
  """
  @spec ensure_pythonx() :: :ok | :mock
  defdelegate ensure_pythonx(), to: AriaUsd.Pythonx

  # Delegate to Prim module
  @doc """
  Creates a new prim.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path for the new prim
    - prim_type: Type of prim (default: "Xform")

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_prim(String.t(), String.t(), String.t()) :: usd_result()
  defdelegate create_prim(file_path, prim_path, prim_type \\ "Xform"), to: AriaUsd.Prim

  @doc """
  Sets an attribute value on a prim.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - attr_name: Name of attribute
    - attr_value: Value to set (as string, will be parsed)

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_attribute(String.t(), String.t(), String.t(), String.t()) :: usd_result()
  defdelegate set_attribute(file_path, prim_path, attr_name, attr_value), to: AriaUsd.Prim

  @doc """
  Removes a prim from the stage.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim to remove

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec remove_prim(String.t(), String.t()) :: usd_result()
  defdelegate remove_prim(file_path, prim_path), to: AriaUsd.Prim

  # Delegate to Layer module
  @doc """
  Composes layers in USD.

  ## Parameters
    - base_file: Path to base USD file
    - layer_file: Path to layer file to compose
    - output_file: Path to output composed file

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec compose_layer(String.t(), String.t(), String.t()) :: usd_result()
  defdelegate compose_layer(base_file, layer_file, output_file), to: AriaUsd.Layer

  # Delegate to Vrm module
  @doc """
  Converts VRM to USD (one-way, transmission format to internal format).

  ## Parameters
    - vrm_path: Path to VRM file
    - output_usd_path: Path to output USD file
    - opts: Optional keyword list with :vrm_extensions and :vrm_metadata for preserving VRM data

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec vrm_to_usd(String.t(), String.t(), keyword()) :: usd_result()
  defdelegate vrm_to_usd(vrm_path, output_usd_path, opts \\ []), to: AriaUsd.Vrm

  # Delegate to Tscn module
  @doc """
  Converts USD to Godot TSCN. TSCN is Godot's internal format, but USD ↔ TSCN conversion has loss due to different scene graph representations.

  ## Parameters
    - usd_path: Path to USD file
    - output_tscn_path: Path to output TSCN file

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec usd_to_tscn(String.t(), String.t()) :: usd_result()
  defdelegate usd_to_tscn(usd_path, output_tscn_path), to: AriaUsd.Tscn

  @doc """
  Converts Godot TSCN to USD. TSCN is Godot's internal format, but USD ↔ TSCN conversion has loss due to different scene graph representations.

  ## Parameters
    - tscn_path: Path to TSCN file
    - output_usd_path: Path to output USD file
    - opts: Optional keyword list with :tscn_data for pre-parsed TSCN data

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec tscn_to_usd(String.t(), String.t(), keyword()) :: usd_result()
  defdelegate tscn_to_usd(tscn_path, output_usd_path, opts \\ []), to: AriaUsd.Tscn

  # Delegate to Unity module
  @doc """
  Converts USD to Unity package (.unitypackage) format.
  This is a lower-loss conversion compared to other transmission formats.

  ## Parameters
    - usd_path: Path to USD file
    - output_unitypackage_path: Path to output .unitypackage file

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec usd_to_unity_package(String.t(), String.t()) :: usd_result()
  defdelegate usd_to_unity_package(usd_path, output_unitypackage_path), to: AriaUsd.Unity

  @doc """
  Converts Unity assets to USD format.
  Uses unidot_importer via Godot or direct conversion.

  ## Parameters
    - unity_asset_path: Path to Unity asset file or directory
    - output_usd_path: Path to output USD file

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec convert_unity_to_usd(String.t(), String.t()) :: usd_result()
  defdelegate convert_unity_to_usd(unity_asset_path, output_usd_path), to: AriaUsd.Unity

  @doc """
  Imports a Unity package (.unitypackage) file.
  Uses unidot_importer via Godot headless mode or Python-based Unity package parser.

  ## Parameters
    - unitypackage_path: Path to .unitypackage file
    - output_dir: Directory to extract/import to

  ## Returns
    - `{:ok, String.t()}` - Success message with import details
    - `{:error, String.t()}` - Error message
  """
  @spec import_unity_package(String.t(), String.t()) :: usd_result()
  defdelegate import_unity_package(unitypackage_path, output_dir), to: AriaUsd.Unity
end
