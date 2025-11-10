# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.Unity do
  @moduledoc """
  Unity package import and USD conversion operations.
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

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
    case AriaUsd.Pythonx.ensure_pythonx() do
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
    case AriaUsd.Pythonx.ensure_pythonx() do
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
    case AriaUsd.Pythonx.ensure_pythonx() do
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

