# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.Mesh do
  @moduledoc """
  Operations for creating and modifying USD mesh primitives.
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}
  @type point :: {float(), float(), float()}
  @type normal :: {float(), float(), float()}

  @doc """
  Creates a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path for the new mesh prim
    - opts: Optional keyword list (currently unused, reserved for future options)

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec create_mesh(String.t(), String.t(), keyword()) :: usd_result()
  def create_mesh(file_path, prim_path, opts \\ [])
      when is_binary(file_path) and is_binary(prim_path) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_create_mesh(file_path, prim_path, opts)
      :mock -> mock_create_mesh(file_path, prim_path)
    end
  end

  defp mock_create_mesh(file_path, prim_path) do
    {:ok, "Mock created mesh prim at #{prim_path} in #{file_path}"}
  end

  defp do_create_mesh(file_path, prim_path, _opts) do
    code = """
    from pxr import Usd, UsdGeom

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        # Create new stage if file doesn't exist
        stage = Usd.Stage.CreateNew('#{file_path}')

    mesh_prim = UsdGeom.Mesh.Define(stage, '#{prim_path}')
    if mesh_prim:
        stage.GetRootLayer().Save()
        result = f"Created mesh prim at {mesh_prim.GetPath()}"
    else:
        result = "Failed to create mesh prim"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode create_mesh result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

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
  @spec set_mesh_points(String.t(), String.t(), [point()]) :: usd_result()
  def set_mesh_points(file_path, prim_path, points)
      when is_binary(file_path) and is_binary(prim_path) and is_list(points) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_set_mesh_points(file_path, prim_path, points)
      :mock -> mock_set_mesh_points(file_path, prim_path, points)
    end
  end

  defp mock_set_mesh_points(file_path, prim_path, points) do
    {:ok, "Mock set #{length(points)} points on mesh at #{prim_path} in #{file_path}"}
  end

  defp do_set_mesh_points(file_path, prim_path, points) do
    # Convert Elixir points to Python list format
    points_str = inspect(points)

    code = """
    from pxr import Usd, UsdGeom, Gf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    mesh_prim = UsdGeom.Mesh.Get(stage, '#{prim_path}')
    if not mesh_prim:
        raise ValueError(f"Mesh prim not found at path {prim_path}")

    # Convert points from Elixir format
    points = #{points_str}
    points_vec = [Gf.Vec3f(p[0], p[1], p[2]) for p in points]

    mesh_prim.GetPointsAttr().Set(points_vec)
    stage.GetRootLayer().Save()
    result = f"Set {len(points_vec)} points on mesh at {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode set_mesh_points result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Sets face connectivity on a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to mesh prim
    - face_vertex_indices: Flat list of vertex indices for all faces
    - face_vertex_counts: List of vertex counts per face (e.g., [3, 3, 4] for 2 triangles and 1 quad)

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_mesh_faces(String.t(), String.t(), [integer()], [integer()]) :: usd_result()
  def set_mesh_faces(file_path, prim_path, face_vertex_indices, face_vertex_counts)
      when is_binary(file_path) and is_binary(prim_path) and
             is_list(face_vertex_indices) and is_list(face_vertex_counts) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_set_mesh_faces(file_path, prim_path, face_vertex_indices, face_vertex_counts)
      :mock -> mock_set_mesh_faces(file_path, prim_path, face_vertex_indices, face_vertex_counts)
    end
  end

  defp mock_set_mesh_faces(file_path, prim_path, face_vertex_indices, face_vertex_counts) do
    {:ok,
     "Mock set #{length(face_vertex_counts)} faces (#{length(face_vertex_indices)} indices) on mesh at #{prim_path} in #{file_path}"}
  end

  defp do_set_mesh_faces(file_path, prim_path, face_vertex_indices, face_vertex_counts) do
    # Convert Elixir lists to Python list format
    indices_str = inspect(face_vertex_indices)
    counts_str = inspect(face_vertex_counts)

    code = """
    from pxr import Usd, UsdGeom

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    mesh_prim = UsdGeom.Mesh.Get(stage, '#{prim_path}')
    if not mesh_prim:
        raise ValueError(f"Mesh prim not found at path {prim_path}")

    # Convert from Elixir format
    face_vertex_indices = #{indices_str}
    face_vertex_counts = #{counts_str}

    mesh_prim.GetFaceVertexIndicesAttr().Set(face_vertex_indices)
    mesh_prim.GetFaceVertexCountsAttr().Set(face_vertex_counts)
    stage.GetRootLayer().Save()
    result = f"Set {len(face_vertex_counts)} faces on mesh at {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode set_mesh_faces result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Sets vertex normals on a mesh primitive.

  ## Parameters
    - file_path: Path to USD file
    - prim_path: Path to mesh prim
    - normals: List of {x, y, z} tuples representing vertex normals (optional)

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec set_mesh_normals(String.t(), String.t(), [normal()]) :: usd_result()
  def set_mesh_normals(file_path, prim_path, normals)
      when is_binary(file_path) and is_binary(prim_path) and is_list(normals) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_set_mesh_normals(file_path, prim_path, normals)
      :mock -> mock_set_mesh_normals(file_path, prim_path, normals)
    end
  end

  defp mock_set_mesh_normals(file_path, prim_path, normals) do
    {:ok, "Mock set #{length(normals)} normals on mesh at #{prim_path} in #{file_path}"}
  end

  defp do_set_mesh_normals(file_path, prim_path, normals) do
    # Convert Elixir normals to Python list format
    normals_str = inspect(normals)

    code = """
    from pxr import Usd, UsdGeom, Gf

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage")

    mesh_prim = UsdGeom.Mesh.Get(stage, '#{prim_path}')
    if not mesh_prim:
        raise ValueError(f"Mesh prim not found at path {prim_path}")

    # Convert normals from Elixir format
    normals = #{normals_str}
    normals_vec = [Gf.Vec3f(n[0], n[1], n[2]) for n in normals]

    mesh_prim.GetNormalsAttr().Set(normals_vec)
    stage.GetRootLayer().Save()
    result = f"Set {len(normals_vec)} normals on mesh at {prim_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode set_mesh_normals result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end
