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
    - attr_type: Type of attribute (optional, defaults to :string)
      - `:string` - String attribute
      - `:int` - Integer attribute
      - `:float` - Float attribute
      - `:vec3f_array` - Array of Vec3f (for points/normals)
      - `:int_array` - Array of integers
      - `:float_array` - Array of floats

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_attribute(String.t(), String.t(), String.t(), term(), atom()) :: usd_result()
  def set_attribute(file_path, prim_path, attr_name, attr_value, attr_type \\ :string)
      when is_binary(file_path) and is_binary(prim_path) and is_binary(attr_name) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_set_attribute(file_path, prim_path, attr_name, attr_value, attr_type)
      :mock -> mock_set_attribute(file_path, prim_path, attr_name, attr_value, attr_type)
    end
  end

  defp mock_set_attribute(file_path, prim_path, attr_name, attr_value, attr_type) do
    {:ok,
     "Mock set attribute #{attr_name} (#{attr_type}) = #{inspect(attr_value)} on #{prim_path} in #{file_path}"}
  end

  defp do_set_attribute(file_path, prim_path, attr_name, attr_value, attr_type) do
    {type_name, value_code} = build_attribute_type_and_value(attr_type, attr_value)

    code = """
    from pxr import Usd, Sdf, Gf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    prim = stage.GetPrimAtPath('#{prim_path}')
    if not prim:
        raise ValueError(f"Prim not found at path {prim_path}")

    attr = prim.GetAttribute('#{attr_name}')
    if not attr:
        # Create attribute with proper type
        attr = prim.CreateAttribute('#{attr_name}', #{type_name})

    # Set the value
    #{value_code}

    stage.GetRootLayer().Save()
    result = f"Set attribute {attr.GetName()} on {prim.GetPath()}"
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

  defp build_attribute_type_and_value(:string, value) when is_binary(value) do
    {"Sdf.ValueTypeNames.String", "attr.Set('#{value}')"}
  end

  defp build_attribute_type_and_value(:int, value) when is_integer(value) do
    {"Sdf.ValueTypeNames.Int", "attr.Set(#{value})"}
  end

  defp build_attribute_type_and_value(:float, value) when is_float(value) or is_integer(value) do
    float_val = if is_integer(value), do: "#{value}.0", else: "#{value}"
    {"Sdf.ValueTypeNames.Float", "attr.Set(#{float_val})"}
  end

  defp build_attribute_type_and_value(:int_array, value) when is_list(value) do
    array_str = inspect(value)
    {"Sdf.ValueTypeNames.IntArray", "attr.Set(#{array_str})"}
  end

  defp build_attribute_type_and_value(:float_array, value) when is_list(value) do
    array_str = inspect(value)
    {"Sdf.ValueTypeNames.FloatArray", "attr.Set(#{array_str})"}
  end

  defp build_attribute_type_and_value(:vec3f_array, value) when is_list(value) do
    # Convert list of tuples to Python list of Vec3f
    vec3f_list =
      Enum.map(value, fn {x, y, z} -> "Gf.Vec3f(#{x}, #{y}, #{z})" end) |> Enum.join(", ")

    {"Sdf.ValueTypeNames.Vector3fArray", "attr.Set([#{vec3f_list}])"}
  end

  defp build_attribute_type_and_value(_attr_type, value) do
    # Fallback to string for unknown types
    value_str = inspect(value)
    {"Sdf.ValueTypeNames.String", "attr.Set('#{value_str}')"}
  end

  @doc """
  Creates a typed attribute on a prim with explicit type specification.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to prim
    - attr_name: Name of attribute
    - attr_type: Type of attribute (same as set_attribute/5)
    - attr_value: Value to set

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_typed_attribute(String.t(), String.t(), String.t(), atom(), term()) ::
          usd_result()
  def create_typed_attribute(file_path, prim_path, attr_name, attr_type, attr_value)
      when is_binary(file_path) and is_binary(prim_path) and is_binary(attr_name) do
    set_attribute(file_path, prim_path, attr_name, attr_value, attr_type)
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
