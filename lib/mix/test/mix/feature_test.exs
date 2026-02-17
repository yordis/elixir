# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

Code.require_file("../test_helper.exs", __DIR__)

defmodule Mix.FeatureTest do
  use MixTest.Case

  defmodule SampleApp do
    def project do
      [app: :sample, version: "0.1.0"]
    end
  end

  describe "all/0" do
    test "returns features from Application env" do
      Mix.Project.push(SampleApp)
      Application.put_env(:sample, :features, %{json: true, metrics: false})

      assert Mix.Feature.all() == %{json: true, metrics: false}
    after
      Application.delete_env(:sample, :features)
    end

    test "returns empty map when no features configured" do
      Mix.Project.push(SampleApp)
      assert Mix.Feature.all() == %{}
    end
  end

  describe "enabled_features/0" do
    test "returns only enabled feature atoms" do
      Mix.Project.push(SampleApp)
      Application.put_env(:sample, :features, %{json: true, logging: true, metrics: false})
      enabled = Mix.Feature.enabled_features()
      assert Enum.sort(enabled) == [:json, :logging]
    after
      Application.delete_env(:sample, :features)
    end

    test "returns empty list when no features configured" do
      Mix.Project.push(SampleApp)
      assert Mix.Feature.enabled_features() == []
    end
  end

  describe "declared_features/0" do
    test "returns all declared feature atoms" do
      Mix.Project.push(SampleApp)
      Application.put_env(:sample, :features, %{json: true, metrics: false})
      declared = Mix.Feature.declared_features()
      assert Enum.sort(declared) == [:json, :metrics]
    after
      Application.delete_env(:sample, :features)
    end

    test "returns empty list when no features configured" do
      Mix.Project.push(SampleApp)
      assert Mix.Feature.declared_features() == []
    end
  end
end
