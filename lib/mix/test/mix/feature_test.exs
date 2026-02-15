# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

Code.require_file("../test_helper.exs", __DIR__)

defmodule Mix.FeatureTest do
  use MixTest.Case

  defmodule SampleWithFeatures do
    def project do
      [
        app: :sample,
        version: "0.1.0",
        features: [
          default: [:json, :logging],
          optional: [:debug_tools, :metrics]
        ]
      ]
    end
  end

  defmodule SampleWithoutFeatures do
    def project do
      [app: :sample, version: "0.1.0"]
    end
  end

  defmodule SampleWithDefaultOnly do
    def project do
      [
        app: :sample,
        version: "0.1.0",
        features: [default: [:json]]
      ]
    end
  end

  defmodule SampleWithOptionalOnly do
    def project do
      [
        app: :sample,
        version: "0.1.0",
        features: [optional: [:debug_tools]]
      ]
    end
  end

  describe "all/0" do
    test "returns map of features with default and optional" do
      Mix.Project.push(SampleWithFeatures)

      assert Mix.Feature.all() == %{
               json: true,
               logging: true,
               debug_tools: false,
               metrics: false
             }
    end

    test "returns empty map when no features configured" do
      Mix.Project.push(SampleWithoutFeatures)
      assert Mix.Feature.all() == %{}
    end

    test "returns map with only default features" do
      Mix.Project.push(SampleWithDefaultOnly)
      assert Mix.Feature.all() == %{json: true}
    end

    test "returns map with only optional features" do
      Mix.Project.push(SampleWithOptionalOnly)
      assert Mix.Feature.all() == %{debug_tools: false}
    end

    test "default takes precedence over optional for same feature" do
      defmodule SampleOverlap do
        def project do
          [
            app: :sample,
            version: "0.1.0",
            features: [default: [:json], optional: [:json]]
          ]
        end
      end

      Mix.Project.push(SampleOverlap)

      assert ExUnit.CaptureIO.capture_io(:stderr, fn ->
               assert Mix.Feature.all() == %{json: true}
             end) =~ "Features [:json] appear in both :default and :optional"
    end
  end

  describe "enabled_features/0" do
    test "returns only enabled feature atoms" do
      Mix.Project.push(SampleWithFeatures)
      enabled = Mix.Feature.enabled_features()
      assert Enum.sort(enabled) == [:json, :logging]
    end

    test "returns empty list when no features configured" do
      Mix.Project.push(SampleWithoutFeatures)
      assert Mix.Feature.enabled_features() == []
    end
  end

  describe "declared_features/0" do
    test "returns all declared feature atoms" do
      Mix.Project.push(SampleWithFeatures)
      declared = Mix.Feature.declared_features()
      assert Enum.sort(declared) == [:debug_tools, :json, :logging, :metrics]
    end

    test "returns empty list when no features configured" do
      Mix.Project.push(SampleWithoutFeatures)
      assert Mix.Feature.declared_features() == []
    end
  end

  describe "enabled?/1 macro" do
    test "resolves to true for enabled features" do
      Mix.Project.push(SampleWithFeatures)

      result =
        Code.eval_string("""
        require Mix.Feature
        Mix.Feature.enabled?(:json)
        """)
        |> elem(0)

      assert result == true
    end

    test "resolves to false for disabled features" do
      Mix.Project.push(SampleWithFeatures)

      result =
        Code.eval_string("""
        require Mix.Feature
        Mix.Feature.enabled?(:debug_tools)
        """)
        |> elem(0)

      assert result == false
    end

    test "resolves to false for undeclared features with warning" do
      Mix.Project.push(SampleWithFeatures)

      assert ExUnit.CaptureIO.capture_io(:stderr, fn ->
               result =
                 Code.eval_string("""
                 require Mix.Feature
                 Mix.Feature.enabled?(:nonexistent)
                 """)
                 |> elem(0)

               send(self(), {:result, result})
             end) =~ "feature :nonexistent is not declared"

      assert_received {:result, false}
    end

    test "raises for non-atom argument" do
      Mix.Project.push(SampleWithFeatures)

      assert_raise ArgumentError, ~r/expects a literal atom/, fn ->
        Code.eval_string("""
        require Mix.Feature
        Mix.Feature.enabled?("json")
        """)
      end
    end
  end

  describe "validation" do
    test "raises on unknown keys" do
      defmodule SampleUnknownKeys do
        def project do
          [
            app: :sample,
            version: "0.1.0",
            features: [default: [:json], defaults: [:logging]]
          ]
        end
      end

      Mix.Project.push(SampleUnknownKeys)

      assert_raise Mix.Error, ~r/Unknown keys \[:defaults\]/, fn ->
        Mix.Feature.all()
      end
    end

    test "raises on non-atom defaults" do
      defmodule SampleNonAtomDefaults do
        def project do
          [
            app: :sample,
            version: "0.1.0",
            features: [default: ["json"]]
          ]
        end
      end

      Mix.Project.push(SampleNonAtomDefaults)

      assert_raise Mix.Error, ~r/Expected :default in :features to be a list of atoms/, fn ->
        Mix.Feature.all()
      end
    end

    test "raises on non-atom optionals" do
      defmodule SampleNonAtomOptionals do
        def project do
          [
            app: :sample,
            version: "0.1.0",
            features: [optional: [123]]
          ]
        end
      end

      Mix.Project.push(SampleNonAtomOptionals)

      assert_raise Mix.Error, ~r/Expected :optional in :features to be a list of atoms/, fn ->
        Mix.Feature.all()
      end
    end

    test "raises on non-keyword-list config" do
      defmodule SampleNotKeyword do
        def project do
          [
            app: :sample,
            version: "0.1.0",
            features: "invalid"
          ]
        end
      end

      Mix.Project.push(SampleNotKeyword)

      assert_raise Mix.Error, ~r/Expected :features in project configuration to be a keyword list/, fn ->
        Mix.Feature.all()
      end
    end

    test "warns on overlap between default and optional" do
      defmodule SampleOverlapWarning do
        def project do
          [
            app: :sample,
            version: "0.1.0",
            features: [default: [:json, :logging], optional: [:json]]
          ]
        end
      end

      Mix.Project.push(SampleOverlapWarning)

      assert ExUnit.CaptureIO.capture_io(:stderr, fn ->
               assert Mix.Feature.all() == %{json: true, logging: true}
             end) =~ "Features [:json] appear in both :default and :optional"
    end
  end
end
