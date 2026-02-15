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

  Use the `enabled?/1` macro in module bodies to conditionally compile code:

      if Mix.Feature.enabled?(:json) do
        defmodule MyApp.JsonParser do
          # only compiled when :json feature is enabled
        end
      end

  Query functions can be used at compile time via module attributes:

      @all_features Mix.Feature.all()
      @enabled Mix.Feature.enabled_features()

  ## Recompilation

  Modules that use `Mix.Feature.enabled?/1` are automatically recompiled
  when `mix.exs` changes, using the same mechanism as `Mix.Project`.
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
    features_config = Mix.Project.config()[:features]
    parse_features(features_config)
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
  Checks if a feature is enabled at compile time.

  This macro resolves to a literal `true` or `false` at compile time,
  allowing the compiler to eliminate dead code branches. It must be
  called in a module body (not inside function definitions).

  A warning is emitted if the feature is not declared in the project
  configuration, which helps catch typos.

  ## Examples

      if Mix.Feature.enabled?(:json) do
        def parse(data), do: Jason.decode!(data)
      end

  """
  defmacro enabled?(feature) when is_atom(feature) do
    features = parse_features(Mix.Project.config()[:features])

    unless Map.has_key?(features, feature) do
      IO.warn(
        "feature #{inspect(feature)} is not declared in your mix.exs :features configuration",
        __CALLER__
      )
    end

    Map.get(features, feature, false)
  end

  defmacro enabled?(feature) do
    raise ArgumentError,
          "Mix.Feature.enabled?/1 expects a literal atom, got: #{Macro.to_string(feature)}"
  end

  defp parse_features(nil), do: %{}
  defp parse_features([]), do: %{}

  defp parse_features(config) when is_list(config) do
    default = Keyword.get(config, :default, [])
    optional = Keyword.get(config, :optional, [])

    default_map = Map.from_keys(default, true)
    optional_map = Map.from_keys(optional, false)

    Map.merge(optional_map, default_map)
  end
end
