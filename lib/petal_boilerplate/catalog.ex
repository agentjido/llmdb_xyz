defmodule PetalBoilerplate.Catalog do
  @moduledoc """
  Domain logic for querying, filtering, and sorting LLM models.

  This module encapsulates all the business logic for working with the llm_db
  model catalog, including enrichment for fast filtering and sorting operations.

  Models are stored in `:persistent_term` for shared read access, with ETS indexes
  for direct model lookups.
  """

  alias PetalBoilerplate.Catalog.Filters

  @ets_table :catalog_models
  @models_key {__MODULE__, :models}
  @model_count_key {__MODULE__, :model_count}
  @default_page_size 50

  @capability_definitions [
    {:chat, [:chat], "Chat", "Supports conversational chat interactions"},
    {:embeddings, [:embeddings], "Embed", "Can generate text embeddings for semantic search"},
    {:reasoning, [:reasoning, :enabled], "Reason",
     "Extended thinking and chain-of-thought reasoning"},
    {:tools, [:tools, :enabled], "Tools", "Can call external tools and functions"},
    {:tools_streaming, [:tools, :streaming], nil, nil},
    {:tools_strict, [:tools, :strict], nil, nil},
    {:tools_parallel, [:tools, :parallel], nil, nil},
    {:json_native, [:json, :native], "JSON", "Native JSON output mode"},
    {:json_schema, [:json, :schema], nil, nil},
    {:json_strict, [:json, :strict], nil, nil},
    {:streaming_text, [:streaming, :text], "Stream", "Supports streaming text responses"},
    {:streaming_tool_calls, [:streaming, :tool_calls], nil, nil}
  ]

  @doc """
  Returns the list of capability definitions with their keys, paths, and labels.
  Used for consistent capability handling across enrichment and UI.
  """
  def capability_definitions, do: @capability_definitions

  @doc """
  Returns capabilities that have UI labels (for badges).
  Returns list of {key, path, label, tooltip} tuples.
  """
  def labeled_capabilities do
    @capability_definitions
    |> Enum.filter(fn {_key, _path, label, _tooltip} -> label != nil end)
    |> Enum.map(fn {key, path, label, tooltip} -> {key, path, label, tooltip} end)
  end

  @doc """
  Returns all providers from llm_db.
  """
  def list_providers do
    LLMDB.providers()
  end

  @doc """
  Initializes the ETS cache for enriched models.
  Call this at application startup.
  """
  def init_cache do
    raw_models = LLMDB.models()
    history_index = build_history_index()
    models = raw_models |> Enum.map(&enrich_model(&1, history_index))
    store_models(models)
    :ok
  end

  @doc """
  Rebuilds the ETS cache using the current runtime configuration.
  """
  def refresh_cache do
    init_cache()
  end

  @doc """
  Finds a single model by provider and model_id.
  Used for direct lookups (e.g., for OG meta tags on initial page load).
  """
  def get_model(provider, model_id) do
    lookup_index({:provider_model, to_string(provider), model_id})
  end

  @doc """
  Finds a single model by its DOM id.
  """
  def get_model_by_dom_id(dom_id) do
    lookup_index({:dom_id, dom_id})
  end

  def find_model(provider, model_id) do
    get_model(provider, model_id)
  end

  @doc """
  Returns all models, enriched with computed fields for fast filtering.
  Uses `:persistent_term` if available, otherwise loads and caches.
  """
  def list_all_models do
    case :persistent_term.get(@models_key, :undefined) do
      :undefined ->
        init_cache()
        list_all_models()

      models ->
        maybe_attach_history_metadata(models)
    end
  end

  @doc """
  Returns the total number of models in the catalog.
  """
  def total_model_count do
    case :persistent_term.get(@model_count_key, :undefined) do
      :undefined ->
        init_cache()
        total_model_count()

      count ->
        count
    end
  end

  @doc """
  Filters and sorts models based on the given filters and sort configuration.
  Accepts either a Filters struct or a map.
  """
  def list_models(all_models, %Filters{} = filters, sort) do
    list_models(all_models, Filters.to_filter_map(filters), sort)
  end

  def list_models(all_models, filters, sort) when is_map(filters) do
    all_models
    |> filter_models(filters)
    |> sort_models(sort)
  end

  @doc """
  Filters, sorts, and paginates models from the shared catalog in a single step.
  """
  def query_models(filters, sort, page, page_size \\ @default_page_size) do
    list_all_models()
    |> list_models(filters, sort)
    |> paginate(page, page_size)
  end

  @doc """
  Paginates a list of models.
  Returns {page_models, total_count, total_pages}.
  """
  def paginate(models, page, page_size \\ @default_page_size) do
    total = length(models)
    total_pages = max(1, ceil(total / page_size))
    page = max(1, min(page, total_pages))

    page_models =
      models
      |> Enum.drop((page - 1) * page_size)
      |> Enum.take(page_size)

    {page_models, total, total_pages, page}
  end

  @doc """
  Returns the default page size.
  """
  def default_page_size, do: @default_page_size

  @doc """
  Returns the default filter configuration as a Filters struct.
  """
  def default_filters do
    Filters.new()
  end

  @doc """
  Returns the default sort configuration.
  """
  def default_sort do
    %{by: :provider, dir: :asc}
  end

  @doc """
  Parses filter parameters from form input into a Filters struct.
  Delegates to Filters.from_params/1.
  """
  def parse_filters(params) do
    Filters.from_params(params)
  end

  @doc """
  Counts the number of active filters for display in the UI.
  Delegates to Filters.active_filter_count/1.
  """
  def active_filter_count(%Filters{} = filters) do
    Filters.active_filter_count(filters)
  end

  def active_filter_count(filters) when is_map(filters) do
    count = 0
    count = if filters.search != "", do: count + 1, else: count
    count = count + MapSet.size(filters.provider_ids)
    count = count + Enum.count(Map.values(filters.capabilities), & &1)
    count = count + MapSet.size(filters.modalities_in)
    count = count + MapSet.size(filters.modalities_out)
    count = if filters.min_context, do: count + 1, else: count
    count = if filters.min_output, do: count + 1, else: count
    count = if filters.max_cost_in, do: count + 1, else: count
    count = if filters.max_cost_out, do: count + 1, else: count
    count = if filters.show_deprecated, do: count + 1, else: count
    count = if not filters.allowed_only, do: count + 1, else: count
    count
  end

  @doc """
  Formats an integer with thousand separators.
  """
  def format_number(nil), do: "N/A"

  def format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}(?=.)/, "\\0,")
    |> String.reverse()
  end

  def format_number(num) when is_float(num) do
    :erlang.float_to_binary(num, decimals: 2)
  end

  @doc """
  Formats a cost value as a dollar amount.
  """
  def format_cost(nil), do: "N/A"

  def format_cost(cost) when is_number(cost) do
    "$#{:erlang.float_to_binary(cost * 1.0, decimals: 2)}"
  end

  # Private functions

  defp enrich_model(model, history_index) do
    aliases = Enum.join(model.aliases || [], " ")
    tags = Enum.join(model.tags || [], " ")

    caps = model.capabilities || %{}

    capability_terms =
      labeled_capabilities()
      |> Enum.filter(fn {_key, path, _label, _tooltip} -> get_capability(caps, path) end)
      |> Enum.map(fn {key, _path, _label, _tooltip} -> to_string(key) end)
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
      @capability_definitions
      |> Enum.reduce(MapSet.new(), fn {key, path, _label, _tooltip}, acc ->
        if get_capability(caps, path), do: MapSet.put(acc, key), else: acc
      end)

    modalities = model.modalities || %{}
    in_set = MapSet.new(modalities[:input] || [])
    out_set = MapSet.new(modalities[:output] || [])

    dom_id = "model-#{model.provider}-#{:erlang.phash2({model.provider, model.id})}"
    original_id = model.id
    history_summary = Map.get(history_index, history_key(model.provider, original_id), %{})

    model
    |> Map.put(:id, dom_id)
    |> Map.put(:model_id, original_id)
    |> Map.put(:__search, search)
    |> Map.put(:__caps, caps_set)
    |> Map.put(:__in, in_set)
    |> Map.put(:__out, out_set)
    |> Map.put(:__context, get_in(model.limits, [:context]) || 0)
    |> Map.put(:__output, get_in(model.limits, [:output]) || 0)
    |> Map.put(:__cost_in, get_in(model.cost, [:input]))
    |> Map.put(:__cost_out, get_in(model.cost, [:output]))
    |> Map.put(:__last_changed_at, Map.get(history_summary, :captured_at))
    |> Map.put(:__last_changed_epoch, Map.get(history_summary, :captured_at_epoch))
    |> Map.put(:__allowed?, LLMDB.allowed?(model))
    |> Map.put(:__provider_str, to_string(model.provider))
  end

  defp maybe_attach_history_metadata([]), do: []

  defp maybe_attach_history_metadata(models) do
    if missing_history_metadata?(models) do
      case build_history_index() do
        history_index when map_size(history_index) > 0 ->
          refreshed_models =
            Enum.map(models, fn model ->
              model_id = Map.get(model, :model_id, Map.get(model, :id))
              history_summary = Map.get(history_index, history_key(model.provider, model_id), %{})

              model
              |> Map.put(:__last_changed_at, Map.get(history_summary, :captured_at))
              |> Map.put(:__last_changed_epoch, Map.get(history_summary, :captured_at_epoch))
            end)

          store_models(refreshed_models)
          refreshed_models

        _ ->
          models
      end
    else
      models
    end
  end

  defp missing_history_metadata?(models) do
    Enum.any?(models) and Enum.all?(models, &is_nil(Map.get(&1, :__last_changed_epoch)))
  end

  defp get_capability(caps, [key]), do: Map.get(caps, key)
  defp get_capability(caps, path), do: get_in(caps, path)

  defp filter_models(models, filters) do
    recent_change_cutoff = recent_change_cutoff_epoch(filters.changed_within_days)

    models
    |> Enum.filter(fn model ->
      passes_provider?(model, filters.provider_ids) and
        passes_search?(model, filters.search) and
        passes_deprecated?(model, filters.show_deprecated) and
        passes_allowed?(model, filters.allowed_only) and
        passes_capabilities?(model, filters.capabilities) and
        passes_modalities?(model, filters.modalities_in, filters.modalities_out) and
        passes_recent_change?(model, recent_change_cutoff) and
        passes_limits?(model, filters.min_context, filters.min_output) and
        passes_cost?(model, filters.max_cost_in, filters.max_cost_out)
    end)
  end

  defp passes_provider?(model, provider_ids) do
    MapSet.size(provider_ids) == 0 or MapSet.member?(provider_ids, model.__provider_str)
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
      filters
      |> Enum.filter(fn {_key, enabled} -> enabled end)
      |> Enum.map(fn {key, _} -> key end)

    Enum.all?(required, &MapSet.member?(caps_set, &1))
  end

  defp passes_modalities?(%{__in: in_set, __out: out_set}, in_filters, out_filters) do
    in_ok = MapSet.size(in_filters) == 0 or MapSet.subset?(in_filters, in_set)
    out_ok = MapSet.size(out_filters) == 0 or MapSet.subset?(out_filters, out_set)
    in_ok and out_ok
  end

  defp passes_recent_change?(_model, nil), do: true

  defp passes_recent_change?(%{__last_changed_epoch: epoch}, cutoff_epoch)
       when is_integer(epoch) and is_integer(cutoff_epoch) do
    epoch >= cutoff_epoch
  end

  defp passes_recent_change?(_model, _cutoff_epoch), do: false

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

  defp sort_models(models, %{by: :recently_changed, dir: dir}) do
    Enum.sort(models, &compare_recently_changed(&1, &2, dir))
  end

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

  defp compare_recently_changed(a, b, dir) do
    a_epoch = Map.get(a, :__last_changed_epoch)
    b_epoch = Map.get(b, :__last_changed_epoch)

    cond do
      is_integer(a_epoch) and is_integer(b_epoch) and a_epoch != b_epoch ->
        if dir == :asc, do: a_epoch <= b_epoch, else: a_epoch >= b_epoch

      is_integer(a_epoch) ->
        true

      is_integer(b_epoch) ->
        false

      true ->
        recent_tie_breaker(a) <= recent_tie_breaker(b)
    end
  end

  defp recent_tie_breaker(model) do
    {Map.get(model, :__provider_str, ""), Map.get(model, :model_id, model.id)}
  end

  defp recent_change_cutoff_epoch(nil), do: nil

  defp recent_change_cutoff_epoch(days) when is_integer(days) and days > 0 do
    DateTime.utc_now()
    |> DateTime.add(-days * 86_400, :second)
    |> DateTime.to_unix()
  end

  defp build_history_index do
    history = history_module()

    case history.recent(500) do
      {:ok, events} ->
        Enum.reduce(events, %{}, fn event, acc ->
          model_key = map_get(event, "model_key", :model_key)
          captured_at = map_get(event, "captured_at", :captured_at)

          cond do
            not is_binary(model_key) or not is_binary(captured_at) ->
              acc

            Map.has_key?(acc, model_key) ->
              acc

            true ->
              Map.put(acc, model_key, %{
                captured_at: captured_at,
                captured_at_epoch: iso8601_to_unix(captured_at)
              })
          end
        end)

      _ ->
        %{}
    end
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end

  defp store_models(models) do
    ensure_lookup_table!()
    :persistent_term.put(@models_key, models)
    :persistent_term.put(@model_count_key, length(models))
    rebuild_lookup_indexes(models)
    :ok
  end

  defp rebuild_lookup_indexes(models) do
    :ets.delete_all_objects(@ets_table)

    lookup_entries =
      Enum.flat_map(models, fn model ->
        provider = Map.get(model, :__provider_str, to_string(model.provider))

        [
          {{:provider_model, provider, model.model_id}, model},
          {{:dom_id, model.id}, model}
        ]
      end)

    :ets.insert(@ets_table, lookup_entries)
    :ok
  end

  defp ensure_lookup_table! do
    if :ets.whereis(@ets_table) == :undefined do
      :ets.new(@ets_table, [:named_table, :set, :public, read_concurrency: true])
    end
  end

  defp lookup_index(key), do: lookup_index(key, false)

  defp lookup_index(key, rebuilt?) do
    ensure_lookup_table!()

    case :ets.lookup(@ets_table, key) do
      [{^key, model}] ->
        model

      [] ->
        case :persistent_term.get(@models_key, :undefined) do
          :undefined ->
            init_cache()
            lookup_index(key, true)

          _models when rebuilt? ->
            nil

          models ->
            rebuild_lookup_indexes(models)
            lookup_index(key, true)
        end
    end
  end

  defp history_key(provider, model_id), do: to_string(provider) <> ":" <> model_id

  defp iso8601_to_unix(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, datetime, _offset} -> DateTime.to_unix(datetime)
      _ -> nil
    end
  end

  defp map_get(map, string_key, atom_key) when is_map(map) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp sort_direction(:asc), do: :asc
  defp sort_direction(:desc), do: :desc
end
