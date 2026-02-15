# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team

defmodule Mix.Dep.FeatureResolver do
  @moduledoc false

  def resolve(%Mix.Dep{features: requested, default_features: include_defaults?, app: app}) do
    dep_config = Mix.Project.config()[:features]
    resolve(app, requested, include_defaults?, dep_config)
  end

  def resolve(app, requested, include_defaults?, dep_config) do
    dep_defaults = Keyword.get(dep_config || [], :default, [])
    dep_optional = Keyword.get(dep_config || [], :optional, [])
    dep_all_declared = dep_defaults ++ dep_optional
    requested = Enum.uniq(requested)

    validate_requested!(app, requested, dep_all_declared)

    enabled =
      if include_defaults?,
        do: Enum.uniq(dep_defaults ++ requested),
        else: requested

    disabled = dep_all_declared -- enabled
    [default: enabled, optional: disabled]
  end

  defp validate_requested!(_app, [], _declared), do: :ok

  defp validate_requested!(app, requested, declared) do
    case requested -- declared do
      [] ->
        :ok

      undeclared ->
        Mix.raise(
          "Unknown features #{inspect(undeclared)} requested for dependency #{inspect(app)}. " <>
            "Declared features are: #{inspect(declared)}"
        )
    end
  end
end
