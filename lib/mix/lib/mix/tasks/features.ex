# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

defmodule Mix.Tasks.Features do
  use Mix.Task

  @shortdoc "Lists the project's declared features and their status"

  @moduledoc """
  Lists all declared features and whether they are enabled or disabled.

      $ mix features

  Features are declared in `mix.exs` under the `:features` key:

      def project do
        [
          app: :my_app,
          version: "1.0.0",
          features: [
            default: [:json, :logging],
            optional: [:debug_tools, :metrics]
          ]
        ]
      end

  """

  @impl true
  def run(_args) do
    Mix.Project.get!()
    config = Mix.Project.config()
    app = config[:app]
    features = Mix.Feature.all()
    shell = Mix.shell()

    if features == %{} do
      shell.info("No features configured for #{inspect(app)}")
    else
      shell.info("Features for #{inspect(app)}\n")

      features
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.each(fn {feature, enabled?} ->
        status = if enabled?, do: "enabled", else: "disabled"
        shell.info("  * #{feature} (#{status})")
      end)
    end
  end
end
