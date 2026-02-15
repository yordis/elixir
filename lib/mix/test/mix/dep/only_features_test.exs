# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

Code.require_file("../../test_helper.exs", __DIR__)

defmodule Mix.Dep.OnlyFeaturesTest do
  use MixTest.Case

  describe "filter_by_features in children/1" do
    defmodule WithEnabledFeature do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [:json], optional: [:metrics]],
          deps: [
            {:json_dep, path: "deps/json_dep", only_features: [:json]}
          ]
        ]
      end
    end

    test "dep included when required feature is enabled" do
      Mix.Project.push(WithEnabledFeature)
      deps = Mix.Dep.Loader.children(false)
      assert Enum.any?(deps, &(&1.app == :json_dep))
    end

    defmodule WithDisabledFeature do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [:json], optional: [:metrics]],
          deps: [
            {:metrics_dep, path: "deps/metrics_dep", only_features: [:metrics]}
          ]
        ]
      end
    end

    test "dep excluded when required feature is disabled" do
      Mix.Project.push(WithDisabledFeature)
      deps = Mix.Dep.Loader.children(false)
      refute Enum.any?(deps, &(&1.app == :metrics_dep))
    end

    defmodule WithOrSemantics do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [:json], optional: [:metrics]],
          deps: [
            {:multi_dep, path: "deps/multi_dep", only_features: [:metrics, :json]}
          ]
        ]
      end
    end

    test "OR semantics — ANY matching feature includes the dep" do
      Mix.Project.push(WithOrSemantics)
      deps = Mix.Dep.Loader.children(false)
      assert Enum.any?(deps, &(&1.app == :multi_dep))
    end

    defmodule WithoutOnlyFeatures do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [:json], optional: [:metrics]],
          deps: [
            {:regular_dep, path: "deps/regular_dep"}
          ]
        ]
      end
    end

    test "dep without only_features is always included" do
      Mix.Project.push(WithoutOnlyFeatures)
      deps = Mix.Dep.Loader.children(false)
      assert Enum.any?(deps, &(&1.app == :regular_dep))
    end

    defmodule WithNoFeaturesConfig do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          deps: [
            {:gated_dep, path: "deps/gated_dep", only_features: [:json]},
            {:regular_dep, path: "deps/regular_dep"}
          ]
        ]
      end
    end

    test "no features configured — all deps pass through" do
      Mix.Project.push(WithNoFeaturesConfig)
      deps = Mix.Dep.Loader.children(false)
      apps = Enum.map(deps, & &1.app)
      assert :gated_dep in apps
      assert :regular_dep in apps
    end

    defmodule WithEmptyDefaults do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [], optional: [:json]],
          deps: [
            {:json_dep, path: "deps/json_dep", only_features: [:json]}
          ]
        ]
      end
    end

    test "empty default features — feature-gated dep excluded" do
      Mix.Project.push(WithEmptyDefaults)
      deps = Mix.Dep.Loader.children(false)
      refute Enum.any?(deps, &(&1.app == :json_dep))
    end

    defmodule WithAllFeaturesDisabled do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [:json], optional: [:metrics]],
          deps: [
            {:metrics_only, path: "deps/metrics_only", only_features: [:metrics]},
            {:absent_feature, path: "deps/absent_feature", only_features: [:nonexistent]}
          ]
        ]
      end
    end

    test "dep excluded when none of its required features are enabled" do
      Mix.Project.push(WithAllFeaturesDisabled)
      deps = Mix.Dep.Loader.children(false)
      apps = Enum.map(deps, & &1.app)
      refute :metrics_only in apps
      refute :absent_feature in apps
    end

    defmodule WithMixedDeps do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          features: [default: [:json, :logging], optional: [:metrics, :debug]],
          deps: [
            {:always_dep, path: "deps/always_dep"},
            {:json_dep, path: "deps/json_dep", only_features: [:json]},
            {:metrics_dep, path: "deps/metrics_dep", only_features: [:metrics]},
            {:multi_dep, path: "deps/multi_dep", only_features: [:metrics, :logging]}
          ]
        ]
      end
    end

    test "mixed deps — only matching features pass" do
      Mix.Project.push(WithMixedDeps)
      deps = Mix.Dep.Loader.children(false)
      apps = Enum.map(deps, & &1.app)
      assert :always_dep in apps
      assert :json_dep in apps
      refute :metrics_dep in apps
      assert :multi_dep in apps
    end
  end

  describe "validate_only_features_opt!" do
    defmodule WithNonListOnlyFeatures do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          deps: [{:bad_dep, path: "deps/bad_dep", only_features: :not_a_list}]
        ]
      end
    end

    test "raises on non-list only_features" do
      Mix.Project.push(WithNonListOnlyFeatures)

      assert_raise Mix.Error, ~r/Expected :only_features in dependency :bad_dep/, fn ->
        Mix.Dep.Loader.children(false)
      end
    end

    defmodule WithEmptyOnlyFeatures do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          deps: [{:bad_dep, path: "deps/bad_dep", only_features: []}]
        ]
      end
    end

    test "raises on empty list only_features" do
      Mix.Project.push(WithEmptyOnlyFeatures)

      assert_raise Mix.Error, ~r/Expected :only_features in dependency :bad_dep/, fn ->
        Mix.Dep.Loader.children(false)
      end
    end

    defmodule WithNonAtomOnlyFeatures do
      def project do
        [
          app: :test_app,
          version: "0.1.0",
          deps: [{:bad_dep, path: "deps/bad_dep", only_features: ["not_atom"]}]
        ]
      end
    end

    test "raises on non-atom entries in only_features" do
      Mix.Project.push(WithNonAtomOnlyFeatures)

      assert_raise Mix.Error, ~r/Expected :only_features in dependency :bad_dep/, fn ->
        Mix.Dep.Loader.children(false)
      end
    end
  end
end
