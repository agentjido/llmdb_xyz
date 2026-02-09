defmodule PetalBoilerplateWeb.ModelLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Filters

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"provider" => provider, "id" => id}) do
    model =
      if socket.assigns.all_models == [] do
        Catalog.find_model(provider, id)
      else
        find_model_by_provider_and_id(socket.assigns.all_models, provider, id)
      end

    socket
    |> assign_og_meta(:show, model)
    |> assign(selected_model: model)
  end

  defp apply_action(socket, :index, params) do
    if connected?(socket) and socket.assigns.all_models != [] do
      filters = Filters.from_params(params)

      socket
      |> assign(selected_model: nil)
      |> apply_filters(filters)
    else
      assign(socket, selected_model: nil)
    end
  end

  defp find_model_by_provider_and_id(models, provider, id) do
    Enum.find(models, fn m ->
      to_string(m.provider) == provider && m.model_id == id
    end)
  end

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
    default_filters = Filters.new()
    sort = Catalog.default_sort()

    if connected?(socket) do
      providers = Catalog.list_providers()
      all_models = Catalog.list_all_models()
      filtered = Catalog.list_models(all_models, default_filters, sort)
      {page_models, total, total_pages, page} = Catalog.paginate(filtered, 1)

      {:ok,
       socket
       |> assign_og_meta(:index, nil)
       |> assign(
         providers: providers,
         all_models: all_models,
         filtered_models: filtered,
         filters: default_filters,
         sort: sort,
         total: total,
         page: page,
         total_pages: total_pages,
         filters_open: false,
         search_value: default_filters.search,
         active_filter_count: Filters.active_filter_count(default_filters),
         active_quick_filters: Filters.active_quick_filters(default_filters),
         selected_model: nil,
         selected_ids: MapSet.new(),
         comparison_open: false
       )
       |> stream(:models, page_models, reset: true)}
    else
      {:ok,
       socket
       |> assign_og_meta(:index, nil)
       |> assign(
         providers: [],
         all_models: [],
         filtered_models: [],
         filters: default_filters,
         sort: sort,
         total: 0,
         page: 1,
         total_pages: 1,
         filters_open: false,
         search_value: "",
         active_filter_count: 0,
         active_quick_filters: [],
         selected_model: nil,
         selected_ids: MapSet.new(),
         comparison_open: false
       )
       |> stream(:models, [])}
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = Filters.from_params(params)
    {:noreply, apply_filters(socket, filters, push_url: true)}
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

    filtered = Catalog.list_models(socket.assigns.all_models, socket.assigns.filters, new_sort)
    {page_models, total, total_pages, page} = Catalog.paginate(filtered, 1)

    {:noreply,
     socket
     |> assign(
       sort: new_sort,
       filtered_models: filtered,
       total: total,
       page: page,
       total_pages: total_pages
     )
     |> stream(:models, page_models, reset: true)}
  end

  @impl true
  def handle_event("page", %{"page" => page_str}, socket) do
    page = String.to_integer(page_str)

    {page_models, total, total_pages, page} =
      Catalog.paginate(socket.assigns.filtered_models, page)

    {:noreply,
     socket
     |> assign(page: page, total: total, total_pages: total_pages)
     |> stream(:models, page_models, reset: true)}
  end

  @impl true
  def handle_event("show_model", %{"id" => dom_id}, socket) do
    model_id = String.replace_prefix(dom_id, "models-", "")
    model = Enum.find(socket.assigns.filtered_models, fn m -> m.id == model_id end)

    if model do
      {:noreply, push_patch(socket, to: ~p"/models/#{model.provider}/#{model.model_id}")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_model", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/")}
  end

  @impl true
  def handle_event("toggle_select", %{"id" => id}, socket) do
    selected_ids = socket.assigns.selected_ids
    max_selection = 4

    selected_ids =
      if MapSet.member?(selected_ids, id) do
        MapSet.delete(selected_ids, id)
      else
        if MapSet.size(selected_ids) < max_selection do
          MapSet.put(selected_ids, id)
        else
          selected_ids
        end
      end

    {:noreply, assign(socket, selected_ids: selected_ids)}
  end

  @impl true
  def handle_event("open_comparison", _params, socket) do
    {:noreply, assign(socket, comparison_open: true)}
  end

  @impl true
  def handle_event("close_comparison", _params, socket) do
    {:noreply, assign(socket, comparison_open: false)}
  end

  @impl true
  def handle_event("clear_comparison", _params, socket) do
    {:noreply, assign(socket, selected_ids: MapSet.new(), comparison_open: false)}
  end

  @impl true
  def handle_event("remove_from_comparison", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_ids: MapSet.delete(socket.assigns.selected_ids, id))}
  end

  @impl true
  def handle_event("quick_filter", %{"kind" => kind}, socket) do
    filters = Filters.apply_quick_filter(socket.assigns.filters, kind)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("reset_filters", _params, socket) do
    {:noreply, apply_filters(socket, Filters.new(), push_url: true)}
  end

  @impl true
  def handle_event("select_all_providers", _params, socket) do
    all_provider_ids = MapSet.new(Enum.map(socket.assigns.providers, &to_string(&1.id)))
    filters = Filters.set_providers(socket.assigns.filters, all_provider_ids)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("clear_providers", _params, socket) do
    filters = Filters.clear_providers(socket.assigns.filters)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("toggle_provider", %{"id" => id}, socket) do
    filters = socket.assigns.filters
    provider_ids = filters.provider_ids

    new_ids =
      if MapSet.member?(provider_ids, id) do
        MapSet.delete(provider_ids, id)
      else
        MapSet.put(provider_ids, id)
      end

    filters = Filters.set_providers(filters, new_ids)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("remove_provider", %{"id" => id}, socket) do
    filters = socket.assigns.filters
    new_ids = MapSet.delete(filters.provider_ids, id)
    filters = Filters.set_providers(filters, new_ids)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("provider_search", %{"provider_search" => term}, socket) do
    filters = Filters.set_provider_search(socket.assigns.filters, term)
    {:noreply, apply_filters(socket, filters)}
  end

  @impl true
  def handle_event("remove_filter", %{"kind" => kind} = params, socket) do
    filters = socket.assigns.filters

    filters =
      case kind do
        "provider" ->
          id = params["filter_value"]
          Filters.set_providers(filters, MapSet.delete(filters.provider_ids, id))

        "capability" ->
          if params["filter_value"] && params["filter_value"] != "" do
            cap = String.to_existing_atom(params["filter_value"])
            %{filters | capabilities: Map.put(filters.capabilities, cap, false)}
          else
            filters
          end

        "modality_in" ->
          mod = String.to_existing_atom(params["filter_value"])
          Filters.toggle_modality_in(filters, mod)

        "modality_out" ->
          mod = String.to_existing_atom(params["filter_value"])
          Filters.toggle_modality_out(filters, mod)

        "min_context" ->
          Filters.set_context_min(filters, nil)

        "min_output" ->
          Filters.set_output_min(filters, nil)

        "max_cost_in" ->
          Filters.set_cost_max(filters, :input, nil)

        "max_cost_out" ->
          Filters.set_cost_max(filters, :output, nil)

        "show_deprecated" ->
          %{filters | show_deprecated: false}

        "allowed_only" ->
          %{filters | allowed_only: true}

        _ ->
          filters
      end

    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("set_min_context", %{"value" => value}, socket) do
    context_value = parse_int_value(value)
    filters = Filters.set_context_min(socket.assigns.filters, context_value)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("set_max_cost", %{"value" => value}, socket) do
    cost_value = parse_float_value(value)
    filters = Filters.set_cost_max(socket.assigns.filters, :input, cost_value)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  defp toggle_direction(:asc), do: :desc
  defp toggle_direction(:desc), do: :asc

  defp apply_filters(socket, %Filters{} = filters, opts \\ []) do
    filtered = Catalog.list_models(socket.assigns.all_models, filters, socket.assigns.sort)
    {page_models, total, total_pages, page} = Catalog.paginate(filtered, 1)

    socket =
      socket
      |> assign(
        filters: filters,
        filtered_models: filtered,
        total: total,
        page: page,
        total_pages: total_pages,
        search_value: filters.search,
        active_filter_count: Filters.active_filter_count(filters),
        active_quick_filters: Filters.active_quick_filters(filters)
      )
      |> stream(:models, page_models, reset: true)

    if Keyword.get(opts, :push_url, false) do
      url_params = Filters.to_params(filters)

      query_string =
        url_params
        |> Enum.map(fn {k, v} -> URI.encode(to_string(k)) <> "=" <> URI.encode(to_string(v)) end)
        |> Enum.join("&")

      url = if query_string == "", do: "/", else: "/?" <> query_string
      push_patch(socket, to: url, replace: true)
    else
      socket
    end
  end

  defp selected_models(assigns) do
    ids = MapSet.to_list(assigns.selected_ids)
    Enum.filter(assigns.all_models, &(&1.id in ids))
  end

  defp parse_int_value(""), do: nil
  defp parse_int_value(nil), do: nil

  defp parse_int_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_int_value(value) when is_integer(value), do: value

  defp parse_float_value(""), do: nil
  defp parse_float_value(nil), do: nil

  defp parse_float_value(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end

  defp parse_float_value(value) when is_float(value), do: value
  defp parse_float_value(value) when is_integer(value), do: value * 1.0

  def format_number(value), do: Catalog.format_number(value)
  def format_cost(value), do: Catalog.format_cost(value)

  defp assign_og_meta(socket, :index, _model) do
    assign(socket,
      page_title: "LLM Model Database",
      page_description:
        "Browse and compare 2,000+ LLM models from OpenAI, Anthropic, Google, Mistral, and more. Filter by capabilities, pricing, and context windows.",
      og_url: "https://llmdb.xyz/",
      og_image: "https://llmdb.xyz/og/home.png"
    )
  end

  defp assign_og_meta(socket, :show, nil) do
    assign(socket,
      page_title: "Model Not Found",
      page_description: "The requested model could not be found.",
      og_url: "https://llmdb.xyz/",
      og_image: "https://llmdb.xyz/og/default.png"
    )
  end

  defp assign_og_meta(socket, :show, model) do
    model_id = Map.get(model, :model_id) || model.id
    title = "#{model.name || model_id} - #{model.provider}"

    description =
      build_model_description(model)

    assign(socket,
      page_title: title,
      page_description: description,
      og_url: "https://llmdb.xyz/models/#{model.provider}/#{model_id}",
      og_image: "https://llmdb.xyz/og/model/#{model.provider}/#{model_id}.png"
    )
  end

  defp build_model_description(model) do
    context = get_model_context(model)
    cost_in = get_model_cost_in(model)
    cost_out = get_model_cost_out(model)
    model_id = Map.get(model, :model_id) || model.id

    parts = []

    parts =
      if context do
        parts ++ ["#{format_number(context)} context"]
      else
        parts
      end

    parts =
      if cost_in do
        parts ++ ["$#{Catalog.format_cost(cost_in)}/M input"]
      else
        parts
      end

    parts =
      if cost_out do
        parts ++ ["$#{Catalog.format_cost(cost_out)}/M output"]
      else
        parts
      end

    base = "#{model.name || model_id} by #{model.provider}"

    if parts == [] do
      base <> " - View specs and compare with other LLMs on llmdb.xyz"
    else
      base <> " - " <> Enum.join(parts, ", ") <> ". Compare LLMs on llmdb.xyz"
    end
  end

  defp get_model_context(model) do
    case model do
      %{__context: ctx} when is_integer(ctx) and ctx > 0 -> ctx
      %{limits: %{context: ctx}} when is_integer(ctx) -> ctx
      _ -> nil
    end
  end

  defp get_model_cost_in(model) do
    case model do
      %{__cost_in: cost} when is_number(cost) -> cost
      %{cost: %{input: cost}} when is_number(cost) -> cost
      _ -> nil
    end
  end

  defp get_model_cost_out(model) do
    case model do
      %{__cost_out: cost} when is_number(cost) -> cost
      %{cost: %{output: cost}} when is_number(cost) -> cost
      _ -> nil
    end
  end
end
