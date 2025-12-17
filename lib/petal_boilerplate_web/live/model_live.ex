defmodule PetalBoilerplateWeb.ModelLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"provider" => provider, "id" => id}) do
    model = find_model_by_provider_and_id(socket.assigns.all_models, provider, id)
    assign(socket, selected_model: model, page_title: model_title(model))
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, selected_model: nil, page_title: "LLM Model Database")
  end

  defp find_model_by_provider_and_id(models, provider, id) do
    Enum.find(models, fn m ->
      to_string(m.provider) == provider && m.model_id == id
    end)
  end

  defp model_title(nil), do: "Model Not Found"
  defp model_title(model), do: "#{model.name || model.model_id} - #{model.provider}"

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
    default_filters = Catalog.default_filters()
    sort = Catalog.default_sort()

    if connected?(socket) do
      providers = Catalog.list_providers()
      all_models = Catalog.list_all_models()
      filtered = Catalog.list_models(all_models, default_filters, sort)
      {page_models, total, total_pages, page} = Catalog.paginate(filtered, 1)

      {:ok,
       socket
       |> assign(
         page_title: "LLM Model Database",
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
         active_filter_count: Catalog.active_filter_count(default_filters),
         selected_model: nil
       )
       |> stream(:models, page_models, reset: true)}
    else
      {:ok,
       socket
       |> assign(
         page_title: "LLM Model Database",
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
         selected_model: nil
       )
       |> stream(:models, [])}
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = Catalog.parse_filters(params)
    filtered = Catalog.list_models(socket.assigns.all_models, filters, socket.assigns.sort)
    {page_models, total, total_pages, page} = Catalog.paginate(filtered, 1)

    {:noreply,
     socket
     |> assign(
       filters: filters,
       filtered_models: filtered,
       total: total,
       page: page,
       total_pages: total_pages,
       search_value: filters.search,
       active_filter_count: Catalog.active_filter_count(filters)
     )
     |> stream(:models, page_models, reset: true)}
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

  defp toggle_direction(:asc), do: :desc
  defp toggle_direction(:desc), do: :asc

  def format_number(value), do: Catalog.format_number(value)
  def format_cost(value), do: Catalog.format_cost(value)
end
