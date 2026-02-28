defmodule PetalBoilerplate.SubscriptionsCalculator do
  @moduledoc """
  Pure calculation engine for subscription-value estimates.
  """

  alias PetalBoilerplate.Subscriptions

  @window_multipliers %{
    rolling_5h: 144.0,
    weekly: 4.345,
    monthly: 1.0,
    mixed: 1.0
  }

  @mix_weights %{
    budget: %{budget: 0.80, balanced: 0.20, premium: 0.00},
    balanced: %{budget: 0.20, balanced: 0.60, premium: 0.20},
    premium: %{budget: 0.00, balanced: 0.30, premium: 0.70}
  }

  @band_multipliers %{
    conservative: 0.85,
    expected: 1.00,
    aggressive: 1.20
  }

  @profile_tokens_per_unit %{
    light: %{
      messages: {2200.0, 3500.0, 5000.0},
      tasks: {12000.0, 18000.0, 28000.0},
      credits: {1500.0, 2500.0, 4000.0},
      mixed: {3000.0, 5000.0, 7500.0}
    },
    daily: %{
      messages: {3500.0, 6000.0, 9000.0},
      tasks: {18000.0, 32000.0, 50000.0},
      credits: {2500.0, 4000.0, 6500.0},
      mixed: {5000.0, 8500.0, 13000.0}
    },
    heavy: %{
      messages: {5000.0, 9000.0, 14000.0},
      tasks: {30000.0, 50000.0, 80000.0},
      credits: {3500.0, 6000.0, 10000.0},
      mixed: {7000.0, 12000.0, 18000.0}
    }
  }

  @type options :: %{
          selected_plan_ids: [String.t()],
          workload_profile: :light | :daily | :heavy,
          model_mix_preset: :budget | :balanced | :premium,
          input_ratio: float(),
          band_mode: :conservative | :expected | :aggressive,
          manual_override: %{min_units: float() | nil, max_units: float() | nil}
        }

  @doc """
  Calculate value outputs for selected plans.
  """
  @spec calculate(options()) :: map()
  def calculate(opts) do
    selected_plans = Subscriptions.selected_plans(opts.selected_plan_ids || [])

    calculated =
      Enum.map(selected_plans, fn plan ->
        calculate_plan(plan, opts)
      end)

    {ranked, insufficient} =
      Enum.split_with(calculated, fn result ->
        result.rankable? and result.confidence in [:high, :medium]
      end)

    ranked_sorted =
      ranked
      |> Enum.sort_by(&(&1.implied_api_value_usd_mid || 0), :desc)
      |> Enum.with_index(1)
      |> Enum.map(fn {result, rank} -> Map.put(result, :rank, rank) end)

    %{
      ranked: ranked_sorted,
      insufficient: insufficient,
      assumptions: %{
        selected_plan_ids: opts.selected_plan_ids,
        workload_profile: opts.workload_profile,
        model_mix_preset: opts.model_mix_preset,
        input_ratio: opts.input_ratio,
        output_ratio: 1.0 - opts.input_ratio,
        band_mode: opts.band_mode,
        manual_override: opts.manual_override
      }
    }
  end

  defp calculate_plan(plan, opts) do
    with {:ok, model_cost} <- blended_model_cost(plan, opts.model_mix_preset, opts.input_ratio),
         {:ok, usage_range, usage_source} <- usage_units_range(plan, opts.manual_override),
         {:ok, token_range} <-
           equivalent_tokens_range(
             plan.primary_unit,
             opts.workload_profile,
             opts.band_mode,
             usage_range
           ),
         {:ok, api_value_range} <- api_value_range(model_cost.blended_per_million, token_range),
         value_multiple <- value_multiple_range(api_value_range, plan.monthly_price_usd),
         confidence <- resolve_confidence(plan, usage_source, model_cost),
         drivers <- build_drivers(plan, opts, model_cost, usage_range, usage_source) do
      %{
        plan_id: plan.id,
        provider: plan.provider,
        plan_name: plan.name,
        monthly_price_usd: plan.monthly_price_usd,
        confidence: confidence,
        rankable?: confidence in [:high, :medium] and is_number(plan.monthly_price_usd),
        implied_api_value_usd_low: api_value_range.low,
        implied_api_value_usd_mid: api_value_range.mid,
        implied_api_value_usd_high: api_value_range.high,
        value_multiple_low: value_multiple.low,
        value_multiple_mid: value_multiple.mid,
        value_multiple_high: value_multiple.high,
        equivalent_tokens_low: token_range.low,
        equivalent_tokens_mid: token_range.mid,
        equivalent_tokens_high: token_range.high,
        blended_cost_per_million: model_cost.blended_per_million,
        drivers: drivers,
        source_urls: plan.source_urls,
        last_verified_on: plan.last_verified_on,
        usage_source: usage_source,
        usage_units_low: usage_range.low,
        usage_units_high: usage_range.high,
        cost_model_specs_used: model_cost.used_specs,
        cost_model_specs_missing: model_cost.missing_specs
      }
    else
      {:error, reason} ->
        %{
          plan_id: plan.id,
          provider: plan.provider,
          plan_name: plan.name,
          monthly_price_usd: plan.monthly_price_usd,
          confidence: :low,
          rankable?: false,
          implied_api_value_usd_low: nil,
          implied_api_value_usd_mid: nil,
          implied_api_value_usd_high: nil,
          value_multiple_low: nil,
          value_multiple_mid: nil,
          value_multiple_high: nil,
          equivalent_tokens_low: nil,
          equivalent_tokens_mid: nil,
          equivalent_tokens_high: nil,
          blended_cost_per_million: nil,
          drivers: fallback_drivers(plan, reason, opts.manual_override),
          source_urls: plan.source_urls,
          last_verified_on: plan.last_verified_on,
          usage_source: :unavailable,
          usage_units_low: nil,
          usage_units_high: nil,
          cost_model_specs_used: [],
          cost_model_specs_missing: Enum.map(plan.model_options || [], & &1.spec)
        }
    end
  end

  defp blended_model_cost(plan, mix_preset, input_ratio) do
    option_weights = model_option_weights(plan.model_options || [], mix_preset)

    {weighted, missing} =
      Enum.reduce(
        option_weights,
        {%{input: 0.0, output: 0.0, weight: 0.0, specs: []}, []},
        fn {option, weight}, {acc, missing_specs} ->
          case lookup_model_cost(option.spec) do
            {:ok, %{input: input_cost, output: output_cost}} ->
              updated = %{
                input: acc.input + input_cost * weight,
                output: acc.output + output_cost * weight,
                weight: acc.weight + weight,
                specs: [option.spec | acc.specs]
              }

              {updated, missing_specs}

            :error ->
              {acc, [option.spec | missing_specs]}
          end
        end
      )

    if weighted.weight <= 0.0 do
      {:error, :missing_model_costs}
    else
      normalized_input = weighted.input / weighted.weight
      normalized_output = weighted.output / weighted.weight
      blended = normalized_input * input_ratio + normalized_output * (1.0 - input_ratio)

      {:ok,
       %{
         input_per_million: normalized_input,
         output_per_million: normalized_output,
         blended_per_million: blended,
         used_specs: Enum.reverse(weighted.specs),
         missing_specs: Enum.reverse(missing)
       }}
    end
  end

  defp model_option_weights([], _mix_preset), do: []

  defp model_option_weights(options, mix_preset) do
    weights_for_preset = Map.get(@mix_weights, mix_preset, @mix_weights.balanced)

    weighted =
      Enum.map(options, fn option ->
        tier = Map.get(option, :tier, :balanced)
        {option, Map.get(weights_for_preset, tier, 0.0)}
      end)

    total_weight = weighted |> Enum.reduce(0.0, fn {_option, weight}, acc -> acc + weight end)

    normalized =
      if total_weight > 0.0 do
        Enum.map(weighted, fn {option, weight} -> {option, weight / total_weight} end)
      else
        fallback_weight = 1.0 / max(length(options), 1)
        Enum.map(options, fn option -> {option, fallback_weight} end)
      end

    normalized
  end

  defp lookup_model_cost(spec) when is_binary(spec) do
    case LLMDB.model(spec) do
      {:ok, model} ->
        input_cost = get_in(model.cost, [:input])
        output_cost = get_in(model.cost, [:output])

        if is_number(input_cost) and is_number(output_cost) do
          {:ok, %{input: input_cost * 1.0, output: output_cost * 1.0}}
        else
          :error
        end

      _ ->
        :error
    end
  end

  defp usage_units_range(plan, manual_override) do
    override_min = manual_override[:min_units]
    override_max = manual_override[:max_units]

    published_or_inferred? = is_number(plan.included_min) and is_number(plan.included_max)

    cond do
      plan.limit_type == :hard_numeric and published_or_inferred? ->
        monthly_scaled_units(plan.included_min, plan.included_max, plan.reset_window, :published)

      plan.limit_type == :multiplier and published_or_inferred? ->
        monthly_scaled_units(plan.included_min, plan.included_max, plan.reset_window, :inferred)

      is_number(override_min) and is_number(override_max) and override_min > 0 and
          override_max >= override_min ->
        monthly_scaled_units(override_min, override_max, plan.reset_window, :manual)

      true ->
        {:error, :missing_usage_range}
    end
  end

  defp monthly_scaled_units(min_units, max_units, reset_window, usage_source) do
    multiplier = Map.get(@window_multipliers, reset_window, 1.0)

    {:ok, %{low: min_units * multiplier, high: max_units * multiplier}, usage_source}
  end

  defp equivalent_tokens_range(primary_unit, workload_profile, band_mode, usage_range) do
    tokens_for_unit =
      @profile_tokens_per_unit
      |> Map.get(workload_profile, @profile_tokens_per_unit.daily)
      |> Map.get(primary_unit, @profile_tokens_per_unit.daily.mixed)

    band_multiplier = Map.get(@band_multipliers, band_mode, @band_multipliers.expected)

    {t_low, t_mid, t_high} = tokens_for_unit

    low = usage_range.low * t_low * band_multiplier
    mid = (usage_range.low + usage_range.high) / 2.0 * t_mid * band_multiplier
    high = usage_range.high * t_high * band_multiplier

    if low <= mid and mid <= high do
      {:ok, %{low: low, mid: mid, high: high}}
    else
      {:error, :invalid_token_band}
    end
  end

  defp api_value_range(blended_cost_per_million, token_range)
       when is_number(blended_cost_per_million) do
    {:ok,
     %{
       low: tokens_to_value(token_range.low, blended_cost_per_million),
       mid: tokens_to_value(token_range.mid, blended_cost_per_million),
       high: tokens_to_value(token_range.high, blended_cost_per_million)
     }}
  end

  defp tokens_to_value(tokens, cost_per_million)
       when is_number(tokens) and is_number(cost_per_million) do
    tokens / 1_000_000.0 * cost_per_million
  end

  defp value_multiple_range(_api_value_range, price) when not is_number(price) or price <= 0 do
    %{low: nil, mid: nil, high: nil}
  end

  defp value_multiple_range(api_value_range, price) do
    %{
      low: api_value_range.low / price,
      mid: api_value_range.mid / price,
      high: api_value_range.high / price
    }
  end

  defp resolve_confidence(plan, usage_source, model_cost) do
    cond do
      plan.limit_type == :opaque ->
        :low

      usage_source == :manual and plan.confidence_default == :high ->
        :medium

      usage_source == :manual and plan.confidence_default in [:medium, :low] ->
        :low

      model_cost.missing_specs != [] and plan.confidence_default == :high ->
        :medium

      true ->
        plan.confidence_default
    end
  end

  defp build_drivers(plan, opts, model_cost, usage_range, usage_source) do
    reset_window = window_label(plan.reset_window)
    input_pct = trunc(opts.input_ratio * 100)
    output_pct = 100 - input_pct
    source_text = usage_source_label(usage_source, plan)

    [
      "#{source_text}: #{round(usage_range.low)}-#{round(usage_range.high)} #{plan.primary_unit}/month",
      "Reset cadence: #{reset_window}",
      "Blended API cost: $#{format_currency(model_cost.blended_per_million)}/1M (#{input_pct}/#{output_pct} I/O)",
      "Workload profile: #{opts.workload_profile}"
    ]
  end

  defp fallback_drivers(plan, reason, manual_override) do
    base = ["Unable to calculate a full value band (#{reason_to_text(reason)})."]

    if is_number(manual_override[:min_units]) and is_number(manual_override[:max_units]) do
      base ++
        [
          "Manual override provided: #{manual_override[:min_units]}-#{manual_override[:max_units]} #{plan.primary_unit}/window."
        ]
    else
      base ++ ["Add a manual usage override to estimate this plan."]
    end
  end

  defp usage_source_label(:published, _plan), do: "Usage basis: published range"
  defp usage_source_label(:inferred, _plan), do: "Usage basis: inferred multiplier range"
  defp usage_source_label(:manual, _plan), do: "Usage basis: manual override applied"
  defp usage_source_label(_, _plan), do: "Usage basis: limited data"

  defp window_label(:rolling_5h), do: "rolling 5-hour window"
  defp window_label(:weekly), do: "weekly window"
  defp window_label(:monthly), do: "monthly window"
  defp window_label(:mixed), do: "mixed window semantics"
  defp window_label(_), do: "custom window"

  defp reason_to_text(:missing_model_costs), do: "no model costs available in LLMDB"
  defp reason_to_text(:missing_usage_range), do: "no published usage range"
  defp reason_to_text(:invalid_token_band), do: "invalid token range assumptions"
  defp reason_to_text(_), do: "unknown reason"

  defp format_currency(value) when is_number(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 2)
  end
end
