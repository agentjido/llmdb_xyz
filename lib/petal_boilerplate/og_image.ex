defmodule PetalBoilerplate.OGImage do
  @moduledoc """
  Generates and caches Open Graph images for social media sharing.

  Uses ChromicPDF to render HTML templates to PNG images at 1200x630.
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
    html = default_html()
    render_html_to_png(html)
  end

  defp generate_home_image do
    html = home_html()
    render_html_to_png(html)
  end

  defp generate_about_image do
    html = about_html()
    render_html_to_png(html)
  end

  defp generate_model_image(model) do
    html = model_html(model)
    render_html_to_png(html)
  end

  defp generate_not_found_image do
    html = not_found_html()
    render_html_to_png(html)
  end

  defp render_html_to_png(html) do
    case ChromicPDF.capture_screenshot({:html, html},
           capture_screenshot: %{
             format: "png",
             clip: %{
               x: 0,
               y: 0,
               width: @image_width,
               height: @image_height,
               scale: 1
             }
           },
           set_device_metrics_override: %{
             width: @image_width,
             height: @image_height,
             deviceScaleFactor: 1,
             mobile: false
           }
         ) do
      {:ok, base64_png} ->
        {:ok, Base.decode64!(base64_png)}

      error ->
        error
    end
  end

  # HTML Templates

  defp base_styles do
    """
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      width: #{@image_width}px;
      height: #{@image_height}px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
      color: white;
      display: flex;
      flex-direction: column;
      padding: 48px 64px;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
    }
    .logo {
      font-size: 28px;
      font-weight: 600;
      color: #60a5fa;
    }
    .provider {
      font-size: 24px;
      color: #94a3b8;
      background: rgba(255,255,255,0.1);
      padding: 8px 20px;
      border-radius: 8px;
    }
    .main {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }
    .title {
      font-size: 72px;
      font-weight: 700;
      line-height: 1.1;
      margin-bottom: 24px;
      background: linear-gradient(90deg, #fff, #60a5fa);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
    }
    .subtitle {
      font-size: 32px;
      color: #94a3b8;
      margin-bottom: 32px;
    }
    .badges {
      display: flex;
      gap: 12px;
      margin-bottom: 32px;
      flex-wrap: wrap;
    }
    .badge {
      background: rgba(96, 165, 250, 0.2);
      border: 1px solid rgba(96, 165, 250, 0.4);
      color: #93c5fd;
      padding: 8px 16px;
      border-radius: 6px;
      font-size: 18px;
      font-weight: 500;
    }
    .stats {
      display: flex;
      gap: 48px;
    }
    .stat {
      display: flex;
      flex-direction: column;
    }
    .stat-value {
      font-size: 36px;
      font-weight: 700;
      color: #fff;
    }
    .stat-label {
      font-size: 18px;
      color: #94a3b8;
      margin-top: 4px;
    }
    .footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 24px;
      border-top: 1px solid rgba(255,255,255,0.1);
    }
    .url {
      font-size: 20px;
      color: #64748b;
    }
    .centered {
      align-items: center;
      text-align: center;
    }
    """
  end

  defp default_html do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>#{base_styles()}</style>
    </head>
    <body class="centered">
      <div class="main centered">
        <div class="title">llmdb.xyz</div>
        <div class="subtitle">Compare 2,000+ LLM Models</div>
        <div class="badges">
          <div class="badge">OpenAI</div>
          <div class="badge">Anthropic</div>
          <div class="badge">Google</div>
          <div class="badge">Mistral</div>
          <div class="badge">+ More</div>
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp home_html do
    model_count = length(Catalog.list_all_models())
    provider_count = length(Catalog.list_providers())

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>#{base_styles()}</style>
    </head>
    <body>
      <div class="header">
        <div class="logo">llmdb.xyz</div>
      </div>
      <div class="main">
        <div class="title">LLM Model Database</div>
        <div class="subtitle">Browse, filter, and compare LLM models</div>
        <div class="stats">
          <div class="stat">
            <div class="stat-value">#{format_number(model_count)}</div>
            <div class="stat-label">Models</div>
          </div>
          <div class="stat">
            <div class="stat-value">#{provider_count}</div>
            <div class="stat-label">Providers</div>
          </div>
        </div>
      </div>
      <div class="footer">
        <div class="url">llmdb.xyz</div>
      </div>
    </body>
    </html>
    """
  end

  defp about_html do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>#{base_styles()}</style>
    </head>
    <body>
      <div class="header">
        <div class="logo">llmdb.xyz</div>
      </div>
      <div class="main">
        <div class="title">About llmdb.xyz</div>
        <div class="subtitle">A comprehensive database of LLM models</div>
        <div class="badges">
          <div class="badge">Open Source</div>
          <div class="badge">Powered by llm_db</div>
          <div class="badge">Built with Elixir</div>
        </div>
      </div>
      <div class="footer">
        <div class="url">llmdb.xyz/about</div>
      </div>
    </body>
    </html>
    """
  end

  defp model_html(model) do
    model_name = html_escape(model.name || model.id)
    provider = html_escape(String.capitalize(to_string(model.provider)))
    model_id = Map.get(model, :model_id) || model.id

    context = get_nested(model, [:limits, :context])
    cost_in = get_nested(model, [:cost, :input])
    cost_out = get_nested(model, [:cost, :output])

    capabilities = get_capability_badges(model)

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>#{base_styles()}</style>
    </head>
    <body>
      <div class="header">
        <div class="logo">llmdb.xyz</div>
        <div class="provider">#{provider}</div>
      </div>
      <div class="main">
        <div class="title">#{model_name}</div>
        #{if capabilities != "", do: "<div class=\"badges\">#{capabilities}</div>", else: ""}
        <div class="stats">
          #{stat_html("Context", format_context(context))}
          #{stat_html("Input", format_cost(cost_in))}
          #{stat_html("Output", format_cost(cost_out))}
        </div>
      </div>
      <div class="footer">
        <div class="url">llmdb.xyz/models/#{html_escape(to_string(model.provider))}/#{html_escape(model_id)}</div>
      </div>
    </body>
    </html>
    """
  end

  defp not_found_html do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>#{base_styles()}</style>
    </head>
    <body class="centered">
      <div class="main centered">
        <div class="title">Model Not Found</div>
        <div class="subtitle">The requested model could not be found</div>
      </div>
      <div class="footer">
        <div class="url">llmdb.xyz</div>
      </div>
    </body>
    </html>
    """
  end

  defp stat_html(_label, nil), do: ""

  defp stat_html(label, value) do
    """
    <div class="stat">
      <div class="stat-value">#{html_escape(value)}</div>
      <div class="stat-label">#{html_escape(label)}</div>
    </div>
    """
  end

  defp get_capability_badges(model) do
    caps = model.capabilities || %{}

    badges =
      [
        if(caps[:chat], do: "Chat"),
        if(caps[:embeddings], do: "Embeddings"),
        if(get_in(caps, [:reasoning, :enabled]), do: "Reasoning"),
        if(get_in(caps, [:tools, :enabled]), do: "Tools"),
        if(get_in(caps, [:streaming, :tool_calls]), do: "Streaming")
      ]
      |> Enum.filter(& &1)
      |> Enum.take(5)

    badges
    |> Enum.map(&"<div class=\"badge\">#{html_escape(&1)}</div>")
    |> Enum.join("")
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

  defp html_escape(nil), do: ""

  defp html_escape(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp html_escape(text), do: html_escape(to_string(text))

  defp get_nested(struct, keys) when is_struct(struct) do
    get_nested(Map.from_struct(struct), keys)
  end

  defp get_nested(map, []) when is_map(map), do: map
  defp get_nested(nil, _keys), do: nil

  defp get_nested(map, [key | rest]) when is_map(map) do
    value = Map.get(map, key)
    get_nested(value, rest)
  end

  defp get_nested(_other, _keys), do: nil
end
