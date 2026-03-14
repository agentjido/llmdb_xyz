defmodule PetalBoilerplateWeb.HistoryLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog

  @history_limit 500

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       search_value: "",
       events: [],
       history_meta: %{},
       history_available: false,
       changed_within_days: nil,
       event_type: nil,
       history_api_url: "/api/history/recent?limit=#{@history_limit}",
       page_title: "Recent History",
       page_description:
         "Track recent llm_db model metadata changes across providers, including introductions, updates, and lineage-aware history.",
       og_url: "https://llmdb.xyz/history",
       og_image: "https://llmdb.xyz/og/default.png"
     )}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    changed_within_days = parse_changed_within(Map.get(params, "changed"))
    event_type = parse_event_type(Map.get(params, "type"))
    {events, history_meta, history_available} = load_history_feed(changed_within_days, event_type)

    {:noreply,
     assign(socket,
       events: events,
       history_meta: history_meta,
       history_available: history_available,
       changed_within_days: changed_within_days,
       event_type: event_type
     )}
  end

  @impl true
  def handle_event("set_filters", params, socket) do
    changed_within_days = parse_changed_within(Map.get(params, "changed_within"))
    event_type = parse_event_type(Map.get(params, "type"))

    {:noreply, push_patch(socket, to: history_path(changed_within_days, event_type))}
  end

  @impl true
  def handle_event("filter", %{"search" => search}, socket) do
    {:noreply, push_navigate(socket, to: model_search_path(search))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col" style="background-color: hsl(var(--background));">
      <PetalBoilerplateWeb.ModelComponents.header search_value={@search_value} />

      <div class="flex-1 w-full max-w-5xl mx-auto py-6 sm:py-8 px-4 sm:px-6">
        <div class="mb-6 flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p class="text-xs uppercase tracking-[0.16em] mb-2" style="color: hsl(var(--primary));">
              Recent changes
            </p>
            <h1 class="text-3xl sm:text-4xl font-semibold" style="color: hsl(var(--foreground));">
              History
            </h1>
            <p
              class="mt-2 max-w-2xl text-sm sm:text-base"
              style="color: hsl(var(--muted-foreground));"
            >
              Reverse-chronological model metadata changes captured from bundled llm_db history snapshots.
            </p>
          </div>

          <form phx-change="set_filters" class="flex flex-col gap-3 sm:flex-row sm:items-end shrink-0">
            <div>
              <label
                class="block text-[11px] font-medium uppercase tracking-[0.14em] mb-1.5"
                for="history-event-type-select"
                style="color: hsl(var(--muted-foreground));"
              >
                Event type
              </label>
              <select
                id="history-event-type-select"
                name="type"
                class="h-10 rounded-md border px-3 text-sm"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--background)); color: hsl(var(--foreground));"
              >
                <option value="" selected={is_nil(@event_type)}>All events</option>
                <option value="introduced" selected={@event_type == "introduced"}>
                  Models introduced
                </option>
                <option value="changed" selected={@event_type == "changed"}>
                  Models changed
                </option>
              </select>
            </div>

            <div>
              <label
                class="block text-[11px] font-medium uppercase tracking-[0.14em] mb-1.5"
                for="history-changed-within-select"
                style="color: hsl(var(--muted-foreground));"
              >
                Changed within
              </label>
              <select
                id="history-changed-within-select"
                name="changed_within"
                class="h-10 rounded-md border px-3 text-sm"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--background)); color: hsl(var(--foreground));"
              >
                <option value="" selected={is_nil(@changed_within_days)}>All captured changes</option>
                <option value="7" selected={@changed_within_days == 7}>Changed in last 7d</option>
                <option value="30" selected={@changed_within_days == 30}>Changed in last 30d</option>
              </select>
            </div>
          </form>
        </div>

        <div
          class="rounded-xl border p-4 sm:p-5 mb-6"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
        >
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <div class="text-sm font-medium" style="color: hsl(var(--foreground));">
                <%= if @history_available do %>
                  Showing {length(@events)} events
                <% else %>
                  History unavailable
                <% end %>
              </div>
              <div class="text-xs mt-1" style="color: hsl(var(--muted-foreground));">
                {history_meta_summary(@history_meta)}
              </div>
            </div>

            <a
              href={@history_api_url}
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-2 text-xs px-3 py-2 rounded-md border transition-colors hover:opacity-80"
              style="border-color: hsl(var(--border)); color: hsl(var(--muted-foreground));"
            >
              <.icon name="hero-arrow-top-right-on-square" class="h-3.5 w-3.5" /> Raw JSON
            </a>
          </div>
        </div>

        <%= if @history_available do %>
          <%= if @events == [] do %>
            <div
              class="rounded-xl border p-8 text-sm"
              style="border-color: hsl(var(--border)); background-color: hsl(var(--card)); color: hsl(var(--muted-foreground));"
            >
              No history events matched this time window.
            </div>
          <% else %>
            <div class="space-y-3">
              <%= for event <- @events do %>
                <article
                  class="rounded-xl border p-4 sm:p-5"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
                >
                  <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div class="min-w-0">
                      <%= if event["model_path"] do %>
                        <a
                          href={event["model_path"]}
                          class="text-base font-medium transition-colors hover:opacity-80"
                          style="color: hsl(var(--foreground));"
                        >
                          {event["model_name"]}
                        </a>
                      <% else %>
                        <div class="text-base font-medium" style="color: hsl(var(--foreground));">
                          {event["model_name"]}
                        </div>
                      <% end %>
                      <div
                        class="mt-1 text-xs font-mono break-all"
                        style="color: hsl(var(--muted-foreground));"
                      >
                        {event["model_key"] || "unknown:model"}
                      </div>
                    </div>

                    <div class="flex items-center gap-3 sm:flex-col sm:items-end sm:gap-2">
                      <span class="text-xs font-mono" style="color: hsl(var(--muted-foreground));">
                        {history_event_date(event)}
                      </span>
                      <span
                        class="text-[10px] px-2 py-0.5 rounded border"
                        style={history_event_type_style(event)}
                      >
                        {history_event_type(event)}
                      </span>
                    </div>
                  </div>

                  <div class="mt-4 space-y-2">
                    <%= case history_change_rows(event, 4) do %>
                      <% [] -> %>
                        <span class="text-xs" style="color: hsl(var(--muted-foreground));">
                          No field-level changes recorded
                        </span>
                      <% rows -> %>
                        <ul class="space-y-1.5">
                          <%= for row <- rows do %>
                            <li class="text-xs leading-relaxed">
                              <span class="font-mono text-[11px] break-all">{row.path}</span>
                              <%= if row.summary do %>
                                <span style="color: hsl(var(--muted-foreground));">
                                  {" "}
                                  {row.summary}
                                </span>
                              <% end %>
                            </li>
                          <% end %>
                        </ul>
                    <% end %>

                    <div
                      :if={history_change_overflow(event, 4) > 0}
                      class="text-xs font-medium"
                      style="color: hsl(var(--primary));"
                    >
                      +{history_change_overflow(event, 4)} more
                    </div>
                  </div>
                </article>
              <% end %>
            </div>
          <% end %>
        <% else %>
          <div
            class="rounded-xl border p-8 text-sm"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card)); color: hsl(var(--muted-foreground));"
          >
            History is not available for this deployment.
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp load_history_feed(changed_within_days, event_type) do
    history = history_module()
    model_lookup = build_model_lookup()

    with {:ok, events} <- history.recent(@history_limit),
         {:ok, meta} <- history.meta() do
      filtered_events =
        events
        |> sort_events_desc()
        |> filter_events(changed_within_days, event_type)
        |> Enum.map(&decorate_event(&1, model_lookup))

      {filtered_events, meta, true}
    else
      _ -> {[], %{}, false}
    end
  end

  defp build_model_lookup do
    Catalog.list_all_models()
    |> Map.new(fn model ->
      {"#{model.provider}:#{model.model_id}", model}
    end)
  end

  defp decorate_event(event, model_lookup) do
    model_key = event_model_key(event)
    {provider, model_id} = split_model_key(model_key)
    model = Map.get(model_lookup, model_key)

    event
    |> Map.put("model_key", model_key)
    |> Map.put("model_name", model_name(model, model_id, model_key))
    |> Map.put("model_path", model_path(provider, model_id))
  end

  defp event_model_key(event) do
    map_get(event, "model_key", :model_key) ||
      [map_get(event, "provider", :provider), map_get(event, "model_id", :model_id)]
      |> Enum.filter(&is_binary/1)
      |> Enum.join(":")
  end

  defp split_model_key(model_key) when is_binary(model_key) do
    case String.split(model_key, ":", parts: 2) do
      [provider, model_id] when provider != "" and model_id != "" -> {provider, model_id}
      _ -> {nil, nil}
    end
  end

  defp split_model_key(_), do: {nil, nil}

  defp model_name(%{name: name}, _model_id, _model_key) when is_binary(name), do: name
  defp model_name(_model, model_id, _model_key) when is_binary(model_id), do: model_id
  defp model_name(_model, _model_id, model_key), do: model_key || "unknown:model"

  defp model_path(provider, model_id) when is_binary(provider) and is_binary(model_id) do
    encoded_provider = URI.encode(provider)

    encoded_model_id =
      model_id
      |> String.split("/")
      |> Enum.map(&URI.encode/1)
      |> Enum.join("/")

    "/models/#{encoded_provider}/#{encoded_model_id}"
  end

  defp model_path(_provider, _model_id), do: nil

  defp filter_events(events, changed_within_days, event_type) do
    events
    |> filter_events_by_days(changed_within_days)
    |> filter_events_by_type(event_type)
  end

  defp filter_events_by_days(events, nil), do: events

  defp filter_events_by_days(events, days) when is_integer(days) and days > 0 do
    cutoff_epoch =
      DateTime.utc_now()
      |> DateTime.add(-days * 86_400, :second)
      |> DateTime.to_unix()

    Enum.filter(events, fn event ->
      case event_epoch(event) do
        epoch when is_integer(epoch) -> epoch >= cutoff_epoch
        _ -> false
      end
    end)
  end

  defp filter_events_by_type(events, nil), do: events

  defp filter_events_by_type(events, type) when is_binary(type) do
    Enum.filter(events, fn event -> history_event_type(event) == type end)
  end

  defp sort_events_desc(events) do
    Enum.sort_by(
      events,
      fn event ->
        {map_get(event, "captured_at", :captured_at, ""),
         map_get(event, "event_id", :event_id, "")}
      end,
      :desc
    )
  end

  defp event_epoch(event) do
    case map_get(event, "captured_at", :captured_at) do
      timestamp when is_binary(timestamp) ->
        case DateTime.from_iso8601(timestamp) do
          {:ok, datetime, _offset} -> DateTime.to_unix(datetime)
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp history_event_date(event) do
    event
    |> map_get("captured_at", :captured_at, "unknown")
    |> to_string()
    |> String.slice(0, 19)
  end

  defp history_event_type(event) do
    event
    |> map_get("type", :type, "changed")
    |> to_string()
  end

  defp history_event_type_style(event) do
    case history_event_type(event) do
      "introduced" ->
        "background-color: hsl(var(--primary) / 0.15); color: hsl(var(--primary)); border-color: hsl(var(--primary) / 0.25);"

      "changed" ->
        "background-color: hsl(var(--accent)); color: hsl(var(--foreground)); border-color: hsl(var(--border));"

      _ ->
        "background-color: hsl(var(--muted)); color: hsl(var(--muted-foreground)); border-color: hsl(var(--border));"
    end
  end

  defp history_change_rows(event, max_items) do
    event
    |> map_get("changes", :changes, [])
    |> Enum.take(max_items)
    |> Enum.map(&history_change_row/1)
  end

  defp history_change_overflow(event, max_items) do
    event
    |> map_get("changes", :changes, [])
    |> length()
    |> Kernel.-(max_items)
    |> max(0)
  end

  defp history_change_row(change) do
    %{
      path: map_get(change, "path", :path, "unknown"),
      summary: history_change_summary(change)
    }
  end

  defp history_change_summary(change) do
    previous = map_get(change, "from", :from) || map_get(change, "previous", :previous)
    current = map_get(change, "to", :to) || map_get(change, "value", :value)

    cond do
      is_nil(previous) and is_nil(current) ->
        nil

      true ->
        "#{history_format_value(previous)} -> #{history_format_value(current)}"
    end
  end

  defp history_format_value(nil), do: "—"

  defp history_format_value(value) when is_binary(value) do
    value
    |> String.replace("\n", " ")
    |> truncate_history_value(80)
  end

  defp history_format_value(value) when is_boolean(value) or is_number(value),
    do: to_string(value)

  defp history_format_value(value) when is_list(value) or is_map(value) do
    value
    |> Jason.encode!()
    |> truncate_history_value(80)
  end

  defp history_format_value(value) do
    value
    |> to_string()
    |> truncate_history_value(80)
  end

  defp truncate_history_value(value, max_len)
       when is_binary(value) and byte_size(value) > max_len do
    String.slice(value, 0, max_len - 1) <> "…"
  end

  defp truncate_history_value(value, _max_len), do: value

  defp history_meta_summary(meta) do
    range_kind =
      map_get(meta, "range_kind", :range_kind) ||
        if(
          is_binary(map_get(meta, "from_snapshot_id", :from_snapshot_id)) and
            is_binary(map_get(meta, "to_snapshot_id", :to_snapshot_id)),
          do: "snapshots",
          else: "commits"
        )

    from_ref =
      map_get(meta, "from_ref", :from_ref) ||
        map_get(meta, "from_snapshot_id", :from_snapshot_id) ||
        map_get(meta, "from_commit", :from_commit)

    to_ref =
      map_get(meta, "to_ref", :to_ref) ||
        map_get(meta, "to_snapshot_id", :to_snapshot_id) ||
        map_get(meta, "to_commit", :to_commit)

    generated_at = map_get(meta, "generated_at", :generated_at)

    range_summary =
      cond do
        is_binary(from_ref) and is_binary(to_ref) ->
          "#{range_kind || "history"} #{short_sha(from_ref)} -> #{short_sha(to_ref)}"

        true ->
          nil
      end

    generated_summary =
      if is_binary(generated_at) do
        "generated #{String.slice(generated_at, 0, 19)}"
      end

    [range_summary, generated_summary]
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> "Recent history feed"
      parts -> Enum.join(parts, " • ")
    end
  end

  defp short_sha(sha) when is_binary(sha), do: String.slice(sha, 0, 7)
  defp short_sha(_), do: "unknown"

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end

  defp history_path(changed_within_days, event_type) do
    query =
      %{}
      |> maybe_put_query_param("changed", changed_within_days)
      |> maybe_put_query_param("type", event_type)

    case URI.encode_query(query) do
      "" -> "/history"
      query_string -> "/history?" <> query_string
    end
  end

  defp model_search_path(nil), do: "/"

  defp model_search_path(search) when is_binary(search) do
    trimmed = String.trim(search)
    if trimmed == "", do: "/", else: "/?q=#{URI.encode(trimmed)}"
  end

  defp parse_changed_within(nil), do: nil
  defp parse_changed_within(""), do: nil
  defp parse_changed_within(days) when is_integer(days) and days > 0, do: days

  defp parse_changed_within(days) when is_binary(days) do
    case Integer.parse(days) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> nil
    end
  end

  defp parse_event_type(nil), do: nil
  defp parse_event_type(""), do: nil
  defp parse_event_type("introduced"), do: "introduced"
  defp parse_event_type("changed"), do: "changed"
  defp parse_event_type(_), do: nil

  defp maybe_put_query_param(params, _key, nil), do: params

  defp maybe_put_query_param(params, key, value) do
    Map.put(params, key, value)
  end

  defp map_get(map, string_key, atom_key, default \\ nil)

  defp map_get(map, string_key, atom_key, default) when is_map(map) do
    cond do
      Map.has_key?(map, string_key) -> Map.get(map, string_key)
      Map.has_key?(map, atom_key) -> Map.get(map, atom_key)
      true -> default
    end
  end

  defp map_get(_map, _string_key, _atom_key, default), do: default
end
