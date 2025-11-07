defmodule PetalBoilerplateWeb.ModelComponents do
  use PetalBoilerplateWeb, :html

  alias PetalBoilerplateWeb.ModelLive

  defp model_dom_id(model) do
    "model-#{model.provider}-#{:erlang.phash2({model.provider, model.id})}"
  end

  attr :sort, :map, required: true
  attr :by, :atom, required: true
  slot :inner_block, required: true

  def sort_header(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1">
      {render_slot(@inner_block)}
      <%= if @sort.by == @by do %>
        {if @sort.dir == :asc, do: "↑", else: "↓"}
      <% end %>
    </span>
    """
  end

  attr :model, :map, required: true

  def capability_badges(assigns) do
    caps = assigns.model.capabilities || %{}

    badges =
      []
      |> then(&if caps[:chat], do: ["Chat" | &1], else: &1)
      |> then(&if caps[:embeddings], do: ["Embed" | &1], else: &1)
      |> then(&if get_in(caps, [:reasoning, :enabled]), do: ["Reason" | &1], else: &1)
      |> then(&if get_in(caps, [:tools, :enabled]), do: ["Tools" | &1], else: &1)
      |> then(&if get_in(caps, [:json, :native]), do: ["JSON" | &1], else: &1)
      |> then(&if get_in(caps, [:streaming, :text]), do: ["Stream" | &1], else: &1)

    assigns = assign(assigns, :badges, Enum.reverse(badges))

    ~H"""
    <div class="flex flex-wrap gap-1.5">
      <%= for b <- @badges do %>
        <span class="px-2 py-0.5 text-xs font-medium text-gray-600 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 border border-gray-200 dark:border-gray-600">
          {b}
        </span>
      <% end %>
    </div>
    """
  end

  attr :label, :string, required: true
  slot :value, required: true

  def metric(assigns) do
    ~H"""
    <div>
      <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
        {@label}
      </div>
      <div class="text-sm text-gray-900 dark:text-gray-100">
        {render_slot(@value)}
      </div>
    </div>
    """
  end

  attr :models, :list, required: true
  attr :sort, :map, required: true
  attr :total, :integer, required: true

  def model_table(assigns) do
    ~H"""
    <.table>
      <.tr>
        <.th
          phx-click="sort"
          phx-value-by="provider"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:provider}>Provider</.sort_header>
        </.th>
        <.th
          phx-click="sort"
          phx-value-by="id"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:id}>Model ID</.sort_header>
        </.th>
        <.th
          phx-click="sort"
          phx-value-by="name"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:name}>Name</.sort_header>
        </.th>
        <.th>Capabilities</.th>
        <.th
          phx-click="sort"
          phx-value-by="context"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:context}>Context</.sort_header>
        </.th>
        <.th
          phx-click="sort"
          phx-value-by="output"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:output}>Output</.sort_header>
        </.th>
        <.th
          phx-click="sort"
          phx-value-by="cost_in"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:cost_in}>Cost In</.sort_header>
        </.th>
        <.th
          phx-click="sort"
          phx-value-by="cost_out"
          class="cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <.sort_header sort={@sort} by={:cost_out}>Cost Out</.sort_header>
        </.th>
      </.tr>

      <%= if @total == 0 do %>
        <.tr>
          <.td colspan="8" class="px-3 py-8 text-center text-gray-500 dark:text-gray-400">
            No models match your filters. Try adjusting your search criteria.
          </.td>
        </.tr>
      <% else %>
        <%= for model <- @models do %>
          <.tr id={model_dom_id(model)} class="hover:bg-gray-50 dark:hover:bg-gray-700">
            <.td class="px-3 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900 dark:text-gray-100">{model.provider}</div>
            </.td>
            <.td class="px-3 py-4">
              <div class="text-sm font-medium text-gray-900 dark:text-gray-100">{model.id}</div>
              <%= if model.deprecated do %>
                <.badge color="danger" size="xs" class="mt-1">Deprecated</.badge>
              <% end %>
            </.td>
            <.td class="px-3 py-4">
              <div class="text-sm text-gray-900 dark:text-gray-100">{model.name}</div>
              <%= if model.family do %>
                <div class="text-xs text-gray-500 dark:text-gray-400">{model.family}</div>
              <% end %>
            </.td>
            <.td class="px-3 py-4">
              <.capability_badges model={model} />
            </.td>
            <.td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_number(get_in(model.limits, [:context]))}
            </.td>
            <.td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_number(get_in(model.limits, [:output]))}
            </.td>
            <.td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_cost(get_in(model.cost, [:input]))}
            </.td>
            <.td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_cost(get_in(model.cost, [:output]))}
            </.td>
          </.tr>
        <% end %>
      <% end %>
    </.table>
    """
  end

  attr :model, :map, required: true

  def model_card(assigns) do
    ~H"""
    <.card>
      <.card_content>
        <div class="space-y-3">
          <div class="flex items-start justify-between gap-3">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <.badge color="primary" variant="light">{@model.provider}</.badge>
                <%= if @model.deprecated do %>
                  <.badge color="danger" size="xs">Deprecated</.badge>
                <% end %>
              </div>
              <h3 class="text-base font-semibold text-gray-900 dark:text-gray-100 truncate">
                {@model.name}
              </h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 truncate">{@model.id}</p>
              <%= if @model.family do %>
                <p class="text-xs text-gray-500 dark:text-gray-500 mt-1">{@model.family}</p>
              <% end %>
            </div>
          </div>

          <%= if has_capabilities?(@model) do %>
            <div>
              <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                Capabilities
              </div>
              <.capability_badges model={@model} />
            </div>
          <% end %>

          <div class="grid grid-cols-2 gap-3 pt-3 border-t border-gray-200 dark:border-gray-700">
            <.metric label="Context">
              <:value>{ModelLive.format_number(get_in(@model.limits, [:context]))}</:value>
            </.metric>
            <.metric label="Output">
              <:value>{ModelLive.format_number(get_in(@model.limits, [:output]))}</:value>
            </.metric>
            <.metric label="Cost In">
              <:value>{ModelLive.format_cost(get_in(@model.cost, [:input]))}</:value>
            </.metric>
            <.metric label="Cost Out">
              <:value>{ModelLive.format_cost(get_in(@model.cost, [:output]))}</:value>
            </.metric>
          </div>
        </div>
      </.card_content>
    </.card>
    """
  end

  attr :providers, :list, required: true
  attr :filters, :map, required: true
  attr :filters_open, :boolean, required: true

  def filters_sidebar(assigns) do
    ~H"""
    <div class={"lg:col-span-1 #{if @filters_open, do: "block", else: "hidden lg:block"} fixed lg:static inset-0 lg:inset-auto z-40 lg:z-auto"}>
      <div class="lg:hidden fixed inset-0 bg-black/50 backdrop-blur-sm" phx-click="toggle_filters">
      </div>

      <div class="fixed lg:static inset-y-0 left-0 w-80 max-w-[85vw] lg:w-auto lg:max-w-none bg-white dark:bg-gray-800 lg:bg-transparent shadow-xl lg:shadow-none overflow-y-auto lg:overflow-visible">
        <div class="lg:sticky lg:top-4 p-4 lg:p-0">
          <div class="flex items-center justify-between mb-4 lg:hidden">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Filters</h2>
            <button
              phx-click="toggle_filters"
              class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                >
                </path>
              </svg>
            </button>
          </div>

          <.card variant="outline" class="border-0 lg:border shadow-none lg:shadow">
            <.card_content category="Filters">
              <form phx-change="filter" phx-debounce="200">
                <div class="mb-6">
                  <.form_label>Providers</.form_label>
                  <.input
                    type="text"
                    name="provider_search"
                    value={@filters.provider_search}
                    placeholder="Search providers..."
                    class="mb-2"
                    phx-debounce="200"
                  />
                  <div class="space-y-2 max-h-48 overflow-y-auto">
                    <%= for provider <- filtered_providers(@providers, @filters.provider_search) do %>
                      <label class="flex items-center gap-2 cursor-pointer">
                        <input
                          type="checkbox"
                          name={"providers[#{provider.id}]"}
                          checked={MapSet.member?(@filters.provider_ids, provider.id)}
                          class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                        />
                        <span class="text-sm text-gray-700 dark:text-gray-300">
                          {provider.name}
                        </span>
                      </label>
                    <% end %>
                  </div>
                </div>

                <div class="mb-6 space-y-2">
                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      name="show_deprecated"
                      value="true"
                      checked={@filters.show_deprecated}
                      class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                    />
                    <span class="text-sm text-gray-700 dark:text-gray-300">
                      Show deprecated
                    </span>
                  </label>

                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      name="allowed_only"
                      value="true"
                      checked={@filters.allowed_only}
                      class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                    />
                    <span class="text-sm text-gray-700 dark:text-gray-300">Allowed only</span>
                  </label>
                </div>

                <div class="mb-6">
                  <.form_label>Capabilities</.form_label>
                  <div class="space-y-2">
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_chat"
                        value="true"
                        checked={@filters.capabilities.chat}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Chat</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_embeddings"
                        value="true"
                        checked={@filters.capabilities.embeddings}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Embeddings</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_reasoning"
                        value="true"
                        checked={@filters.capabilities.reasoning}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Reasoning</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_tools"
                        value="true"
                        checked={@filters.capabilities.tools}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Tools</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_json_native"
                        value="true"
                        checked={@filters.capabilities.json_native}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">JSON Native</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_streaming_text"
                        value="true"
                        checked={@filters.capabilities.streaming_text}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Streaming</span>
                    </label>
                  </div>
                </div>

                <div class="mb-6">
                  <.form_label>Input Modalities</.form_label>
                  <div class="space-y-2">
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[text]"
                        checked={MapSet.member?(@filters.modalities_in, :text)}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Text</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[image]"
                        checked={MapSet.member?(@filters.modalities_in, :image)}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Image</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[audio]"
                        checked={MapSet.member?(@filters.modalities_in, :audio)}
                        class="rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                      />
                      <span class="text-sm text-gray-700 dark:text-gray-300">Audio</span>
                    </label>
                  </div>
                </div>

                <div class="mb-6">
                  <.form_label>Minimum Context</.form_label>
                  <.input
                    type="number"
                    name="min_context"
                    value={@filters.min_context}
                    placeholder="e.g., 32000"
                  />
                </div>

                <div class="mb-6">
                  <.form_label>Minimum Output</.form_label>
                  <.input
                    type="number"
                    name="min_output"
                    value={@filters.min_output}
                    placeholder="e.g., 4000"
                  />
                </div>

                <div class="mb-6">
                  <.form_label>Max Cost In ($/1M tokens)</.form_label>
                  <.input
                    type="number"
                    name="max_cost_in"
                    value={@filters.max_cost_in}
                    placeholder="e.g., 5.00"
                    step="0.01"
                  />
                </div>

                <div>
                  <.form_label>Max Cost Out ($/1M tokens)</.form_label>
                  <.input
                    type="number"
                    name="max_cost_out"
                    value={@filters.max_cost_out}
                    placeholder="e.g., 15.00"
                    step="0.01"
                  />
                </div>
              </form>
            </.card_content>
          </.card>
        </div>
      </div>
    </div>
    """
  end

  defp has_capabilities?(model) do
    caps = model.capabilities || %{}
    map_size(caps) > 0
  end

  defp filtered_providers(providers, search_term) do
    if search_term == "" do
      providers
    else
      search_term = String.downcase(search_term)

      Enum.filter(providers, fn provider ->
        String.contains?(String.downcase(to_string(provider.name)), search_term)
      end)
    end
  end
end
