# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.Layer do
  @moduledoc """
  Operations for composing USD layers.
  """

  @type usd_result :: {:ok, term()} | {:error, String.t()}

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
    case AriaUsd.Pythonx.ensure_pythonx() do
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
end
