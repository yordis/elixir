# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

defmodule Mix.Feature do
  @moduledoc """
  Compile-time feature flags for Mix projects.

  `Mix.Feature` provides query functions for feature flags stored in the
  application environment. Features are configured via standard Elixir
  configuration and checked at compile time using
  `Application.feature_enabled?/2`.

  ## Configuration

  Features are configured via config files or `def application` in your
  `mix.exs`:

      # config/config.exs
      import Config
      config :my_app, features: %{json: true, metrics: false}

  Or in `mix.exs`:

      def application do
        [env: [features: %{json: true, metrics: false}]]
      end

  ## Usage

  Use `Application.feature_enabled?/2` in module bodies to conditionally
  compile code:

      if Application.feature_enabled?(:my_app, :json) do
        defmodule MyApp.JsonParser do
          # only compiled when :json feature is enabled
        end
      end

  ## Recompilation

  Modules that use `Application.feature_enabled?/2` are automatically
  recompiled when feature configuration changes, using the same mechanism
  as `Application.compile_env/3`.
  """

  @doc """
  Returns a map of all declared features and their enabled status.

  ## Examples

      # Given config :my_app, features: %{json: true, metrics: false}
      Mix.Feature.all()
      #=> %{json: true, metrics: false}

  """
  @spec all() :: %{atom() => boolean()}
  def all do
    app = Mix.Project.config()[:app]
    Application.get_env(app, :features, %{})
  end

  @doc """
  Returns the list of enabled feature atoms.

  ## Examples

      # Given config :my_app, features: %{json: true, metrics: false}
      Mix.Feature.enabled_features()
      #=> [:json]

  """
  @spec enabled_features() :: [atom()]
  def enabled_features do
    all()
    |> Enum.filter(fn {_, enabled?} -> enabled? end)
    |> Enum.map(fn {feature, _} -> feature end)
  end

  @doc """
  Returns the list of all declared feature atoms (both enabled and disabled).

  ## Examples

      # Given config :my_app, features: %{json: true, metrics: false}
      Mix.Feature.declared_features()
      #=> [:json, :metrics]

  """
  @spec declared_features() :: [atom()]
  def declared_features do
    all() |> Map.keys()
  end
end
