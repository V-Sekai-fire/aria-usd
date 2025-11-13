# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd do
  @moduledoc """
  Standalone Elixir module for USD operations using Pythonx for AOUSD (Alliance for OpenUSD) operations via pxr.

  This module provides core USD functionality for:
  - Creating and modifying USD prims and attributes
  - Composing USD layers
  - Stage operations (create, open, save)
  - Mesh primitive operations
  - Variant set management

  Format conversion modules (VRM, TSCN, Unity) are available as separate packages.

  This module delegates to specialized sub-modules following the Single Responsibility Principle:
  - `AriaUsd.Pythonx` - Pythonx availability checking
  - `AriaUsd.Stage` - Stage operations (create, open, save)
  - `AriaUsd.Prim` - Prim operations (create, set_attribute, remove)
  - `AriaUsd.Mesh` - Mesh primitive operations (create, set points/faces/normals)
  - `AriaUsd.VariantSet` - Variant set operations (create, add variant, set selection)
  - `AriaUsd.Layer` - Layer composition

  Note: Format conversion modules (VRM, TSCN, Unity) have been moved to separate packages:
  - `aria_usd_vrm` - VRM to USD conversion
  - `aria_usd_tscn` - TSCN ↔ USD conversion
  - `aria_usd_unity` - Unity ↔ USD conversion
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

  # Delegate to Pythonx module
  @doc """
  Checks if Pythonx is available and working.
  Returns :ok if available, :mock if not.
  """
  @spec ensure_pythonx() :: :ok | :mock
  defdelegate ensure_pythonx(), to: AriaUsd.Pythonx

  # Delegate to Stage module
  @doc """
  Creates a new USD stage.

  ## Parameters
    - file_path: Path to USD file to create

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_stage(String.t()) :: usd_result()
  defdelegate create_stage(file_path), to: AriaUsd.Stage

  @doc """
  Opens an existing USD stage.

  ## Parameters
    - file_path: Path to USD file to open

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec open_stage(String.t()) :: usd_result()
  defdelegate open_stage(file_path), to: AriaUsd.Stage

  @doc """
  Saves a USD stage to file.

  ## Parameters
    - file_path: Path to USD file to save

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec save_stage(String.t()) :: usd_result()
  defdelegate save_stage(file_path), to: AriaUsd.Stage

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
  Sets an attribute value on a prim with optional type specification.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - attr_name: Name of attribute
    - attr_value: Value to set
    - attr_type: Type of attribute (optional, defaults to :string)
      - `:string`, `:int`, `:float`, `:vec3f_array`, `:int_array`, `:float_array`

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_attribute(String.t(), String.t(), String.t(), term(), atom()) :: usd_result()
  defdelegate set_attribute(file_path, prim_path, attr_name, attr_value, attr_type \\ :string),
    to: AriaUsd.Prim

  @doc """
  Creates a typed attribute on a prim with explicit type specification.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - attr_name: Name of attribute
    - attr_type: Type of attribute
    - attr_value: Value to set

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_typed_attribute(String.t(), String.t(), String.t(), atom(), term()) ::
          usd_result()
  defdelegate create_typed_attribute(file_path, prim_path, attr_name, attr_type, attr_value),
    to: AriaUsd.Prim

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

  # Delegate to Mesh module
  @doc """
  Creates a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path for the new mesh prim
    - opts: Optional keyword list

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_mesh(String.t(), String.t(), keyword()) :: usd_result()
  defdelegate create_mesh(file_path, prim_path, opts \\ []), to: AriaUsd.Mesh

  @doc """
  Sets vertex positions (points) on a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to mesh prim
    - points: List of {x, y, z} tuples representing vertex positions

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_mesh_points(String.t(), String.t(), [{float(), float(), float()}]) :: usd_result()
  defdelegate set_mesh_points(file_path, prim_path, points), to: AriaUsd.Mesh

  @doc """
  Sets face connectivity on a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to mesh prim
    - face_vertex_indices: Flat list of vertex indices for all faces
    - face_vertex_counts: List of vertex counts per face

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_mesh_faces(String.t(), String.t(), [integer()], [integer()]) :: usd_result()
  defdelegate set_mesh_faces(file_path, prim_path, face_vertex_indices, face_vertex_counts),
    to: AriaUsd.Mesh

  @doc """
  Sets vertex normals on a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to mesh prim
    - normals: List of {x, y, z} tuples representing vertex normals

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_mesh_normals(String.t(), String.t(), [{float(), float(), float()}]) :: usd_result()
  defdelegate set_mesh_normals(file_path, prim_path, normals), to: AriaUsd.Mesh

  # Delegate to VariantSet module
  @doc """
  Creates a variant set on a prim.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim that will have the variant set
    - variant_set_name: Name of the variant set

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_variant_set(String.t(), String.t(), String.t()) :: usd_result()
  defdelegate create_variant_set(file_path, prim_path, variant_set_name), to: AriaUsd.VariantSet

  @doc """
  Gets an existing variant set on a prim.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - variant_set_name: Name of the variant set

  ## Returns
    - `{:ok, String.t()}` - Success message if variant set exists
    - `{:error, String.t()}` - Error message if not found
  """
  @spec get_variant_set(String.t(), String.t(), String.t()) :: usd_result()
  defdelegate get_variant_set(file_path, prim_path, variant_set_name), to: AriaUsd.VariantSet

  @doc """
  Sets the active variant selection for a variant set.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - variant_set_name: Name of the variant set
    - variant_name: Name of the variant to select

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_variant_selection(String.t(), String.t(), String.t(), String.t()) :: usd_result()
  defdelegate set_variant_selection(file_path, prim_path, variant_set_name, variant_name),
    to: AriaUsd.VariantSet

  @doc """
  Adds a variant to a variant set and executes operations within that variant's edit context.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - variant_set_name: Name of the variant set
    - variant_name: Name of the variant to add
    - callback_fn: Function that returns Python code string to execute within variant context

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec add_variant(String.t(), String.t(), String.t(), String.t(), (-> String.t())) ::
          usd_result()
  defdelegate add_variant(file_path, prim_path, variant_set_name, variant_name, callback_fn),
    to: AriaUsd.VariantSet

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
end
