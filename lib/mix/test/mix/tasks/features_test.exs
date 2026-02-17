# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

Code.require_file("../../test_helper.exs", __DIR__)

defmodule Mix.Tasks.FeaturesTest do
  use MixTest.Case

  defmodule FeaturesApp do
    def project do
      [app: :sample, version: "0.1.0"]
    end
  end

  defmodule NoFeaturesApp do
    def project do
      [app: :sample, version: "0.1.0"]
    end
  end

  test "lists features with enabled/disabled status" do
    Mix.Project.push(FeaturesApp)

    Application.put_env(:sample, :features, %{
      json: true,
      logging: true,
      debug_tools: false,
      metrics: false
    })

    Mix.Tasks.Features.run([])

    assert_received {:mix_shell, :info, ["Features for :sample\n"]}
    assert_received {:mix_shell, :info, ["  * debug_tools (disabled)"]}
    assert_received {:mix_shell, :info, ["  * json (enabled)"]}
    assert_received {:mix_shell, :info, ["  * logging (enabled)"]}
    assert_received {:mix_shell, :info, ["  * metrics (disabled)"]}
  after
    Application.delete_env(:sample, :features)
  end

  test "shows no features message when none configured" do
    Mix.Project.push(NoFeaturesApp)
    Mix.Tasks.Features.run([])

    assert_received {:mix_shell, :info, ["No features configured for :sample"]}
  end
end
