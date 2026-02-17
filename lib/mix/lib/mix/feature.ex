# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

defmodule Mix.Feature do
  @moduledoc """
  Compile-time feature flags for Mix projects.

  `Mix.Feature` provides a mechanism for conditionally compiling code based
  on feature flags declared in your project's `mix.exs`. This is similar to
  Rust's `cfg(feature = "...")` semantics — features resolve to literal
  `true` or `false` at compile time, enabling dead code elimination.

  ## Configuration

  Features are declared in the `project/0` function of your `mix.exs`:

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

    * `:default` — features enabled by default
    * `:optional` — features that are declared but disabled by default

  Per-environment features work naturally using standard Elixir:

      features: [
        default: [:json] ++ if(Mix.env() == :dev, do: [:debug_tools], else: [])
      ]

  ## Usage

  Use `Application.feature_enabled?/2` in module bodies to conditionally
  compile code:

      if Application.feature_enabled?(:my_app, :json) do
        defmodule MyApp.JsonParser do
          # only compiled when :json feature is enabled
        end
      end

  Query functions can be used at compile time via module attributes:

      @all_features Mix.Feature.all()
      @enabled Mix.Feature.enabled_features()

  ## Recompilation

  Modules that use `Application.feature_enabled?/2` are automatically
  recompiled when feature configuration changes, using the same mechanism
  as `Application.compile_env/3`.
  """

  @doc """
  Returns a map of all declared features and their enabled status.

  Features listed under `:default` are `true`, features listed under
  `:optional` are `false`.

  ## Examples

      # Given features: [default: [:json], optional: [:metrics]]
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

      # Given features: [default: [:json, :logging], optional: [:metrics]]
      Mix.Feature.enabled_features()
      #=> [:json, :logging]

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

      # Given features: [default: [:json], optional: [:metrics]]
      Mix.Feature.declared_features()
      #=> [:json, :metrics]

  """
  @spec declared_features() :: [atom()]
  def declared_features do
    all() |> Map.keys()
  end

  @doc """
  Seeds the Application environment with features from the project config.

  Parses the `:features` configuration from `mix.exs` and writes the
  resulting feature map to `Application.put_env(app, :features, map)`.
  This must be called before compilation so that
  `Application.feature_enabled?/2` can read the values.
  """
  @spec seed_features() :: :ok
  def seed_features do
    config = Mix.Project.config()
    app = config[:app]
    features_config = config[:features]
    features_map = parse_features(features_config)
    Application.put_env(app, :features, features_map)
  end

  @doc false
  def parse_features(nil), do: %{}
  def parse_features([]), do: %{}

  def parse_features(config) when is_list(config) do
    validate_features_config!(config)

    default = Keyword.get(config, :default, [])
    optional = Keyword.get(config, :optional, [])

    default_map = Map.from_keys(default, true)
    optional_map = Map.from_keys(optional, false)

    Map.merge(optional_map, default_map)
  end

  def parse_features(config) do
    Mix.raise(
      "Expected :features in project configuration to be a keyword list, " <>
        "got: #{inspect(config)}"
    )
  end

  defp validate_features_config!(config) do
    unknown_keys = Keyword.keys(config) -- [:default, :optional]

    if unknown_keys != [] do
      Mix.raise(
        "Unknown keys #{inspect(unknown_keys)} in :features configuration. " <>
          "Supported keys are: :default, :optional"
      )
    end

    validate_feature_list!(:default, Keyword.get(config, :default, []))
    validate_feature_list!(:optional, Keyword.get(config, :optional, []))

    overlap =
      Keyword.get(config, :default, []) --
        (Keyword.get(config, :default, []) -- Keyword.get(config, :optional, []))

    if overlap != [] do
      IO.warn(
        "Features #{inspect(overlap)} appear in both :default and :optional. " <>
          "They will be enabled since :default takes precedence"
      )
    end
  end

  defp validate_feature_list!(key, list) do
    unless is_list(list) and Enum.all?(list, &is_atom/1) do
      Mix.raise(
        "Expected #{inspect(key)} in :features to be a list of atoms, " <>
          "got: #{inspect(list)}"
      )
    end
  end
end
