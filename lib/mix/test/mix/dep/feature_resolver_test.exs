# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

Code.require_file("../../test_helper.exs", __DIR__)

defmodule Mix.Dep.FeatureResolverTest do
  use MixTest.Case

  alias Mix.Dep.FeatureResolver

  describe "resolve/4" do
    test "defaults enabled, no requested features" do
      config = [default: [:json, :logging], optional: [:metrics]]
      assert FeatureResolver.resolve(:my_lib, [], true, config) == [
               default: [:json, :logging],
               optional: [:metrics]
             ]
    end

    test "defaults enabled with requested features" do
      config = [default: [:json], optional: [:metrics, :debug]]
      assert FeatureResolver.resolve(:my_lib, [:metrics], true, config) == [
               default: [:json, :metrics],
               optional: [:debug]
             ]
    end

    test "defaults disabled, only requested features enabled" do
      config = [default: [:json, :logging], optional: [:metrics]]
      assert FeatureResolver.resolve(:my_lib, [:metrics], false, config) == [
               default: [:metrics],
               optional: [:json, :logging]
             ]
    end

    test "defaults disabled with no requested features" do
      config = [default: [:json, :logging], optional: [:metrics]]
      assert FeatureResolver.resolve(:my_lib, [], false, config) == [
               default: [],
               optional: [:json, :logging, :metrics]
             ]
    end

    test "raises on undeclared feature" do
      config = [default: [:json], optional: [:metrics]]

      assert_raise Mix.Error, ~r/Unknown features \[:nope\]/, fn ->
        FeatureResolver.resolve(:my_lib, [:nope], true, config)
      end
    end

    test "raises on multiple undeclared features" do
      config = [default: [:json], optional: []]

      assert_raise Mix.Error, ~r/Unknown features/, fn ->
        FeatureResolver.resolve(:my_lib, [:foo, :bar], true, config)
      end
    end

    test "empty config with no requested features" do
      assert FeatureResolver.resolve(:my_lib, [], true, []) == [
               default: [],
               optional: []
             ]
    end

    test "empty config with requested features raises" do
      assert_raise Mix.Error, ~r/Unknown features \[:json\]/, fn ->
        FeatureResolver.resolve(:my_lib, [:json], true, [])
      end
    end

    test "nil config with no requested features" do
      assert FeatureResolver.resolve(:my_lib, [], true, nil) == [
               default: [],
               optional: []
             ]
    end

    test "nil config with requested features raises" do
      assert_raise Mix.Error, ~r/Unknown features/, fn ->
        FeatureResolver.resolve(:my_lib, [:json], true, nil)
      end
    end

    test "duplicate features in requested list are deduplicated" do
      config = [default: [:json], optional: [:metrics]]
      assert FeatureResolver.resolve(:my_lib, [:metrics, :metrics], true, config) == [
               default: [:json, :metrics],
               optional: []
             ]
    end

    test "requesting a default feature is a no-op" do
      config = [default: [:json, :logging], optional: [:metrics]]
      assert FeatureResolver.resolve(:my_lib, [:json], true, config) == [
               default: [:json, :logging],
               optional: [:metrics]
             ]
    end

    test "defaults disabled, requesting default feature enables only it" do
      config = [default: [:json, :logging], optional: [:metrics]]
      assert FeatureResolver.resolve(:my_lib, [:json], false, config) == [
               default: [:json],
               optional: [:logging, :metrics]
             ]
    end
  end
end
