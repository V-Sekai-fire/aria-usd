# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsd.Pythonx do
  @moduledoc """
  Utilities for checking and managing Pythonx availability.
  """

  require Logger

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
end

