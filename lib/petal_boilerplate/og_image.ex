defmodule PetalBoilerplate.OGImage do
  @moduledoc """
  Generates and caches Open Graph images for social media sharing.

  Uses the Image library (libvips) to render SVG templates to PNG images at 1200x630.
  Images are cached in ETS for fast retrieval.
  """

  use GenServer

  alias PetalBoilerplate.Catalog

  @ets_table :og_image_cache
  @image_width 1200
  @image_height 630
  @cache_ttl_ms :timer.hours(24)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets or generates an OG image for the given type and optional model.
  Returns {:ok, png_binary} or {:error, reason}.
  """
  def get_image(:default) do
    get_cached_or_generate("default", fn -> generate_default_image() end)
  end

  def get_image(:home) do
    get_cached_or_generate("home", fn -> generate_home_image() end)
  end

  def get_image(:about) do
    get_cached_or_generate("about", fn -> generate_about_image() end)
  end

  def get_image({:model, provider, model_id}) do
    cache_key = "model:#{provider}:#{model_id}"

    get_cached_or_generate(cache_key, fn ->
      case Catalog.find_model(provider, model_id) do
        nil -> generate_not_found_image()
        model -> generate_model_image(model)
      end
    end)
  end

  @doc """
  Clears all cached OG images.
  """
  def clear_cache do
    GenServer.call(__MODULE__, :clear_cache)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    :ets.new(@ets_table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}}
  end

  @impl true
  def handle_call(:clear_cache, _from, state) do
    :ets.delete_all_objects(@ets_table)
    {:reply, :ok, state}
  end

  # Private functions

  defp get_cached_or_generate(cache_key, generator_fn) do
    now = System.system_time(:millisecond)

    case :ets.lookup(@ets_table, cache_key) do
      [{^cache_key, png_data, expires_at}] when expires_at > now ->
        {:ok, png_data}

      _ ->
        case generator_fn.() do
          {:ok, png_data} ->
            expires_at = now + @cache_ttl_ms
            :ets.insert(@ets_table, {cache_key, png_data, expires_at})
            {:ok, png_data}

          error ->
            error
        end
    end
  end

  defp generate_default_image do
    svg = default_svg()
    render_svg_to_png(svg)
  end

  defp generate_home_image do
    svg = home_svg()
    render_svg_to_png(svg)
  end

  defp generate_about_image do
    svg = about_svg()
    render_svg_to_png(svg)
  end

  defp generate_model_image(model) do
    svg = model_svg(model)
    render_svg_to_png(svg)
  end

  defp generate_not_found_image do
    svg = not_found_svg()
    render_svg_to_png(svg)
  end

  defp render_svg_to_png(svg) do
    try do
      case Image.from_svg(svg) do
        {:ok, image} ->
          Image.write(image, :memory, suffix: ".png")

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e -> {:error, e}
    end
  end

  # SVG Templates

  defp default_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{@image_width}" height="#{@image_height}" viewBox="0 0 #{@image_width} #{@image_height}">
      <defs>
        <linearGradient id="bggrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#1a1a2e"/>
          <stop offset="50%" stop-color="#16213e"/>
          <stop offset="100%" stop-color="#0f3460"/>
        </linearGradient>
      </defs>
      <rect width="#{@image_width}" height="#{@image_height}" fill="url(#bggrad)"/>

      <!-- Logo -->
      <text x="#{div(@image_width, 2)}" y="200" text-anchor="middle" fill="#60a5fa" font-size="72" font-family="system-ui, -apple-system, sans-serif" font-weight="700">
        llmdb.xyz
      </text>

      <!-- Subtitle -->
      <text x="#{div(@image_width, 2)}" y="280" text-anchor="middle" fill="#94a3b8" font-size="36" font-family="system-ui, -apple-system, sans-serif">
        Compare 2,000+ LLM Models
      </text>

      <!-- Provider badges -->
      #{provider_badges_svg(div(@image_width, 2) - 280, 340)}
    </svg>
    """
  end

  defp home_svg do
    model_count = length(Catalog.list_all_models())
    provider_count = length(Catalog.list_providers())

    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{@image_width}" height="#{@image_height}" viewBox="0 0 #{@image_width} #{@image_height}">
      <defs>
        <linearGradient id="bggrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#1a1a2e"/>
          <stop offset="50%" stop-color="#16213e"/>
          <stop offset="100%" stop-color="#0f3460"/>
        </linearGradient>
      </defs>
      <rect width="#{@image_width}" height="#{@image_height}" fill="url(#bggrad)"/>

      <!-- Header -->
      <text x="64" y="80" fill="#60a5fa" font-size="32" font-family="system-ui, -apple-system, sans-serif" font-weight="600">
        llmdb.xyz
      </text>

      <!-- Title -->
      <text x="64" y="220" fill="#ffffff" font-size="72" font-family="system-ui, -apple-system, sans-serif" font-weight="700">
        LLM Model Database
      </text>

      <!-- Subtitle -->
      <text x="64" y="280" fill="#94a3b8" font-size="32" font-family="system-ui, -apple-system, sans-serif">
        Browse, filter, and compare LLM models
      </text>

      <!-- Stats -->
      #{stat_svg(format_number(model_count), "Models", 64, 380)}
      #{stat_svg("#{provider_count}", "Providers", 280, 380)}

      <!-- Footer -->
      <line x1="64" y1="#{@image_height - 80}" x2="#{@image_width - 64}" y2="#{@image_height - 80}" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
      <text x="64" y="#{@image_height - 40}" fill="#64748b" font-size="20" font-family="system-ui, -apple-system, sans-serif">
        llmdb.xyz
      </text>
    </svg>
    """
  end

  defp about_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{@image_width}" height="#{@image_height}" viewBox="0 0 #{@image_width} #{@image_height}">
      <defs>
        <linearGradient id="bggrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#1a1a2e"/>
          <stop offset="50%" stop-color="#16213e"/>
          <stop offset="100%" stop-color="#0f3460"/>
        </linearGradient>
      </defs>
      <rect width="#{@image_width}" height="#{@image_height}" fill="url(#bggrad)"/>

      <!-- Header -->
      <text x="64" y="80" fill="#60a5fa" font-size="32" font-family="system-ui, -apple-system, sans-serif" font-weight="600">
        llmdb.xyz
      </text>

      <!-- Title -->
      <text x="64" y="220" fill="#ffffff" font-size="72" font-family="system-ui, -apple-system, sans-serif" font-weight="700">
        About llmdb.xyz
      </text>

      <!-- Subtitle -->
      <text x="64" y="280" fill="#94a3b8" font-size="32" font-family="system-ui, -apple-system, sans-serif">
        A comprehensive database of LLM models
      </text>

      <!-- Badges -->
      #{badge_row_svg(["Open Source", "Powered by llm_db", "Built with Elixir"], 64, 360)}

      <!-- Footer -->
      <line x1="64" y1="#{@image_height - 80}" x2="#{@image_width - 64}" y2="#{@image_height - 80}" stroke="rgba(255,255,255,0.1)" stroke-width="1"/>
      <text x="64" y="#{@image_height - 40}" fill="#64748b" font-size="20" font-family="system-ui, -apple-system, sans-serif">
        llmdb.xyz/about
      </text>
    </svg>
    """
  end

  defp model_svg(model) do
    model_name = svg_escape(truncate_name(model.name || model.id, 36))
    provider = svg_escape(String.capitalize(to_string(model.provider)))
    model_id = Map.get(model, :model_id) || model.id
    provider_slug = svg_escape(to_string(model.provider))
    family = model.family && svg_escape(model.family)

    input_modalities = get_modality_list(model, :input)
    output_modalities = get_modality_list(model, :output)
    capabilities = get_capability_list(model)

    limits = model.limits || %{}
    context = Map.get(limits, :context)
    output_limit = Map.get(limits, :output)

    cost = model.cost || %{}
    cost_in = Map.get(cost, :input)
    cost_out = Map.get(cost, :output)

    release_date = model.release_date
    knowledge = model.knowledge

    card_x = 40
    card_y = 40
    card_w = @image_width - card_x * 2
    card_h = @image_height - card_y * 2

    right_col_x = round(card_x + card_w * 0.58)

    """
    <svg xmlns="http://www.w3.org/2000/svg"
         width="#{@image_width}" height="#{@image_height}"
         viewBox="0 0 #{@image_width} #{@image_height}">
      <defs>
        <linearGradient id="bggrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#0c1222"/>
          <stop offset="50%" stop-color="#111827"/>
          <stop offset="100%" stop-color="#1e293b"/>
        </linearGradient>
        <linearGradient id="cardgrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="rgba(30,41,59,0.95)"/>
          <stop offset="100%" stop-color="rgba(15,23,42,0.98)"/>
        </linearGradient>
      </defs>
      <rect width="#{@image_width}" height="#{@image_height}" fill="url(#bggrad)"/>

      <!-- Card container -->
      <rect x="#{card_x}" y="#{card_y}" rx="20" ry="20"
            width="#{card_w}" height="#{card_h}"
            fill="url(#cardgrad)"
            stroke="rgba(148,163,184,0.25)" stroke-width="1"/>

      <!-- Header: logo + provider/family -->
      <text x="#{card_x + 28}" y="#{card_y + 36}"
            fill="#60a5fa" font-size="22"
            font-family="system-ui, -apple-system, sans-serif" font-weight="700">
        llmdb.xyz
      </text>

      <text x="#{card_x + 28}" y="#{card_y + 62}"
            fill="#9ca3af" font-size="16"
            font-family="system-ui, -apple-system, sans-serif">
        #{provider}#{if family, do: " • " <> family, else: ""}
      </text>

      <!-- Status badge (top right) -->
      #{status_badge_svg(model, card_x + card_w - 24, card_y + 44)}

      <!-- Main model title -->
      <text x="#{card_x + 28}" y="#{card_y + 130}"
            fill="#ffffff" font-size="52"
            font-family="system-ui, -apple-system, sans-serif" font-weight="800">
        #{model_name}
      </text>

      <!-- Model ID -->
      <text x="#{card_x + 28}" y="#{card_y + 162}"
            fill="#64748b" font-size="18"
            font-family="system-ui, -apple-system, sans-serif">
        #{svg_escape(to_string(model_id))}
      </text>

      <!-- Left column: modalities + capabilities -->
      #{modalities_badges_svg(input_modalities, output_modalities, card_x + 28, card_y + 210)}

      #{capabilities_badges_svg(capabilities, card_x + 28, card_y + 310)}

      <!-- Metadata (left side, bottom) -->
      #{metadata_row_svg(release_date, knowledge, card_x + 28, card_y + 370)}

      <!-- Vertical divider -->
      <line x1="#{right_col_x - 24}" y1="#{card_y + 90}"
            x2="#{right_col_x - 24}" y2="#{card_y + card_h - 70}"
            stroke="rgba(148,163,184,0.15)" stroke-width="1"/>

      <!-- Right column: pricing + limits -->
      #{pricing_block_svg(cost_in, cost_out, right_col_x, card_y + 100)}

      #{limits_block_svg(context, output_limit, right_col_x, card_y + 220)}

      <!-- Footer URL -->
      <line x1="#{card_x + 28}" y1="#{@image_height - card_y - 50}"
            x2="#{@image_width - card_x - 28}" y2="#{@image_height - card_y - 50}"
            stroke="rgba(255,255,255,0.08)" stroke-width="1"/>

      <text x="#{card_x + 28}" y="#{@image_height - card_y - 22}"
            fill="#64748b" font-size="16"
            font-family="system-ui, -apple-system, sans-serif">
        llmdb.xyz/models/#{provider_slug}/#{svg_escape(to_string(model_id))}
      </text>
    </svg>
    """
  end

  defp not_found_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="#{@image_width}" height="#{@image_height}" viewBox="0 0 #{@image_width} #{@image_height}">
      <defs>
        <linearGradient id="bggrad" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stop-color="#1a1a2e"/>
          <stop offset="50%" stop-color="#16213e"/>
          <stop offset="100%" stop-color="#0f3460"/>
        </linearGradient>
      </defs>
      <rect width="#{@image_width}" height="#{@image_height}" fill="url(#bggrad)"/>

      <!-- Title -->
      <text x="#{div(@image_width, 2)}" y="280" text-anchor="middle" fill="#ffffff" font-size="64" font-family="system-ui, -apple-system, sans-serif" font-weight="700">
        Model Not Found
      </text>

      <!-- Subtitle -->
      <text x="#{div(@image_width, 2)}" y="350" text-anchor="middle" fill="#94a3b8" font-size="28" font-family="system-ui, -apple-system, sans-serif">
        The requested model could not be found
      </text>

      <!-- Footer -->
      <text x="#{div(@image_width, 2)}" y="#{@image_height - 60}" text-anchor="middle" fill="#64748b" font-size="20" font-family="system-ui, -apple-system, sans-serif">
        llmdb.xyz
      </text>
    </svg>
    """
  end

  # SVG Helper Functions

  defp stat_svg(nil, _label, _x, _y), do: ""

  defp stat_svg(value, label, x, y) do
    """
    <text x="#{x}" y="#{y}" fill="#ffffff" font-size="36" font-family="system-ui, -apple-system, sans-serif" font-weight="700">
      #{svg_escape(value)}
    </text>
    <text x="#{x}" y="#{y + 32}" fill="#94a3b8" font-size="18" font-family="system-ui, -apple-system, sans-serif">
      #{svg_escape(label)}
    </text>
    """
  end

  defp badge_row_svg(labels, start_x, y) do
    {svg, _} =
      labels
      |> Enum.take(5)
      |> Enum.reduce({"", start_x}, fn label, {acc, x} ->
        text_width = String.length(label) * 11
        badge_width = text_width + 32

        badge = """
        <rect x="#{x}" y="#{y - 24}" rx="6" ry="6" width="#{badge_width}" height="36" fill="rgba(96,165,250,0.2)" stroke="rgba(96,165,250,0.4)" stroke-width="1"/>
        <text x="#{x + 16}" y="#{y}" fill="#93c5fd" font-size="18" font-family="system-ui, -apple-system, sans-serif">
          #{svg_escape(label)}
        </text>
        """

        {acc <> badge, x + badge_width + 12}
      end)

    svg
  end

  defp provider_badges_svg(start_x, y) do
    providers = ["OpenAI", "Anthropic", "Google", "Mistral", "+ More"]
    badge_row_svg(providers, start_x, y)
  end

  defp metadata_row_svg(release_date, knowledge, x, y) do
    parts =
      [
        if(release_date, do: "Released: #{release_date}"),
        if(knowledge, do: "Knowledge: #{knowledge}")
      ]
      |> Enum.filter(& &1)

    if parts == [] do
      ""
    else
      """
      <text x="#{x}" y="#{y}" fill="#64748b" font-size="16" font-family="system-ui, -apple-system, sans-serif">
        #{svg_escape(Enum.join(parts, "  •  "))}
      </text>
      """
    end
  end

  defp get_modality_list(model, direction) do
    modalities = get_nested(model, [:modalities, direction]) || []

    modalities
    |> Enum.map(fn mod ->
      mod |> to_string() |> String.capitalize()
    end)
  end

  defp get_capability_list(model) do
    caps = model.capabilities || %{}

    [
      if(caps[:chat], do: "Chat"),
      if(caps[:embeddings], do: "Embeddings"),
      if(get_nested(caps, [:reasoning, :enabled]), do: "Reasoning"),
      if(get_nested(caps, [:tools, :enabled]), do: "Tools"),
      if(get_nested(caps, [:streaming, :text]), do: "Streaming")
    ]
    |> Enum.filter(& &1)
    |> Enum.take(5)
  end

  defp format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}(?=.)/, "\\0,")
    |> String.reverse()
  end

  defp format_number(num), do: to_string(num)

  defp format_context(nil), do: nil
  defp format_context(ctx) when ctx >= 1_000_000, do: "#{Float.round(ctx / 1_000_000, 1)}M"
  defp format_context(ctx) when ctx >= 1_000, do: "#{div(ctx, 1000)}K"
  defp format_context(ctx), do: "#{ctx}"

  defp format_cost(nil), do: nil
  defp format_cost(cost), do: "$#{:erlang.float_to_binary(cost * 1.0, decimals: 2)}/M"

  defp truncate_name(name, max_len) when is_binary(name) do
    if String.length(name) > max_len do
      String.slice(name, 0, max_len - 3) <> "..."
    else
      name
    end
  end

  defp truncate_name(name, _max_len), do: to_string(name)

  defp svg_escape(nil), do: ""

  defp svg_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  defp svg_escape(text), do: svg_escape(to_string(text))

  defp get_nested(struct, keys) when is_struct(struct) do
    get_nested(Map.from_struct(struct), keys)
  end

  defp get_nested(value, []), do: value
  defp get_nested(nil, _keys), do: nil

  defp get_nested(map, [key | rest]) when is_map(map) do
    value = Map.get(map, key)
    get_nested(value, rest)
  end

  defp get_nested(_other, _keys), do: nil

  # Lifecycle status helpers

  defp lifecycle_status(model) do
    status = get_nested(model, [:lifecycle, :status])

    cond do
      status in ["active", "deprecated", "retired"] -> status
      model.deprecated -> "deprecated"
      true -> "active"
    end
  end

  defp lifecycle_style("active") do
    %{
      label: "ACTIVE",
      fill: "rgba(22,163,74,0.16)",
      stroke: "rgba(34,197,94,0.7)",
      text: "#bbf7d0"
    }
  end

  defp lifecycle_style("deprecated") do
    %{
      label: "DEPRECATED",
      fill: "rgba(245,158,11,0.12)",
      stroke: "rgba(251,191,36,0.7)",
      text: "#fed7aa"
    }
  end

  defp lifecycle_style("retired") do
    %{
      label: "RETIRED",
      fill: "rgba(239,68,68,0.12)",
      stroke: "rgba(248,113,113,0.7)",
      text: "#fecaca"
    }
  end

  defp lifecycle_style(_), do: lifecycle_style("active")

  defp status_badge_svg(model, x, y) do
    status = lifecycle_status(model)
    style = lifecycle_style(status)
    width = 150
    height = 34

    """
    <rect x="#{x - width}" y="#{y - height + 4}" rx="999" ry="999"
          width="#{width}" height="#{height}"
          fill="#{style.fill}" stroke="#{style.stroke}" stroke-width="1"/>
    <text x="#{x - width / 2}" y="#{y}"
          text-anchor="middle"
          fill="#{style.text}" font-size="14"
          font-family="system-ui, -apple-system, sans-serif" font-weight="600"
          letter-spacing="0.12em">
      #{style.label}
    </text>
    """
  end

  # Color-coded badge helpers

  defp badge_row_svg_with_colors([], _x, _y, _fill, _stroke, _text_color), do: ""

  defp badge_row_svg_with_colors(labels, start_x, y, fill, stroke, text_color) do
    {svg, _} =
      labels
      |> Enum.take(5)
      |> Enum.reduce({"", start_x}, fn label, {acc, x} ->
        text_width = String.length(label) * 10
        badge_width = text_width + 28

        badge = """
        <rect x="#{x}" y="#{y - 22}" rx="999" ry="999"
              width="#{badge_width}" height="32"
              fill="#{fill}" stroke="#{stroke}" stroke-width="1"/>
        <text x="#{x + 14}" y="#{y}"
              fill="#{text_color}" font-size="16"
              font-family="system-ui, -apple-system, sans-serif">
          #{svg_escape(label)}
        </text>
        """

        {acc <> badge, x + badge_width + 10}
      end)

    svg
  end

  defp modalities_badges_svg([], [], _x, _y), do: ""

  defp modalities_badges_svg(input_mods, output_mods, x, y) do
    input_svg =
      if input_mods != [] do
        labels = Enum.map(input_mods, fn m -> "▸ #{m}" end)

        badge_row_svg_with_colors(
          labels,
          x,
          y,
          "rgba(45,212,191,0.16)",
          "rgba(34,197,94,0.5)",
          "#a5f3fc"
        )
      else
        ""
      end

    output_svg =
      if output_mods != [] do
        labels = Enum.map(output_mods, fn m -> "◂ #{m}" end)

        badge_row_svg_with_colors(
          labels,
          x,
          y + 44,
          "rgba(56,189,248,0.16)",
          "rgba(59,130,246,0.6)",
          "#e0f2fe"
        )
      else
        ""
      end

    input_svg <> output_svg
  end

  defp capabilities_badges_svg([], _x, _y), do: ""

  defp capabilities_badges_svg(labels, x, y) do
    badge_row_svg_with_colors(
      labels,
      x,
      y,
      "rgba(129,140,248,0.18)",
      "rgba(129,140,248,0.6)",
      "#c7d2fe"
    )
  end

  # Pricing and limits blocks

  defp pricing_block_svg(nil, nil, _x, _y), do: ""

  defp pricing_block_svg(cost_in, cost_out, x, y) do
    width = 320
    height = 100

    main =
      case {cost_in, cost_out} do
        {cin, cout} when not is_nil(cin) and not is_nil(cout) ->
          "#{format_cost(cin)} in  •  #{format_cost(cout)} out"

        {cin, nil} when not is_nil(cin) ->
          "Input: #{format_cost(cin)}"

        {nil, cout} when not is_nil(cout) ->
          "Output: #{format_cost(cout)}"

        _ ->
          ""
      end

    if main == "" do
      ""
    else
      """
      <rect x="#{x}" y="#{y}" rx="16" ry="16" width="#{width}" height="#{height}"
            fill="rgba(15,23,42,0.9)" stroke="rgba(148,163,184,0.4)" stroke-width="1.2"/>
      <text x="#{x + 20}" y="#{y + 28}"
            fill="#e5e7eb" font-size="18"
            font-family="system-ui, -apple-system, sans-serif" font-weight="600">
        💰 Pricing
      </text>
      <text x="#{x + 20}" y="#{y + 58}"
            fill="#f9fafb" font-size="20"
            font-family="system-ui, -apple-system, sans-serif" font-weight="700">
        #{svg_escape(main)}
      </text>
      <text x="#{x + 20}" y="#{y + 84}"
            fill="#9ca3af" font-size="14"
            font-family="system-ui, -apple-system, sans-serif">
        Per 1M tokens (USD)
      </text>
      """
    end
  end

  defp limits_block_svg(nil, nil, _x, _y), do: ""

  defp limits_block_svg(context, output_limit, x, y) do
    width = 320
    height = 80

    ctx = if context, do: format_context(context), else: "—"
    out = if output_limit, do: format_context(output_limit), else: "—"

    if context == nil and output_limit == nil do
      ""
    else
      """
      <rect x="#{x}" y="#{y}" rx="16" ry="16" width="#{width}" height="#{height}"
            fill="rgba(15,23,42,0.9)" stroke="rgba(75,85,99,0.8)" stroke-width="1"/>
      <text x="#{x + 20}" y="#{y + 26}"
            fill="#e5e7eb" font-size="16"
            font-family="system-ui, -apple-system, sans-serif" font-weight="600">
        📊 Limits
      </text>
      <text x="#{x + 20}" y="#{y + 54}"
            fill="#f9fafb" font-size="18"
            font-family="system-ui, -apple-system, sans-serif">
        Context: #{ctx}  •  Output: #{out}
      </text>
      """
    end
  end
end
