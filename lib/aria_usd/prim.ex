# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.Prim do
  @moduledoc """
  Operations for creating, modifying, and removing USD prims.
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

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
  def create_prim(file_path, prim_path, prim_type \\ "Xform")
      when is_binary(file_path) and is_binary(prim_path) and is_binary(prim_type) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_create_prim(file_path, prim_path, prim_type)
      :mock -> mock_create_prim(file_path, prim_path, prim_type)
    end
  end

  defp mock_create_prim(file_path, prim_path, prim_type) do
    {:ok, "Mock created #{prim_type} prim at #{prim_path} in #{file_path}"}
  end

  defp do_create_prim(file_path, prim_path, prim_type) do
    code = """
    from pxr import Usd

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        # Create new stage if file doesn't exist
        stage = Usd.Stage.CreateNew('#{file_path}')

    prim = stage.DefinePrim('#{prim_path}', '#{prim_type}')
    if prim:
        stage.GetRootLayer().Save()
        result = f"Created {prim_type} prim at {prim.GetPath()}"
    else:
        result = "Failed to create prim"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode create_prim result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def set_attribute(file_path, prim_path, attr_name, attr_value)
      when is_binary(file_path) and is_binary(prim_path) and is_binary(attr_name) and
             is_binary(attr_value) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_set_attribute(file_path, prim_path, attr_name, attr_value)
      :mock -> mock_set_attribute(file_path, prim_path, attr_name, attr_value)
    end
  end

  defp mock_set_attribute(file_path, prim_path, attr_name, attr_value) do
    {:ok, "Mock set attribute #{attr_name} = #{attr_value} on #{prim_path} in #{file_path}"}
  end

  defp do_set_attribute(file_path, prim_path, attr_name, attr_value) do
    code = """
    from pxr import Usd

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    prim = stage.GetPrimAtPath('#{prim_path}')
    if not prim:
        raise ValueError(f"Prim not found at path {prim_path}")

    attr = prim.GetAttribute('#{attr_name}')
    if not attr:
        # Create attribute if it doesn't exist
        from pxr import Sdf
        attr = prim.CreateAttribute('#{attr_name}', Sdf.ValueTypeNames.String)

    # TODO: 2025-11-09 fire - Try to set the value (simplified - in practice would need type conversion)
    attr.Set('#{attr_value}')
    stage.GetRootLayer().Save()
    result = f"Set attribute {attr.GetName()} = {attr.Get()} on {prim.GetPath()}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode set_attribute result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def remove_prim(file_path, prim_path) when is_binary(file_path) and is_binary(prim_path) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_remove_prim(file_path, prim_path)
      :mock -> mock_remove_prim(file_path, prim_path)
    end
  end

  defp mock_remove_prim(file_path, prim_path) do
    {:ok, "Mock removed prim at #{prim_path} from #{file_path}"}
  end

  defp do_remove_prim(file_path, prim_path) do
    code = """
    from pxr import Usd

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    prim = stage.GetPrimAtPath('#{prim_path}')
    if prim:
        stage.RemovePrim('#{prim_path}')
        stage.GetRootLayer().Save()
        result = f"Removed prim at {prim_path}"
    else:
        result = f"Prim not found at path {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode remove_prim result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end

