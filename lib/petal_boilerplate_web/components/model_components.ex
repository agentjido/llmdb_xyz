defmodule PetalBoilerplateWeb.ModelComponents do
  use PetalBoilerplateWeb, :html

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Filters
  alias PetalBoilerplateWeb.ModelLive

  # =============================================================================
  # Task 2.1: Header Component
  # =============================================================================

  defp llm_db_version do
    Application.spec(:llm_db, :vsn) |> to_string()
  end

  attr :search_value, :string, required: true

  def header(assigns) do
    ~H"""
    <header
      class="sticky top-0 z-50 border-b backdrop-blur supports-[backdrop-filter]:bg-[hsl(var(--background)/0.6)]"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--background) / 0.95);"
    >
      <div class="w-full max-w-full flex h-14 items-center gap-3 px-4">
        <a
          href="/"
          class="flex items-center gap-2 shrink-0 transition-opacity hover:opacity-80"
          title="Go to home page"
        >
          <.icon name="hero-circle-stack" class="h-6 w-6" style="color: hsl(var(--primary));" />
          <span
            class="text-lg font-semibold tracking-tight hidden sm:inline"
            style="color: hsl(var(--foreground));"
          >
            LLM Model DB
          </span>
        </a>

        <div class="flex-1" />

        <form
          phx-change="filter"
          phx-debounce="300"
          class="w-full max-w-[200px] sm:max-w-xs md:max-w-sm"
        >
          <div class="relative">
            <.icon
              name="hero-magnifying-glass"
              class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2"
              style="color: hsl(var(--muted-foreground));"
            />
            <input
              type="text"
              name="search"
              value={@search_value}
              placeholder="Search..."
              class="w-full pl-9 h-9 rounded-md border-0 text-sm"
              style="background-color: hsl(var(--secondary)); color: hsl(var(--foreground));"
            />
          </div>
        </form>

        <a
          href="https://hex.pm/packages/llm_db"
          target="_blank"
          rel="noopener noreferrer"
          class="text-xs hidden sm:flex items-center gap-1 px-2 py-1 rounded border transition-colors hover:opacity-80"
          style="color: hsl(var(--muted-foreground)); border-color: hsl(var(--border));"
          title="View llm_db package on Hex"
        >
          <.icon name="hero-cube" class="h-3 w-3" />
          llm_db v{llm_db_version()}
        </a>

        <a
          href="/about"
          class="text-sm hidden sm:block transition-colors hover:opacity-80"
          style="color: hsl(var(--muted-foreground));"
        >
          About
        </a>

        <div class="flex items-center gap-0.5 shrink-0">
          <a
            href="https://agentjido.xyz/discord"
            target="_blank"
            rel="noopener noreferrer"
            title="Join Discord"
            class="p-2 rounded-md transition-colors hover:opacity-80"
            style="color: hsl(var(--foreground));"
          >
            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
            </svg>
          </a>
          <a
            href="https://github.com/agentjido/llm_db"
            target="_blank"
            rel="noopener noreferrer"
            title="GitHub"
            class="p-2 rounded-md transition-colors hover:opacity-80"
            style="color: hsl(var(--foreground));"
          >
            <svg class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
            </svg>
          </a>
          <button
            type="button"
            onclick="toggleScheme()"
            title="Toggle theme"
            class="p-2 rounded-md transition-colors hover:opacity-80"
            style="color: hsl(var(--foreground));"
          >
            <.icon name="hero-moon" class="h-4 w-4 color-scheme-dark-icon" />
            <.icon name="hero-sun" class="h-4 w-4 color-scheme-light-icon hidden" />
          </button>
        </div>
      </div>
    </header>
    """
  end

  # =============================================================================
  # Task 2.2: Capability Badge Component
  # =============================================================================

  @capability_colors %{
    chat: "--cap-chat",
    tools: "--cap-tools",
    vision: "--cap-vision",
    reasoning: "--cap-reason",
    streaming: "--cap-stream",
    embeddings: "--cap-embed",
    json_output: "--muted-foreground",
    audio_input: "--cap-stream",
    audio_output: "--cap-stream",
    image_generation: "--cap-vision"
  }

  @capability_labels %{
    chat: "Chat",
    tools: "Tools",
    vision: "Vision",
    reasoning: "Reasoning",
    streaming: "Streaming",
    embeddings: "Embed",
    json_output: "JSON",
    audio_input: "Audio In",
    audio_output: "Audio Out",
    image_generation: "Image Gen"
  }

  @capability_icons %{
    chat: "hero-chat-bubble-left",
    tools: "hero-wrench",
    vision: "hero-eye",
    reasoning: "hero-academic-cap",
    streaming: "hero-bolt",
    embeddings: "hero-hashtag",
    json_output: "hero-code-bracket",
    audio_input: "hero-microphone",
    audio_output: "hero-speaker-wave",
    image_generation: "hero-photo"
  }

  attr :capability, :atom, required: true
  attr :active, :boolean, default: true
  attr :compact, :boolean, default: false

  def capability_badge(assigns) do
    color_var = Map.get(@capability_colors, assigns.capability, "--muted-foreground")
    label = Map.get(@capability_labels, assigns.capability, to_string(assigns.capability))
    icon_name = Map.get(@capability_icons, assigns.capability)

    assigns =
      assigns
      |> assign(:color_var, color_var)
      |> assign(:label, label)
      |> assign(:icon_name, icon_name)

    ~H"""
    <span
      :if={@active}
      class={"inline-flex items-center gap-1 rounded border font-medium #{if @compact, do: "px-1.5 py-0.5 text-[10px]", else: "px-2 py-0.5 text-xs"}"}
      style={"background-color: hsl(var(#{@color_var}) / 0.2); color: hsl(var(#{@color_var})); border-color: hsl(var(#{@color_var}) / 0.3);"}
    >
      <.icon :if={@icon_name} name={@icon_name} class="h-2.5 w-2.5" />
      {@label}
    </span>
    """
  end

  # =============================================================================
  # Task 2.3: Filter Bar Component
  # =============================================================================

  attr :filters, :any, required: true
  attr :providers, :list, required: true
  attr :active_quick_filters, :list, default: []

  def filter_bar(assigns) do
    quick_filters = Filters.quick_filters()
    assigns = assign(assigns, :quick_filters, quick_filters)

    ~H"""
    <div
      class="sticky top-14 z-40 border-b backdrop-blur supports-[backdrop-filter]:bg-[hsl(var(--background)/0.8)]"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--background) / 0.95);"
    >
      <div class="hidden md:block">
        <div class="w-full max-w-full py-2.5 px-4">
          <div class="flex items-center gap-3">
            <span class="text-sm shrink-0 font-medium" style="color: hsl(var(--muted-foreground));">
              Quick:
            </span>
            <div class="flex items-center gap-2 flex-wrap">
              <%= for qf <- @quick_filters do %>
                <.quick_filter_pill
                  label={qf.label}
                  icon={qf.icon}
                  kind={to_string(qf.key)}
                  active={qf.key in @active_quick_filters}
                />
              <% end %>
            </div>
          </div>
        </div>

        <div class="w-full max-w-full pb-2.5 px-4">
          <div class="flex items-center gap-2">
            <.icon
              name="hero-funnel"
              class="h-4 w-4 shrink-0"
              style="color: hsl(var(--muted-foreground));"
            />

            <.filter_dropdown label={"Provider #{provider_count_label(@filters)}"}>
              <.provider_filter_content providers={@providers} filters={@filters} />
            </.filter_dropdown>

            <.filter_dropdown label="Capabilities">
              <.capabilities_filter_content filters={@filters} />
            </.filter_dropdown>

            <.filter_dropdown label={"Context #{context_label(@filters)}"}>
              <.context_filter_content filters={@filters} />
            </.filter_dropdown>

            <.filter_dropdown label={"Cost #{cost_label(@filters)}"}>
              <.cost_filter_content filters={@filters} />
            </.filter_dropdown>

            <div class="flex flex-wrap gap-1 ml-2">
              <%= for provider <- selected_provider_badges(@filters, @providers) |> Enum.take(3) do %>
                <span
                  class="inline-flex items-center gap-1 h-6 px-2 text-xs rounded-md"
                  style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                >
                  {provider.name}
                  <button
                    type="button"
                    phx-click="remove_provider"
                    phx-value-id={provider.id}
                    class="hover:opacity-70"
                  >
                    <.icon name="hero-x-mark" class="h-3 w-3" />
                  </button>
                </span>
              <% end %>
              <%= if length(selected_provider_badges(@filters, @providers)) > 3 do %>
                <span
                  class="inline-flex items-center h-6 px-2 text-xs rounded-md"
                  style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                >
                  +{length(selected_provider_badges(@filters, @providers)) - 3} more
                </span>
              <% end %>
            </div>

            <button
              :if={has_active_filters?(@filters)}
              type="button"
              phx-click="reset_filters"
              class="ml-auto h-8 px-3 text-sm transition-colors hover:opacity-80"
              style="color: hsl(var(--muted-foreground));"
            >
              Clear all
            </button>
          </div>
        </div>
      </div>

      <div class="md:hidden">
        <div class="w-full max-w-full py-2.5 px-4">
          <div class="flex items-center gap-2">
            <button
              type="button"
              phx-click="toggle_filters"
              class="h-9 px-3 flex items-center gap-2 rounded-md border text-sm"
              style="border-color: hsl(var(--border));"
            >
              <.icon name="hero-adjustments-horizontal" class="h-4 w-4" /> Filters
              <span
                :if={active_filter_count(@filters) > 0}
                class="h-5 min-w-5 px-1.5 text-xs rounded-full flex items-center justify-center"
                style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
              >
                {active_filter_count(@filters)}
              </span>
            </button>

            <div class="flex items-center gap-1.5 overflow-x-auto scrollbar-none flex-1">
              <%= for qf <- Enum.filter(@quick_filters, &(&1.key in @active_quick_filters)) |> Enum.take(3) do %>
                <button
                  type="button"
                  phx-click="quick_filter"
                  phx-value-kind={to_string(qf.key)}
                  class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-full text-xs font-medium shrink-0"
                  style="background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));"
                >
                  <.icon name={qf.icon} class="h-3.5 w-3.5" />
                  <span>{qf.label}</span>
                  <.icon name="hero-x-mark" class="h-3 w-3" />
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :kind, :string, required: true
  attr :active, :boolean, default: false

  defp quick_filter_pill(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="quick_filter"
      phx-value-kind={@kind}
      class={"inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-colors #{if @active, do: "", else: "hover:opacity-80"}"}
      style={
        if @active,
          do: "background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));",
          else: "background-color: hsl(var(--muted)); color: hsl(var(--muted-foreground));"
      }
    >
      <.icon name={@icon} class="h-4 w-4" />
      <span>{@label}</span>
    </button>
    """
  end

  attr :label, :string, required: true
  slot :inner_block, required: true

  defp filter_dropdown(assigns) do
    ~H"""
    <div class="relative group">
      <button
        type="button"
        class="h-8 px-3 text-sm rounded-md border flex items-center gap-1 transition-colors hover:opacity-80"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
      >
        {@label}
        <.icon name="hero-chevron-down" class="h-3 w-3" style="color: hsl(var(--muted-foreground));" />
      </button>
      <div
        class="absolute left-0 top-full mt-1 hidden group-focus-within:block hover:block rounded-md border shadow-lg z-50"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--popover)); color: hsl(var(--popover-foreground));"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :providers, :list, required: true
  attr :filters, :map, required: true

  defp provider_filter_content(assigns) do
    ~H"""
    <div class="w-64">
      <div class="p-2 border-b" style="border-color: hsl(var(--border));">
        <div class="relative">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-2 top-1/2 -translate-y-1/2 h-3.5 w-3.5"
            style="color: hsl(var(--muted-foreground));"
          />
          <input
            type="text"
            name="provider_search"
            value={@filters.provider_search}
            placeholder="Search providers..."
            class="h-8 w-full pl-7 text-sm rounded-md border-0"
            style="background-color: hsl(var(--secondary));"
            phx-change="filter"
            phx-debounce="200"
          />
        </div>
      </div>
      <div
        class="flex gap-1 p-2 border-b"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
      >
        <button
          type="button"
          phx-click="select_all_providers"
          class="h-6 flex-1 text-xs rounded hover:opacity-80"
        >
          Select All
        </button>
        <button
          type="button"
          phx-click="clear_providers"
          class="h-6 flex-1 text-xs rounded hover:opacity-80"
          disabled={MapSet.size(@filters.provider_ids) == 0}
        >
          Clear ({MapSet.size(@filters.provider_ids)})
        </button>
      </div>
      <div class="max-h-[280px] overflow-y-auto p-1">
        <form phx-change="filter">
          <%= for provider <- filtered_providers(@providers, @filters.provider_search) do %>
            <label
              class="flex items-center gap-2 cursor-pointer rounded px-2 py-1.5 hover:opacity-80"
              style="background-color: transparent;"
              onmouseover="this.style.backgroundColor='hsl(var(--accent))'"
              onmouseout="this.style.backgroundColor='transparent'"
            >
              <input
                type="checkbox"
                name={"providers[#{provider.id}]"}
                checked={MapSet.member?(@filters.provider_ids, provider.id)}
                class="rounded"
                style="border-color: hsl(var(--border));"
              />
              <span class="text-sm truncate">{provider.name}</span>
            </label>
          <% end %>
        </form>
      </div>
    </div>
    """
  end

  attr :filters, :map, required: true

  defp capabilities_filter_content(assigns) do
    capabilities = [
      {:chat, "Chat"},
      {:tools, "Tools"},
      {:streaming_text, "Streaming"},
      {:vision, "Vision"},
      {:reasoning, "Reasoning"},
      {:embeddings, "Embeddings"},
      {:json_native, "JSON Output"}
    ]

    assigns = assign(assigns, :capabilities, capabilities)

    ~H"""
    <div class="w-44 p-2">
      <form phx-change="filter">
        <%= for {cap_key, cap_label} <- @capabilities do %>
          <label
            class="flex items-center gap-2 cursor-pointer rounded px-2 py-1 hover:opacity-80"
            style="background-color: transparent;"
            onmouseover="this.style.backgroundColor='hsl(var(--accent))'"
            onmouseout="this.style.backgroundColor='transparent'"
          >
            <input
              type="checkbox"
              name={"cap_#{cap_key}"}
              value="true"
              checked={get_capability_filter(@filters.capabilities, cap_key)}
              class="rounded"
              style="border-color: hsl(var(--border));"
            />
            <span class="text-sm">{cap_label}</span>
          </label>
        <% end %>
      </form>
    </div>
    """
  end

  attr :filters, :map, required: true

  defp context_filter_content(assigns) do
    context_options = [
      {0, "Any"},
      {8000, "8K+"},
      {32000, "32K+"},
      {100_000, "100K+"},
      {200_000, "200K+"},
      {1_000_000, "1M+"}
    ]

    assigns = assign(assigns, :context_options, context_options)

    ~H"""
    <div class="w-48 p-3">
      <div class="text-xs font-medium mb-2">Minimum context window</div>
      <div class="grid grid-cols-3 gap-1">
        <%= for {val, label} <- @context_options do %>
          <button
            type="button"
            phx-click="set_min_context"
            phx-value-value={val}
            class="px-2 py-1.5 text-xs rounded transition-colors"
            style={
              if @filters.min_context == val,
                do: "background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));",
                else: "background-color: hsl(var(--muted));"
            }
          >
            {label}
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  attr :filters, :map, required: true

  defp cost_filter_content(assigns) do
    cost_options = [
      {0.5, "<$0.50"},
      {1, "<$1"},
      {3, "<$3"},
      {10, "<$10"},
      {50, "<$50"},
      {nil, "Any"}
    ]

    assigns = assign(assigns, :cost_options, cost_options)

    ~H"""
    <div class="w-48 p-3">
      <div class="text-xs font-medium mb-2">Max input cost (per 1M tokens)</div>
      <div class="grid grid-cols-2 gap-1">
        <%= for {val, label} <- @cost_options do %>
          <button
            type="button"
            phx-click="set_max_cost"
            phx-value-value={val || ""}
            class="px-2 py-1.5 text-xs rounded transition-colors"
            style={
              if @filters.max_cost_in == val,
                do: "background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));",
                else: "background-color: hsl(var(--muted));"
            }
          >
            {label}
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp provider_count_label(filters) do
    count = MapSet.size(filters.provider_ids)
    if count > 0, do: "(#{count})", else: ""
  end

  defp context_label(filters) do
    if filters.min_context && filters.min_context > 0 do
      "(>#{div(filters.min_context, 1000)}K)"
    else
      ""
    end
  end

  defp cost_label(filters) do
    if filters.max_cost_in && filters.max_cost_in < 100 do
      "(<$#{filters.max_cost_in})"
    else
      ""
    end
  end

  defp selected_provider_badges(filters, providers) do
    Enum.filter(providers, &MapSet.member?(filters.provider_ids, &1.id))
  end

  defp has_active_filters?(filters) do
    MapSet.size(filters.provider_ids) > 0 ||
      (filters.min_context && filters.min_context > 0) ||
      (filters.max_cost_in && filters.max_cost_in < 100) ||
      has_capability_filters?(filters.capabilities)
  end

  defp has_capability_filters?(capabilities) do
    Enum.any?(
      [:chat, :tools, :vision, :reasoning, :embeddings, :json_native, :streaming_text],
      fn cap ->
        get_capability_filter(capabilities, cap)
      end
    )
  end

  defp get_capability_filter(capabilities, key) when is_map(capabilities) do
    Map.get(capabilities, key, false)
  end

  defp get_capability_filter(_, _), do: false

  defp active_filter_count(%Filters{} = filters) do
    Filters.active_filter_count(filters)
  end

  defp active_filter_count(filters) when is_map(filters) do
    count = 0
    count = if MapSet.size(filters.provider_ids) > 0, do: count + 1, else: count
    count = if filters.min_context && filters.min_context > 0, do: count + 1, else: count
    count = if filters.max_cost_in && filters.max_cost_in < 100, do: count + 1, else: count
    count
  end

  # =============================================================================
  # Task 2.4: Model Table Component
  # =============================================================================

  attr :models, :any, required: true
  attr :sort, :map, required: true
  attr :total, :integer, required: true
  attr :selected_ids, :any, default: MapSet.new()
  attr :can_add_more, :boolean, default: true

  def model_table(assigns) do
    ~H"""
    <div class="overflow-x-auto scrollbar-thin">
      <table class="w-full text-sm hidden md:table">
        <thead style="background-color: hsl(var(--table-header));">
          <tr class="border-b" style="border-color: hsl(var(--table-border));">
            <th class="w-10 px-3 py-3 text-left"></th>
            <.sortable_header field={:provider} label="Provider" sort={@sort} />
            <.sortable_header field={:name} label="Model" sort={@sort} />
            <th class="px-3 py-3 text-left font-medium" style="color: hsl(var(--muted-foreground));">
              I/O
            </th>
            <th class="px-3 py-3 text-left font-medium" style="color: hsl(var(--muted-foreground));">
              Features
            </th>
            <.sortable_header field={:context} label="Context" sort={@sort} align="right" />
            <.sortable_header field={:cost_in} label="In/Out $/M" sort={@sort} align="right" />
          </tr>
        </thead>
        <tbody id="models-table-body" phx-update="stream">
          <%= if @total == 0 do %>
            <tr id="no-models-row">
              <td
                colspan="7"
                class="px-3 py-12 text-center"
                style="color: hsl(var(--muted-foreground));"
              >
                No models match your filters
              </td>
            </tr>
          <% else %>
            <tr
              :for={{dom_id, model} <- @models}
              id={dom_id}
              phx-click="show_model"
              phx-value-id={dom_id}
              class="border-b cursor-pointer transition-colors"
              style={"border-color: hsl(var(--table-border)); #{if MapSet.member?(@selected_ids, dom_id), do: "background-color: hsl(var(--table-row-selected));", else: ""}"}
              onmouseover={
                if !MapSet.member?(@selected_ids, dom_id),
                  do: "this.style.backgroundColor='hsl(var(--table-row-hover))'"
              }
              onmouseout={
                if !MapSet.member?(@selected_ids, dom_id),
                  do: "this.style.backgroundColor='transparent'"
              }
            >
              <td class="px-3 py-2" phx-click="toggle_select" phx-value-id={dom_id}>
                <input
                  type="checkbox"
                  checked={MapSet.member?(@selected_ids, dom_id)}
                  disabled={!MapSet.member?(@selected_ids, dom_id) && !@can_add_more}
                  class="rounded"
                  style="border-color: hsl(var(--border));"
                  onclick="event.stopPropagation()"
                />
              </td>
              <td class="px-3 py-2" style="color: hsl(var(--muted-foreground));">
                {model.provider}
              </td>
              <td class="px-3 py-2">
                <div class="flex items-center gap-2">
                  <div>
                    <div class="font-medium">{model.name}</div>
                    <div class="text-xs font-mono" style="color: hsl(var(--muted-foreground));">
                      {model.model_id}
                    </div>
                  </div>
                  <%= if model.deprecated || lifecycle_status(model) != "active" do %>
                    <span
                      class="text-[10px] px-1 py-0 rounded"
                      style="background-color: hsl(var(--destructive) / 0.1); color: hsl(var(--destructive));"
                    >
                      {lifecycle_label(model)}
                    </span>
                  <% end %>
                </div>
              </td>
              <td class="px-3 py-2">
                <.modality_badges model={model} />
              </td>
              <td class="px-3 py-2">
                <div class="flex flex-wrap gap-1">
                  <.capability_badge
                    :if={get_in(model.capabilities, [:reasoning, :enabled])}
                    capability={:reasoning}
                    compact
                  />
                  <.capability_badge
                    :if={get_in(model.capabilities, [:tools, :enabled])}
                    capability={:tools}
                    compact
                  />
                  <.capability_badge :if={has_vision?(model)} capability={:vision} compact />
                  <.capability_badge
                    :if={embeddings_enabled?(model.capabilities)}
                    capability={:embeddings}
                    compact
                  />
                  <.capability_badge
                    :if={get_in(model.capabilities, [:json, :native])}
                    capability={:json_output}
                    compact
                  />
                </div>
              </td>
              <td class="px-3 py-2 text-right font-mono text-xs">
                {ModelLive.format_number(get_in(model.limits, [:context]))}
              </td>
              <td class="px-3 py-2 text-right font-mono text-xs">
                {ModelLive.format_cost(get_in(model.cost, [:input]))}/{ModelLive.format_cost(
                  get_in(model.cost, [:output])
                )}
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>

      <div class="md:hidden divide-y" style="border-color: hsl(var(--border));">
        <%= if @total == 0 do %>
          <div class="py-12 text-center" style="color: hsl(var(--muted-foreground));">
            No models match your filters
          </div>
        <% else %>
          <div
            :for={{dom_id, model} <- @models}
            id={"mobile-#{dom_id}"}
            class="p-3 transition-colors cursor-pointer"
            style={
              if MapSet.member?(@selected_ids, dom_id),
                do: "background-color: hsl(var(--table-row-selected));",
                else: ""
            }
            phx-click="show_model"
            phx-value-id={dom_id}
          >
            <div class="flex items-start gap-3">
              <div class="pt-0.5" phx-click="toggle_select" phx-value-id={dom_id}>
                <input
                  type="checkbox"
                  checked={MapSet.member?(@selected_ids, dom_id)}
                  disabled={!MapSet.member?(@selected_ids, dom_id) && !@can_add_more}
                  class="rounded"
                  style="border-color: hsl(var(--border));"
                  onclick="event.stopPropagation()"
                />
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <span class="font-medium truncate">{model.name}</span>
                  <%= if model.deprecated || lifecycle_status(model) != "active" do %>
                    <span
                      class="text-[10px] px-1 py-0 rounded"
                      style="background-color: hsl(var(--destructive) / 0.1); color: hsl(var(--destructive));"
                    >
                      {lifecycle_label(model)}
                    </span>
                  <% end %>
                </div>
                <div class="text-xs mt-0.5" style="color: hsl(var(--muted-foreground));">
                  {model.provider}
                </div>

                <div
                  class="flex items-center gap-3 mt-2 text-xs"
                  style="color: hsl(var(--muted-foreground));"
                >
                  <.modality_badges model={model} />
                  <span class="font-mono">
                    {ModelLive.format_number(get_in(model.limits, [:context]))}
                  </span>
                  <span class="font-mono">
                    {ModelLive.format_cost(get_in(model.cost, [:input]))}/{ModelLive.format_cost(
                      get_in(model.cost, [:output])
                    )}
                  </span>
                </div>

                <div class="flex flex-wrap gap-1 mt-2">
                  <.capability_badge
                    :if={get_in(model.capabilities, [:reasoning, :enabled])}
                    capability={:reasoning}
                    compact
                  />
                  <.capability_badge
                    :if={get_in(model.capabilities, [:tools, :enabled])}
                    capability={:tools}
                    compact
                  />
                  <.capability_badge :if={has_vision?(model)} capability={:vision} compact />
                  <.capability_badge
                    :if={embeddings_enabled?(model.capabilities)}
                    capability={:embeddings}
                    compact
                  />
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :sort, :map, required: true
  attr :align, :string, default: "left"

  defp sortable_header(assigns) do
    is_active = assigns.sort.by == assigns.field

    assigns =
      assigns
      |> assign(:is_active, is_active)

    ~H"""
    <th
      phx-click="sort"
      phx-value-by={@field}
      class={"px-3 py-3 font-medium cursor-pointer transition-colors select-none hover:opacity-80 #{if @align == "right", do: "text-right", else: "text-left"}"}
      style="color: hsl(var(--muted-foreground));"
    >
      <div class={"flex items-center gap-1 #{if @align == "right", do: "justify-end", else: ""}"}>
        <span>{@label}</span>
        <%= if @is_active do %>
          <%= if @sort.dir == :asc do %>
            <.icon name="hero-arrow-up" class="h-3.5 w-3.5" />
          <% else %>
            <.icon name="hero-arrow-down" class="h-3.5 w-3.5" />
          <% end %>
        <% else %>
          <.icon name="hero-arrows-up-down" class="h-3.5 w-3.5 opacity-30" />
        <% end %>
      </div>
    </th>
    """
  end

  attr :model, :map, required: true

  defp modality_badges(assigns) do
    modalities = assigns.model.modalities || %{}
    input_list = modalities[:input] || []
    output_list = modalities[:output] || []
    all_modalities = (input_list ++ output_list) |> Enum.uniq()

    assigns = assign(assigns, :modalities, all_modalities)

    ~H"""
    <div class="flex gap-0.5">
      <span :for={mod <- @modalities} class="title={mod}" style="color: hsl(var(--muted-foreground));">
        <.modality_icon modality={mod} />
      </span>
    </div>
    """
  end

  attr :modality, :atom, required: true

  defp modality_icon(assigns) do
    ~H"""
    <%= case @modality do %>
      <% :text -> %>
        <.icon name="hero-document-text" class="h-3 w-3" />
      <% :image -> %>
        <.icon name="hero-photo" class="h-3 w-3" />
      <% :audio -> %>
        <.icon name="hero-speaker-wave" class="h-3 w-3" />
      <% :video -> %>
        <.icon name="hero-video-camera" class="h-3 w-3" />
      <% _ -> %>
        <.icon name="hero-question-mark-circle" class="h-3 w-3" />
    <% end %>
    """
  end

  defp has_vision?(model) do
    modalities = model.modalities || %{}
    input_list = modalities[:input] || []
    :image in input_list
  end

  # =============================================================================
  # Task 2.5: Model Detail Modal Component
  # =============================================================================

  attr :model, :map, default: nil

  def model_detail_modal(assigns) do
    ~H"""
    <div
      :if={@model}
      id="model-detail-modal"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div class="fixed inset-0 bg-black/50 backdrop-blur-sm" phx-click="close_model" />
      <div
        class="relative z-10 w-full max-w-3xl max-h-[85vh] overflow-y-auto rounded-lg border shadow-lg m-4"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
        phx-click-away="close_model"
      >
        <div class="p-6">
          <div class="flex items-center gap-2 mb-1">
            <span class="text-sm" style="color: hsl(var(--muted-foreground));">
              {@model.provider}
            </span>
            <span
              class="text-xs px-2 py-0.5 rounded"
              style={"background-color: hsl(var(#{lifecycle_bg_color(@model)})); color: hsl(var(#{lifecycle_text_color(@model)}));"}
            >
              {lifecycle_label(@model)}
            </span>
            <span
              :if={@model.family}
              class="text-xs px-2 py-0.5 rounded border"
              style="border-color: hsl(var(--border));"
            >
              {@model.family}
            </span>
          </div>

          <h2 class="text-2xl font-semibold mb-2">{@model.name}</h2>

          <div class="flex items-center gap-2 mb-4">
            <code
              class="text-sm px-2 py-1 rounded font-mono"
              style="background-color: hsl(var(--muted));"
            >
              {@model.model_id}
            </code>
            <button
              type="button"
              onclick={"navigator.clipboard.writeText('#{@model.model_id}'); this.querySelector('.copy-icon').classList.add('hidden'); this.querySelector('.check-icon').classList.remove('hidden'); setTimeout(() => { this.querySelector('.copy-icon').classList.remove('hidden'); this.querySelector('.check-icon').classList.add('hidden'); }, 2000);"}
              class="p-1 rounded hover:opacity-80"
            >
              <.icon name="hero-clipboard" class="h-3 w-3 copy-icon" />
              <.icon name="hero-check" class="h-3 w-3 check-icon hidden" />
            </button>
          </div>

          <%= if has_modalities?(@model) do %>
            <div class="mb-6">
              <h3 class="text-sm font-semibold mb-3">Modalities</h3>
              <div class="grid grid-cols-2 gap-4">
                <div
                  class="rounded-lg border p-3"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                >
                  <div class="text-xs mb-2" style="color: hsl(var(--muted-foreground));">Input</div>
                  <div class="flex flex-wrap gap-2">
                    <%= for mod <- (@model.modalities[:input] || []) do %>
                      <span
                        class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-sm"
                        style="background-color: hsl(var(--primary) / 0.1); color: hsl(var(--primary));"
                      >
                        <.modality_icon modality={mod} />
                        {mod}
                      </span>
                    <% end %>
                  </div>
                </div>
                <div
                  class="rounded-lg border p-3"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                >
                  <div class="text-xs mb-2" style="color: hsl(var(--muted-foreground));">Output</div>
                  <div class="flex flex-wrap gap-2">
                    <%= for mod <- (@model.modalities[:output] || []) do %>
                      <span
                        class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-sm"
                        style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                      >
                        <.modality_icon modality={mod} />
                        {mod}
                      </span>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <div class="mb-6">
            <h3 class="text-sm font-semibold mb-3">Capabilities</h3>
            <div class="flex flex-wrap gap-2">
              <.capability_badge :if={@model.capabilities[:chat]} capability={:chat} />
              <.capability_badge
                :if={get_in(@model.capabilities, [:reasoning, :enabled])}
                capability={:reasoning}
              />
              <.capability_badge
                :if={get_in(@model.capabilities, [:tools, :enabled])}
                capability={:tools}
              />
              <.capability_badge :if={has_vision?(@model)} capability={:vision} />
              <.capability_badge
                :if={get_in(@model.capabilities, [:streaming, :text])}
                capability={:streaming}
              />
              <.capability_badge
                :if={embeddings_enabled?(@model.capabilities)}
                capability={:embeddings}
              />
              <.capability_badge
                :if={get_in(@model.capabilities, [:json, :native])}
                capability={:json_output}
              />
            </div>
          </div>

          <div class="mb-6">
            <h3 class="text-sm font-semibold mb-3">Specifications</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div
                class="rounded-lg border p-3"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
              >
                <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">
                  Context Window
                </div>
                <div class="font-mono font-medium text-sm">
                  {ModelLive.format_number(get_in(@model.limits, [:context]))} tokens
                </div>
              </div>
              <div
                class="rounded-lg border p-3"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
              >
                <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">
                  Max Output
                </div>
                <div class="font-mono font-medium text-sm">
                  {ModelLive.format_number(get_in(@model.limits, [:output]))} tokens
                </div>
              </div>
              <div
                class="rounded-lg border p-3"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
              >
                <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">
                  Input Cost
                </div>
                <div class="font-mono font-medium text-sm">
                  {ModelLive.format_cost(get_in(@model.cost, [:input]))}/M
                </div>
              </div>
              <div
                class="rounded-lg border p-3"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
              >
                <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">
                  Output Cost
                </div>
                <div class="font-mono font-medium text-sm">
                  {ModelLive.format_cost(get_in(@model.cost, [:output]))}/M
                </div>
              </div>
            </div>
          </div>

          <button
            type="button"
            phx-click="close_model"
            class="absolute top-4 right-4 p-2 rounded-md hover:opacity-80"
            style="color: hsl(var(--muted-foreground));"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  # =============================================================================
  # Task 2.6: Comparison Modal Component
  # =============================================================================

  attr :is_open, :boolean, required: true
  attr :models, :list, required: true
  attr :on_remove, :string, default: "remove_from_comparison"
  attr :on_clear, :string, default: "clear_comparison"
  attr :on_close, :string, default: "close_comparison"

  def comparison_modal(assigns) do
    capabilities = [:chat, :tools, :streaming, :vision, :reasoning, :embeddings, :json_output]
    assigns = assign(assigns, :capabilities, capabilities)

    ~H"""
    <div
      :if={@is_open}
      id="comparison-modal"
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-click={@on_close}
    >
      <div class="fixed inset-0 bg-black/50 backdrop-blur-sm" />
      <div
        class="relative z-10 w-full max-w-5xl max-h-[85vh] overflow-y-auto rounded-lg border shadow-lg m-4"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
        phx-click-away={@on_close}
        onclick="event.stopPropagation()"
      >
        <div class="p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-xl font-semibold">Compare Models ({length(@models)})</h2>
            <div class="flex gap-2">
              <button
                type="button"
                onclick="navigator.clipboard.writeText(window.location.href); this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Share', 2000);"
                class="px-3 py-1.5 text-sm rounded-md border flex items-center gap-1"
                style="border-color: hsl(var(--border));"
              >
                <.icon name="hero-clipboard" class="h-4 w-4" /> Share
              </button>
              <button type="button" phx-click={@on_clear} class="px-3 py-1.5 text-sm hover:opacity-80">
                Clear all
              </button>
            </div>
          </div>

          <%= if length(@models) == 0 do %>
            <div class="py-12 text-center" style="color: hsl(var(--muted-foreground));">
              Select models from the table to compare
            </div>
          <% else %>
            <div class="space-y-6">
              <div
                class="grid gap-4"
                style={"grid-template-columns: repeat(#{length(@models)}, 1fr);"}
              >
                <%= for model <- @models do %>
                  <div
                    class="relative rounded-lg border p-3"
                    style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
                  >
                    <button
                      type="button"
                      phx-click={@on_remove}
                      phx-value-id={model.id}
                      class="absolute top-1 right-1 h-6 w-6 flex items-center justify-center rounded hover:opacity-80"
                    >
                      <.icon name="hero-x-mark" class="h-3 w-3" />
                    </button>
                    <div class="flex items-center gap-2">
                      <span class="text-xs" style="color: hsl(var(--muted-foreground));">
                        {model.provider}
                      </span>
                      <span
                        class="text-[10px] px-1 py-0 rounded"
                        style={"background-color: hsl(var(#{lifecycle_bg_color(model)})); color: hsl(var(#{lifecycle_text_color(model)}));"}
                      >
                        {lifecycle_label(model)}
                      </span>
                    </div>
                    <div class="font-medium">{model.name}</div>
                    <div class="text-xs font-mono mt-1" style="color: hsl(var(--muted-foreground));">
                      {model.model_id}
                    </div>
                    <div
                      :if={model.family}
                      class="text-xs mt-1"
                      style="color: hsl(var(--muted-foreground));"
                    >
                      Family: {model.family}
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-medium" style="color: hsl(var(--muted-foreground));">
                  Modalities
                </h4>
                <div
                  class="rounded-lg border overflow-hidden"
                  style="border-color: hsl(var(--border));"
                >
                  <div
                    class="grid border-b"
                    style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr); border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.5);"}
                  >
                    <div class="p-2 text-xs font-medium">Input</div>
                    <%= for model <- @models do %>
                      <div class="p-2 flex gap-1 justify-center flex-wrap">
                        <%= for mod <- (model.modalities[:input] || []) do %>
                          <span
                            class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px]"
                            style="background-color: hsl(var(--primary) / 0.1); color: hsl(var(--primary));"
                          >
                            <.modality_icon modality={mod} />
                            {mod}
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                  <div
                    class="grid"
                    style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr);"}
                  >
                    <div class="p-2 text-xs font-medium">Output</div>
                    <%= for model <- @models do %>
                      <div class="p-2 flex gap-1 justify-center flex-wrap">
                        <%= for mod <- (model.modalities[:output] || []) do %>
                          <span
                            class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px]"
                            style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                          >
                            <.modality_icon modality={mod} />
                            {mod}
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-medium" style="color: hsl(var(--muted-foreground));">
                  Specifications
                </h4>
                <div
                  class="rounded-lg border overflow-hidden"
                  style="border-color: hsl(var(--border));"
                >
                  <.comparison_spec_row
                    label="Context"
                    models={@models}
                    getter={fn m -> ModelLive.format_number(get_in(m.limits, [:context])) end}
                    bg
                  />
                  <.comparison_spec_row
                    label="Max Output"
                    models={@models}
                    getter={fn m -> ModelLive.format_number(get_in(m.limits, [:output])) end}
                  />
                  <.comparison_spec_row
                    label="Input Cost"
                    models={@models}
                    getter={fn m -> "#{ModelLive.format_cost(get_in(m.cost, [:input]))}/M" end}
                    bg
                  />
                  <.comparison_spec_row
                    label="Output Cost"
                    models={@models}
                    getter={fn m -> "#{ModelLive.format_cost(get_in(m.cost, [:output]))}/M" end}
                  />
                </div>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-medium" style="color: hsl(var(--muted-foreground));">
                  Capabilities
                </h4>
                <div
                  class="rounded-lg border overflow-hidden"
                  style="border-color: hsl(var(--border));"
                >
                  <%= for {cap, idx} <- Enum.with_index(@capabilities) do %>
                    <.comparison_capability_row
                      capability={cap}
                      models={@models}
                      bg={rem(idx, 2) == 0}
                      last={idx == length(@capabilities) - 1}
                    />
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <button
            type="button"
            phx-click={@on_close}
            class="absolute top-4 right-4 p-2 rounded-md hover:opacity-80"
            style="color: hsl(var(--muted-foreground));"
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :models, :list, required: true
  attr :getter, :any, required: true
  attr :bg, :boolean, default: false

  defp comparison_spec_row(assigns) do
    ~H"""
    <div
      class="grid border-b last:border-b-0"
      style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr); border-color: hsl(var(--border)); #{if @bg, do: "background-color: hsl(var(--muted) / 0.5);", else: ""}"}
    >
      <div class="p-2 text-xs font-medium">{@label}</div>
      <%= for model <- @models do %>
        <div class="p-2 text-xs font-mono text-center">{@getter.(model)}</div>
      <% end %>
    </div>
    """
  end

  attr :capability, :atom, required: true
  attr :models, :list, required: true
  attr :bg, :boolean, default: false
  attr :last, :boolean, default: false

  defp comparison_capability_row(assigns) do
    label = Map.get(@capability_labels, assigns.capability, to_string(assigns.capability))
    assigns = assign(assigns, :label, label)

    ~H"""
    <div
      class={"grid #{if @last, do: "", else: "border-b"}"}
      style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr); border-color: hsl(var(--border)); #{if @bg, do: "background-color: hsl(var(--muted) / 0.5);", else: ""}"}
    >
      <div class="p-2 text-xs font-medium">{@label}</div>
      <%= for model <- @models do %>
        <div class="p-2 text-center">
          <%= if model_has_capability?(model, @capability) do %>
            <.capability_badge capability={@capability} compact />
          <% else %>
            <span class="text-xs" style="color: hsl(var(--muted-foreground));">—</span>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp model_has_capability?(model, :chat), do: model.capabilities[:chat]
  defp model_has_capability?(model, :tools), do: get_in(model.capabilities, [:tools, :enabled])

  defp model_has_capability?(model, :streaming),
    do: get_in(model.capabilities, [:streaming, :text])

  defp model_has_capability?(model, :vision), do: has_vision?(model)

  defp model_has_capability?(model, :reasoning),
    do: get_in(model.capabilities, [:reasoning, :enabled])

  defp model_has_capability?(model, :embeddings), do: embeddings_enabled?(model.capabilities)

  defp model_has_capability?(model, :json_output),
    do: get_in(model.capabilities, [:json, :native])

  defp model_has_capability?(_, _), do: false

  # =============================================================================
  # Legacy Components (kept for backwards compatibility)
  # =============================================================================

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
          class="px-2 py-0.5 text-xs font-medium rounded border"
          title={tooltip}
          style="background-color: hsl(var(--muted)); color: hsl(var(--muted-foreground)); border-color: hsl(var(--border));"
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
      <div class="text-xs font-medium uppercase mb-1" style="color: hsl(var(--muted-foreground));">
        {@label}
      </div>
      <div class="text-sm" style="color: hsl(var(--foreground));">
        {render_slot(@value)}
      </div>
    </div>
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
              <h3 class="text-base font-semibold truncate" style="color: hsl(var(--foreground));">
                {@model.name}
              </h3>
              <p class="text-sm truncate" style="color: hsl(var(--muted-foreground));">
                {@model.model_id}
              </p>
              <%= if @model.family do %>
                <p class="text-xs mt-1" style="color: hsl(var(--muted-foreground));">
                  {@model.family}
                </p>
              <% end %>
            </div>
          </div>

          <%= if has_capabilities?(@model) do %>
            <div>
              <div
                class="text-xs font-medium uppercase mb-1"
                style="color: hsl(var(--muted-foreground));"
              >
                Capabilities
              </div>
              <.capability_badges model={@model} />
            </div>
          <% end %>

          <div class="grid grid-cols-2 gap-3 pt-3 border-t" style="border-color: hsl(var(--border));">
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

      <div
        class="fixed lg:static inset-y-0 left-0 w-80 max-w-[85vw] lg:w-auto lg:max-w-none shadow-xl lg:shadow-none overflow-y-auto lg:overflow-visible"
        style="background-color: hsl(var(--background));"
      >
        <div class="lg:sticky lg:top-4 p-4 lg:p-0">
          <div class="flex items-center justify-between mb-4 lg:hidden">
            <h2 class="text-lg font-semibold">Filters</h2>
            <button phx-click="toggle_filters" class="p-2 hover:opacity-80">
              <.icon name="hero-x-mark" class="w-6 h-6" />
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
                          class="rounded"
                          style="border-color: hsl(var(--border));"
                        />
                        <span class="text-sm">
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
                      class="rounded"
                      style="border-color: hsl(var(--border));"
                    />
                    <span class="text-sm">Show deprecated</span>
                  </label>

                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      name="allowed_only"
                      value="true"
                      checked={@filters.allowed_only}
                      class="rounded"
                      style="border-color: hsl(var(--border));"
                    />
                    <span class="text-sm">Allowed only</span>
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
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Chat</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_embeddings"
                        value="true"
                        checked={@filters.capabilities.embeddings}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Embeddings</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_reasoning"
                        value="true"
                        checked={@filters.capabilities.reasoning}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Reasoning</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_tools"
                        value="true"
                        checked={@filters.capabilities.tools}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Tools</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_json_native"
                        value="true"
                        checked={@filters.capabilities.json_native}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">JSON Native</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_streaming_text"
                        value="true"
                        checked={@filters.capabilities.streaming_text}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Streaming</span>
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
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Text</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[image]"
                        checked={MapSet.member?(@filters.modalities_in, :image)}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Image</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[audio]"
                        checked={MapSet.member?(@filters.modalities_in, :audio)}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Audio</span>
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

  # =============================================================================
  # Helper Functions
  # =============================================================================

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

  defp lifecycle_status(model) do
    get_in(model.lifecycle, [:status]) || "active"
  end

  defp lifecycle_label(model) do
    status = lifecycle_status(model)

    cond do
      model.deprecated -> "Deprecated"
      status == "deprecated" -> "Deprecated"
      status == "retired" -> "Retired"
      true -> "Active"
    end
  end

  defp lifecycle_bg_color(model) do
    status = lifecycle_status(model)

    cond do
      model.deprecated -> "--destructive"
      status == "deprecated" -> "--destructive"
      status == "retired" -> "--muted"
      true -> "--secondary"
    end
  end

  defp lifecycle_text_color(model) do
    status = lifecycle_status(model)

    cond do
      model.deprecated -> "--destructive-foreground"
      status == "deprecated" -> "--destructive-foreground"
      status == "retired" -> "--muted-foreground"
      true -> "--secondary-foreground"
    end
  end

  defp embeddings_enabled?(caps) do
    case Map.get(caps || %{}, :embeddings) do
      true -> true
      %{} = emb -> map_size(emb) > 0
      _ -> false
    end
  end

  defp has_modalities?(model) do
    modalities = model.modalities || %{}
    input_list = modalities[:input] || []
    output_list = modalities[:output] || []
    length(input_list) > 0 or length(output_list) > 0
  end
end
