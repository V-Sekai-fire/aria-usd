# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.Stage do
  @moduledoc """
  Operations for creating, opening, and saving USD stages.
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

  @doc """
  Creates a new USD stage.

  ## Parameters
    - file_path: Path to USD file to create

  ## Returns
    - `{:ok, String.t()}` - Success message with file path
    - `{:error, String.t()}` - Error message
  """
  @spec create_stage(String.t()) :: usd_result()
  def create_stage(file_path) when is_binary(file_path) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_create_stage(file_path)
      :mock -> mock_create_stage(file_path)
    end
  end

  defp mock_create_stage(file_path) do
    {:ok, "Mock created stage at #{file_path}"}
  end

  defp do_create_stage(file_path) do
    code = """
    from pxr import Usd

    stage = Usd.Stage.CreateNew('#{file_path}')
    if not stage:
        raise ValueError("Failed to create stage at #{file_path}")

    result = f"Created stage at {file_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode create_stage result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Opens an existing USD stage.

  ## Parameters
    - file_path: Path to USD file to open

  ## Returns
    - `{:ok, String.t()}` - Success message with file path
    - `{:error, String.t()}` - Error message
  """
  @spec open_stage(String.t()) :: usd_result()
  def open_stage(file_path) when is_binary(file_path) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_open_stage(file_path)
      :mock -> mock_open_stage(file_path)
    end
  end

  defp mock_open_stage(file_path) do
    {:ok, "Mock opened stage at #{file_path}"}
  end

  defp do_open_stage(file_path) do
    code = """
    from pxr import Usd

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage at #{file_path}")

    result = f"Opened stage at {file_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode open_stage result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc """
  Saves a USD stage to file.

  ## Parameters
    - file_path: Path to USD file to save

  ## Returns
    - `{:ok, String.t()}` - Success message
    - `{:error, String.t()}` - Error message
  """
  @spec save_stage(String.t()) :: usd_result()
  def save_stage(file_path) when is_binary(file_path) do
    case AriaUsd.Pythonx.ensure_pythonx() do
      :ok -> do_save_stage(file_path)
      :mock -> mock_save_stage(file_path)
    end
  end

  defp mock_save_stage(file_path) do
    {:ok, "Mock saved stage at #{file_path}"}
  end

  defp do_save_stage(file_path) do
    code = """
    from pxr import Usd

    stage = Usd.Stage.Open('#{file_path}')
    if not stage:
        raise ValueError("Failed to open stage at #{file_path} for saving")

    stage.GetRootLayer().Save()
    result = f"Saved stage at {file_path}"
    result
    """

    case Pythonx.eval(code, %{}) do
      {result, _globals} ->
        case Pythonx.decode(result) do
          status when is_binary(status) -> {:ok, status}
          _ -> {:error, "Failed to decode save_stage result"}
        end

      error ->
        {:error, inspect(error)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end
end
