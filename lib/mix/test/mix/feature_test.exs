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

  describe "seed_features/0" do
    test "seeds Application env with parsed features" do
      Mix.Project.push(SampleWithFeatures)
      Mix.Feature.seed_features()

      assert Application.get_env(:sample, :features) == %{
               json: true,
               logging: true,
               debug_tools: false,
               metrics: false
             }
    after
      Application.delete_env(:sample, :features)
    end

    test "seeds empty map when no features configured" do
      Mix.Project.push(SampleWithoutFeatures)
      Mix.Feature.seed_features()
      assert Application.get_env(:sample, :features) == %{}
    after
      Application.delete_env(:sample, :features)
    end

    test "seeds with only default features" do
      Mix.Project.push(SampleWithDefaultOnly)
      Mix.Feature.seed_features()
      assert Application.get_env(:sample, :features) == %{json: true}
    after
      Application.delete_env(:sample, :features)
    end

    test "seeds with only optional features" do
      Mix.Project.push(SampleWithOptionalOnly)
      Mix.Feature.seed_features()
      assert Application.get_env(:sample, :features) == %{debug_tools: false}
    after
      Application.delete_env(:sample, :features)
    end
  end

  describe "all/0" do
    test "returns map of features from Application env" do
      Mix.Project.push(SampleWithFeatures)
      Mix.Feature.seed_features()

      assert Mix.Feature.all() == %{
               json: true,
               logging: true,
               debug_tools: false,
               metrics: false
             }
    after
      Application.delete_env(:sample, :features)
    end

    test "returns empty map when no features seeded" do
      Mix.Project.push(SampleWithoutFeatures)
      assert Mix.Feature.all() == %{}
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
               Mix.Feature.seed_features()
               assert Mix.Feature.all() == %{json: true}
             end) =~ "Features [:json] appear in both :default and :optional"
    after
      Application.delete_env(:sample, :features)
    end
  end

  describe "enabled_features/0" do
    test "returns only enabled feature atoms" do
      Mix.Project.push(SampleWithFeatures)
      Mix.Feature.seed_features()
      enabled = Mix.Feature.enabled_features()
      assert Enum.sort(enabled) == [:json, :logging]
    after
      Application.delete_env(:sample, :features)
    end

    test "returns empty list when no features configured" do
      Mix.Project.push(SampleWithoutFeatures)
      assert Mix.Feature.enabled_features() == []
    end
  end

  describe "declared_features/0" do
    test "returns all declared feature atoms" do
      Mix.Project.push(SampleWithFeatures)
      Mix.Feature.seed_features()
      declared = Mix.Feature.declared_features()
      assert Enum.sort(declared) == [:debug_tools, :json, :logging, :metrics]
    after
      Application.delete_env(:sample, :features)
    end

    test "returns empty list when no features configured" do
      Mix.Project.push(SampleWithoutFeatures)
      assert Mix.Feature.declared_features() == []
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
        Mix.Feature.seed_features()
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
        Mix.Feature.seed_features()
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
        Mix.Feature.seed_features()
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
        Mix.Feature.seed_features()
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
               Mix.Feature.seed_features()
               assert Mix.Feature.all() == %{json: true, logging: true}
             end) =~ "Features [:json] appear in both :default and :optional"
    after
      Application.delete_env(:sample, :features)
    end
  end
end
