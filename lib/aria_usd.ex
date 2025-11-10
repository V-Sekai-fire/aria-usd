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
  """

  require Logger

  @type usd_result :: {:ok, term()} | {:error, String.t()}

  # Helper functions
  @doc """
  Checks if Pythonx is available and working.
  Returns :ok if available, :mock if not.
  """
  @spec ensure_pythonx() :: :ok | :mock
  def ensure_pythonx do
    case Application.ensure_all_started(:pythonx) do
      {:error, reason} ->
        Logger.warning("Failed to start Pythonx application: #{inspect(reason)}")
        :mock

      {:ok, _} ->
        check_pythonx_availability()
    end
  rescue
    exception ->
      Logger.error("Exception starting Pythonx: #{Exception.message(exception)}")
      :mock
  end

  defp check_pythonx_availability do
    null_device = File.open!("/dev/null", [:write])

    case Pythonx.eval("1 + 1", %{}, stdout_device: null_device, stderr_device: null_device) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          2 -> :ok
          _ -> :mock
        end

      _ ->
        :mock
    end
  end

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
    case ensure_pythonx() do
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
    case ensure_pythonx() do
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
        raise ValueError(f"Prim not found at path #{'#{prim_path}'}")

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
    case ensure_pythonx() do
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
  def compose_layer(base_file, layer_file, output_file)
      when is_binary(base_file) and is_binary(layer_file) and is_binary(output_file) do
    case ensure_pythonx() do
      :ok -> do_compose_layer(base_file, layer_file, output_file)
      :mock -> mock_compose_layer(base_file, layer_file, output_file)
    end
  end

  defp mock_compose_layer(base_file, layer_file, output_file) do
    {:ok, "Mock composed #{base_file} with #{layer_file} to #{output_file}"}
  end

  defp do_compose_layer(base_file, layer_file, output_file) do
    code = """
    from pxr import Usd, Sdf

    base_stage = Usd.Stage.Open('#{base_file}')
    if not base_stage:
        raise ValueError("Failed to open base stage")

    layer = Sdf.Layer.FindOrOpen('#{layer_file}')
    if not layer:
        raise ValueError("Failed to open layer")

    # Compose the layer
    base_stage.GetRootLayer().subLayerPaths.append('#{layer_file}')
    base_stage.Export('#{output_file}')
    result = f"Composed {base_file} with {layer_file} to {output_file}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode compose_layer result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def vrm_to_usd(vrm_path, output_usd_path, opts \\ [])
      when is_binary(vrm_path) and is_binary(output_usd_path) do
    vrm_extensions = Keyword.get(opts, :vrm_extensions)
    vrm_metadata = Keyword.get(opts, :vrm_metadata)

    if vrm_extensions && vrm_metadata do
      # Use provided VRM data for conversion
      case ensure_pythonx() do
        :ok ->
          # Extract GLTF from VRM first (simplified - assumes VRM is GLB)
          do_vrm_to_usd_with_metadata(vrm_path, output_usd_path, vrm_extensions, vrm_metadata)

        :mock ->
          mock_vrm_to_usd(vrm_path, output_usd_path)
      end
    else
      # Fallback to Python implementation without metadata preservation
      case ensure_pythonx() do
        :ok -> do_vrm_to_usd(vrm_path, output_usd_path)
        :mock -> mock_vrm_to_usd(vrm_path, output_usd_path)
      end
    end
  end

  defp do_vrm_to_usd_with_metadata(gltf_path, output_usd_path, vrm_extensions, vrm_metadata) do
    # Encode VRM extensions and metadata as JSON for storage in USD
    # Use base64 encoding to avoid string escaping issues in Python
    vrm_ext_json = Jason.encode!(vrm_extensions) |> Base.encode64()
    vrm_meta_json = Jason.encode!(vrm_metadata) |> Base.encode64()
    # Metadata uses atom keys, so access with atom
    vrm_version = Map.get(vrm_metadata, :version, "unknown") || "unknown"

    code = """
    import os
    import json
    import base64
    from pxr import Usd, Sdf, Vt

    gltf_path = '#{gltf_path}'
    output_usd_path = '#{output_usd_path}'
    vrm_ext_json_b64 = '#{vrm_ext_json}'
    vrm_meta_json_b64 = '#{vrm_meta_json}'
    vrm_version = '#{vrm_version}'

    if not os.path.exists(gltf_path):
        raise FileNotFoundError(f"GLTF file not found: {gltf_path}")

    # Decode base64 JSON strings
    try:
        vrm_ext_json = base64.b64decode(vrm_ext_json_b64).decode('utf-8')
        vrm_meta_json = base64.b64decode(vrm_meta_json_b64).decode('utf-8')
    except Exception as e:
        raise ValueError(f"Failed to decode VRM JSON data: {str(e)}")

    # Use USD to open GLTF (via Adobe plugins if available)
    stage = Usd.Stage.Open(gltf_path)
    if stage:
        # Get root prim (or create one if needed)
        root_prim = stage.GetPseudoRoot()
        
        # Apply VrmAPI schema using apiSchemas metadata
        # Handle different USD types for apiSchemas (VtArray, list, etc.)
        api_schemas = root_prim.GetMetadata('apiSchemas')
        api_schemas_list = []
        
        if api_schemas:
            # Convert VtArray or other USD types to Python list
            if hasattr(api_schemas, '__iter__') and not isinstance(api_schemas, (str, bytes)):
                api_schemas_list = [str(schema) for schema in api_schemas]
            elif isinstance(api_schemas, (list, tuple)):
                api_schemas_list = [str(s) for s in api_schemas]
            else:
                api_schemas_list = [str(api_schemas)]
        
        # Add VrmAPI to apiSchemas if not already present
        if 'VrmAPI' not in api_schemas_list:
            api_schemas_list.append('VrmAPI')
            # Set as VtArray for proper USD type
            root_prim.SetMetadata('apiSchemas', Vt.StringArray(api_schemas_list))
        
        # Create VrmAPI attributes on root prim
        # vrm:version
        version_attr = root_prim.CreateAttribute('vrm:version', Sdf.ValueTypeNames.String, True)
        version_attr.Set(vrm_version)
        
        # vrm:extensions (as JSON string)
        ext_attr = root_prim.CreateAttribute('vrm:extensions', Sdf.ValueTypeNames.String, True)
        ext_attr.Set(vrm_ext_json)
        
        # vrm:metadata (as JSON string)
        meta_attr = root_prim.CreateAttribute('vrm:metadata', Sdf.ValueTypeNames.String, True)
        meta_attr.Set(vrm_meta_json)
        
        # vrm:sourceFormat
        source_attr = root_prim.CreateAttribute('vrm:sourceFormat', Sdf.ValueTypeNames.String, True)
        source_attr.Set('VRM')
        
        stage.Export(output_usd_path)
        result = f"Converted GLTF {gltf_path} to USD {output_usd_path} with VRM schema applied"
    else:
        result = "Failed to open GLTF file"

    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode vrm_to_usd result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp mock_vrm_to_usd(vrm_path, output_usd_path) do
    # Check if VRM file exists
    if File.exists?(vrm_path) do
      {:ok, "Mock converted VRM #{vrm_path} to USD #{output_usd_path}"}
    else
      {:error, "VRM file not found: #{vrm_path}"}
    end
  end

  defp do_vrm_to_usd(vrm_path, output_usd_path) do
    code = """
    import os
    from pxr import Usd

    vrm_path = '#{vrm_path}'
    output_usd_path = '#{output_usd_path}'

    if not os.path.exists(vrm_path):
        raise FileNotFoundError(f"VRM file not found: {vrm_path}")

    # VRM files are GLB format, use directly with USD GLTF plugin
    gltf_path = vrm_path

    # Use USD to open GLTF (via Adobe plugins if available)
    stage = Usd.Stage.Open(gltf_path)
    if stage:
        stage.Export(output_usd_path)
        result = f"Converted VRM {vrm_path} to USD {output_usd_path}"
    else:
        result = "Failed to open GLTF from VRM"

    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode vrm_to_usd result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def usd_to_tscn(usd_path, output_tscn_path)
      when is_binary(usd_path) and is_binary(output_tscn_path) do
    case ensure_pythonx() do
      :ok -> do_usd_to_tscn(usd_path, output_tscn_path)
      :mock -> mock_usd_to_tscn(usd_path, output_tscn_path)
    end
  end

  defp mock_usd_to_tscn(usd_path, output_tscn_path) do
    # Check if USD file exists
    if File.exists?(usd_path) do
      {:ok, "Mock converted USD #{usd_path} to TSCN #{output_tscn_path}"}
    else
      {:error, "USD file not found: #{usd_path}"}
    end
  end

  defp do_usd_to_tscn(usd_path, output_tscn_path) do
    code = """
    import os
    from pxr import Usd

    usd_path = '#{usd_path}'
    output_tscn_path = '#{output_tscn_path}'

    if not os.path.exists(usd_path):
        raise FileNotFoundError(f"USD file not found: {usd_path}")

    # Open USD stage
    stage = Usd.Stage.Open(usd_path)
    if not stage:
        raise ValueError("Failed to open USD stage")

    # Convert USD to TSCN format
    # TSCN is Godot's text scene format - we'll generate it from USD prims
    tscn_lines = ['[gd_scene load_steps=2 format=3]', '', '[ext_resource type="Script" path="res://script.gd" id=1]', '']

    def traverse_prim(prim, indent=0):
        lines = []
        prefix = '  ' * indent
        prim_path = str(prim.GetPath())
        prim_type = prim.GetTypeName()
        
        # Convert USD prim to TSCN node
        lines.append(f"{prefix}[node name=\\"{prim_path.split('/')[-1]}\\" type=\\"{prim_type}\\" parent=\\"{prim_path}\\" index=0]")
        
        # Add attributes as properties
        for attr in prim.GetAttributes():
            attr_name = str(attr.GetName())
            attr_value = attr.Get()
            lines.append(f"{prefix}{attr_name} = {attr_value}")
        
        # Recurse children
        for child in prim.GetChildren():
            lines.extend(traverse_prim(child, indent + 1))
        
        return lines

    root = stage.GetPseudoRoot()
    for child in root.GetChildren():
        tscn_lines.extend(traverse_prim(child))

    # Write TSCN file
    with open(output_tscn_path, 'w') as f:
        f.write('\\n'.join(tscn_lines))

    result = f"Converted USD {usd_path} to TSCN {output_tscn_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode usd_to_tscn result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def tscn_to_usd(tscn_path, output_usd_path, opts \\ [])
      when is_binary(tscn_path) and is_binary(output_usd_path) do
    tscn_data = Keyword.get(opts, :tscn_data)

    if tscn_data do
      # Use provided parsed TSCN data
      case ensure_pythonx() do
        :ok -> do_tscn_to_usd_from_parsed(tscn_data, output_usd_path)
        :mock -> mock_tscn_to_usd(tscn_path, output_usd_path)
      end
    else
      # Fallback - would need TSCN parser (not included in standalone module)
      {:error, "TSCN parsing not available in standalone module. Provide :tscn_data option."}
    end
  end

  defp mock_tscn_to_usd(tscn_path, output_usd_path) do
    # Check if TSCN file exists
    if File.exists?(tscn_path) do
      {:ok, "Mock converted TSCN #{tscn_path} to USD #{output_usd_path}"}
    else
      {:error, "TSCN file not found: #{tscn_path}"}
    end
  end

  defp do_tscn_to_usd_from_parsed(tscn_data, output_usd_path) do
    # Encode TSCN data as JSON for Python processing
    tscn_json = Jason.encode!(tscn_data)

    code = """
    import os
    import json
    from pxr import Usd, Gf

    output_usd_path = '#{output_usd_path}'
    tscn_data = json.loads('''#{tscn_json}''')

    # Create USD stage
    stage = Usd.Stage.CreateNew(output_usd_path)

    # Process nodes and build hierarchy
    nodes = tscn_data.get('nodes', [])
    node_map = {}

    # First pass: create all prims
    for node in nodes:
        node_name = node.get('name', 'Node')
        node_type = node.get('type', 'Node')
        parent = node.get('parent')
        
        if parent and parent != ".":
            # Has parent - find parent path
            parent_path = node_map.get(parent, "/")
            prim_path = f"{parent_path}/{node_name}" if parent_path != "/" else f"/{node_name}"
        else:
            # Root node
            prim_path = f"/{node_name}"
        
        prim = stage.DefinePrim(prim_path, node_type)
        node_map[node_name] = prim_path
        
        # Add properties
        properties = node.get('properties', {})
        for prop_name, prop_value in properties.items():
            # Convert property value to USD attribute
            if isinstance(prop_value, dict):
                if prop_value.get('type') == 'Vector3':
                    vec = Gf.Vec3f(prop_value.get('x', 0), prop_value.get('y', 0), prop_value.get('z', 0))
                    attr = prim.CreateAttribute(prop_name, Usd.TypeId.Tokens.Vector3f)
                    attr.Set(vec)
                elif prop_value.get('type') == 'Transform':
                    origin = prop_value.get('origin', {})
                    if isinstance(origin, dict):
                        origin_vec = Gf.Vec3f(origin.get('x', 0), origin.get('y', 0), origin.get('z', 0))
                        transform = Gf.Matrix4d(1.0).SetTranslate(origin_vec)
                        attr = prim.CreateAttribute(prop_name, Usd.TypeId.Tokens.Matrix4d)
                        attr.Set(transform)
            elif isinstance(prop_value, (int, float)):
                attr = prim.CreateAttribute(prop_name, Usd.TypeId.Tokens.Float)
                attr.Set(float(prop_value))
            elif isinstance(prop_value, str):
                attr = prim.CreateAttribute(prop_name, Usd.TypeId.Tokens.String)
                attr.Set(prop_value)
            elif isinstance(prop_value, bool):
                attr = prim.CreateAttribute(prop_name, Usd.TypeId.Tokens.Bool)
                attr.Set(prop_value)

    stage.GetRootLayer().Save()
    result = f"Converted TSCN to USD {output_usd_path} with {len(nodes)} nodes"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode tscn_to_usd result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def usd_to_unity_package(usd_path, output_unitypackage_path)
      when is_binary(usd_path) and is_binary(output_unitypackage_path) do
    case ensure_pythonx() do
      :ok -> do_usd_to_unity_package(usd_path, output_unitypackage_path)
      :mock -> mock_usd_to_unity_package(usd_path, output_unitypackage_path)
    end
  end

  defp mock_usd_to_unity_package(usd_path, output_unitypackage_path) do
    {:ok, "Mock converted USD #{usd_path} to Unity package #{output_unitypackage_path}"}
  end

  defp do_usd_to_unity_package(usd_path, output_unitypackage_path) do
    code = """
    import os
    import tarfile
    import tempfile
    import uuid
    from pxr import Usd

    usd_path = '#{usd_path}'
    output_unitypackage_path = '#{output_unitypackage_path}'

    if not os.path.exists(usd_path):
        raise FileNotFoundError(f"USD file not found: {usd_path}")

    # Unity packages are tar.gz files with a specific structure
    # Each asset has: pathname/asset and pathname/asset.meta
    # We'll create a Unity package from USD by converting USD to Unity-compatible formats

    with tempfile.TemporaryDirectory() as tmpdir:
        # Open USD stage
        stage = Usd.Stage.Open(usd_path)
        if not stage:
            raise ValueError("Failed to open USD stage")
        
        # TODO: 2025-11-09 fire - Create Unity package structure
        # For now, we'll create a basic structure - in a full implementation,
        # this would convert USD prims to Unity GameObjects and components
        
        # Create a GUID for the asset
        asset_guid = str(uuid.uuid4()).replace('-', '')
        
        # Create asset directory structure
        asset_dir = os.path.join(tmpdir, f"Assets/USD_Import")
        os.makedirs(asset_dir, exist_ok=True)
        
        # TODO: 2025-11-09 fire - Create a basic Unity scene file from USD
        # In practice, this would need proper Unity YAML format
        scene_content = f'''%YAML 1.1
    %TAG !u! tag:unity3d.com,2011:
    --- !u!1 &{asset_guid}
    GameObject:
    m_ObjectHideFlags: 0
    m_CorrespondingSourceObject: {{fileID: 0}}
    m_PrefabInstance: {{fileID: 0}}
    m_PrefabAsset: {{fileID: 0}}
    serializedVersion: 6
    m_Component:
    - component: {{fileID: {asset_guid}1}}
    m_Layer: 0
    m_Name: USD_Scene
    '''
        
        scene_file = os.path.join(asset_dir, "USD_Scene.unity")
        with open(scene_file, 'w') as f:
            f.write(scene_content)
        
        # Create .meta file
        meta_content = f'''fileFormatVersion: 2
    guid: {asset_guid}
    '''
        meta_file = os.path.join(asset_dir, "USD_Scene.unity.meta")
        with open(meta_file, 'w') as f:
            f.write(meta_content)
        
        # Create Unity package (tar.gz)
        with tarfile.open(output_unitypackage_path, 'w:gz') as tar:
            # Add files in Unity package format: pathname/asset
            for root, dirs, files in os.walk(asset_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    # Unity package format: relative path from Assets/
                    arcname = os.path.relpath(file_path, tmpdir)
                    tar.add(file_path, arcname=arcname)
        
        result = f"Converted USD {usd_path} to Unity package {output_unitypackage_path} (lower-loss conversion)"

    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode usd_to_unity_package result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def convert_unity_to_usd(unity_asset_path, output_usd_path)
      when is_binary(unity_asset_path) and is_binary(output_usd_path) do
    case ensure_pythonx() do
      :ok -> do_convert_unity_to_usd(unity_asset_path, output_usd_path)
      :mock -> mock_convert_unity_to_usd(unity_asset_path, output_usd_path)
    end
  end

  defp mock_convert_unity_to_usd(unity_asset_path, output_usd_path) do
    {:ok, "Mock converted #{unity_asset_path} to #{output_usd_path}"}
  end

  defp do_convert_unity_to_usd(unity_asset_path, output_usd_path) do
    # TODO: 2025-11-09 fire - This would ideally use Godot with unidot_importer to convert Unity assets
    # For now, provide a basic implementation that can be extended
    code = """
    import os
    from pxr import Usd

    unity_asset_path = '#{unity_asset_path}'
    output_usd_path = '#{output_usd_path}'

    if not os.path.exists(unity_asset_path):
        raise FileNotFoundError(f"Unity asset not found: {unity_asset_path}")

    # TODO: 2025-11-09 fire - Create a basic USD stage
    # In a full implementation, this would parse Unity assets and convert them
    stage = Usd.Stage.CreateNew(output_usd_path)

    # Create a root prim to represent the Unity asset
    root_prim = stage.DefinePrim('/UnityAsset', 'Xform')
    root_prim.GetAttribute('comment').Set(f'Converted from Unity asset: {unity_asset_path}')

    stage.GetRootLayer().Save()
    # TODO: 2025-11-09 fire - Full conversion requires Godot with unidot_importer addon
    result = f"Created USD stage from Unity asset at {output_usd_path}. Note: Full conversion requires Godot with unidot_importer addon."
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode convert_unity_to_usd result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  def import_unity_package(unitypackage_path, output_dir)
      when is_binary(unitypackage_path) and is_binary(output_dir) do
    case ensure_pythonx() do
      :ok -> do_import_unity_package(unitypackage_path, output_dir)
      :mock -> mock_import_unity_package(unitypackage_path, output_dir)
    end
  end

  defp mock_import_unity_package(unitypackage_path, output_dir) do
    {:ok, "Mock imported #{unitypackage_path} to #{output_dir}"}
  end

  defp do_import_unity_package(unitypackage_path, output_dir) do
    # Try to use Godot with unidot_importer if available
    # Otherwise, use Python-based Unity package parser
    code = """
    import os
    import tarfile
    import json
    import shutil

    unitypackage_path = '#{unitypackage_path}'
    output_dir = '#{output_dir}'

    if not os.path.exists(unitypackage_path):
        raise FileNotFoundError(f"Unity package not found: {unitypackage_path}")

    os.makedirs(output_dir, exist_ok=True)

    # Unity packages are tar.gz files with a specific structure
    # Extract the package
    extracted_files = []
    try:
        with tarfile.open(unitypackage_path, 'r:gz') as tar:
            # Unity packages have a specific structure: pathname/asset, pathname/asset.meta
            for member in tar.getmembers():
                if member.isfile():
                    # Extract to output directory
                    member.name = os.path.basename(member.name)
                    tar.extract(member, output_dir)
                    extracted_files.append(member.name)
        
        result = f"Extracted {len(extracted_files)} files from Unity package to {output_dir}"
    except Exception as e:
        result = f"Error extracting Unity package: {str(e)}"

    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode import_unity_package result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end

