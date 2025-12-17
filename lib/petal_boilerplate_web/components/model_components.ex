defmodule PetalBoilerplateWeb.ModelComponents do
  use PetalBoilerplateWeb, :html

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.ModelLive
  alias Phoenix.LiveView.JS

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
      Catalog.labeled_capabilities()
      |> Enum.filter(fn {_key, path, _label, _tooltip} -> get_capability(caps, path) end)
      |> Enum.map(fn {_key, _path, label, tooltip} -> {label, tooltip} end)

    assigns = assign(assigns, :badges, badges)

    ~H"""
    <div class="flex flex-wrap gap-1.5">
      <%= for {label, tooltip} <- @badges do %>
        <span
          class="px-2 py-0.5 text-xs font-medium text-gray-600 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 cursor-help"
          title={tooltip}
        >
          {label}
        </span>
      <% end %>
    </div>
    """
  end

  defp get_capability(caps, [key]), do: Map.get(caps, key)
  defp get_capability(caps, path), do: get_in(caps, path)

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

  attr :models, :any, required: true
  attr :sort, :map, required: true
  attr :total, :integer, required: true

  def model_table(assigns) do
    ~H"""
    <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
      <thead class="bg-gray-50 dark:bg-gray-800">
        <tr>
          <th
            phx-click="sort"
            phx-value-by="provider"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:provider}>Provider</.sort_header>
          </th>
          <th
            phx-click="sort"
            phx-value-by="id"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:id}>Model ID</.sort_header>
          </th>
          <th
            phx-click="sort"
            phx-value-by="name"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:name}>Name</.sort_header>
          </th>
          <th class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
            Capabilities
          </th>
          <th
            phx-click="sort"
            phx-value-by="context"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:context}>Context</.sort_header>
          </th>
          <th
            phx-click="sort"
            phx-value-by="output"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:output}>Output</.sort_header>
          </th>
          <th
            phx-click="sort"
            phx-value-by="cost_in"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:cost_in}>Cost In</.sort_header>
          </th>
          <th
            phx-click="sort"
            phx-value-by="cost_out"
            class="px-3 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <.sort_header sort={@sort} by={:cost_out}>Cost Out</.sort_header>
          </th>
        </tr>
      </thead>
      <tbody
        id="models-table-body"
        phx-update="stream"
        class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700"
      >
        <%= if @total == 0 do %>
          <tr id="no-models-row">
            <td colspan="8" class="px-3 py-8 text-center text-gray-500 dark:text-gray-400">
              No models match your filters. Try adjusting your search criteria.
            </td>
          </tr>
        <% else %>
          <tr
            :for={{dom_id, model} <- @models}
            id={dom_id}
            phx-click="show_model"
            phx-value-id={dom_id}
            class="hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer"
          >
            <td class="px-3 py-4 whitespace-nowrap">
              <div class="text-sm font-medium text-gray-900 dark:text-gray-100">{model.provider}</div>
            </td>
            <td class="px-3 py-4">
              <div class="text-sm font-medium text-gray-900 dark:text-gray-100">{model.model_id}</div>
              <%= if model.deprecated do %>
                <.badge color="danger" size="xs" class="mt-1">Deprecated</.badge>
              <% end %>
            </td>
            <td class="px-3 py-4">
              <div class="text-sm text-gray-900 dark:text-gray-100">{model.name}</div>
              <%= if model.family do %>
                <div class="text-xs text-gray-500 dark:text-gray-400">{model.family}</div>
              <% end %>
            </td>
            <td class="px-3 py-4">
              <.capability_badges model={model} />
            </td>
            <td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_number(get_in(model.limits, [:context]))}
            </td>
            <td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_number(get_in(model.limits, [:output]))}
            </td>
            <td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_cost(get_in(model.cost, [:input]))}
            </td>
            <td class="px-3 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
              {ModelLive.format_cost(get_in(model.cost, [:output]))}
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
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
              <p class="text-sm text-gray-600 dark:text-gray-400 truncate">{@model.model_id}</p>
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

  attr :model, :map, default: nil

  def model_detail_modal(assigns) do
    ~H"""
    <div
      :if={@model}
      id="model-modal"
      class="fixed inset-0 z-50"
      phx-mounted={JS.add_class("overflow-hidden", to: "body")}
      phx-remove={JS.remove_class("overflow-hidden", to: "body")}
    >
      <div
        class="fixed inset-0 bg-black/50 backdrop-blur-sm"
        phx-click="close_model"
        aria-hidden="true"
      />
      <div class="fixed inset-0 overflow-y-auto">
        <div class="flex min-h-full items-center justify-center p-4">
          <div
            class="relative w-full max-w-3xl bg-white dark:bg-gray-800 rounded-lg shadow-xl"
            phx-click-away="close_model"
            phx-window-keydown="close_model"
            phx-key="escape"
          >
            <div class="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
              <div>
                <div class="flex items-center gap-2 flex-wrap">
                  <.badge color="primary" variant="light">{@model.provider}</.badge>
                  <%= if @model.deprecated do %>
                    <.badge color="danger" size="xs">Deprecated</.badge>
                  <% end %>
                  <%= if lifecycle_status(@model) do %>
                    <.badge color={lifecycle_color(lifecycle_status(@model))} size="xs">
                      {lifecycle_status(@model)}
                    </.badge>
                  <% end %>
                </div>
                <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mt-1">
                  {@model.name || @model.model_id}
                </h2>
                <%= if @model.family do %>
                  <p class="text-sm text-gray-500 dark:text-gray-400">{@model.family} family</p>
                <% end %>
              </div>
              <button
                type="button"
                phx-click="close_model"
                class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="p-4 space-y-6 max-h-[75vh] overflow-y-auto">
              <section class="space-y-3">
                <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700 pb-1">
                  Identity
                </h3>
                <div>
                  <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                    ReqLLM Model Reference
                  </div>
                  <div class="flex items-center gap-2">
                    <code
                      id="reqllm-model-ref"
                      class="flex-1 text-sm text-primary-700 dark:text-primary-300 bg-primary-50 dark:bg-primary-900/30 px-3 py-2 rounded font-mono break-all border border-primary-200 dark:border-primary-700"
                    >
                      {@model.provider}:{@model.model_id}
                    </code>
                    <button
                      type="button"
                      onclick={"navigator.clipboard.writeText('#{@model.provider}:#{@model.model_id}').then(() => { this.querySelector('.copy-icon').classList.add('hidden'); this.querySelector('.check-icon').classList.remove('hidden'); setTimeout(() => { this.querySelector('.copy-icon').classList.remove('hidden'); this.querySelector('.check-icon').classList.add('hidden'); }, 2000); })"}
                      class="flex-shrink-0 p-2 text-gray-500 hover:text-primary-600 dark:hover:text-primary-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
                      title="Copy to clipboard"
                    >
                      <svg
                        class="w-5 h-5 copy-icon"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                        />
                      </svg>
                      <svg
                        class="w-5 h-5 check-icon hidden text-green-500"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M5 13l4 4L19 7"
                        />
                      </svg>
                    </button>
                  </div>
                  <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                    Use this string to reference this model in ReqLLM
                  </p>
                </div>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                      Model ID
                    </div>
                    <code class="text-sm text-gray-900 dark:text-gray-100 bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded font-mono block break-all">
                      {@model.model_id}
                    </code>
                  </div>
                  <%= if @model.provider_model_id && @model.provider_model_id != @model.model_id do %>
                    <div>
                      <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                        Provider Model ID
                      </div>
                      <code class="text-sm text-gray-900 dark:text-gray-100 bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded font-mono block break-all">
                        {@model.provider_model_id}
                      </code>
                    </div>
                  <% end %>
                </div>
                <%= if @model.aliases && length(@model.aliases) > 0 do %>
                  <div>
                    <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                      Aliases
                    </div>
                    <div class="flex flex-wrap gap-1">
                      <%= for alias_name <- @model.aliases do %>
                        <code class="text-xs bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded font-mono">
                          {alias_name}
                        </code>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </section>

              <section class="space-y-3">
                <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700 pb-1">
                  Capabilities
                </h3>
                <.detailed_capabilities model={@model} />
              </section>

              <section class="space-y-3">
                <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700 pb-1">
                  Limits & Costs
                </h3>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  <.metric label="Context Window">
                    <:value>{ModelLive.format_number(get_in(@model.limits, [:context]))}</:value>
                  </.metric>
                  <.metric label="Max Output">
                    <:value>{ModelLive.format_number(get_in(@model.limits, [:output]))}</:value>
                  </.metric>
                  <.metric label="Input Cost">
                    <:value>{ModelLive.format_cost(get_in(@model.cost, [:input]))}</:value>
                  </.metric>
                  <.metric label="Output Cost">
                    <:value>{ModelLive.format_cost(get_in(@model.cost, [:output]))}</:value>
                  </.metric>
                </div>
                <.extra_costs model={@model} />
              </section>

              <%= if has_modalities?(@model) do %>
                <section class="space-y-3">
                  <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700 pb-1">
                    Modalities
                  </h3>
                  <div class="grid grid-cols-2 gap-4">
                    <%= if @model.modalities[:input] && length(@model.modalities[:input]) > 0 do %>
                      <div>
                        <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                          Input
                        </div>
                        <div class="flex flex-wrap gap-1">
                          <%= for mod <- @model.modalities[:input] do %>
                            <span class="px-2 py-0.5 text-xs font-medium text-emerald-600 dark:text-emerald-400 bg-emerald-100 dark:bg-emerald-900/30 rounded">
                              {mod}
                            </span>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                    <%= if @model.modalities[:output] && length(@model.modalities[:output]) > 0 do %>
                      <div>
                        <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                          Output
                        </div>
                        <div class="flex flex-wrap gap-1">
                          <%= for mod <- @model.modalities[:output] do %>
                            <span class="px-2 py-0.5 text-xs font-medium text-purple-600 dark:text-purple-400 bg-purple-100 dark:bg-purple-900/30 rounded">
                              {mod}
                            </span>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </section>
              <% end %>

              <%= if has_dates?(@model) or has_lifecycle?(@model) do %>
                <section class="space-y-3">
                  <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700 pb-1">
                    Lifecycle
                  </h3>
                  <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    <%= if @model.release_date do %>
                      <.metric label="Released">
                        <:value>{@model.release_date}</:value>
                      </.metric>
                    <% end %>
                    <%= if @model.last_updated do %>
                      <.metric label="Updated">
                        <:value>{@model.last_updated}</:value>
                      </.metric>
                    <% end %>
                    <%= if @model.knowledge do %>
                      <.metric label="Knowledge Cutoff">
                        <:value>{@model.knowledge}</:value>
                      </.metric>
                    <% end %>
                    <%= if get_in(@model.lifecycle, [:retires_at]) do %>
                      <.metric label="Retires">
                        <:value>{get_in(@model.lifecycle, [:retires_at])}</:value>
                      </.metric>
                    <% end %>
                  </div>
                  <%= if get_in(@model.lifecycle, [:replacement]) do %>
                    <div>
                      <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-1">
                        Replacement
                      </div>
                      <code class="text-sm text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/30 px-2 py-1 rounded font-mono">
                        {get_in(@model.lifecycle, [:replacement])}
                      </code>
                    </div>
                  <% end %>
                </section>
              <% end %>

              <%= if @model.tags && length(@model.tags) > 0 do %>
                <section class="space-y-3">
                  <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700 pb-1">
                    Tags
                  </h3>
                  <div class="flex flex-wrap gap-1">
                    <%= for tag <- @model.tags do %>
                      <span class="px-2 py-0.5 text-xs font-medium text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/30 rounded">
                        {tag}
                      </span>
                    <% end %>
                  </div>
                </section>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :model, :map, required: true

  defp detailed_capabilities(assigns) do
    caps = assigns.model.capabilities || %{}

    capability_groups = [
      %{
        name: "Core",
        items: [
          {:chat, Map.get(caps, :chat), "Chat", nil},
          {:embeddings, embeddings_enabled?(caps), "Embeddings", embeddings_details(caps)}
        ]
      },
      %{
        name: "Reasoning",
        items: [
          {:reasoning, get_in(caps, [:reasoning, :enabled]), "Reasoning", reasoning_details(caps)}
        ]
      },
      %{
        name: "Tools",
        items: [
          {:tools_enabled, get_in(caps, [:tools, :enabled]), "Tool Use", nil},
          {:tools_streaming, get_in(caps, [:tools, :streaming]), "Streaming Tools", nil},
          {:tools_parallel, get_in(caps, [:tools, :parallel]), "Parallel Tools", nil},
          {:tools_strict, get_in(caps, [:tools, :strict]), "Strict Mode", nil}
        ]
      },
      %{
        name: "JSON",
        items: [
          {:json_native, get_in(caps, [:json, :native]), "JSON Mode", nil},
          {:json_schema, get_in(caps, [:json, :schema]), "JSON Schema", nil},
          {:json_strict, get_in(caps, [:json, :strict]), "Strict JSON", nil}
        ]
      },
      %{
        name: "Streaming",
        items: [
          {:streaming_text, get_in(caps, [:streaming, :text]), "Text Streaming", nil},
          {:streaming_tools, get_in(caps, [:streaming, :tool_calls]), "Tool Call Streaming", nil}
        ]
      }
    ]

    assigns = assign(assigns, :capability_groups, capability_groups)

    ~H"""
    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
      <%= for group <- @capability_groups do %>
        <div class="space-y-1">
          <div class="text-xs font-medium text-gray-400 dark:text-gray-500 uppercase">
            {group.name}
          </div>
          <%= for {_key, enabled, label, detail} <- group.items do %>
            <div class="flex items-center gap-1.5">
              <%= if enabled do %>
                <svg class="w-4 h-4 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
              <% else %>
                <svg
                  class="w-4 h-4 text-gray-300 dark:text-gray-600"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              <% end %>
              <span class={"text-xs #{if enabled, do: "text-gray-700 dark:text-gray-300", else: "text-gray-400 dark:text-gray-500"}"}>
                {label}
              </span>
              <%= if detail do %>
                <span class="text-xs text-gray-400 dark:text-gray-500">({detail})</span>
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :model, :map, required: true

  defp extra_costs(assigns) do
    cost = assigns.model.cost || %{}

    extra_cost_items =
      [
        {:request, "Per Request"},
        {:cache_read, "Cache Read"},
        {:cache_write, "Cache Write"},
        {:reasoning, "Reasoning"},
        {:image, "Image"},
        {:audio, "Audio"},
        {:input_audio, "Input Audio"},
        {:output_audio, "Output Audio"},
        {:input_video, "Input Video"},
        {:output_video, "Output Video"},
        {:training, "Training"}
      ]
      |> Enum.filter(fn {key, _label} -> Map.get(cost, key) end)
      |> Enum.map(fn {key, label} -> {label, Map.get(cost, key)} end)

    assigns = assign(assigns, :extra_costs, extra_cost_items)

    ~H"""
    <%= if length(@extra_costs) > 0 do %>
      <div class="pt-2">
        <div class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase mb-2">
          Additional Costs ($/1M tokens)
        </div>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
          <%= for {label, value} <- @extra_costs do %>
            <div class="text-xs">
              <span class="text-gray-500 dark:text-gray-400">{label}:</span>
              <span class="text-gray-900 dark:text-gray-100 ml-1">
                {ModelLive.format_cost(value)}
              </span>
            </div>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  defp lifecycle_status(model) do
    get_in(model.lifecycle, [:status])
  end

  defp lifecycle_color("active"), do: "success"
  defp lifecycle_color("deprecated"), do: "warning"
  defp lifecycle_color("retired"), do: "danger"
  defp lifecycle_color(_), do: "gray"

  defp embeddings_enabled?(caps) do
    case Map.get(caps, :embeddings) do
      true -> true
      %{} = emb -> map_size(emb) > 0
      _ -> false
    end
  end

  defp embeddings_details(caps) do
    case Map.get(caps, :embeddings) do
      %{default_dimensions: dim} when is_integer(dim) -> "#{dim}d"
      %{max_dimensions: dim} when is_integer(dim) -> "up to #{dim}d"
      _ -> nil
    end
  end

  defp reasoning_details(caps) do
    case get_in(caps, [:reasoning, :token_budget]) do
      budget when is_integer(budget) and budget > 0 -> "#{div(budget, 1000)}k budget"
      _ -> nil
    end
  end

  defp has_modalities?(model) do
    modalities = model.modalities || %{}
    input_list = modalities[:input] || []
    output_list = modalities[:output] || []
    length(input_list) > 0 or length(output_list) > 0
  end

  defp has_dates?(model) do
    not is_nil(model.release_date) or not is_nil(model.last_updated) or not is_nil(model.knowledge)
  end

  defp has_lifecycle?(model) do
    lifecycle = model.lifecycle || %{}

    not is_nil(lifecycle[:status]) or not is_nil(lifecycle[:retires_at]) or
      not is_nil(lifecycle[:replacement])
  end
end
