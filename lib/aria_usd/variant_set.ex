# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.VariantSet do
  @moduledoc """
  Operations for creating and managing USD variant sets.
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

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
  def create_variant_set(file_path, prim_path, variant_set_name)
      when is_binary(file_path) and is_binary(prim_path) and is_binary(variant_set_name) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_create_variant_set(file_path, prim_path, variant_set_name)
      :mock -> mock_create_variant_set(file_path, prim_path, variant_set_name)
    end
  end

  defp mock_create_variant_set(file_path, prim_path, variant_set_name) do
    {:ok,
     "Mock created variant set '#{variant_set_name}' on prim at #{prim_path} in #{file_path}"}
  end

  defp do_create_variant_set(file_path, prim_path, variant_set_name) do
    # variant_set_name is used in Python code string interpolation below
    _ = variant_set_name

    code = """
    from pxr import Usd, Sdf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        # Create new stage if file doesn't exist
        stage = Usd.Stage.CreateNew('#{file_path}')

    prim = stage.GetPrimAtPath('#{prim_path}')
    if not prim:
        raise ValueError(f"Prim not found at path {prim_path}")

    variant_set = Usd.VariantSet.Define(stage, Sdf.Path('#{prim_path}'))
    if variant_set:
        stage.GetRootLayer().Save()
        result = f"Created variant set '#{variant_set_name}' on prim at {prim_path}"
    else:
        result = f"Failed to create variant set '#{variant_set_name}'"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode create_variant_set result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def get_variant_set(file_path, prim_path, variant_set_name)
      when is_binary(file_path) and is_binary(prim_path) and is_binary(variant_set_name) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_get_variant_set(file_path, prim_path, variant_set_name)
      :mock -> mock_get_variant_set(file_path, prim_path, variant_set_name)
    end
  end

  defp mock_get_variant_set(file_path, prim_path, variant_set_name) do
    {:ok, "Mock got variant set '#{variant_set_name}' on prim at #{prim_path} in #{file_path}"}
  end

  defp do_get_variant_set(file_path, prim_path, variant_set_name) do
    # variant_set_name is used in Python code string interpolation below
    _ = variant_set_name

    code = """
    from pxr import Usd, Sdf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    prim = stage.GetPrimAtPath('#{prim_path}')
    if not prim:
        raise ValueError(f"Prim not found at path {prim_path}")

    variant_set = Usd.VariantSet.Get(stage, Sdf.Path('#{prim_path}'))
    if variant_set:
        result = f"Found variant set '#{variant_set_name}' on prim at {prim_path}"
    else:
        result = f"Variant set '#{variant_set_name}' not found on prim at {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode get_variant_set result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def set_variant_selection(file_path, prim_path, variant_set_name, variant_name)
      when is_binary(file_path) and is_binary(prim_path) and
             is_binary(variant_set_name) and is_binary(variant_name) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_set_variant_selection(file_path, prim_path, variant_set_name, variant_name)
      :mock -> mock_set_variant_selection(file_path, prim_path, variant_set_name, variant_name)
    end
  end

  defp mock_set_variant_selection(file_path, prim_path, variant_set_name, variant_name) do
    {:ok,
     "Mock set variant selection to '#{variant_name}' in variant set '#{variant_set_name}' on prim at #{prim_path} in #{file_path}"}
  end

  defp do_set_variant_selection(file_path, prim_path, variant_set_name, variant_name) do
    # variant_set_name is used in Python code string interpolation below
    _ = variant_set_name

    code = """
    from pxr import Usd, Sdf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    prim = stage.GetPrimAtPath('#{prim_path}')
    if not prim:
        raise ValueError(f"Prim not found at path {prim_path}")

    variant_set = Usd.VariantSet.Get(stage, Sdf.Path('#{prim_path}'))
    if not variant_set:
        # Create variant set if it doesn't exist
        variant_set = Usd.VariantSet.Define(stage, Sdf.Path('#{prim_path}'))

    variant_set.SetVariantSelection('#{variant_name}')
    stage.GetRootLayer().Save()
    result = f"Set variant selection to '#{variant_name}' in variant set '#{variant_set_name}' on prim at {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode set_variant_selection result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Adds a variant to a variant set and executes operations within that variant's edit context.

  This function creates or gets a variant set, adds a new variant, and executes
  the provided callback function within the variant's edit context. The callback
  receives the file_path and prim_path and should return operations to perform
  within the variant context.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - variant_set_name: Name of the variant set
    - variant_name: Name of the variant to add
    - callback_fn: Function that returns a list of operations to perform (as Python code string)

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message

  ## Example
      AriaUsd.VariantSet.add_variant("stage.usd", "/Root", "meshTopology", "original", fn ->
        \"\"\"
        # Create mesh prim
        mesh_prim = UsdGeom.Mesh.Define(stage, "/MyMesh")
        # ... more operations
        \"\"\"
      end)
  """
  @spec add_variant(String.t(), String.t(), String.t(), String.t(), (-> String.t())) ::
          usd_result()
  def add_variant(file_path, prim_path, variant_set_name, variant_name, callback_fn)
      when is_binary(file_path) and is_binary(prim_path) and
             is_binary(variant_set_name) and is_binary(variant_name) and
             is_function(callback_fn, 0) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_add_variant(file_path, prim_path, variant_set_name, variant_name, callback_fn)
      :mock -> mock_add_variant(file_path, prim_path, variant_set_name, variant_name)
    end
  end

  defp mock_add_variant(file_path, prim_path, variant_set_name, variant_name) do
    {:ok,
     "Mock added variant '#{variant_name}' to variant set '#{variant_set_name}' on prim at #{prim_path} in #{file_path}"}
  end

  defp do_add_variant(file_path, prim_path, variant_set_name, variant_name, callback_fn) do
    # variant_set_name is used in Python code string interpolation below
    _ = variant_set_name

    # Get the callback code
    variant_code = callback_fn.()

    code = """
    from pxr import Usd, Sdf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        # Create new stage if file doesn't exist
        stage = Usd.Stage.CreateNew('#{file_path}')

    prim = stage.GetPrimAtPath('#{prim_path}')
    if not prim:
        raise ValueError(f"Prim not found at path {prim_path}")

    # Get or create variant set
    variant_set = Usd.VariantSet.Get(stage, Sdf.Path('#{prim_path}'))
    if not variant_set:
        variant_set = Usd.VariantSet.Define(stage, Sdf.Path('#{prim_path}'))

    # Add variant and execute operations within variant edit context
    with variant_set.GetVariantEditContext('#{variant_name}'):
        #{variant_code}

    stage.GetRootLayer().Save()
    result = f"Added variant '{variant_name}' to variant set '{variant_set_name}' on prim at {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode add_variant result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end
