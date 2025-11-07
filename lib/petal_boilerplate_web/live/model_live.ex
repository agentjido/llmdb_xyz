defmodule PetalBoilerplateWeb.ModelLive do
  use PetalBoilerplateWeb, :live_view

  defp model_dom_id(model) do
    "model-card-#{model.provider}-#{:erlang.phash2({model.provider, model.id})}"
  end

  # Whitelist for sort fields to avoid atom exhaustion
  @sort_fields %{
    "provider" => :provider,
    "id" => :id,
    "name" => :name,
    "family" => :family,
    "context" => :context,
    "output" => :output,
    "cost_in" => :cost_in,
    "cost_out" => :cost_out
  }

  @impl true
  def mount(_params, _session, socket) do
    default_filters = %{
      search: "",
      provider_search: "",
      provider_ids: MapSet.new(),
      capabilities: %{
        chat: false,
        embeddings: false,
        reasoning: false,
        tools: false,
        tools_streaming: false,
        tools_strict: false,
        tools_parallel: false,
        json_native: false,
        json_schema: false,
        json_strict: false,
        streaming_text: false,
        streaming_tool_calls: false
      },
      modalities_in: MapSet.new(),
      modalities_out: MapSet.new(),
      min_context: nil,
      min_output: nil,
      max_cost_in: nil,
      max_cost_out: nil,
      show_deprecated: false,
      allowed_only: true
    }

    sort = %{by: :provider, dir: :asc}

    if connected?(socket) do
      providers = LLMDb.provider()

      all_models =
        LLMDb.model()
        |> Enum.map(&enrich_model/1)

      filtered = filter_models(all_models, default_filters)
      sorted = sort_models(filtered, sort)

      {:ok,
       assign(socket,
         page_title: "LLM Model Database",
         providers: providers,
         all_models: all_models,
         models: sorted,
         filters: default_filters,
         sort: sort,
         total: length(sorted),
         filters_open: false,
         search_value: default_filters.search
       )}
    else
      {:ok,
       assign(socket,
         page_title: "LLM Model Database",
         providers: [],
         all_models: [],
         models: [],
         filters: default_filters,
         sort: sort,
         total: 0,
         filters_open: false,
         search_value: ""
       )}
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = parse_filters(params, socket.assigns.filters)
    filtered = filter_models(socket.assigns.all_models, filters)
    sorted = sort_models(filtered, socket.assigns.sort)

    {:noreply,
     assign(socket,
       filters: filters,
       models: sorted,
       total: length(sorted),
       search_value: filters.search
     )}
  end

  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, filters_open: !socket.assigns.filters_open)}
  end

  @impl true
  def handle_event("sort", %{"by" => field_str}, socket) do
    field = Map.fetch!(@sort_fields, field_str)
    current_sort = socket.assigns.sort

    new_sort =
      if current_sort.by == field do
        %{by: field, dir: toggle_direction(current_sort.dir)}
      else
        %{by: field, dir: :asc}
      end

    sorted = sort_models(socket.assigns.models, new_sort)

    {:noreply, assign(socket, sort: new_sort, models: sorted)}
  end

  # Model enrichment - precompute indices for fast filtering
  defp enrich_model(model) do
    aliases = Enum.join(model.aliases || [], " ")
    tags = Enum.join(model.tags || [], " ")

    caps = model.capabilities || %{}

    capability_terms =
      []
      |> then(&if caps[:chat], do: ["chat" | &1], else: &1)
      |> then(&if caps[:embeddings], do: ["embeddings" | &1], else: &1)
      |> then(&if get_in(caps, [:reasoning, :enabled]), do: ["reasoning" | &1], else: &1)
      |> then(&if get_in(caps, [:tools, :enabled]), do: ["tools" | &1], else: &1)
      |> then(&if get_in(caps, [:json, :native]), do: ["json" | &1], else: &1)
      |> then(&if get_in(caps, [:streaming, :text]), do: ["streaming" | &1], else: &1)
      |> Enum.join(" ")

    search =
      [
        to_string(model.provider),
        model.id,
        model.name,
        model.family || "",
        aliases,
        tags,
        capability_terms
      ]
      |> Enum.filter(&is_binary/1)
      |> Enum.join(" ")
      |> String.downcase()

    caps_set =
      [:chat, :embeddings]
      |> Enum.reduce(MapSet.new(), fn k, acc ->
        if Map.get(caps, k), do: MapSet.put(acc, k), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:reasoning, :enabled]), do: MapSet.put(acc, :reasoning), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:tools, :enabled]), do: MapSet.put(acc, :tools), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:tools, :streaming]), do: MapSet.put(acc, :tools_streaming), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:tools, :strict]), do: MapSet.put(acc, :tools_strict), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:tools, :parallel]), do: MapSet.put(acc, :tools_parallel), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:json, :native]), do: MapSet.put(acc, :json_native), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:json, :schema]), do: MapSet.put(acc, :json_schema), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:json, :strict]), do: MapSet.put(acc, :json_strict), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:streaming, :text]), do: MapSet.put(acc, :streaming_text), else: acc
      end)
      |> then(fn acc ->
        if get_in(caps, [:streaming, :tool_calls]),
          do: MapSet.put(acc, :streaming_tool_calls),
          else: acc
      end)

    modalities = model.modalities || %{}
    in_set = MapSet.new(modalities[:input] || [])
    out_set = MapSet.new(modalities[:output] || [])

    model
    |> Map.put(:__search, search)
    |> Map.put(:__caps, caps_set)
    |> Map.put(:__in, in_set)
    |> Map.put(:__out, out_set)
    |> Map.put(:__context, get_in(model.limits, [:context]) || 0)
    |> Map.put(:__output, get_in(model.limits, [:output]) || 0)
    |> Map.put(:__cost_in, get_in(model.cost, [:input]))
    |> Map.put(:__cost_out, get_in(model.cost, [:output]))
    |> Map.put(:__allowed?, LLMDb.allowed?(model))
  end

  # Filter parsing
  defp parse_filters(params, _current_filters) do
    %{
      search: params["search"] || "",
      provider_search: params["provider_search"] || "",
      provider_ids: parse_provider_ids(params["providers"]),
      capabilities: parse_capabilities(params),
      modalities_in: parse_modalities(params["modalities_in"]),
      modalities_out: parse_modalities(params["modalities_out"]),
      min_context: parse_int(params["min_context"]),
      min_output: parse_int(params["min_output"]),
      max_cost_in: parse_float(params["max_cost_in"]),
      max_cost_out: parse_float(params["max_cost_out"]),
      show_deprecated: params["show_deprecated"] == "true",
      allowed_only: params["allowed_only"] != "false"
    }
  end

  defp parse_provider_ids(nil), do: MapSet.new()

  defp parse_provider_ids(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(&String.to_existing_atom/1)
    |> MapSet.new()
  end

  defp parse_capabilities(params) do
    %{
      chat: params["cap_chat"] == "true",
      embeddings: params["cap_embeddings"] == "true",
      reasoning: params["cap_reasoning"] == "true",
      tools: params["cap_tools"] == "true",
      tools_streaming: params["cap_tools_streaming"] == "true",
      tools_strict: params["cap_tools_strict"] == "true",
      tools_parallel: params["cap_tools_parallel"] == "true",
      json_native: params["cap_json_native"] == "true",
      json_schema: params["cap_json_schema"] == "true",
      json_strict: params["cap_json_strict"] == "true",
      streaming_text: params["cap_streaming_text"] == "true",
      streaming_tool_calls: params["cap_streaming_tool_calls"] == "true"
    }
  end

  defp parse_modalities(nil), do: MapSet.new()

  defp parse_modalities(map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(&String.to_existing_atom/1)
    |> MapSet.new()
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil

  defp parse_float(str) when is_binary(str) do
    case Float.parse(str) do
      {float, _} -> float
      :error -> nil
    end
  end

  # Filtering logic
  defp filter_models(models, filters) do
    models
    |> Enum.filter(fn model ->
      passes_provider?(model, filters.provider_ids) and
        passes_search?(model, filters.search) and
        passes_deprecated?(model, filters.show_deprecated) and
        passes_allowed?(model, filters.allowed_only) and
        passes_capabilities?(model, filters.capabilities) and
        passes_modalities?(model, filters.modalities_in, filters.modalities_out) and
        passes_limits?(model, filters.min_context, filters.min_output) and
        passes_cost?(model, filters.max_cost_in, filters.max_cost_out)
    end)
  end

  defp passes_provider?(model, provider_ids) do
    MapSet.size(provider_ids) == 0 or MapSet.member?(provider_ids, model.provider)
  end

  defp passes_search?(_model, ""), do: true

  defp passes_search?(%{__search: search_idx}, term) do
    String.contains?(search_idx, String.downcase(term))
  end

  defp passes_deprecated?(_model, true), do: true

  defp passes_deprecated?(model, false) do
    not (model.deprecated || Map.get(model, :deprecated?, false))
  end

  defp passes_allowed?(_model, false), do: true
  defp passes_allowed?(%{__allowed?: allowed?}, true), do: allowed?

  defp passes_capabilities?(%{__caps: caps_set}, filters) do
    required =
      []
      |> then(&if filters.chat, do: [:chat | &1], else: &1)
      |> then(&if filters.embeddings, do: [:embeddings | &1], else: &1)
      |> then(&if filters.reasoning, do: [:reasoning | &1], else: &1)
      |> then(&if filters.tools, do: [:tools | &1], else: &1)
      |> then(&if filters.tools_streaming, do: [:tools_streaming | &1], else: &1)
      |> then(&if filters.tools_strict, do: [:tools_strict | &1], else: &1)
      |> then(&if filters.tools_parallel, do: [:tools_parallel | &1], else: &1)
      |> then(&if filters.json_native, do: [:json_native | &1], else: &1)
      |> then(&if filters.json_schema, do: [:json_schema | &1], else: &1)
      |> then(&if filters.json_strict, do: [:json_strict | &1], else: &1)
      |> then(&if filters.streaming_text, do: [:streaming_text | &1], else: &1)
      |> then(&if filters.streaming_tool_calls, do: [:streaming_tool_calls | &1], else: &1)

    Enum.all?(required, &MapSet.member?(caps_set, &1))
  end

  defp passes_modalities?(%{__in: in_set, __out: out_set}, in_filters, out_filters) do
    in_ok = MapSet.size(in_filters) == 0 or MapSet.subset?(in_filters, in_set)
    out_ok = MapSet.size(out_filters) == 0 or MapSet.subset?(out_filters, out_set)
    in_ok and out_ok
  end

  defp passes_limits?(%{__context: ctx, __output: out}, min_context, min_output) do
    context_ok = is_nil(min_context) or (is_integer(ctx) and ctx >= min_context)
    output_ok = is_nil(min_output) or (is_integer(out) and out >= min_output)
    context_ok and output_ok
  end

  defp passes_cost?(%{__cost_in: cin, __cost_out: cout}, max_in, max_out) do
    in_ok = is_nil(max_in) or (is_number(cin) and cin <= max_in)
    out_ok = is_nil(max_out) or (is_number(cout) and cout <= max_out)
    in_ok and out_ok
  end

  # Sorting logic
  defp sort_models(models, %{by: by, dir: dir}) do
    models
    |> Enum.sort_by(&sort_value(&1, by), sort_direction(dir))
  end

  defp sort_value(model, :provider), do: {model.provider, model.id}
  defp sort_value(model, :id), do: model.id
  defp sort_value(model, :name), do: model.name
  defp sort_value(model, :family), do: model.family || ""
  defp sort_value(model, :context), do: model.__context || 0
  defp sort_value(model, :output), do: model.__output || 0
  defp sort_value(model, :cost_in), do: model.__cost_in || 999_999
  defp sort_value(model, :cost_out), do: model.__cost_out || 999_999

  defp sort_direction(:asc), do: :asc
  defp sort_direction(:desc), do: :desc

  defp toggle_direction(:asc), do: :desc
  defp toggle_direction(:desc), do: :asc

  # Public helpers for formatting (used by components)
  def format_number(nil), do: "N/A"

  def format_number(num) when is_integer(num) do
    num
    |> to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end

  def format_number(num) when is_float(num) do
    :erlang.float_to_binary(num, decimals: 2)
  end

  def format_cost(nil), do: "N/A"

  def format_cost(cost) when is_number(cost) do
    "$#{:erlang.float_to_binary(cost * 1.0, decimals: 2)}"
  end
end
