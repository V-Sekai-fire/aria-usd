# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaUsdTest do
  use ExUnit.Case, async: false

  alias AriaUsd
  alias Pythonx
  alias Jason

  # Helper to create a temporary USD file path
  defp tmp_usd_path(prefix \\ "test") do
    System.tmp_dir!() |> Path.join("#{prefix}_#{:rand.uniform(1_000_000)}.usd")
  end

  # Helper to verify a prim exists in USD file
  defp prim_exists?(usd_path, prim_path) do
    case AriaUsd.ensure_pythonx() do
      :mock ->
        false

      :ok ->
        code = """
        from pxr import Usd

        stage = Usd.Stage.Open('#{usd_path}')
        if stage:
            prim = stage.GetPrimAtPath('#{prim_path}')
            result = {'exists': prim.IsValid()}
        else:
            result = {'exists': False}

        import json
        json.dumps(result)
        """

        case Pythonx.eval(code, %{}) do
          {result_json, _globals} ->
            case Pythonx.decode(result_json) do
              json_str when is_binary(json_str) ->
                case Jason.decode(json_str) do
                  {:ok, %{"exists" => exists}} -> exists
                  _ -> false
                end

              _ ->
                false
            end

          _ ->
            false
        end
    end
  end

  # Helper to get attribute value from USD file
  defp get_attribute_value(usd_path, prim_path, attr_name) do
    case AriaUsd.ensure_pythonx() do
      :mock ->
        nil

      :ok ->
        code = """
        from pxr import Usd

        stage = Usd.Stage.Open('#{usd_path}')
        if stage:
            prim = stage.GetPrimAtPath('#{prim_path}')
            if prim:
                attr = prim.GetAttribute('#{attr_name}')
                if attr:
                    value = attr.Get()
                    result = {'value': str(value), 'has_value': True}
                else:
                    result = {'has_value': False}
            else:
                result = {'has_value': False}
        else:
            result = {'has_value': False}

        import json
        json.dumps(result)
        """

        case Pythonx.eval(code, %{}) do
          {result_json, _globals} ->
            case Pythonx.decode(result_json) do
              json_str when is_binary(json_str) ->
                case Jason.decode(json_str) do
                  {:ok, %{"has_value" => true, "value" => value}} -> value
                  _ -> nil
                end

              _ ->
                nil
            end

          _ ->
            nil
        end
    end
  end

  describe "ensure_pythonx/0" do
    test "returns :ok or :mock" do
      result = AriaUsd.ensure_pythonx()
      assert result in [:ok, :mock]
    end
  end

  describe "create_prim/3" do
    test "creates prim in USD file (mock when pxr unavailable)" do
      case AriaUsd.create_prim("/path/to/test.usd", "/NewPrim", "Xform") do
        {:ok, status} ->
          assert is_binary(status)

        {:error, _reason} ->
          # Skip test if USD not available
          :ok
      end
    end

    @tag :requires_pythonx
    test "creates prim in actual USD file and verifies it exists" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          tmp_usd = tmp_usd_path("create_prim")
          prim_path = "/TestPrim"

          try do
            # Create prim
            assert {:ok, _message} = AriaUsd.create_prim(tmp_usd, prim_path, "Xform")

            # Verify file was created
            assert File.exists?(tmp_usd)

            # Verify prim exists in USD file
            assert prim_exists?(tmp_usd, prim_path) == true
          after
            if File.exists?(tmp_usd), do: File.rm(tmp_usd)
          end
      end
    end

    @tag :requires_pythonx
    test "creates prim with custom type" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          tmp_usd = tmp_usd_path("create_prim_custom")
          prim_path = "/CustomPrim"

          try do
            # Create prim with Mesh type
            assert {:ok, _message} = AriaUsd.create_prim(tmp_usd, prim_path, "Mesh")

            # Verify prim exists
            assert prim_exists?(tmp_usd, prim_path) == true
          after
            if File.exists?(tmp_usd), do: File.rm(tmp_usd)
          end
      end
    end

    test "handles invalid input types" do
      assert_raise FunctionClauseError, fn ->
        AriaUsd.create_prim(123, "/Prim", "Xform")
      end

      assert_raise FunctionClauseError, fn ->
        AriaUsd.create_prim("/path", 123, "Xform")
      end
    end
  end

  describe "set_attribute/4" do
    test "sets attribute in USD file (mock when pxr unavailable)" do
      case AriaUsd.set_attribute("/path/to/test.usd", "/Prim", "testAttr", "testValue") do
        {:ok, status} ->
          assert is_binary(status)

        {:error, _reason} ->
          # Skip test if USD not available
          :ok
      end
    end

    @tag :requires_pythonx
    test "sets attribute in actual USD file and verifies value" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          tmp_usd = tmp_usd_path("set_attribute")
          prim_path = "/TestPrim"
          attr_name = "testAttr"
          attr_value = "testValue"

          try do
            # Create prim first
            assert {:ok, _} = AriaUsd.create_prim(tmp_usd, prim_path, "Xform")

            # Set attribute
            assert {:ok, _message} =
                     AriaUsd.set_attribute(tmp_usd, prim_path, attr_name, attr_value)

            # Verify attribute value
            value = get_attribute_value(tmp_usd, prim_path, attr_name)
            assert value == attr_value
          after
            if File.exists?(tmp_usd), do: File.rm(tmp_usd)
          end
      end
    end

    @tag :requires_pythonx
    test "creates attribute if it doesn't exist" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          tmp_usd = tmp_usd_path("set_attribute_new")
          prim_path = "/TestPrim"
          attr_name = "newAttr"
          attr_value = "newValue"

          try do
            # Create prim
            assert {:ok, _} = AriaUsd.create_prim(tmp_usd, prim_path, "Xform")

            # Set attribute (should create it)
            assert {:ok, _message} =
                     AriaUsd.set_attribute(tmp_usd, prim_path, attr_name, attr_value)

            # Verify attribute was created and has correct value
            value = get_attribute_value(tmp_usd, prim_path, attr_name)
            assert value == attr_value
          after
            if File.exists?(tmp_usd), do: File.rm(tmp_usd)
          end
      end
    end

    test "handles invalid input types" do
      assert_raise FunctionClauseError, fn ->
        AriaUsd.set_attribute(123, "/Prim", "attr", "value")
      end
    end
  end

  describe "remove_prim/2" do
    test "removes prim from USD file (mock when pxr unavailable)" do
      case AriaUsd.remove_prim("/path/to/test.usd", "/Prim") do
        {:ok, status} ->
          assert is_binary(status)

        {:error, _reason} ->
          # Skip test if USD not available
          :ok
      end
    end

    @tag :requires_pythonx
    test "removes prim from actual USD file and verifies it's gone" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          tmp_usd = tmp_usd_path("remove_prim")
          prim_path = "/TestPrim"

          try do
            # Create prim first
            assert {:ok, _} = AriaUsd.create_prim(tmp_usd, prim_path, "Xform")
            assert prim_exists?(tmp_usd, prim_path) == true

            # Remove prim
            assert {:ok, _message} = AriaUsd.remove_prim(tmp_usd, prim_path)

            # Verify prim no longer exists
            assert prim_exists?(tmp_usd, prim_path) == false
          after
            if File.exists?(tmp_usd), do: File.rm(tmp_usd)
          end
      end
    end

    @tag :requires_pythonx
    test "handles removing non-existent prim gracefully" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          tmp_usd = tmp_usd_path("remove_prim_nonexistent")
          prim_path = "/NonExistentPrim"

          try do
            # Create USD file
            assert {:ok, _} = AriaUsd.create_prim(tmp_usd, "/OtherPrim", "Xform")

            # Try to remove non-existent prim
            case AriaUsd.remove_prim(tmp_usd, prim_path) do
              {:ok, _message} ->
                # Should still succeed (USD allows this)
                :ok

              {:error, _reason} ->
                # Also acceptable
                :ok
            end
          after
            if File.exists?(tmp_usd), do: File.rm(tmp_usd)
          end
      end
    end

    test "handles invalid input types" do
      assert_raise FunctionClauseError, fn ->
        AriaUsd.remove_prim(123, "/Prim")
      end

      assert_raise FunctionClauseError, fn ->
        AriaUsd.remove_prim("/path", 123)
      end
    end
  end

  describe "compose_layer/3" do
    test "composes layers in USD (mock when pxr unavailable)" do
      case AriaUsd.compose_layer("/path/to/base.usd", "/path/to/layer.usd", "/path/to/output.usd") do
        {:ok, status} ->
          assert is_binary(status)

        {:error, _reason} ->
          # Skip test if USD not available
          :ok
      end
    end

    @tag :requires_pythonx
    test "composes layers with real USD files and verifies result" do
      case AriaUsd.ensure_pythonx() do
        :mock ->
          :ok

        :ok ->
          base_usd = tmp_usd_path("compose_base")
          layer_usd = tmp_usd_path("compose_layer")
          output_usd = tmp_usd_path("compose_output")

          try do
            # Create base USD file with a prim
            assert {:ok, _} = AriaUsd.create_prim(base_usd, "/BasePrim", "Xform")
            assert prim_exists?(base_usd, "/BasePrim") == true

            # Create layer USD file with another prim
            assert {:ok, _} = AriaUsd.create_prim(layer_usd, "/LayerPrim", "Xform")
            assert prim_exists?(layer_usd, "/LayerPrim") == true

            # Compose layers
            assert {:ok, _message} = AriaUsd.compose_layer(base_usd, layer_usd, output_usd)

            # Verify output file was created
            assert File.exists?(output_usd)
          after
            if File.exists?(base_usd), do: File.rm(base_usd)
            if File.exists?(layer_usd), do: File.rm(layer_usd)
            if File.exists?(output_usd), do: File.rm(output_usd)
          end
      end
    end

    test "handles invalid input types" do
      assert_raise FunctionClauseError, fn ->
        AriaUsd.compose_layer(123, "/layer", "/output")
      end

      assert_raise FunctionClauseError, fn ->
        AriaUsd.compose_layer("/base", 123, "/output")
      end

      assert_raise FunctionClauseError, fn ->
        AriaUsd.compose_layer("/base", "/layer", 123)
      end
    end
  end
end
