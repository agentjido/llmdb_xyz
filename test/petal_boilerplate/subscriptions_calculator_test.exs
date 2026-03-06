defmodule PetalBoilerplate.SubscriptionsCalculatorTest do
  use ExUnit.Case, async: true

  alias PetalBoilerplate.SubscriptionsCalculator

  test "returns deterministic monotonic band for hard numeric plan" do
    result =
      SubscriptionsCalculator.calculate(%{
        selected_plan_ids: ["openai_pro"],
        workload_profile: :daily,
        model_mix_preset: :balanced,
        input_ratio: 0.8,
        band_mode: :expected,
        manual_override: %{min_units: nil, max_units: nil}
      })

    assert [ranked] = result.ranked
    assert ranked.confidence == :high

    assert ranked.implied_api_value_usd_low <= ranked.implied_api_value_usd_mid
    assert ranked.implied_api_value_usd_mid <= ranked.implied_api_value_usd_high

    assert ranked.equivalent_tokens_low <= ranked.equivalent_tokens_mid
    assert ranked.equivalent_tokens_mid <= ranked.equivalent_tokens_high

    assert ranked.value_multiple_low <= ranked.value_multiple_mid
    assert ranked.value_multiple_mid <= ranked.value_multiple_high
  end

  test "opaque plans are not ranked by default" do
    result =
      SubscriptionsCalculator.calculate(%{
        selected_plan_ids: ["cursor_pro"],
        workload_profile: :daily,
        model_mix_preset: :balanced,
        input_ratio: 0.8,
        band_mode: :expected,
        manual_override: %{min_units: nil, max_units: nil}
      })

    assert result.ranked == []
    assert [insufficient] = result.insufficient
    assert insufficient.confidence == :low
    assert insufficient.rankable? == false
  end

  test "manual override enables estimation path for opaque plans" do
    result =
      SubscriptionsCalculator.calculate(%{
        selected_plan_ids: ["cursor_pro"],
        workload_profile: :daily,
        model_mix_preset: :balanced,
        input_ratio: 0.8,
        band_mode: :expected,
        manual_override: %{min_units: 50.0, max_units: 100.0}
      })

    assert result.ranked == []
    assert [insufficient] = result.insufficient
    assert insufficient.equivalent_tokens_mid > 0
    assert Enum.any?(insufficient.drivers, &String.contains?(&1, "manual override applied"))
  end

  test "high and medium confidence plans rank above low confidence plans" do
    result =
      SubscriptionsCalculator.calculate(%{
        selected_plan_ids: ["openai_plus", "anthropic_max_20x", "cursor_pro"],
        workload_profile: :daily,
        model_mix_preset: :balanced,
        input_ratio: 0.8,
        band_mode: :expected,
        manual_override: %{min_units: nil, max_units: nil}
      })

    assert length(result.ranked) >= 2
    assert Enum.all?(result.ranked, &(&1.confidence in [:high, :medium]))
    assert Enum.all?(result.insufficient, &(&1.confidence == :low))
  end
end
