defmodule PetalBoilerplate.Catalog.Filters do
  @moduledoc """
  Typed filter state with parsing, quick presets, and URL serialization.

  This module is the single source of truth for filter state in the LLM model catalog.
  It provides a structured approach to filtering with composable quick filter presets.
  """

  alias PetalBoilerplate.Catalog

  @type t :: %__MODULE__{
          search: String.t(),
          provider_search: String.t(),
          provider_ids: MapSet.t(String.t()),
          capabilities: %{atom() => boolean()},
          modalities_in: MapSet.t(atom()),
          modalities_out: MapSet.t(atom()),
          min_context: integer() | nil,
          min_output: integer() | nil,
          max_cost_in: float() | nil,
          max_cost_out: float() | nil,
          show_deprecated: boolean(),
          allowed_only: boolean()
        }

  defstruct search: "",
            provider_search: "",
            provider_ids: MapSet.new(),
            capabilities: %{},
            modalities_in: MapSet.new(),
            modalities_out: MapSet.new(),
            min_context: nil,
            min_output: nil,
            max_cost_in: nil,
            max_cost_out: nil,
            show_deprecated: false,
            allowed_only: true

  @quick_filters [
    %{
      key: :openai,
      label: "OpenAI",
      icon: "hero-cpu-chip",
      description: "Models from OpenAI (GPT-4, GPT-3.5, etc.)",
      filter_type: :provider,
      target: :openai
    },
    %{
      key: :anthropic,
      label: "Anthropic",
      icon: "hero-sparkles",
      description: "Models from Anthropic (Claude)",
      filter_type: :provider,
      target: :anthropic
    },
    %{
      key: :google,
      label: "Google",
      icon: "hero-light-bulb",
      description: "Models from Google (Gemini)",
      filter_type: :provider,
      target: :google
    },
    %{
      key: :xai,
      label: "xAI",
      icon: "hero-bolt",
      description: "Models from xAI (Grok)",
      filter_type: :provider,
      target: :xai
    },
    %{
      key: :openrouter,
      label: "OpenRouter",
      icon: "hero-arrows-right-left",
      description: "Models from OpenRouter",
      filter_type: :provider,
      target: :openrouter
    },
    %{
      key: :tools,
      label: "Tools",
      icon: "hero-wrench",
      description: "Models that support function/tool calling",
      filter_type: :capability,
      target: :tools
    },
    %{
      key: :vision,
      label: "Vision",
      icon: "hero-eye",
      description: "Models that accept image input",
      filter_type: :modality_in,
      target: :image
    },
    %{
      key: :reasoning,
      label: "Reasoning",
      icon: "hero-academic-cap",
      description: "Models with extended thinking capabilities",
      filter_type: :capability,
      target: :reasoning
    },
    %{
      key: :context_100k,
      label: "100K+",
      icon: "hero-bolt",
      description: "Models with 100,000+ token context window",
      filter_type: :context,
      target: 100_000
    },
    %{
      key: :budget,
      label: "<$1/M",
      icon: "hero-currency-dollar",
      description: "Models under $1 per million input tokens",
      filter_type: :cost,
      target: 1.0
    },
    %{
      key: :chat,
      label: "Chat",
      icon: "hero-chat-bubble-left",
      description: "Conversational chat models",
      filter_type: :capability,
      target: :chat
    },
    %{
      key: :embeddings,
      label: "Embed",
      icon: "hero-hashtag",
      description: "Text embedding models",
      filter_type: :capability,
      target: :embeddings
    },
    %{
      key: :json,
      label: "JSON",
      icon: "hero-code-bracket",
      description: "Models with native JSON output",
      filter_type: :capability,
      target: :json_native
    },
    %{
      key: :audio,
      label: "Audio",
      icon: "hero-speaker-wave",
      description: "Models that process audio input",
      filter_type: :modality_in,
      target: :audio
    }
  ]

  @doc """
  Creates a new filter struct with default capabilities.
  """
  def new do
    %__MODULE__{capabilities: default_capabilities()}
  end

  @doc """
  Returns the list of quick filter definitions.
  """
  def quick_filters, do: @quick_filters

  @doc """
  Parses form/URL params into a Filters struct.
  """
  def from_params(params) when is_map(params) do
    %__MODULE__{
      search: params["search"] || params["q"] || "",
      provider_search: params["provider_search"] || "",
      provider_ids: parse_provider_ids(params["providers"]),
      capabilities: parse_capabilities(params),
      modalities_in: parse_modalities(params["modalities_in"] || params["in"]),
      modalities_out: parse_modalities(params["modalities_out"] || params["out"]),
      min_context: parse_int(params["min_context"] || params["ctx"]),
      min_output: parse_int(params["min_output"]),
      max_cost_in: parse_float(params["max_cost_in"] || params["cost"]),
      max_cost_out: parse_float(params["max_cost_out"]),
      show_deprecated: params["show_deprecated"] == "true",
      allowed_only: params["allowed_only"] != "false"
    }
  end

  @doc """
  Serializes a Filters struct to URL query params.
  """
  def to_params(%__MODULE__{} = f) do
    params = %{}

    params = if f.search != "", do: Map.put(params, "q", f.search), else: params

    params =
      if MapSet.size(f.provider_ids) > 0,
        do: Map.put(params, "providers", Enum.join(f.provider_ids, ",")),
        else: params

    active_caps =
      f.capabilities
      |> Enum.filter(fn {_, v} -> v end)
      |> Enum.map(fn {k, _} -> k end)

    params =
      if active_caps != [],
        do: Map.put(params, "caps", Enum.join(active_caps, ",")),
        else: params

    params =
      if MapSet.size(f.modalities_in) > 0,
        do: Map.put(params, "in", f.modalities_in |> MapSet.to_list() |> Enum.join(",")),
        else: params

    params =
      if MapSet.size(f.modalities_out) > 0,
        do: Map.put(params, "out", f.modalities_out |> MapSet.to_list() |> Enum.join(",")),
        else: params

    params = if f.min_context, do: Map.put(params, "ctx", f.min_context), else: params
    params = if f.min_output, do: Map.put(params, "min_output", f.min_output), else: params
    params = if f.max_cost_in, do: Map.put(params, "cost", f.max_cost_in), else: params
    params = if f.max_cost_out, do: Map.put(params, "max_cost_out", f.max_cost_out), else: params
    params = if f.show_deprecated, do: Map.put(params, "show_deprecated", "true"), else: params
    params = if not f.allowed_only, do: Map.put(params, "allowed_only", "false"), else: params

    params
  end

  @doc """
  Sets the provider IDs filter.
  """
  def set_providers(%__MODULE__{} = f, provider_ids) when is_struct(provider_ids, MapSet) do
    %{f | provider_ids: provider_ids}
  end

  def set_providers(%__MODULE__{} = f, provider_ids) when is_list(provider_ids) do
    %{f | provider_ids: MapSet.new(provider_ids)}
  end

  @doc """
  Clears all provider filters.
  """
  def clear_providers(%__MODULE__{} = f) do
    %{f | provider_ids: MapSet.new()}
  end

  @doc """
  Toggles a capability filter on/off.
  """
  def toggle_capability(%__MODULE__{} = f, cap) when is_atom(cap) do
    current = Map.get(f.capabilities, cap, false)
    %{f | capabilities: Map.put(f.capabilities, cap, not current)}
  end

  @doc """
  Toggles an input modality filter on/off.
  """
  def toggle_modality_in(%__MODULE__{} = f, modality) when is_atom(modality) do
    new_mods =
      if MapSet.member?(f.modalities_in, modality) do
        MapSet.delete(f.modalities_in, modality)
      else
        MapSet.put(f.modalities_in, modality)
      end

    %{f | modalities_in: new_mods}
  end

  @doc """
  Toggles an output modality filter on/off.
  """
  def toggle_modality_out(%__MODULE__{} = f, modality) when is_atom(modality) do
    new_mods =
      if MapSet.member?(f.modalities_out, modality) do
        MapSet.delete(f.modalities_out, modality)
      else
        MapSet.put(f.modalities_out, modality)
      end

    %{f | modalities_out: new_mods}
  end

  @doc """
  Sets the minimum context window filter.
  """
  def set_context_min(%__MODULE__{} = f, nil), do: %{f | min_context: nil}

  def set_context_min(%__MODULE__{} = f, value) when is_integer(value),
    do: %{f | min_context: value}

  @doc """
  Sets the minimum output filter.
  """
  def set_output_min(%__MODULE__{} = f, nil), do: %{f | min_output: nil}

  def set_output_min(%__MODULE__{} = f, value) when is_integer(value),
    do: %{f | min_output: value}

  @doc """
  Sets the maximum cost filter for input or output.
  """
  def set_cost_max(%__MODULE__{} = f, :input, nil), do: %{f | max_cost_in: nil}

  def set_cost_max(%__MODULE__{} = f, :input, value) when is_number(value),
    do: %{f | max_cost_in: value * 1.0}

  def set_cost_max(%__MODULE__{} = f, :output, nil), do: %{f | max_cost_out: nil}

  def set_cost_max(%__MODULE__{} = f, :output, value) when is_number(value),
    do: %{f | max_cost_out: value * 1.0}

  @doc """
  Sets the search term.
  """
  def set_search(%__MODULE__{} = f, term) when is_binary(term), do: %{f | search: term}

  @doc """
  Sets the provider search term.
  """
  def set_provider_search(%__MODULE__{} = f, term) when is_binary(term),
    do: %{f | provider_search: term}

  @doc """
  Applies a quick filter by key, toggling it on/off.
  """
  def apply_quick_filter(%__MODULE__{} = f, key) when is_atom(key) do
    case Enum.find(@quick_filters, &(&1.key == key)) do
      nil -> f
      qf -> do_apply_quick_filter(f, qf)
    end
  end

  def apply_quick_filter(%__MODULE__{} = f, key) when is_binary(key) do
    case safe_to_existing_atom(key) do
      nil -> f
      atom_key -> apply_quick_filter(f, atom_key)
    end
  end

  defp do_apply_quick_filter(f, %{filter_type: :capability, target: cap}) do
    toggle_capability(f, cap)
  end

  defp do_apply_quick_filter(f, %{filter_type: :modality_in, target: mod}) do
    toggle_modality_in(f, mod)
  end

  defp do_apply_quick_filter(f, %{filter_type: :context, target: value}) do
    if f.min_context == value do
      %{f | min_context: nil}
    else
      %{f | min_context: value}
    end
  end

  defp do_apply_quick_filter(f, %{filter_type: :cost, target: value}) do
    if f.max_cost_in == value do
      %{f | max_cost_in: nil}
    else
      %{f | max_cost_in: value}
    end
  end

  defp do_apply_quick_filter(f, %{filter_type: :provider, target: provider_id}) do
    provider_str = to_string(provider_id)

    if MapSet.member?(f.provider_ids, provider_str) do
      %{f | provider_ids: MapSet.delete(f.provider_ids, provider_str)}
    else
      %{f | provider_ids: MapSet.put(f.provider_ids, provider_str)}
    end
  end

  @doc """
  Returns the count of active filters.
  """
  def active_filter_count(%__MODULE__{} = f) do
    count = 0
    count = if f.search != "", do: count + 1, else: count
    count = count + MapSet.size(f.provider_ids)
    count = count + Enum.count(Map.values(f.capabilities), & &1)
    count = count + MapSet.size(f.modalities_in)
    count = count + MapSet.size(f.modalities_out)
    count = if f.min_context, do: count + 1, else: count
    count = if f.min_output, do: count + 1, else: count
    count = if f.max_cost_in, do: count + 1, else: count
    count = if f.max_cost_out, do: count + 1, else: count
    count = if f.show_deprecated, do: count + 1, else: count
    count = if not f.allowed_only, do: count + 1, else: count
    count
  end

  @doc """
  Returns a list of active quick filter keys.
  """
  def active_quick_filters(%__MODULE__{} = f) do
    @quick_filters
    |> Enum.filter(&quick_filter_active?(f, &1))
    |> Enum.map(& &1.key)
  end

  defp quick_filter_active?(f, %{filter_type: :capability, target: cap}) do
    Map.get(f.capabilities, cap, false)
  end

  defp quick_filter_active?(f, %{filter_type: :modality_in, target: mod}) do
    MapSet.member?(f.modalities_in, mod)
  end

  defp quick_filter_active?(f, %{filter_type: :context, target: value}) do
    f.min_context == value
  end

  defp quick_filter_active?(f, %{filter_type: :cost, target: value}) do
    f.max_cost_in == value
  end

  defp quick_filter_active?(f, %{filter_type: :provider, target: provider_id}) do
    MapSet.member?(f.provider_ids, to_string(provider_id))
  end

  @doc """
  Converts the Filters struct to a map format compatible with Catalog.list_models/3.
  """
  def to_filter_map(%__MODULE__{} = f) do
    %{
      search: f.search,
      provider_search: f.provider_search,
      provider_ids: f.provider_ids,
      capabilities: f.capabilities,
      modalities_in: f.modalities_in,
      modalities_out: f.modalities_out,
      min_context: f.min_context,
      min_output: f.min_output,
      max_cost_in: f.max_cost_in,
      max_cost_out: f.max_cost_out,
      show_deprecated: f.show_deprecated,
      allowed_only: f.allowed_only
    }
  end

  defp default_capabilities do
    Catalog.capability_definitions()
    |> Enum.map(fn {key, _path, _label, _tooltip} -> {key, false} end)
    |> Map.new()
  end

  defp parse_provider_ids(nil), do: MapSet.new()
  defp parse_provider_ids(""), do: MapSet.new()

  defp parse_provider_ids(str) when is_binary(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> MapSet.new()
  end

  defp parse_provider_ids(map) when is_map(map) do
    map
    |> Map.keys()
    |> MapSet.new()
  end

  defp parse_capabilities(params) do
    base_caps = default_capabilities()

    caps_from_string =
      case params["caps"] do
        nil ->
          %{}

        "" ->
          %{}

        str when is_binary(str) ->
          str
          |> String.split(",", trim: true)
          |> Enum.reduce(%{}, fn cap_str, acc ->
            case safe_to_existing_atom(cap_str) do
              nil -> acc
              atom -> Map.put(acc, atom, true)
            end
          end)
      end

    caps_from_params =
      Catalog.capability_definitions()
      |> Enum.reduce(%{}, fn {key, _path, _label, _tooltip}, acc ->
        param_key = "cap_#{key}"

        if params[param_key] == "true" do
          Map.put(acc, key, true)
        else
          acc
        end
      end)

    base_caps
    |> Map.merge(caps_from_string)
    |> Map.merge(caps_from_params)
  end

  defp parse_modalities(nil), do: MapSet.new()
  defp parse_modalities(""), do: MapSet.new()

  defp parse_modalities(str) when is_binary(str) do
    str
    |> String.split(",", trim: true)
    |> Enum.reduce(MapSet.new(), fn mod_str, acc ->
      case safe_to_existing_atom(mod_str) do
        nil -> acc
        atom -> MapSet.put(acc, atom)
      end
    end)
  end

  defp parse_modalities(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.reduce(MapSet.new(), fn key, acc ->
      case safe_to_existing_atom(key) do
        nil -> acc
        atom -> MapSet.put(acc, atom)
      end
    end)
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(val) when is_integer(val), do: val

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val * 1.0

  defp parse_float(str) when is_binary(str) do
    case Float.parse(str) do
      {float, _} -> float
      :error -> nil
    end
  end

  defp safe_to_existing_atom(str) when is_binary(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> nil
  end
end
