defmodule PetalBoilerplateWeb.SubscriptionValueLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Subscriptions
  alias PetalBoilerplate.SubscriptionsCalculator

  @workload_profiles ["light", "daily", "heavy"]
  @model_mix_presets ["budget", "balanced", "premium"]
  @band_modes ["conservative", "expected", "aggressive"]

  @impl true
  def mount(_params, _session, socket) do
    selected_plan_ids = Subscriptions.default_selected_plan_ids()

    socket =
      socket
      |> assign_og_meta()
      |> assign(
        plans: Subscriptions.plans_for_selection(),
        selected_plan_ids: selected_plan_ids,
        workload_profile: "daily",
        model_mix_preset: "balanced",
        io_input_pct: 80,
        band_mode: "expected",
        override_min_units: "",
        override_max_units: "",
        show_advanced: false,
        calculated?: false,
        ranked_results: [],
        insufficient_results: [],
        assumptions: %{},
        show_support_cta: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("calculate", %{"calculator" => params}, socket) do
    selected_plan_ids = parse_selected_plan_ids(params["selected_plan_ids"])
    workload_profile = parse_enum(params["workload_profile"], @workload_profiles, "daily")
    model_mix_preset = parse_enum(params["model_mix_preset"], @model_mix_presets, "balanced")
    band_mode = parse_enum(params["band_mode"], @band_modes, "expected")
    io_input_pct = parse_int(params["io_input_pct"], 80, 10, 95)

    override_min_units = parse_float(params["override_min_units"])
    override_max_units = parse_float(params["override_max_units"])

    calculation =
      SubscriptionsCalculator.calculate(%{
        selected_plan_ids: selected_plan_ids,
        workload_profile: workload_profile_atom(workload_profile),
        model_mix_preset: model_mix_preset_atom(model_mix_preset),
        input_ratio: io_input_pct / 100.0,
        band_mode: band_mode_atom(band_mode),
        manual_override: %{min_units: override_min_units, max_units: override_max_units}
      })

    {:noreply,
     assign(socket,
       selected_plan_ids: selected_plan_ids,
       workload_profile: workload_profile,
       model_mix_preset: model_mix_preset,
       io_input_pct: io_input_pct,
       band_mode: band_mode,
       override_min_units: params["override_min_units"] || "",
       override_max_units: params["override_max_units"] || "",
       calculated?: true,
       ranked_results: calculation.ranked,
       insufficient_results: calculation.insufficient,
       assumptions: calculation.assumptions,
       show_support_cta: true
     )}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket) do
    {:noreply, assign(socket, show_advanced: !socket.assigns.show_advanced)}
  end

  @impl true
  def handle_event("dismiss_support_cta", _params, socket) do
    {:noreply, assign(socket, show_support_cta: false)}
  end

  # Header search form sends this event; we intentionally ignore it on this page.
  @impl true
  def handle_event("filter", _params, socket) do
    {:noreply, socket}
  end

  def selected_plan?(selected_plan_ids, plan_id) do
    plan_id in selected_plan_ids
  end

  def plan_price_label(nil), do: "Custom / Contact sales"
  def plan_price_label(price) when is_number(price), do: "$#{format_currency(price)}/mo"

  def format_currency(value) when is_number(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 2)
  end

  def format_currency(_), do: "N/A"

  def format_tokens(value) when is_number(value) do
    cond do
      value >= 1_000_000_000 -> "#{:erlang.float_to_binary(value / 1_000_000_000, decimals: 2)}B"
      value >= 1_000_000 -> "#{:erlang.float_to_binary(value / 1_000_000, decimals: 2)}M"
      value >= 1000 -> "#{:erlang.float_to_binary(value / 1000, decimals: 2)}K"
      true -> Integer.to_string(round(value))
    end
  end

  def format_tokens(_), do: "N/A"

  def format_multiple(value) when is_number(value),
    do: "#{:erlang.float_to_binary(value, decimals: 2)}x"

  def format_multiple(_), do: "N/A"

  def confidence_class(:high), do: "bg-emerald-100 text-emerald-800"
  def confidence_class(:medium), do: "bg-amber-100 text-amber-800"
  def confidence_class(:low), do: "bg-rose-100 text-rose-800"
  def confidence_class(_), do: "bg-gray-100 text-gray-800"

  def reset_window_label(:rolling_5h), do: "5-hour rolling"
  def reset_window_label(:weekly), do: "Weekly"
  def reset_window_label(:monthly), do: "Monthly"
  def reset_window_label(:mixed), do: "Mixed"
  def reset_window_label(_), do: "Custom"

  def limit_type_label(:hard_numeric), do: "Hard numeric"
  def limit_type_label(:multiplier), do: "Multiplier"
  def limit_type_label(:opaque), do: "Opaque"
  def limit_type_label(_), do: "Unknown"

  def workload_label("light"), do: "Light"
  def workload_label("daily"), do: "Daily"
  def workload_label("heavy"), do: "Heavy"
  def workload_label(_), do: "Daily"

  def model_mix_label("budget"), do: "Budget"
  def model_mix_label("balanced"), do: "Balanced"
  def model_mix_label("premium"), do: "Premium"
  def model_mix_label(_), do: "Balanced"

  def band_mode_label("conservative"), do: "Conservative"
  def band_mode_label("expected"), do: "Expected"
  def band_mode_label("aggressive"), do: "Aggressive"
  def band_mode_label(_), do: "Expected"

  defp assign_og_meta(socket) do
    assign(socket,
      page_title: "Subscription Value Calculator",
      page_description:
        "Compare coding subscription value with transparent assumptions, confidence bands, and source links.",
      og_url: "https://llmdb.xyz/compare-subs",
      og_image: "https://llmdb.xyz/og/compare-subs.png"
    )
  end

  defp parse_selected_plan_ids(nil), do: Subscriptions.default_selected_plan_ids()

  defp parse_selected_plan_ids(raw_ids) do
    selected =
      raw_ids
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()
      |> Enum.take(4)

    if selected == [], do: Subscriptions.default_selected_plan_ids(), else: selected
  end

  defp parse_enum(raw, allowed, default) when is_binary(raw) do
    if raw in allowed, do: raw, else: default
  end

  defp parse_enum(_raw, _allowed, default), do: default

  defp parse_int(raw, default, min_value, max_value) when is_binary(raw) do
    case Integer.parse(raw) do
      {value, ""} -> clamp(value, min_value, max_value)
      _ -> default
    end
  end

  defp parse_int(_raw, default, _min_value, _max_value), do: default

  defp parse_float(""), do: nil

  defp parse_float(raw) when is_binary(raw) do
    case Float.parse(raw) do
      {value, ""} when value > 0 -> value
      _ -> nil
    end
  end

  defp parse_float(_), do: nil

  defp workload_profile_atom("light"), do: :light
  defp workload_profile_atom("daily"), do: :daily
  defp workload_profile_atom("heavy"), do: :heavy
  defp workload_profile_atom(_), do: :daily

  defp model_mix_preset_atom("budget"), do: :budget
  defp model_mix_preset_atom("balanced"), do: :balanced
  defp model_mix_preset_atom("premium"), do: :premium
  defp model_mix_preset_atom(_), do: :balanced

  defp band_mode_atom("conservative"), do: :conservative
  defp band_mode_atom("expected"), do: :expected
  defp band_mode_atom("aggressive"), do: :aggressive
  defp band_mode_atom(_), do: :expected

  defp clamp(value, min_value, max_value) do
    value
    |> max(min_value)
    |> min(max_value)
  end
end
